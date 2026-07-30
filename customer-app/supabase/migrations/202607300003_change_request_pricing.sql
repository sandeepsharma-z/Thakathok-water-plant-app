create or replace function public.review_booking_request(
  p_request_id uuid,p_decision text,p_admin_note text default ''
) returns jsonb language plpgsql security definer set search_path=public as $$
declare
  req public.booking_requests%rowtype;
  b public.bookings%rowtype;
  cfg public.settings%rowtype;
  new_cans int; new_subtotal int; new_discount int; new_delivery int;
  new_total int; new_advance int; delta int;
  allocation public.booking_can_allocations%rowtype;
begin
  if not public.current_user_is_admin() then raise exception 'ADMIN_REQUIRED'; end if;
  if p_decision not in ('approved','rejected') then raise exception 'INVALID_DECISION'; end if;
  select * into req from public.booking_requests where id=p_request_id for update;
  if req.id is null then raise exception 'REQUEST_NOT_FOUND'; end if;
  if req.status<>'pending' then raise exception 'REQUEST_ALREADY_REVIEWED'; end if;
  select * into b from public.bookings where id=req.booking_id for update;
  if b.id is null then raise exception 'BOOKING_NOT_FOUND'; end if;
  if p_decision='approved' then
    if req.request_type='cancellation' then
      perform public.cancel_booking_by_admin(b.id,'Customer request approved: '||req.reason);
    else
      if b.status not in ('pending','confirmed') then raise exception 'CHANGE_NOT_ALLOWED'; end if;
      select * into cfg from public.settings where id=1;
      new_cans:=coalesce(req.proposed_cans,b.cans);
      new_subtotal:=new_cans*b.per_can_rate;
      new_discount:=round(new_subtotal*coalesce(b.offer_discount_percent,0)/100.0);
      new_delivery:=case when new_cans>=cfg.delivery_free_threshold
          or b.village=cfg.free_delivery_village then 0
          else coalesce((select delivery_charge from public.villages where name=b.village),cfg.delivery_charge) end;
      new_total:=new_subtotal-new_discount+new_delivery;
      new_advance:=case when b.status='pending'
        then round(new_total*cfg.advance_percent/100.0) else b.advance end;
      if b.status='confirmed' and new_cans<>b.cans then
        select * into allocation from public.booking_can_allocations
          where booking_id=b.id for update;
        if allocation.id is not null and allocation.state='reserved' then
          delta:=new_cans-allocation.quantity;
          if delta>0 and (select available_cans from public.can_inventory where branch_id=allocation.branch_id)<delta
            then raise exception 'INSUFFICIENT_STOCK'; end if;
          update public.can_inventory set available_cans=available_cans-delta,
            reserved_cans=reserved_cans+delta,updated_at=now()
            where branch_id=allocation.branch_id;
          update public.booking_can_allocations set quantity=new_cans,updated_at=now()
            where id=allocation.id;
        end if;
      end if;
      update public.bookings set
        event_date=coalesce(req.proposed_event_date,b.event_date),
        event_time=coalesce(nullif(trim(req.proposed_event_time),''),b.event_time),
        cans=new_cans,subtotal=new_subtotal,discount_amount=new_discount,
        delivery_charge=new_delivery,grand_total=new_total,advance=new_advance,
        balance=greatest(new_total-new_advance,0),
        address=coalesce(nullif(trim(req.proposed_address),''),b.address)
      where id=b.id;
    end if;
  end if;
  update public.booking_requests set status=p_decision,
    admin_note=nullif(trim(coalesce(p_admin_note,'')),''),
    reviewed_at=now(),reviewed_by=auth.uid(),updated_at=now()
    where id=req.id;
  return jsonb_build_object('ok',true,'decision',p_decision,'type',req.request_type);
end $$;
