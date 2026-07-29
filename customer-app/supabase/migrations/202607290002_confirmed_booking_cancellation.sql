alter table public.bookings
  add column if not exists cancellation_reason text,
  add column if not exists cancelled_at timestamptz,
  add column if not exists cancelled_by uuid references auth.users(id);

create or replace function public.cancel_booking_by_admin(
  p_booking_id uuid,
  p_reason text
) returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  booking public.bookings%rowtype;
  reason text:=trim(coalesce(p_reason,''));
begin
  if not public.current_user_is_admin() then
    raise exception 'ADMIN_REQUIRED';
  end if;
  if length(reason)<3 then
    raise exception 'REASON_REQUIRED';
  end if;

  select * into booking from public.bookings
  where id=p_booking_id for update;
  if booking.id is null then raise exception 'BOOKING_NOT_FOUND'; end if;
  if booking.status='cancelled' then
    return jsonb_build_object('already_cancelled',true);
  end if;
  if booking.status not in ('pending','confirmed') then
    raise exception 'CANCELLATION_NOT_ALLOWED';
  end if;

  update public.bookings set
    status='cancelled',
    cancellation_reason=reason,
    cancelled_at=now(),
    cancelled_by=auth.uid()
  where id=p_booking_id;

  return jsonb_build_object(
    'already_cancelled',false,
    'advance_retained',booking.advance,
    'previous_status',booking.status
  );
end $$;

revoke all on function public.cancel_booking_by_admin(uuid,text)
  from public,anon;
grant execute on function public.cancel_booking_by_admin(uuid,text)
  to authenticated;
