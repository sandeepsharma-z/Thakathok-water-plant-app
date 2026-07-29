-- Automatic, ledger-backed can inventory. Safe to re-run.
alter table public.can_inventory
  add column if not exists reserved_cans int not null default 0
  check (reserved_cans >= 0);

create table if not exists public.booking_can_allocations (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references public.bookings(id) on delete cascade,
  branch_id uuid not null references public.branches(id),
  quantity int not null check (quantity > 0),
  returned_quantity int not null default 0 check (returned_quantity >= 0),
  damaged_quantity int not null default 0 check (damaged_quantity >= 0),
  state text not null default 'waiting'
    check (state in ('waiting','reserved','delivered','closed','cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (returned_quantity + damaged_quantity <= quantity)
);

create table if not exists public.can_inventory_movements (
  id bigint generated always as identity primary key,
  branch_id uuid not null references public.branches(id),
  booking_id uuid references public.bookings(id) on delete set null,
  movement_type text not null check (movement_type in (
    'stock_added','stock_removed','reserved','reservation_released',
    'delivered','returned','damaged','repaired'
  )),
  quantity int not null check (quantity > 0),
  note text not null default '',
  available_after int not null,
  reserved_after int not null,
  out_after int not null,
  damaged_after int not null,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

create index if not exists can_allocations_branch_state_idx
  on public.booking_can_allocations(branch_id, state);
create index if not exists can_movements_branch_created_idx
  on public.can_inventory_movements(branch_id, created_at desc);

alter table public.booking_can_allocations enable row level security;
alter table public.can_inventory_movements enable row level security;
drop policy if exists can_allocations_admin_all on public.booking_can_allocations;
create policy can_allocations_admin_all on public.booking_can_allocations
  for all to authenticated using (true) with check (true);
drop policy if exists can_movements_admin_read on public.can_inventory_movements;
create policy can_movements_admin_read on public.can_inventory_movements
  for select to authenticated using (true);

create or replace function public.log_can_movement(
  p_branch_id uuid, p_booking_id uuid, p_type text, p_quantity int, p_note text default ''
) returns void language plpgsql security definer set search_path=public as $$
declare inv public.can_inventory%rowtype;
begin
  select * into inv from public.can_inventory where branch_id=p_branch_id;
  insert into public.can_inventory_movements(
    branch_id,booking_id,movement_type,quantity,note,
    available_after,reserved_after,out_after,damaged_after
  ) values (
    p_branch_id,p_booking_id,p_type,p_quantity,coalesce(p_note,''),
    inv.available_cans,inv.reserved_cans,inv.out_for_delivery,inv.damaged_cans
  );
end $$;

create or replace function public.try_allocate_booking_cans(p_booking_id uuid)
returns text language plpgsql security definer set search_path=public as $$
declare
  b public.bookings%rowtype;
  a public.booking_can_allocations%rowtype;
  chosen_branch uuid;
  available int;
begin
  select * into b from public.bookings where id=p_booking_id;
  if b.id is null or b.status <> 'confirmed' then return 'not_confirmed'; end if;

  select coalesce(v.branch_id, main.id) into chosen_branch
  from (select id from public.branches where code='MAIN' limit 1) main
  left join public.villages v on lower(trim(v.name))=lower(trim(b.village))
  limit 1;
  if chosen_branch is null then raise exception 'NO_BRANCH_CONFIGURED'; end if;

  insert into public.can_inventory(branch_id) values(chosen_branch)
  on conflict(branch_id) do nothing;
  insert into public.booking_can_allocations(booking_id,branch_id,quantity)
  values(b.id,chosen_branch,b.cans)
  on conflict(booking_id) do nothing;

  select * into a from public.booking_can_allocations
  where booking_id=b.id for update;
  if a.state <> 'waiting' then return a.state; end if;

  select available_cans into available from public.can_inventory
  where branch_id=a.branch_id for update;
  if available < a.quantity then return 'waiting'; end if;

  update public.can_inventory
  set available_cans=available_cans-a.quantity,
      reserved_cans=reserved_cans+a.quantity,
      updated_at=now()
  where branch_id=a.branch_id;
  update public.booking_can_allocations
  set state='reserved',updated_at=now() where id=a.id;
  perform public.log_can_movement(
    a.branch_id,b.id,'reserved',a.quantity,'Reserved for '||b.booking_code
  );
  return 'reserved';
end $$;

create or replace function public.sync_booking_can_inventory()
returns trigger language plpgsql security definer set search_path=public as $$
declare a public.booking_can_allocations%rowtype;
begin
  if new.status='confirmed' and
     (tg_op='INSERT' or old.status is distinct from 'confirmed') then
    perform public.try_allocate_booking_cans(new.id);
  end if;

  if tg_op='UPDATE' and new.status='cancelled' and old.status='confirmed' then
    select * into a from public.booking_can_allocations
    where booking_id=new.id for update;
    if a.state='reserved' then
      update public.can_inventory
      set available_cans=available_cans+a.quantity,
          reserved_cans=reserved_cans-a.quantity,updated_at=now()
      where branch_id=a.branch_id;
      update public.booking_can_allocations set state='cancelled',updated_at=now()
      where id=a.id;
      perform public.log_can_movement(
        a.branch_id,new.id,'reservation_released',a.quantity,
        'Cancelled '||new.booking_code
      );
    elsif a.state='waiting' then
      update public.booking_can_allocations set state='cancelled',updated_at=now()
      where id=a.id;
    end if;
  end if;

  if tg_op='UPDATE' and new.status='delivered' and old.status='confirmed' then
    select * into a from public.booking_can_allocations
    where booking_id=new.id for update;
    if a.id is null then
      perform public.try_allocate_booking_cans(new.id);
      select * into a from public.booking_can_allocations
      where booking_id=new.id for update;
    end if;
    if a.state <> 'reserved' then
      raise exception 'INSUFFICIENT_CAN_STOCK';
    end if;
    update public.can_inventory
    set reserved_cans=reserved_cans-a.quantity,
        out_for_delivery=out_for_delivery+a.quantity,updated_at=now()
    where branch_id=a.branch_id;
    update public.booking_can_allocations set state='delivered',updated_at=now()
    where id=a.id;
    perform public.log_can_movement(
      a.branch_id,new.id,'delivered',a.quantity,'Delivered '||new.booking_code
    );
  end if;
  return new;
end $$;

drop trigger if exists bookings_can_inventory_sync on public.bookings;
create trigger bookings_can_inventory_sync
after insert or update of status on public.bookings
for each row execute function public.sync_booking_can_inventory();

create or replace function public.adjust_can_inventory(
  p_branch_id uuid, p_action text, p_quantity int, p_note text default ''
) returns jsonb language plpgsql security definer set search_path=public as $$
declare inv public.can_inventory%rowtype; waiting record;
begin
  if p_quantity <= 0 then raise exception 'INVALID_QUANTITY'; end if;
  insert into public.can_inventory(branch_id) values(p_branch_id)
  on conflict(branch_id) do nothing;
  select * into inv from public.can_inventory where branch_id=p_branch_id for update;

  if p_action='add' then
    update public.can_inventory set total_cans=total_cans+p_quantity,
      available_cans=available_cans+p_quantity,updated_at=now()
    where branch_id=p_branch_id;
    perform public.log_can_movement(p_branch_id,null,'stock_added',p_quantity,p_note);
  elsif p_action='remove' then
    if inv.available_cans < p_quantity then raise exception 'INSUFFICIENT_AVAILABLE'; end if;
    update public.can_inventory set total_cans=total_cans-p_quantity,
      available_cans=available_cans-p_quantity,updated_at=now()
    where branch_id=p_branch_id;
    perform public.log_can_movement(p_branch_id,null,'stock_removed',p_quantity,p_note);
  elsif p_action='damage' then
    if inv.available_cans < p_quantity then raise exception 'INSUFFICIENT_AVAILABLE'; end if;
    update public.can_inventory set available_cans=available_cans-p_quantity,
      damaged_cans=damaged_cans+p_quantity,updated_at=now()
    where branch_id=p_branch_id;
    perform public.log_can_movement(p_branch_id,null,'damaged',p_quantity,p_note);
  elsif p_action='repair' then
    if inv.damaged_cans < p_quantity then raise exception 'INSUFFICIENT_DAMAGED'; end if;
    update public.can_inventory set damaged_cans=damaged_cans-p_quantity,
      available_cans=available_cans+p_quantity,updated_at=now()
    where branch_id=p_branch_id;
    perform public.log_can_movement(p_branch_id,null,'repaired',p_quantity,p_note);
  else raise exception 'INVALID_ACTION';
  end if;

  if p_action in ('add','repair') then
    for waiting in
      select a.booking_id from public.booking_can_allocations a
      join public.bookings b on b.id=a.booking_id
      where a.branch_id=p_branch_id and a.state='waiting'
      order by b.event_date,b.created_at
    loop
      perform public.try_allocate_booking_cans(waiting.booking_id);
    end loop;
  end if;
  select * into inv from public.can_inventory where branch_id=p_branch_id;
  return to_jsonb(inv);
end $$;

create or replace function public.record_can_return(
  p_booking_id uuid, p_returned int, p_damaged int, p_note text default ''
) returns jsonb language plpgsql security definer set search_path=public as $$
declare a public.booking_can_allocations%rowtype; remaining int;
begin
  if p_returned < 0 or p_damaged < 0 or p_returned+p_damaged <= 0 then
    raise exception 'INVALID_QUANTITY';
  end if;
  select * into a from public.booking_can_allocations
  where booking_id=p_booking_id for update;
  if public.current_delivery_staff_id() is not null and not exists(
    select 1 from public.bookings b
    where b.id=p_booking_id
      and b.assigned_staff_id=public.current_delivery_staff_id()
  ) then raise exception 'NOT_ASSIGNED'; end if;
  if a.state not in ('delivered','closed') then raise exception 'NOT_DELIVERED'; end if;
  remaining:=a.quantity-a.returned_quantity-a.damaged_quantity;
  if p_returned+p_damaged > remaining then raise exception 'EXCEEDS_PENDING_CANS'; end if;
  update public.can_inventory set
    out_for_delivery=out_for_delivery-p_returned-p_damaged,
    available_cans=available_cans+p_returned,
    damaged_cans=damaged_cans+p_damaged,updated_at=now()
  where branch_id=a.branch_id;
  update public.booking_can_allocations set
    returned_quantity=returned_quantity+p_returned,
    damaged_quantity=damaged_quantity+p_damaged,
    state=case when p_returned+p_damaged=remaining then 'closed' else 'delivered' end,
    updated_at=now()
  where id=a.id returning * into a;
  if p_returned>0 then
    perform public.log_can_movement(a.branch_id,p_booking_id,'returned',p_returned,p_note);
  end if;
  if p_damaged>0 then
    perform public.log_can_movement(a.branch_id,p_booking_id,'damaged',p_damaged,p_note);
  end if;
  return to_jsonb(a);
end $$;

revoke all on function public.adjust_can_inventory(uuid,text,int,text) from public,anon;
grant execute on function public.adjust_can_inventory(uuid,text,int,text) to authenticated;
revoke all on function public.record_can_return(uuid,int,int,text) from public,anon;
grant execute on function public.record_can_return(uuid,int,int,text) to authenticated;

-- Backfill confirmed/delivered rows without rewriting historical inventory.
insert into public.booking_can_allocations(booking_id,branch_id,quantity,state)
select b.id,coalesce(v.branch_id,main.id),b.cans,
  case when b.status='delivered' then 'delivered' else 'waiting' end
from public.bookings b
cross join lateral (select id from public.branches where code='MAIN' limit 1) main
left join public.villages v on lower(trim(v.name))=lower(trim(b.village))
where b.status in ('confirmed','delivered')
on conflict(booking_id) do nothing;
