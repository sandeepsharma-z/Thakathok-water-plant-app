-- ============================================================
-- Mahalakshmi Water Plant (ThakaThok) — database schema
-- Run this in Supabase Dashboard → SQL Editor → New query → Run.
-- Safe to re-run: uses IF NOT EXISTS / ON CONFLICT.
-- ============================================================

-- ── 1. App settings (admin-controlled, single row) ──────────
create table if not exists public.settings (
  id                      int primary key default 1,
  per_can_rate            int  not null default 45,
  delivery_charge         int  not null default 200,
  delivery_free_threshold int  not null default 25,   -- >= this many cans → no delivery charge
  free_delivery_village   text not null default 'Kasara Balkunda',
  plant_name              text not null default 'Mahalakshmi Water Plant',
  plant_phone             text not null default '91XXXXXXXXXX',
  updated_at              timestamptz not null default now(),
  constraint settings_single_row check (id = 1)
);

-- Seed the single settings row (won't duplicate on re-run)
insert into public.settings (id) values (1)
on conflict (id) do nothing;

-- ── 2. Bookings ─────────────────────────────────────────────
create table if not exists public.bookings (
  id              uuid primary key default gen_random_uuid(),
  booking_code    text not null,                 -- e.g. THK100MAY20
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
  status          text not null default 'pending', -- pending | confirmed | cancelled | delivered
  created_at      timestamptz not null default now()
);

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

-- ============================================================
-- Done. Verify:
--   select * from public.settings;
--   select * from public.bookings;
--
-- Then create the admin login:
--   Dashboard → Authentication → Users → "Add user"
--   (email + password, and tick "Auto Confirm User")
-- ============================================================
