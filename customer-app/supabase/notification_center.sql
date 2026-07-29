-- Dynamic in-app notification center. Safe to re-run.
create table if not exists public.notification_campaigns (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  notification_type text not null default 'custom',
  action_type text not null default 'none',
  action_value text not null default '',
  image_url text,
  audience text not null default 'selected',
  sent_count int not null default 0,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.customer_notifications (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.notification_campaigns(id) on delete cascade,
  mobile text not null references public.customers(mobile) on delete cascade,
  read_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  unique(campaign_id, mobile)
);
create index if not exists customer_notifications_mobile_idx
  on public.customer_notifications(mobile, created_at desc);

create table if not exists public.customer_device_tokens (
  id uuid primary key default gen_random_uuid(),
  mobile text not null references public.customers(mobile) on delete cascade,
  token text not null unique,
  platform text not null default 'android',
  enabled boolean not null default true,
  updated_at timestamptz not null default now()
);

alter table public.notification_campaigns enable row level security;
alter table public.customer_notifications enable row level security;
alter table public.customer_device_tokens enable row level security;

drop policy if exists campaigns_admin_all on public.notification_campaigns;
create policy campaigns_admin_all on public.notification_campaigns for all to authenticated using(true) with check(true);
drop policy if exists customer_notifications_admin_all on public.customer_notifications;
create policy customer_notifications_admin_all on public.customer_notifications for all to authenticated using(true) with check(true);
drop policy if exists customer_notifications_app_read on public.customer_notifications;
create policy customer_notifications_app_read on public.customer_notifications for select to anon using(true);
drop policy if exists customer_notifications_app_update on public.customer_notifications;
create policy customer_notifications_app_update on public.customer_notifications for update to anon using(true) with check(true);
drop policy if exists campaigns_app_read on public.notification_campaigns;
create policy campaigns_app_read on public.notification_campaigns for select to anon using(true);
drop policy if exists device_tokens_app_all on public.customer_device_tokens;
create policy device_tokens_app_all on public.customer_device_tokens for all to anon using(true) with check(true);
drop policy if exists device_tokens_admin_read on public.customer_device_tokens;
create policy device_tokens_admin_read on public.customer_device_tokens for select to authenticated using(true);

-- Keep campaign statistics accurate.
create or replace function public.refresh_notification_sent_count() returns trigger
language plpgsql security definer set search_path=public as $$
begin
  update notification_campaigns set sent_count=(
    select count(*) from customer_notifications where campaign_id=coalesce(new.campaign_id,old.campaign_id)
  ) where id=coalesce(new.campaign_id,old.campaign_id);
  return coalesce(new,old);
end $$;
drop trigger if exists notification_recipient_count on public.customer_notifications;
create trigger notification_recipient_count after insert or delete on public.customer_notifications
for each row execute function public.refresh_notification_sent_count();
