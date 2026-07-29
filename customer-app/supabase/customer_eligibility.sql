-- Customer next-order eligibility and admin All Done approval. Safe to re-run.
alter table public.bookings add column if not exists all_done_at timestamptz;
alter table public.bookings add column if not exists all_done_by uuid;

create or replace function public.get_customer_order_eligibility(p_mobile text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare
  clean_mobile text:=regexp_replace(coalesce(p_mobile,''),'\D','','g');
  due_amount int:=0; pending_cans int:=0; open_code text; open_status text;
begin
  if length(clean_mobile)<>10 then
    return jsonb_build_object('eligible',false,'reason','Please login again.');
  end if;
  select coalesce(sum(balance),0) into due_amount from public.bookings
  where mobile=clean_mobile and status in ('confirmed','delivered') and balance>0;
  select coalesce(sum(a.quantity-a.returned_quantity-a.damaged_quantity),0)
  into pending_cans
  from public.booking_can_allocations a
  join public.bookings b on b.id=a.booking_id
  where b.mobile=clean_mobile and a.state='delivered';
  select booking_code,status into open_code,open_status
  from public.bookings
  where mobile=clean_mobile and status in ('pending','confirmed','delivered')
    and all_done_at is null
  order by created_at desc limit 1;

  if due_amount>0 then
    return jsonb_build_object(
      'eligible',false,'reason',
      'Previous payment of '||chr(8377)||due_amount||' is pending. Please clear it before placing a new order.',
      'pending_dues',due_amount,'pending_cans',pending_cans,'booking_code',open_code
    );
  end if;
  if pending_cans>0 then
    return jsonb_build_object(
      'eligible',false,'reason',
      pending_cans||' empty cans are pending for return. Please return them before placing a new order.',
      'pending_dues',due_amount,'pending_cans',pending_cans,'booking_code',open_code
    );
  end if;
  if open_code is not null then
    return jsonb_build_object(
      'eligible',false,'reason',
      case when open_status='pending'
        then 'Your previous cash booking '||open_code||' is awaiting confirmation.'
        else 'Your previous order '||open_code||' is not marked All Done yet.'
      end,
      'pending_dues',0,'pending_cans',0,'booking_code',open_code
    );
  end if;
  return jsonb_build_object(
    'eligible',true,'reason','','pending_dues',0,'pending_cans',0
  );
end $$;
grant execute on function public.get_customer_order_eligibility(text)
  to anon,authenticated,service_role;

create or replace function public.mark_booking_all_done(p_booking_id uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare b public.bookings%rowtype; a public.booking_can_allocations%rowtype;
begin
  select * into b from public.bookings where id=p_booking_id for update;
  if b.id is null then raise exception 'BOOKING_NOT_FOUND'; end if;
  if b.all_done_at is not null then
    return jsonb_build_object('already_done',true,'booking_code',b.booking_code);
  end if;
  if b.status<>'delivered' then raise exception 'DELIVERY_NOT_COMPLETE'; end if;
  if b.balance>0 then raise exception 'PAYMENT_PENDING'; end if;
  select * into a from public.booking_can_allocations where booking_id=b.id;
  if a.id is null or a.state<>'closed' then raise exception 'CANS_PENDING'; end if;
  update public.bookings set all_done_at=now(),all_done_by=auth.uid()
  where id=b.id;
  return jsonb_build_object('already_done',false,'booking_code',b.booking_code);
end $$;
revoke all on function public.mark_booking_all_done(uuid) from public,anon;
grant execute on function public.mark_booking_all_done(uuid) to authenticated;

create or replace function public.block_ineligible_cash_booking()
returns trigger language plpgsql security definer set search_path=public as $$
declare result jsonb; jwt_role text;
begin
  jwt_role:=coalesce(current_setting('request.jwt.claim.role',true),'');
  if jwt_role<>'service_role' then
    result:=public.get_customer_order_eligibility(new.mobile);
    if not coalesce((result->>'eligible')::boolean,false) then
      raise exception 'CUSTOMER_NOT_ELIGIBLE: %',result->>'reason';
    end if;
  end if;
  return new;
end $$;
drop trigger if exists bookings_customer_eligibility on public.bookings;
create trigger bookings_customer_eligibility
before insert on public.bookings
for each row execute function public.block_ineligible_cash_booking();
