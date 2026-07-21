# ThakaThok — Mahalakshmi Water Plant (Customer App)

A Flutter app for **bulk water orders** for weddings, functions and events, built for
**Mahalakshmi Water Plant**, sold through the ThakaThok brand.

> **Bulk orders only.** There is deliberately no "1 can / add to cart" retail flow — the
> client sells water in bulk for events. Customers submit an enquiry and pay a
> **30% non-refundable advance** to confirm the booking.

---

## Order flow

```
Splash → Home → Bulk Order Enquiry Form → Payment (30% advance) → Booking Confirmed
```

| # | Screen | What it does |
|---|--------|--------------|
| 1 | **Splash** | Brand logo, animated intro |
| 2 | **Home** | Brand header, search, banners, products, categories |
| 3 | **Bulk Order Enquiry Form** | 8 fields, live total, delivery-charge rule |
| 4 | **Payment** | Order summary, 30% advance, online / cash options |
| 5 | **Booking Confirmed** | Booking ID, status, event details |

---

## Business rules implemented

### Enquiry form fields
1. **Event Type** — Wedding / Birthday / Other
2. **Number of Cans** — 20 / 50 / 100 / 150 / Custom
3. **Per Can Rate** — admin-controlled, read-only for the customer
4. **Total Amount** — auto-calculated (`cans × rate`), read-only
5. **Event Date + Time** — calendar + time picker
6. **Mobile Number** — +91, 10 digits
7. **Village / Area** — 7 villages only
8. **Address / Hall Name**

### Villages
Kasara Balkunda · Sardarwadi · Tambala · Chilwantwadi · Pirupatelvadi · Devi Hallali · Mamdapur

### Delivery charge
- Applies only when the order is **under 25 cans**
- **Kasara Balkunda → free delivery**; the other 6 villages are charged
- Amount is admin-controlled (default ₹200)
- At 25 cans or more the delivery-charge line disappears entirely

### Payment
- **30% advance** confirms the booking; balance 70% is cash on delivery
- The advance is **NON-REFUNDABLE** — shown in red, bold, above the advance line
- **Pay Online** (UPI/GPay/PhonePe) → confirmed immediately
- **Pay Cash** → booking stays *pending*; shows Booking ID + "pay within 24 hours"
  instructions. The plant confirms it from the admin panel once cash is received.

### Booking ID
Format `THK<cans><MON><day>` — e.g. `THK100MAY20`.

---

## Tech stack

- **Flutter** 3.44.x / Dart 3.12.x
- **Supabase** (`supabase_flutter`) — bookings + admin-controlled settings
- `google_fonts` (Poppins), `flutter_svg`
- `flutter_launcher_icons` for the app icon

---

## Getting started

### 1. Prerequisites
- Flutter SDK 3.44 or newer
- Android SDK **36** + build-tools 36 (required by current Flutter)
- JDK 21

### 2. Supabase credentials
The real config file is gitignored. Create it from the template:

```bash
cp lib/config/supabase_config.example.dart lib/config/supabase_config.dart
```

Then fill in your project URL and **anon / publishable** key
(Supabase Dashboard → Project Settings → API).

> Only the publishable key belongs in the app. Never ship the `service_role` key.

### 3. Database schema
Run [`supabase/schema.sql`](supabase/schema.sql) once in
**Supabase Dashboard → SQL Editor**. It creates:

- **`settings`** — per-can rate, delivery charge, threshold, plant name/phone
- **`bookings`** — every enquiry/booking with its status

### 4. Run

```bash
flutter pub get
flutter run                 # connected device
flutter build apk --release # release APK
flutter build web           # web build
```

---

## Project layout

```
lib/
  config/    supabase_config.dart (gitignored) + .example
  models/    order_details.dart — order data + all money calculations
  screens/   splash · home · bulk_order_form · payment · booking_confirmed
  services/  booking_service.dart — Supabase reads/writes
  theme/     app_colors.dart
  widgets/   brand_logo.dart
supabase/
  schema.sql — tables, indexes and RLS policies
```

---

## Status

**Done**
- All four customer screens per the client's final spec
- Delivery-charge and 30%-advance calculations
- Supabase wiring — bookings are written on payment
- App icon + branding

**Pending**
- **Admin panel** — bookings list, confirm cash bookings, set per-can rate &
  delivery charge, blocked-date calendar, 24-hour auto-cancel
- **Real payment gateway** (UPI) — the online option is currently a stub
- **WhatsApp/Telegram alert** to the plant on a new cash booking
- **DLT SMS** on confirmation (entity/header/templates already approved)
- Customer "My Bookings" screen

---

## ⚠️ Security note before going live

`supabase/schema.sql` currently ships **MVP** row-level-security policies that let the
anon key read every booking. That is fine while testing, but before launch:

- add phone-OTP auth, and
- restrict `bookings` SELECT to the signed-in customer's own rows.

Admin-only writes (settings, confirming bookings) must never be exposed to the anon key.
