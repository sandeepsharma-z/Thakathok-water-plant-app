# Ownership and Handover

The client should retain ownership of:

- Source repository and production deployment.
- Supabase project and database backups.
- Vercel project/domain.
- Razorpay and Fast2SMS/DLT accounts.
- Google Play Console account.
- Android upload keystore and its password.

## Handover items

- Complete source code.
- Database migrations and Edge Functions.
- Admin, customer and delivery-staff operating notes.
- Signed APK/AAB as applicable.
- Environment-variable inventory (values transferred privately).
- Production verification walkthrough.

## Secret handling

Payment secrets, service-role keys, access tokens and signing passwords must never
be committed or sent in public chat. The customer app contains only the Supabase
publishable key. Client-owned external-service secrets stay server-side.

The Android upload keystore must be backed up securely. Losing it can prevent
publishing updates under the same application identity.
