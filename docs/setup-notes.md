# Setup and Release Notes

## Requirements

- Flutter 3.44+, Android SDK 36 and JDK 21.
- Node.js 20+ and npm.
- Supabase project and CLI.

## Customer app

1. Copy `customer-app/lib/config/supabase_config.example.dart` to
   `supabase_config.dart` and add the publishable project values.
2. Run migrations in `customer-app/supabase/migrations`.
3. Deploy Edge Functions from `customer-app/supabase/functions`.
4. Run `flutter pub get`, `flutter analyze` and `flutter test`.
5. Build with `flutter build apk --release`.

Android release signing uses:

- `customer-app/android/key.properties`
- `customer-app/android/app/upload-keystore.jks`

Both are gitignored. Back them up securely; the same key is required for every
future Android update.

## Admin and staff web panel

1. Copy `admin-panel/.env.example` to `.env.local`.
2. Add only the Supabase URL and publishable key.
3. Run `npm install`, `npm run build`, then deploy.
4. Admin login is `/login`; delivery staff login is `/staff/login`.
5. Create staff accounts under Admin → Delivery Staff, then assign confirmed orders.

## Production checklist

- Keep service-role and payment secrets out of source control.
- Enable Razorpay Live only after client-owned key verification.
- Verify Fast2SMS account balance, DLT route/header and all three approved templates.
- Test one complete customer → admin → staff → All Done order before public launch.
- Retain the signing keystore, database backups and environment-variable backup.
