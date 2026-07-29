# ThakaThok Customer App

Flutter Android customer app for Mahalakshmi Water Plant.

## Features

- Mobile/password accounts and token-protected customer data.
- Dynamic home, products, categories, support, branding and UI labels.
- Profile/avatar, booking eligibility, blocked dates and coupon validation.
- Cash, wallet and Razorpay order flows.
- Booking history, wallet ledger, dues and in-app notifications.

## Verify and build

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

The release signing keystore and `android/key.properties` are private,
gitignored files. Preserve both for future app updates.

Supabase schema and functions are under `supabase/`. Sensitive customer actions
must go through `customer-api`; do not restore anonymous booking/customer read
policies.
