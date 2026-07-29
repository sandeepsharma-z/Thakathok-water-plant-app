-- Customer data is accessible only through token-validated customer-api.
-- Registration/login RPCs and public CMS/settings reads remain available.
drop policy if exists bookings_insert on public.bookings;
drop policy if exists bookings_read on public.bookings;
drop policy if exists customers_anon_insert on public.customers;
drop policy if exists customers_anon_update on public.customers;
drop policy if exists customers_anon_read on public.customers;
drop policy if exists wallet_transactions_anon_read on public.wallet_transactions;
drop policy if exists customer_notifications_app_read on public.customer_notifications;
drop policy if exists customer_notifications_app_update on public.customer_notifications;

drop policy if exists customer_notifications_admin_all on public.customer_notifications;
create policy customer_notifications_admin_all on public.customer_notifications
for all to authenticated using(public.current_user_is_admin())
with check(public.current_user_is_admin());

drop policy if exists campaigns_admin_all on public.notification_campaigns;
create policy campaigns_admin_all on public.notification_campaigns
for all to authenticated using(public.current_user_is_admin())
with check(public.current_user_is_admin());

drop policy if exists customer_avatars_anon_insert on storage.objects;
drop policy if exists customer_avatars_anon_update on storage.objects;

-- These legacy RPCs accepted only a mobile number and therefore allowed one
-- customer to inspect or mutate another customer's data. The customer-api
-- invokes them with the service role after validating the opaque session.
revoke execute on function public.get_customer_order_eligibility(text) from anon;
revoke execute on function public.update_customer_avatar(text, text) from anon;
grant execute on function public.get_customer_order_eligibility(text) to service_role;
grant execute on function public.update_customer_avatar(text, text) to service_role;
