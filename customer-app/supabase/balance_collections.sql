-- Immutable booking payment collection ledger. Safe to re-run.
alter table public.bookings
  add column if not exists fully_paid_at timestamptz;

create table if not exists public.booking_collections (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete restrict,
  collection_type text not null check (collection_type in ('advance','balance')),
  amount int not null check (amount > 0),
  method text not null check (method in ('cash','online','wallet','upi','bank','other')),
  reference text not null default '',
  note text not null default '',
  collected_by uuid default auth.uid(),
  collected_at timestamptz not null default now(),
  unique (booking_id, collection_type)
);
create index if not exists booking_collections_created_idx
  on public.booking_collections(collected_at desc);

alter table public.booking_collections enable row level security;
drop policy if exists booking_collections_admin_read on public.booking_collections;
create policy booking_collections_admin_read on public.booking_collections
  for select to authenticated using (true);

create or replace function public.collect_booking_balance(
  p_booking_id uuid,
  p_method text,
  p_reference text default '',
  p_note text default ''
) returns jsonb
language plpgsql security definer set search_path=public as $$
declare b public.bookings%rowtype; collected_id uuid; due int;
begin
  if p_method not in ('cash','upi','bank','other') then
    raise exception 'INVALID_METHOD';
  end if;
  select * into b from public.bookings where id=p_booking_id for update;
  if b.id is null then raise exception 'BOOKING_NOT_FOUND'; end if;
  if public.current_delivery_staff_id() is not null
     and b.assigned_staff_id<>public.current_delivery_staff_id() then
    raise exception 'NOT_ASSIGNED';
  end if;
  if b.status not in ('confirmed','delivered') then
    raise exception 'BOOKING_NOT_COLLECTIBLE';
  end if;
  if b.balance <= 0 then
    select id into collected_id from public.booking_collections
    where booking_id=b.id and collection_type='balance';
    return jsonb_build_object(
      'booking_id',b.id,'booking_code',b.booking_code,'amount',0,
      'already_collected',true,'collection_id',collected_id
    );
  end if;
  due:=b.balance;
  insert into public.booking_collections(
    booking_id,collection_type,amount,method,reference,note
  ) values (
    b.id,'balance',due,p_method,trim(coalesce(p_reference,'')),
    trim(coalesce(p_note,''))
  ) returning id into collected_id;
  update public.bookings
  set balance=0,fully_paid_at=now() where id=b.id;
  return jsonb_build_object(
    'booking_id',b.id,'booking_code',b.booking_code,'amount',due,
    'already_collected',false,'collection_id',collected_id
  );
exception when unique_violation then
  return jsonb_build_object(
    'booking_id',b.id,'booking_code',b.booking_code,'amount',0,
    'already_collected',true
  );
end $$;

revoke all on function public.collect_booking_balance(uuid,text,text,text)
  from public,anon;
grant execute on function public.collect_booking_balance(uuid,text,text,text)
  to authenticated;

-- Snapshot existing confirmed/delivered advances into the immutable ledger.
insert into public.booking_collections(
  booking_id,collection_type,amount,method,reference,note,collected_at
)
select id,'advance',advance,
  case payment_method
    when 'online' then 'online'
    when 'wallet' then 'wallet'
    else 'cash'
  end,
  coalesce(razorpay_payment_id,''),
  'Initial 30% booking advance',
  created_at
from public.bookings
where status in ('confirmed','delivered') and advance>0
on conflict(booking_id,collection_type) do nothing;
