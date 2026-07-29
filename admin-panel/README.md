# ThakaThok Admin and Delivery Staff Panel

Next.js 16 dashboard backed by Supabase.

## Access

- Admin: `/login`
- Delivery staff: `/staff/login`

Staff accounts are created under Delivery Staff in the admin dashboard. Each
staff member signs in with the configured mobile number and password, sees only
assigned orders, and records delivery, cash, returned cans and optional proof.

## Local verification

```powershell
npm install
npm run build
npm run dev
```

Only the Supabase project URL and publishable key belong in `.env.local`.
Razorpay, Fast2SMS and service-role secrets remain server-side.

Monthly reports use the collection ledger for received payments and can be
exported as PDF or Excel.
