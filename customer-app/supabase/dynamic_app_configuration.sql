-- Customer-app CMS configuration. Safe to re-run.
alter table public.settings
  add column if not exists advance_percent int not null default 30
    check (advance_percent between 1 and 100);
alter table public.settings
  add column if not exists booking_event_types jsonb not null default
    '["Wedding","Birthday","Other"]'::jsonb;
alter table public.settings
  add column if not exists booking_quantity_options jsonb not null default
    '[20,50,100,150]'::jsonb;
alter table public.settings
  add column if not exists home_ui_content jsonb not null default '{
    "popular_heading":"Most Popular 🔥",
    "shop_heading":"Shop By Need",
    "greeting_tagline":"Stay Hydrated, Stay Healthy 💧",
    "search_phrases":[
      "Search for water products",
      "Search for Jar Water 20L",
      "Search for Water Bottle 1.5L",
      "Search for Jar Water 10L"
    ],
    "quick_actions":[
      {"title":"Order Water","subtitle":"New order"},
      {"title":"Repeat Order","subtitle":"Quick reorder"},
      {"title":"My Orders","subtitle":"Track & history"},
      {"title":"My Wallet","subtitle":"Balance & history"},
      {"title":"Support","subtitle":"Help & support"}
    ],
    "trust_items":[
      {"title":"100% Pure & Safe"},
      {"title":"On-Time Delivery"},
      {"title":"Easy Returns"},
      {"title":"Best Price Guaranteed"}
    ]
  }'::jsonb;
alter table public.settings
  add column if not exists app_branding jsonb not null default '{
    "brand_name":"ThakaThok",
    "plant_display_name":"Mahalakshmi Water Plant",
    "logo_url":"assets/images/logo.png",
    "primary_color":"#004FDA",
    "accent_color":"#37B6FF"
  }'::jsonb;
alter table public.settings
  add column if not exists app_labels jsonb not null default '{
    "bottom_home":"Home",
    "bottom_bookings":"My Bookings",
    "bottom_products":"Products",
    "bottom_wallet":"Wallet",
    "bottom_profile":"Profile",
    "drawer_profile":"My Profile",
    "drawer_order":"Request Bulk Order",
    "drawer_bookings":"My Bookings",
    "drawer_wallet":"Wallet",
    "drawer_support":"Help & Support",
    "drawer_logout":"Logout",
    "booking_form_title":"Bulk Order Enquiry",
    "request_order_button":"REQUEST BULK ORDER",
    "payment_title":"Payment",
    "payment_summary_heading":"Order Summary",
    "booking_confirmed_title":"Booking Confirmed!",
    "booking_pending_title":"Booking Pending",
    "back_home_button":"BACK TO HOME",
    "date_required_error":"Please select event date & time",
    "booking_save_error":"Could not save booking. Please try again.",
    "date_unavailable_error":"This event date is no longer available. Please choose another date."
  }'::jsonb;
alter table public.settings
  add column if not exists payment_content jsonb not null default '{
    "advance_warning":"Advance is NON-REFUNDABLE",
    "cash_heading":"Cash Payment Selected",
    "cash_step_1":"Note down Booking ID:",
    "cash_step_2":"Pay {advance} cash to {plant_name} within 24 hours",
    "cash_step_3":"Call / WhatsApp {plant_phone} with your Booking ID",
    "cash_notice":"Booking will be CONFIRMED only after cash is received. Date is not blocked until the advance is paid.",
    "cash_button":"I WILL PAY CASH",
    "confirmed_message":"Your advance is received and the date is blocked.",
    "pending_message":"Pay the cash advance to confirm. Date is not blocked yet.",
    "non_refundable_note":"Note: Advance paid is non-refundable as per policy."
  }'::jsonb;

update public.settings
set app_labels = app_labels || '{
  "screen_my_bookings":"My Bookings",
  "screen_wallet":"My Wallet",
  "screen_profile":"My Profile",
  "screen_notifications":"Notifications",
  "screen_support":"Help & Support",
  "screen_all_products":"All Product Packs",
  "screen_product_details":"Pack Details",
  "screen_search":"Search Products",
  "login_heading":"Welcome back",
  "register_heading":"Create your account",
  "login_subtitle":"Login with your mobile number and password.",
  "register_subtitle":"Sign up once with your mobile number — no OTP needed.",
  "full_name_label":"Full Name",
  "mobile_label":"Mobile Number",
  "password_label":"Password",
  "login_button":"LOGIN",
  "register_button":"CREATE ACCOUNT",
  "have_account_text":"Already have an account?",
  "no_account_text":"Don''t have an account?",
  "login_link":"Login",
  "register_link":"Create ID",
  "name_required_error":"Enter your name",
  "mobile_invalid_error":"Enter a valid 10-digit mobile number",
  "password_invalid_error":"Password must be at least 6 characters",
  "account_exists_error":"An account already exists for this mobile number.",
  "invalid_login_error":"Mobile number or password is incorrect.",
  "connection_error":"Could not continue. Check your connection and try again."
}'::jsonb
where id=1;
