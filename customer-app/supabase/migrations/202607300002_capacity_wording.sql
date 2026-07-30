update public.settings
set payment_content=coalesce(payment_content,'{}'::jsonb)||jsonb_build_object(
  'cash_notice','Booking will be CONFIRMED only after cash is received. Can capacity is reserved after the advance is paid.',
  'confirmed_message','Your advance is received, the booking is confirmed and cans are reserved.',
  'pending_message','Pay the cash advance to confirm and reserve the required cans.'
),updated_at=now()
where id=1;
