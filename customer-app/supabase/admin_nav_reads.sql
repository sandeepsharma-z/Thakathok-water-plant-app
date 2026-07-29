-- Per-admin sidebar seen state. Safe to re-run.
create table if not exists public.admin_nav_reads (
  user_id uuid not null,
  section text not null check (section in ('orders','customers')),
  last_seen_at timestamptz not null default now(),
  primary key (user_id, section)
);
alter table public.admin_nav_reads enable row level security;
drop policy if exists admin_nav_reads_own_all on public.admin_nav_reads;
create policy admin_nav_reads_own_all on public.admin_nav_reads
  for all to authenticated
  using (user_id=auth.uid())
  with check (user_id=auth.uid());

