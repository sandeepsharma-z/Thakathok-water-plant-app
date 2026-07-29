-- Scalable delivery-staff panel. Safe to re-run.
create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
insert into public.admin_users(user_id)
select id from auth.users
where coalesce(email,'') not like '%@staff.thakathok.local'
  and coalesce(email,'') not like 'staff.%@mahalakshmiwaterplant.com'
on conflict(user_id) do nothing;

create table if not exists public.delivery_staff (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  name text not null,
  mobile text not null unique,
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.bookings
  add column if not exists assigned_staff_id uuid
    references public.delivery_staff(id) on delete set null;
alter table public.bookings
  add column if not exists assigned_at timestamptz;

create table if not exists public.delivery_records (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references public.bookings(id) on delete restrict,
  staff_id uuid not null references public.delivery_staff(id) on delete restrict,
  delivered_at timestamptz not null default now(),
  cash_collected int not null default 0 check (cash_collected >= 0),
  empty_cans_returned int not null default 0 check (empty_cans_returned >= 0),
  proof_photo_url text,
  customer_signature text,
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists bookings_staff_idx
  on public.bookings(assigned_staff_id,event_date);
create index if not exists delivery_records_staff_idx
  on public.delivery_records(staff_id,delivered_at desc);

alter table public.delivery_staff enable row level security;
alter table public.delivery_records enable row level security;
alter table public.admin_users enable row level security;
drop policy if exists admin_users_own_read on public.admin_users;
create policy admin_users_own_read on public.admin_users
  for select to authenticated using(user_id=auth.uid());

create or replace function public.current_delivery_staff_id()
returns uuid language sql stable security definer set search_path=public as $$
  select id from public.delivery_staff
  where user_id=auth.uid() limit 1
$$;
revoke all on function public.current_delivery_staff_id() from public,anon;
grant execute on function public.current_delivery_staff_id() to authenticated;
create or replace function public.current_delivery_staff_enabled()
returns boolean language sql stable security definer set search_path=public as $$
  select exists(
    select 1 from public.delivery_staff where user_id=auth.uid() and enabled
  )
$$;
revoke all on function public.current_delivery_staff_enabled() from public,anon;
grant execute on function public.current_delivery_staff_enabled() to authenticated;
create or replace function public.current_user_is_admin()
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.admin_users where user_id=auth.uid())
$$;
revoke all on function public.current_user_is_admin() from public,anon;
grant execute on function public.current_user_is_admin() to authenticated;

-- Replace legacy "any authenticated user" write access with explicit admin access.
drop policy if exists settings_admin_update on public.settings;
create policy settings_admin_update on public.settings for update to authenticated
  using(public.current_user_is_admin()) with check(public.current_user_is_admin());
drop policy if exists bookings_admin_update on public.bookings;
create policy bookings_admin_update on public.bookings for update to authenticated
  using(public.current_user_is_admin()) with check(public.current_user_is_admin());
drop policy if exists bookings_read on public.bookings;
create policy bookings_read on public.bookings for select to anon using(true);
drop policy if exists bookings_admin_read on public.bookings;
create policy bookings_admin_read on public.bookings for select to authenticated
  using(public.current_user_is_admin());
drop policy if exists customers_admin_all on public.customers;
create policy customers_admin_all on public.customers for all to authenticated
  using(public.current_user_is_admin()) with check(public.current_user_is_admin());
drop policy if exists customers_anon_read on public.customers;
create policy customers_anon_read on public.customers for select to anon using(true);

drop policy if exists delivery_staff_admin_all on public.delivery_staff;
create policy delivery_staff_admin_all on public.delivery_staff
  for all to authenticated
  using (
    public.current_user_is_admin()
    or user_id=auth.uid()
  )
  with check (
    public.current_user_is_admin()
    or user_id=auth.uid()
  );

drop policy if exists delivery_records_admin_read on public.delivery_records;
create policy delivery_records_admin_read on public.delivery_records
  for select to authenticated using (
    public.current_user_is_admin()
    or staff_id=public.current_delivery_staff_id()
  );

drop policy if exists bookings_staff_read on public.bookings;
create policy bookings_staff_read on public.bookings
  for select to authenticated using (
    assigned_staff_id=public.current_delivery_staff_id()
  );

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values(
  'delivery-proofs','delivery-proofs',true,5242880,
  array['image/jpeg','image/png','image/webp']
)
on conflict(id) do update set
  public=true,file_size_limit=5242880,
  allowed_mime_types=array['image/jpeg','image/png','image/webp'];

drop policy if exists staff_upload_delivery_proof on storage.objects;
create policy staff_upload_delivery_proof on storage.objects
  for insert to authenticated with check (
    bucket_id='delivery-proofs'
    and public.current_delivery_staff_enabled()
    and (storage.foldername(name))[1]=auth.uid()::text
  );
drop policy if exists staff_update_delivery_proof on storage.objects;
create policy staff_update_delivery_proof on storage.objects
  for update to authenticated using (
    bucket_id='delivery-proofs' and owner_id=auth.uid()::text
  );

create or replace function public.assign_delivery_staff(
  p_booking_id uuid,p_staff_id uuid
) returns void language plpgsql security definer set search_path=public as $$
begin
  if not public.current_user_is_admin() then
    raise exception 'ADMIN_ONLY';
  end if;
  if not exists(select 1 from public.delivery_staff where id=p_staff_id and enabled) then
    raise exception 'STAFF_UNAVAILABLE';
  end if;
  update public.bookings set assigned_staff_id=p_staff_id,assigned_at=now()
  where id=p_booking_id and status in ('confirmed','delivered');
  if not found then raise exception 'BOOKING_NOT_ASSIGNABLE'; end if;
end $$;

create or replace function public.complete_staff_delivery(
  p_booking_id uuid,p_cash_collected int default 0,
  p_empty_cans_returned int default 0,p_photo_url text default null,
  p_signature text default null,p_notes text default ''
) returns jsonb language plpgsql security definer set search_path=public as $$
declare s public.delivery_staff%rowtype; b public.bookings%rowtype;
  collected jsonb; returned jsonb;
begin
  select * into s from public.delivery_staff where user_id=auth.uid() and enabled;
  if s.id is null then raise exception 'STAFF_ACCESS_DENIED'; end if;
  select * into b from public.bookings where id=p_booking_id for update;
  if b.id is null or b.assigned_staff_id<>s.id then raise exception 'NOT_ASSIGNED'; end if;
  if b.status not in ('confirmed','delivered') then raise exception 'INVALID_STATUS'; end if;
  if p_cash_collected<0 or p_empty_cans_returned<0 then raise exception 'INVALID_AMOUNT'; end if;
  if p_cash_collected>b.balance then raise exception 'CASH_EXCEEDS_BALANCE'; end if;

  if b.status='confirmed' then
    update public.bookings set status='delivered' where id=b.id;
  end if;
  if p_cash_collected>0 then
    if p_cash_collected<>b.balance then raise exception 'COLLECT_FULL_BALANCE'; end if;
    collected:=public.collect_booking_balance(
      b.id,'cash','STAFF-'||s.id::text,'Collected by '||s.name
    );
  end if;
  if p_empty_cans_returned>0 then
    returned:=public.record_can_return(
      b.id,p_empty_cans_returned,0,'Recorded by delivery staff '||s.name
    );
  end if;

  insert into public.delivery_records(
    booking_id,staff_id,cash_collected,empty_cans_returned,
    proof_photo_url,customer_signature,notes
  ) values(
    b.id,s.id,p_cash_collected,p_empty_cans_returned,
    nullif(trim(coalesce(p_photo_url,'')),''),
    nullif(trim(coalesce(p_signature,'')),''),
    trim(coalesce(p_notes,''))
  )
  on conflict(booking_id) do update set
    cash_collected=public.delivery_records.cash_collected+excluded.cash_collected,
    empty_cans_returned=public.delivery_records.empty_cans_returned+excluded.empty_cans_returned,
    proof_photo_url=coalesce(excluded.proof_photo_url,public.delivery_records.proof_photo_url),
    customer_signature=coalesce(excluded.customer_signature,public.delivery_records.customer_signature),
    notes=case when excluded.notes='' then public.delivery_records.notes else excluded.notes end,
    updated_at=now();

  insert into public.activity_logs(actor_id,action,entity,entity_id,details)
  values(auth.uid(),'delivered','staff_delivery',b.id::text,jsonb_build_object(
    'booking_code',b.booking_code,'staff',s.name,'cash_collected',p_cash_collected,
    'empty_cans_returned',p_empty_cans_returned,'photo',p_photo_url is not null,
    'signature',p_signature is not null
  ));
  return jsonb_build_object('ok',true,'booking_code',b.booking_code);
end $$;

revoke all on function public.assign_delivery_staff(uuid,uuid) from public,anon;
grant execute on function public.assign_delivery_staff(uuid,uuid) to authenticated;
revoke all on function public.complete_staff_delivery(uuid,int,int,text,text,text) from public,anon;
grant execute on function public.complete_staff_delivery(uuid,int,int,text,text,text) to authenticated;
