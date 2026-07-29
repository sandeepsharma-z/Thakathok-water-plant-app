-- DLT SMS delivery audit log. Safe to re-run.
create table if not exists public.sms_logs (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid references public.bookings(id) on delete set null,
  booking_code text not null default '',
  mobile text not null,
  sms_type text not null
    check (sms_type in ('order_confirmation', 'delivery_confirmation', 'dues_reminder')),
  template_id text not null default '',
  status text not null check (status in ('sent', 'failed', 'skipped')),
  provider_request_id text,
  provider_message text not null default '',
  created_at timestamptz not null default now()
);

create index if not exists sms_logs_booking_type_idx
  on public.sms_logs (booking_id, sms_type, created_at desc);
create index if not exists sms_logs_mobile_idx
  on public.sms_logs (mobile, created_at desc);

alter table public.sms_logs enable row level security;
drop policy if exists sms_logs_admin_read on public.sms_logs;
create policy sms_logs_admin_read on public.sms_logs
  for select to authenticated using (true);
drop policy if exists sms_logs_admin_insert on public.sms_logs;
create policy sms_logs_admin_insert on public.sms_logs
  for insert to authenticated with check (true);

