alter table public.settings
  add column if not exists minimum_notice_minutes int not null default 60,
  add column if not exists max_cans_per_day int not null default 200,
  add column if not exists empty_can_return_hours int not null default 48,
  add column if not exists lost_damaged_can_charge int not null default 600;

alter table public.settings
  drop constraint if exists settings_minimum_notice_minutes_check,
  add constraint settings_minimum_notice_minutes_check
    check (minimum_notice_minutes in (30,60,120,180)),
  drop constraint if exists settings_max_cans_per_day_check,
  add constraint settings_max_cans_per_day_check check (max_cans_per_day > 0),
  drop constraint if exists settings_empty_can_return_hours_check,
  add constraint settings_empty_can_return_hours_check check (empty_can_return_hours > 0),
  drop constraint if exists settings_lost_damaged_can_charge_check,
  add constraint settings_lost_damaged_can_charge_check check (lost_damaged_can_charge >= 0);

-- A confirmed order no longer blocks the whole date. Manual plant holidays
-- remain blocked and capacity is enforced by total confirmed cans.
drop trigger if exists bookings_sync_blocked_date on public.bookings;
delete from public.blocked_dates where source='booking';

create or replace function public.enforce_final_booking_rules()
returns trigger language plpgsql security definer set search_path=public as $$
declare
  cfg public.settings%rowtype;
  requested_at timestamptz;
  booked int;
  usable_stock int;
  daily_limit int;
begin
  if new.status='cancelled' then return new; end if;
  select * into cfg from public.settings where id=1;

  if exists (
    select 1 from public.blocked_dates d
    where d.blocked_date=new.event_date and d.source='manual'
  ) then raise exception 'DATE_UNAVAILABLE'; end if;

  if tg_op='INSERT'
     or new.event_date is distinct from old.event_date
     or new.event_time is distinct from old.event_time then
    begin
      requested_at :=
        (new.event_date + to_timestamp(new.event_time,'HH12:MI AM')::time)
        at time zone 'Asia/Kolkata';
    exception when others then
      raise exception 'INVALID_DELIVERY_TIME';
    end;
    if requested_at < now() + make_interval(mins=>cfg.minimum_notice_minutes) then
      raise exception 'MINIMUM_NOTICE_%',cfg.minimum_notice_minutes;
    end if;
  end if;

  if new.status='confirmed' and (
    tg_op='INSERT' or old.status is distinct from new.status
    or old.event_date is distinct from new.event_date
    or old.cans is distinct from new.cans
  ) then
    select coalesce(sum(greatest(total_cans-damaged_cans,0)),0)
      into usable_stock from public.can_inventory;
    daily_limit := case when usable_stock>0
      then least(cfg.max_cans_per_day,usable_stock)
      else cfg.max_cans_per_day end;
    select coalesce(sum(cans),0) into booked
      from public.bookings
      where event_date=new.event_date and status='confirmed'
        and id is distinct from new.id;
    if booked+new.cans>daily_limit then
      raise exception 'DAILY_CAPACITY_%_%',daily_limit,greatest(daily_limit-booked,0);
    end if;
  end if;
  return new;
end $$;

drop trigger if exists bookings_enforce_available_date on public.bookings;
drop trigger if exists bookings_enforce_final_rules on public.bookings;
create trigger bookings_enforce_final_rules
before insert or update of event_date,event_time,status,cans on public.bookings
for each row execute function public.enforce_final_booking_rules();

create table if not exists public.booking_requests (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  mobile text not null,
  request_type text not null check (request_type in ('cancellation','change')),
  reason text not null,
  proposed_event_date date,
  proposed_event_time text,
  proposed_cans int check (proposed_cans is null or proposed_cans > 0),
  proposed_address text,
  status text not null default 'pending'
    check (status in ('pending','approved','rejected')),
  admin_note text,
  reviewed_at timestamptz,
  reviewed_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index if not exists booking_requests_one_pending
  on public.booking_requests(booking_id) where status='pending';
create index if not exists booking_requests_status_idx
  on public.booking_requests(status,created_at desc);
alter table public.booking_requests enable row level security;
drop policy if exists booking_requests_admin_all on public.booking_requests;
create policy booking_requests_admin_all on public.booking_requests
  for all to authenticated using(public.current_user_is_admin())
  with check(public.current_user_is_admin());

create or replace function public.review_booking_request(
  p_request_id uuid,p_decision text,p_admin_note text default ''
) returns jsonb language plpgsql security definer set search_path=public as $$
declare
  req public.booking_requests%rowtype;
  b public.bookings%rowtype;
  cfg public.settings%rowtype;
  new_cans int;
  new_subtotal int;
  new_discount int;
  new_delivery int;
  new_total int;
  new_advance int;
  allocation public.booking_can_allocations%rowtype;
  delta int;
begin
  if not public.current_user_is_admin() then raise exception 'ADMIN_REQUIRED'; end if;
  if p_decision not in ('approved','rejected') then raise exception 'INVALID_DECISION'; end if;
  select * into req from public.booking_requests where id=p_request_id for update;
  if req.id is null then raise exception 'REQUEST_NOT_FOUND'; end if;
  if req.status<>'pending' then raise exception 'REQUEST_ALREADY_REVIEWED'; end if;
  select * into b from public.bookings where id=req.booking_id for update;
  if b.id is null then raise exception 'BOOKING_NOT_FOUND'; end if;

  if p_decision='approved' then
    if req.request_type='cancellation' then
      perform public.cancel_booking_by_admin(b.id,'Customer request approved: '||req.reason);
    else
      if b.status not in ('pending','confirmed') then raise exception 'CHANGE_NOT_ALLOWED'; end if;
      select * into cfg from public.settings where id=1;
      new_cans:=coalesce(req.proposed_cans,b.cans);
      new_subtotal:=new_cans*b.per_can_rate;
      new_discount:=round(new_subtotal*coalesce(b.offer_discount_percent,0)/100.0);
      new_delivery:=case when new_cans>=cfg.delivery_free_threshold
          or b.village=cfg.free_delivery_village then 0
          else coalesce((select delivery_charge from public.villages where name=b.village),cfg.delivery_charge) end;
      new_total:=new_subtotal-new_discount+new_delivery;
      new_advance:=case when b.status='pending'
        then round(new_total*cfg.advance_percent/100.0) else b.advance end;

      if b.status='confirmed' and new_cans<>b.cans then
        select * into allocation from public.booking_can_allocations
          where booking_id=b.id for update;
        if allocation.id is not null and allocation.state='reserved' then
          delta:=new_cans-allocation.quantity;
          if delta>0 and (select available_cans from public.can_inventory where branch_id=allocation.branch_id)<delta
            then raise exception 'INSUFFICIENT_STOCK'; end if;
          update public.can_inventory set
            available_cans=available_cans-delta,
            reserved_cans=reserved_cans+delta,updated_at=now()
            where branch_id=allocation.branch_id;
          update public.booking_can_allocations set quantity=new_cans,updated_at=now()
            where id=allocation.id;
        end if;
      end if;

      update public.bookings set
        event_date=coalesce(req.proposed_event_date,b.event_date),
        event_time=coalesce(nullif(trim(req.proposed_event_time),''),b.event_time),
        cans=new_cans,subtotal=new_subtotal,discount_amount=new_discount,
        delivery_charge=new_delivery,
        grand_total=new_total,advance=new_advance,
        balance=greatest(new_total-new_advance,0),
        address=coalesce(nullif(trim(req.proposed_address),''),b.address)
      where id=b.id;
    end if;
  end if;

  update public.booking_requests set status=p_decision,
    admin_note=nullif(trim(coalesce(p_admin_note,'')),''),
    reviewed_at=now(),reviewed_by=auth.uid(),updated_at=now()
    where id=req.id;
  return jsonb_build_object('ok',true,'decision',p_decision,'type',req.request_type);
end $$;
revoke all on function public.review_booking_request(uuid,text,text) from public,anon;
grant execute on function public.review_booking_request(uuid,text,text) to authenticated;

-- Lost/damaged jars immediately become a customer due using the configured
-- replacement cost while the physical stock moves to damaged inventory.
create or replace function public.record_can_return(
  p_booking_id uuid, p_returned int, p_damaged int, p_note text default ''
) returns jsonb language plpgsql security definer set search_path=public as $$
declare a public.booking_can_allocations%rowtype; inv public.can_inventory%rowtype;
  remaining int; penalty int; charge int;
begin
  if not public.current_user_is_admin() and public.current_delivery_staff_id() is null
    then raise exception 'ACCESS_DENIED'; end if;
  if p_returned<0 or p_damaged<0 or p_returned+p_damaged<=0
    then raise exception 'INVALID_RETURN'; end if;
  select * into a from public.booking_can_allocations where booking_id=p_booking_id for update;
  if a.id is null or a.state not in ('delivered','reserved') then raise exception 'NO_PENDING_CANS'; end if;
  remaining:=a.quantity-a.returned_quantity-a.damaged_quantity;
  if p_returned+p_damaged>remaining then raise exception 'EXCEEDS_PENDING_CANS'; end if;
  select * into inv from public.can_inventory where branch_id=a.branch_id for update;
  update public.can_inventory set
    out_for_delivery=greatest(out_for_delivery-p_returned-p_damaged,0),
    reserved_cans=case when a.state='reserved' then greatest(reserved_cans-p_returned-p_damaged,0) else reserved_cans end,
    available_cans=available_cans+p_returned,
    damaged_cans=damaged_cans+p_damaged,updated_at=now()
    where branch_id=a.branch_id;
  update public.booking_can_allocations set
    returned_quantity=returned_quantity+p_returned,
    damaged_quantity=damaged_quantity+p_damaged,
    state=case when p_returned+p_damaged=remaining then 'closed' else 'delivered' end,
    updated_at=now() where id=a.id returning * into a;
  if p_returned>0 then perform public.log_can_movement(a.branch_id,p_booking_id,'returned',p_returned,p_note); end if;
  if p_damaged>0 then perform public.log_can_movement(a.branch_id,p_booking_id,'damaged',p_damaged,p_note); end if;
  select lost_damaged_can_charge into charge from public.settings where id=1;
  penalty:=p_damaged*coalesce(charge,600);
  if penalty>0 then
    update public.bookings set grand_total=grand_total+penalty,balance=balance+penalty
      where id=p_booking_id;
  end if;
  return jsonb_build_object('allocation',to_jsonb(a),'penalty_added',penalty);
end $$;
