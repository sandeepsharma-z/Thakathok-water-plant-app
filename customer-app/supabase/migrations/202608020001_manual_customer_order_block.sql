-- Customer ordering is controlled only by an explicit admin switch.
alter table public.customers add column if not exists ordering_blocked boolean not null default false;
alter table public.customers add column if not exists ordering_blocked_at timestamptz;
alter table public.customers add column if not exists ordering_blocked_by uuid;

create or replace function public.get_customer_order_eligibility(p_mobile text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare
  clean_mobile text:=regexp_replace(coalesce(p_mobile,''),'\D','','g');
  due_amount int:=0; pending_cans int:=0; is_blocked boolean:=false;
begin
  if length(clean_mobile)<>10 then
    return jsonb_build_object('eligible',false,'reason','Please login again.');
  end if;
  select coalesce(sum(balance),0) into due_amount from public.bookings
  where mobile=clean_mobile and status in ('confirmed','delivered') and balance>0;
  select coalesce(sum(a.quantity-a.returned_quantity-a.damaged_quantity),0)
  into pending_cans from public.booking_can_allocations a
  join public.bookings b on b.id=a.booking_id
  where b.mobile=clean_mobile and a.state='delivered';
  select coalesce(ordering_blocked,false) into is_blocked
  from public.customers where mobile=clean_mobile;
  if is_blocked then
    return jsonb_build_object(
      'eligible',false,
      'reason','Your ordering is temporarily on hold. Please contact Mahalakshmi Water Plant on 8080739807 to clear dues.',
      'pending_dues',due_amount,'pending_cans',pending_cans,'manually_blocked',true
    );
  end if;
  return jsonb_build_object(
    'eligible',true,'reason','','pending_dues',due_amount,
    'pending_cans',pending_cans,'manually_blocked',false
  );
end $$;

revoke execute on function public.get_customer_order_eligibility(text) from public,anon,authenticated;
grant execute on function public.get_customer_order_eligibility(text) to service_role;
