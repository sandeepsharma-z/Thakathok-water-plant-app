alter table public.delivery_staff
  add column if not exists email text;

create unique index if not exists delivery_staff_email_unique
  on public.delivery_staff(lower(email))
  where email is not null;

update public.delivery_staff ds
set email=u.email
from auth.users u
where u.id=ds.user_id and ds.email is null;
