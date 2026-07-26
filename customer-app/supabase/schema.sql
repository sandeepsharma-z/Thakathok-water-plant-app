-- ============================================================
-- Mahalakshmi Water Plant (ThakaThok) — database schema
-- Run this in Supabase Dashboard → SQL Editor → New query → Run.
-- Safe to re-run: uses IF NOT EXISTS / ON CONFLICT.
-- ============================================================

create extension if not exists pgcrypto;

-- ── 1. App settings (admin-controlled, single row) ──────────
create table if not exists public.settings (
  id                      int primary key default 1,
  per_can_rate            int  not null default 45,
  delivery_charge         int  not null default 200,
  delivery_free_threshold int  not null default 25,   -- >= this many cans → no delivery charge
  free_delivery_village   text not null default 'Kasara Balkunda',
  plant_name              text not null default 'Mahalakshmi Water Plant',
  plant_phone             text not null default '91XXXXXXXXXX',
  -- Payment + SMS keys (admin sets these from the panel; never hard-coded)
  razorpay_key_id         text not null default '',
  razorpay_key_secret     text not null default '',
  fast2sms_api_key        text not null default '',
  -- Approved DLT template IDs (Header MAHWAP)
  sms_template_order      text not null default '1207178316043909799',
  sms_template_delivery   text not null default '1207178316251051882',
  sms_template_dues       text not null default '1207178316198620329',
  -- Home-screen offer (single active offer for v1)
  offer_enabled           boolean not null default true,
  offer_title             text not null default 'Weekend Splash Offer',
  offer_description       text not null default 'Get up to 15% OFF on all orders above Rs.300',
  offer_code              text not null default 'SPLASH15',
  offer_discount_percent  int not null default 15,
  offer_min_subtotal      int not null default 300,
  updated_at              timestamptz not null default now(),
  constraint settings_single_row check (id = 1),
  constraint settings_offer_percent check (
    offer_discount_percent between 1 and 100
  ),
  constraint settings_offer_minimum check (offer_min_subtotal >= 0)
);

-- Backfill columns on existing databases (safe to re-run)
alter table public.settings add column if not exists razorpay_key_id       text not null default '';
alter table public.settings add column if not exists razorpay_key_secret   text not null default '';
alter table public.settings add column if not exists fast2sms_api_key      text not null default '';
alter table public.settings add column if not exists sms_template_order    text not null default '1207178316043909799';
alter table public.settings add column if not exists sms_template_delivery text not null default '1207178316251051882';
alter table public.settings add column if not exists sms_template_dues     text not null default '1207178316198620329';
alter table public.settings add column if not exists offer_enabled          boolean not null default true;
alter table public.settings add column if not exists offer_title            text not null default 'Weekend Splash Offer';
alter table public.settings add column if not exists offer_description      text not null default 'Get up to 15% OFF on all orders above Rs.300';
alter table public.settings add column if not exists offer_code             text not null default 'SPLASH15';
alter table public.settings add column if not exists offer_discount_percent int not null default 15;
alter table public.settings add column if not exists offer_min_subtotal     int not null default 300;

-- Seed the single settings row (won't duplicate on re-run)
insert into public.settings (id) values (1)
on conflict (id) do nothing;

-- ── 2. Bookings ─────────────────────────────────────────────
-- Note: customer_name is added below via ALTER for existing DBs; new installs
-- get it from the create table if the column list there includes it.
create table if not exists public.bookings (
  id              uuid primary key default gen_random_uuid(),
  booking_code    text not null,                 -- e.g. THK100MAY20
  customer_name   text not null default '',      -- name entered on the form
  event_type      text not null,                 -- Wedding / Birthday / Other
  cans            int  not null,
  per_can_rate    int  not null,
  subtotal        int  not null,
  delivery_charge int  not null default 0,
  grand_total     int  not null,
  advance         int  not null,
  balance         int  not null,
  village         text not null,
  mobile          text not null,
  address         text not null,
  event_date      date not null,
  event_time      text not null,                 -- "10:30 AM"
  payment_method  text not null,                 -- 'online' | 'cash'
  offer_code       text,
  offer_discount_percent int not null default 0,
  discount_amount  int not null default 0,
  status          text not null default 'pending', -- pending | confirmed | cancelled | delivered
  created_at      timestamptz not null default now()
);

alter table public.bookings add column if not exists customer_name text not null default '';
alter table public.bookings add column if not exists offer_code text;
alter table public.bookings add column if not exists offer_discount_percent int not null default 0;
alter table public.bookings add column if not exists discount_amount int not null default 0;
create index if not exists bookings_mobile_idx     on public.bookings (mobile);
create index if not exists bookings_status_idx     on public.bookings (status);
create index if not exists bookings_event_date_idx on public.bookings (event_date);

-- ── 3. Row Level Security ───────────────────────────────────
-- NOTE (MVP, no customer login yet):
--   * Customers use the public anon key.
--   * We let anon INSERT bookings and SELECT them (so "My Bookings" works
--     by filtering on mobile). This means anyone with the anon key could
--     read all bookings — acceptable for the MVP, but BEFORE going live we
--     should add phone-OTP auth and tighten these policies.
--   * settings: anon can read (customer sees per-can rate); only the
--     service_role / dashboard can change it (admin).

alter table public.settings enable row level security;
alter table public.bookings enable row level security;

-- settings: read-only for anon
drop policy if exists settings_read on public.settings;
create policy settings_read on public.settings
  for select using (true);

-- bookings: anon can create
drop policy if exists bookings_insert on public.bookings;
create policy bookings_insert on public.bookings
  for insert with check (true);

-- bookings: anon can read (MVP — tighten later with auth)
drop policy if exists bookings_read on public.bookings;
create policy bookings_read on public.bookings
  for select using (true);

-- ── 4. Admin policies ───────────────────────────────────────
-- The admin (plant owner) signs in with Supabase Auth (email + password),
-- created once in Dashboard → Authentication → Users. Any signed-in user is
-- treated as the admin for this single-tenant app.

-- settings: signed-in admin can change the rates
drop policy if exists settings_admin_update on public.settings;
create policy settings_admin_update on public.settings
  for update to authenticated using (true) with check (true);

-- bookings: signed-in admin can confirm / cancel
drop policy if exists bookings_admin_update on public.bookings;
create policy bookings_admin_update on public.bookings
  for update to authenticated using (true) with check (true);

-- ── 5. Customers (profiles synced from the app + admin notes) ─
create table if not exists public.customers (
  mobile     text primary key,
  name       text not null default '',
  note       text not null default '',
  village    text not null default '',
  address    text not null default '',
  avatar_url text,
  wallet_balance int not null default 0,
  notifications_read boolean not null default false,
  notification_removed_ids text[] not null default '{}',
  updated_at timestamptz not null default now()
);
alter table public.customers add column if not exists village text not null default '';
alter table public.customers add column if not exists address text not null default '';
alter table public.customers add column if not exists avatar_url text;
alter table public.customers add column if not exists wallet_balance int not null default 0;
alter table public.customers add column if not exists notifications_read boolean not null default false;
alter table public.customers add column if not exists notification_removed_ids text[] not null default '{}';
alter table public.customers enable row level security;
-- Signed-in admin: full control.
drop policy if exists customers_admin_all on public.customers;
create policy customers_admin_all on public.customers
  for all to authenticated using (true) with check (true);
-- App (anon) can register/update its own profile (MVP — tighten with auth later).
drop policy if exists customers_anon_insert on public.customers;
create policy customers_anon_insert on public.customers
  for insert to anon with check (true);
drop policy if exists customers_anon_update on public.customers;
create policy customers_anon_update on public.customers
  for update to anon using (true) with check (true);
drop policy if exists customers_anon_read on public.customers;
create policy customers_anon_read on public.customers
  for select to anon using (true);

-- ── 6. Customer avatar storage (MVP; tighten after phone OTP auth) ─────
insert into storage.buckets (id, name, public)
values ('customer-avatars', 'customer-avatars', true)
on conflict (id) do update set public = true;

drop policy if exists customer_avatars_public_read on storage.objects;
create policy customer_avatars_public_read on storage.objects
  for select using (bucket_id = 'customer-avatars');

drop policy if exists customer_avatars_anon_insert on storage.objects;
create policy customer_avatars_anon_insert on storage.objects
  for insert to anon with check (bucket_id = 'customer-avatars');

drop policy if exists customer_avatars_anon_update on storage.objects;
create policy customer_avatars_anon_update on storage.objects
  for update to anon using (bucket_id = 'customer-avatars')
  with check (bucket_id = 'customer-avatars');

-- ── 7. Mobile + password customer accounts (no OTP) ──────────
create table if not exists public.customer_accounts (
  mobile        text primary key,
  password_hash text not null,
  created_at    timestamptz not null default now(),
  constraint customer_accounts_mobile check (mobile ~ '^[0-9]{10}$')
);
alter table public.customer_accounts enable row level security;
-- No direct table policies: passwords are accessed only through the RPCs below.

create or replace function public.register_customer_account(
  p_mobile text,
  p_password text,
  p_name text default ''
) returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  clean_mobile text := regexp_replace(coalesce(p_mobile, ''), '\D', '', 'g');
  clean_name text := trim(coalesce(p_name, ''));
begin
  if length(clean_mobile) <> 10 then
    raise exception 'INVALID_MOBILE';
  end if;
  if length(coalesce(p_password, '')) < 6 then
    raise exception 'WEAK_PASSWORD';
  end if;
  if exists (
    select 1 from public.customer_accounts where mobile = clean_mobile
  ) then
    raise exception 'ACCOUNT_EXISTS';
  end if;

  insert into public.customer_accounts (mobile, password_hash)
  values (clean_mobile, crypt(p_password, gen_salt('bf')));

  insert into public.customers (mobile, name, updated_at)
  values (clean_mobile, clean_name, now())
  on conflict (mobile) do update
  set name = case
      when excluded.name = '' then public.customers.name
      else excluded.name
    end,
    updated_at = now();

  return jsonb_build_object('mobile', clean_mobile, 'name', clean_name);
end;
$$;

create or replace function public.login_customer_account(
  p_mobile text,
  p_password text
) returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  clean_mobile text := regexp_replace(coalesce(p_mobile, ''), '\D', '', 'g');
  profile public.customers%rowtype;
begin
  if not exists (
    select 1
    from public.customer_accounts
    where mobile = clean_mobile
      and password_hash = crypt(p_password, password_hash)
  ) then
    raise exception 'INVALID_LOGIN';
  end if;

  select * into profile from public.customers where mobile = clean_mobile;
  return jsonb_build_object(
    'mobile', clean_mobile,
    'name', coalesce(profile.name, ''),
    'village', coalesce(profile.village, ''),
    'address', coalesce(profile.address, ''),
    'avatar_url', coalesce(profile.avatar_url, '')
  );
end;
$$;

revoke all on function public.register_customer_account(text, text, text)
  from public;
revoke all on function public.login_customer_account(text, text)
  from public;
grant execute on function public.register_customer_account(text, text, text)
  to anon;
grant execute on function public.login_customer_account(text, text)
  to anon;

create or replace function public.update_customer_avatar(
  p_mobile text,
  p_avatar_url text
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  clean_mobile text := regexp_replace(coalesce(p_mobile, ''), '\D', '', 'g');
begin
  if length(clean_mobile) <> 10 then
    raise exception 'INVALID_MOBILE';
  end if;
  update public.customers
  set avatar_url = nullif(trim(coalesce(p_avatar_url, '')), ''),
      updated_at = now()
  where mobile = clean_mobile;
end;
$$;

revoke all on function public.update_customer_avatar(text, text) from public;
grant execute on function public.update_customer_avatar(text, text) to anon;

-- ============================================================
-- Done. Verify:
--   select * from public.settings;
--   select * from public.bookings;
--
-- Then create the admin login:
--   Dashboard → Authentication → Users → "Add user"
--   (email + password, and tick "Auto Confirm User")
-- ============================================================
