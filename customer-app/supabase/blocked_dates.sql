-- Admin and confirmed-booking date blocking. Safe to re-run.
create table if not exists public.blocked_dates (
  blocked_date date primary key,
  reason text not null default '',
  source text not null default 'manual'
    check (source in ('manual','booking')),
  booking_id uuid unique references public.bookings(id) on delete cascade,
  created_at timestamptz not null default now()
);

create index if not exists blocked_dates_booking_idx
  on public.blocked_dates (booking_id);

alter table public.blocked_dates enable row level security;
drop policy if exists blocked_dates_public_read on public.blocked_dates;
create policy blocked_dates_public_read on public.blocked_dates
  for select using (true);
drop policy if exists blocked_dates_admin_insert on public.blocked_dates;
create policy blocked_dates_admin_insert on public.blocked_dates
  for insert to authenticated with check (source='manual' and booking_id is null);
drop policy if exists blocked_dates_admin_update on public.blocked_dates;
create policy blocked_dates_admin_update on public.blocked_dates
  for update to authenticated using (source='manual')
  with check (source='manual' and booking_id is null);
drop policy if exists blocked_dates_admin_delete on public.blocked_dates;
create policy blocked_dates_admin_delete on public.blocked_dates
  for delete to authenticated using (source='manual');

create or replace function public.enforce_available_booking_date()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if new.status<>'cancelled' and exists (
    select 1 from public.blocked_dates d
    where d.blocked_date=new.event_date
      and (d.booking_id is null or d.booking_id<>new.id)
  ) then
    raise exception 'DATE_UNAVAILABLE';
  end if;
  return new;
end $$;

drop trigger if exists bookings_enforce_available_date on public.bookings;
create trigger bookings_enforce_available_date
before insert or update of event_date,status on public.bookings
for each row execute function public.enforce_available_booking_date();

create or replace function public.sync_booking_blocked_date()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if tg_op='DELETE' then
    delete from public.blocked_dates where booking_id=old.id;
    return old;
  end if;

  if new.status='confirmed' then
    delete from public.blocked_dates
      where booking_id=new.id and blocked_date<>new.event_date;
    insert into public.blocked_dates(
      blocked_date,reason,source,booking_id
    ) values (
      new.event_date,
      'Confirmed booking '||new.booking_code,
      'booking',
      new.id
    )
    on conflict (booking_id) do update
      set blocked_date=excluded.blocked_date,
          reason=excluded.reason;
  elsif new.status='cancelled' then
    delete from public.blocked_dates where booking_id=new.id;
  end if;
  return new;
end $$;

drop trigger if exists bookings_sync_blocked_date on public.bookings;
create trigger bookings_sync_blocked_date
after insert or update of event_date,status or delete on public.bookings
for each row execute function public.sync_booking_blocked_date();

-- Backfill all currently confirmed future bookings.
insert into public.blocked_dates(blocked_date,reason,source,booking_id)
select
  b.event_date,
  'Confirmed booking '||b.booking_code,
  'booking',
  b.id
from public.bookings b
where b.status='confirmed'
  and b.event_date>=current_date
on conflict do nothing;

