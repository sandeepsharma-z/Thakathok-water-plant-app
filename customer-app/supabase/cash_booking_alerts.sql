-- Cash-booking admin notifications and owner SMS configuration. Safe to re-run.
alter table public.settings
  add column if not exists sms_template_cash_alert text not null default '';

alter table public.sms_logs drop constraint if exists sms_logs_sms_type_check;
alter table public.sms_logs add constraint sms_logs_sms_type_check
  check (sms_type in (
    'order_confirmation',
    'delivery_confirmation',
    'dues_reminder',
    'cash_booking_owner'
  ));

create table if not exists public.admin_notifications (
  id uuid primary key default gen_random_uuid(),
  notification_type text not null default 'cash_booking',
  title text not null,
  body text not null,
  booking_id uuid references public.bookings(id) on delete cascade,
  link text not null default '/bookings?status=pending',
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists admin_notifications_created_idx
  on public.admin_notifications (created_at desc);
create index if not exists admin_notifications_unread_idx
  on public.admin_notifications (read_at, created_at desc);

alter table public.admin_notifications enable row level security;
drop policy if exists admin_notifications_admin_read on public.admin_notifications;
create policy admin_notifications_admin_read on public.admin_notifications
  for select to authenticated using (true);
drop policy if exists admin_notifications_admin_update on public.admin_notifications;
create policy admin_notifications_admin_update on public.admin_notifications
  for update to authenticated using (true) with check (true);

create or replace function public.create_cash_booking_admin_notification()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if new.payment_method='cash' and new.status='pending' then
    insert into public.admin_notifications(
      notification_type,title,body,booking_id,link
    ) values (
      'cash_booking',
      'New Cash Booking - '||new.booking_code,
      coalesce(nullif(new.customer_name,''),'Customer')||' | '||
        new.cans||' cans | Advance '||chr(8377)||new.advance,
      new.id,
      '/bookings?status=pending&q='||new.booking_code
    );
  end if;
  return new;
end $$;

drop trigger if exists bookings_cash_admin_notification on public.bookings;
create trigger bookings_cash_admin_notification
after insert on public.bookings
for each row execute function public.create_cash_booking_admin_notification();

-- Backfill any existing pending cash bookings once, so the dashboard starts
-- with the current work instead of waiting for the next booking.
insert into public.admin_notifications(
  notification_type,title,body,booking_id,link
)
select
  'cash_booking',
  'New Cash Booking - '||b.booking_code,
  coalesce(nullif(b.customer_name,''),'Customer')||' | '||
    b.cans||' cans | Advance '||chr(8377)||b.advance,
  b.id,
  '/bookings?status=pending&q='||b.booking_code
from public.bookings b
where b.payment_method='cash'
  and b.status='pending'
  and not exists (
    select 1 from public.admin_notifications n
    where n.booking_id=b.id and n.notification_type='cash_booking'
  );
