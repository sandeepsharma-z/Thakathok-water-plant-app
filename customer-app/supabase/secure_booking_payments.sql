-- Secure Razorpay order binding for online booking advances. Safe to re-run.
create table if not exists public.booking_payment_orders (
  razorpay_order_id text primary key,
  mobile text not null,
  amount int not null check(amount > 0),
  booking_payload jsonb not null,
  status text not null default 'created'
    check(status in ('created','confirmed','failed')),
  razorpay_payment_id text unique,
  created_at timestamptz not null default now(),
  confirmed_at timestamptz
);
create index if not exists booking_payment_orders_mobile_idx
  on public.booking_payment_orders(mobile,created_at desc);
alter table public.booking_payment_orders enable row level security;
drop policy if exists booking_payment_orders_admin_read on public.booking_payment_orders;
create policy booking_payment_orders_admin_read on public.booking_payment_orders
  for select to authenticated using(true);

alter table public.bookings add column if not exists razorpay_order_id text;
alter table public.bookings add column if not exists razorpay_payment_id text;
create unique index if not exists bookings_razorpay_order_unique
  on public.bookings(razorpay_order_id) where razorpay_order_id is not null;
create unique index if not exists bookings_razorpay_payment_unique
  on public.bookings(razorpay_payment_id) where razorpay_payment_id is not null;

create or replace function public.finalize_verified_booking_payment(
  p_order_id text, p_payment_id text
) returns jsonb
language plpgsql security definer set search_path=public as $$
declare
  payment_order public.booking_payment_orders%rowtype;
  p jsonb;
  new_booking_id uuid;
  code text;
begin
  select * into payment_order from public.booking_payment_orders
  where razorpay_order_id=p_order_id for update;
  if payment_order.razorpay_order_id is null then raise exception 'ORDER_NOT_FOUND'; end if;
  if payment_order.status='confirmed' then
    select id,booking_code into new_booking_id,code from public.bookings
      where razorpay_order_id=p_order_id;
    return jsonb_build_object('booking_id',new_booking_id,'booking_code',code,'already_confirmed',true);
  end if;
  p:=payment_order.booking_payload;
  insert into public.bookings(
    booking_code,customer_name,event_type,cans,per_can_rate,subtotal,
    delivery_charge,grand_total,advance,balance,village,mobile,address,
    event_date,event_time,payment_method,offer_code,offer_discount_percent,
    discount_amount,status,razorpay_order_id,razorpay_payment_id
  ) values (
    p->>'booking_code',p->>'customer_name',p->>'event_type',(p->>'cans')::int,
    (p->>'per_can_rate')::int,(p->>'subtotal')::int,(p->>'delivery_charge')::int,
    (p->>'grand_total')::int,(p->>'advance')::int,(p->>'balance')::int,
    p->>'village',p->>'mobile',p->>'address',(p->>'event_date')::date,
    p->>'event_time','online',nullif(p->>'offer_code',''),
    (p->>'offer_discount_percent')::int,(p->>'discount_amount')::int,
    'confirmed',p_order_id,p_payment_id
  ) returning id,booking_code into new_booking_id,code;
  update public.booking_payment_orders set status='confirmed',
    razorpay_payment_id=p_payment_id,confirmed_at=now()
    where razorpay_order_id=p_order_id;
  return jsonb_build_object('booking_id',new_booking_id,'booking_code',code,'already_confirmed',false);
exception when unique_violation then
  select id,booking_code into new_booking_id,code from public.bookings
    where razorpay_order_id=p_order_id or razorpay_payment_id=p_payment_id limit 1;
  return jsonb_build_object('booking_id',new_booking_id,'booking_code',code,'already_confirmed',true);
end $$;
revoke all on function public.finalize_verified_booking_payment(text,text)
  from public,anon,authenticated;
grant execute on function public.finalize_verified_booking_payment(text,text)
  to service_role;
