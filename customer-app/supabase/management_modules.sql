-- Dynamic operations modules. Safe to re-run.
create extension if not exists pgcrypto;

create table if not exists public.branches (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text not null unique,
  address text not null default '',
  phone text not null default '',
  manager_name text not null default '',
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.villages (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  branch_id uuid references public.branches(id) on delete set null,
  delivery_charge int check (delivery_charge is null or delivery_charge >= 0),
  enabled boolean not null default true,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.can_inventory (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid unique references public.branches(id) on delete cascade,
  total_cans int not null default 0 check (total_cans >= 0),
  available_cans int not null default 0 check (available_cans >= 0),
  out_for_delivery int not null default 0 check (out_for_delivery >= 0),
  damaged_cans int not null default 0 check (damaged_cans >= 0),
  updated_at timestamptz not null default now()
);

create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid references public.branches(id) on delete set null,
  category text not null,
  amount numeric(12,2) not null check (amount > 0),
  expense_date date not null default current_date,
  description text not null default '',
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.activity_logs (
  id bigint generated always as identity primary key,
  actor_id uuid,
  action text not null,
  entity text not null,
  entity_id text,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists activity_logs_created_idx on public.activity_logs(created_at desc);
create index if not exists expenses_date_idx on public.expenses(expense_date desc);

insert into public.branches (name, code, address, phone, manager_name)
values ('Mahalakshmi Water Plant', 'MAIN', '', '', 'Admin')
on conflict (code) do nothing;

insert into public.villages (name, branch_id, sort_order)
select v.name, b.id, v.ord
from public.branches b
cross join (values
  ('Kasara Balkunda',1), ('Sardarwadi',2), ('Tambala',3),
  ('Chilwantwadi',4), ('Pirupatelvadi',5), ('Devi Hallali',6), ('Mamdapur',7)
) as v(name,ord)
where b.code='MAIN'
on conflict (name) do nothing;

insert into public.can_inventory (branch_id)
select id from public.branches where code='MAIN'
on conflict (branch_id) do nothing;

alter table public.branches enable row level security;
alter table public.villages enable row level security;
alter table public.can_inventory enable row level security;
alter table public.expenses enable row level security;
alter table public.activity_logs enable row level security;

drop policy if exists villages_public_read on public.villages;
create policy villages_public_read on public.villages for select to anon using (enabled);
drop policy if exists villages_admin_all on public.villages;
create policy villages_admin_all on public.villages for all to authenticated using (true) with check (true);
drop policy if exists branches_admin_all on public.branches;
create policy branches_admin_all on public.branches for all to authenticated using (true) with check (true);
drop policy if exists inventory_admin_all on public.can_inventory;
create policy inventory_admin_all on public.can_inventory for all to authenticated using (true) with check (true);
drop policy if exists expenses_admin_all on public.expenses;
create policy expenses_admin_all on public.expenses for all to authenticated using (true) with check (true);
drop policy if exists logs_admin_read on public.activity_logs;
create policy logs_admin_read on public.activity_logs for select to authenticated using (true);

create or replace function public.log_admin_change() returns trigger
language plpgsql security definer set search_path=public as $$
begin
  insert into public.activity_logs(actor_id, action, entity, entity_id, details)
  values (
    auth.uid(), lower(tg_op), tg_table_name,
    coalesce((case when tg_op='DELETE' then to_jsonb(old) else to_jsonb(new) end)->>'id',
             (case when tg_op='DELETE' then to_jsonb(old) else to_jsonb(new) end)->>'mobile',
             (case when tg_op='DELETE' then to_jsonb(old) else to_jsonb(new) end)->>'booking_code'),
    jsonb_build_object('record', case when tg_op='DELETE' then to_jsonb(old) else to_jsonb(new) end)
  );
  return coalesce(new, old);
end $$;

do $$
declare t text;
begin
  foreach t in array array['branches','villages','can_inventory','expenses','bookings','settings','customers']
  loop
    execute format('drop trigger if exists %I_admin_log on public.%I', t, t);
    execute format('create trigger %I_admin_log after insert or update or delete on public.%I for each row execute function public.log_admin_change()', t, t);
  end loop;
end $$;
