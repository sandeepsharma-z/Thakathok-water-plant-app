alter table public.delivery_staff
  add column if not exists archived_at timestamptz;

alter table public.delivery_staff
  alter column user_id drop not null;

alter table public.delivery_staff
  drop constraint if exists delivery_staff_user_id_fkey;

alter table public.delivery_staff
  add constraint delivery_staff_user_id_fkey
  foreign key (user_id) references auth.users(id) on delete set null;

create index if not exists delivery_staff_active_idx
  on public.delivery_staff(enabled)
  where archived_at is null;
