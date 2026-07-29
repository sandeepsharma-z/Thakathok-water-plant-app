# ThakaThok Water Delivery

Production-oriented water-delivery system for Mahalakshmi Water Plant.

## Modules

- `customer-app` — Flutter Android app for mobile/password accounts, profile, ordering, payments, wallet, notifications, dues and booking history.
- `admin-panel` — Next.js dashboard for bookings, customers, delivery, inventory, villages, products, content, finance, reports and activity.
- Delivery staff panel — `/staff/login` and `/staff` inside the admin deployment, with assigned orders, delivery proof, collections and empty-can returns.
- `customer-app/supabase` — database migrations and Supabase Edge Functions.

## Implemented business flow

1. Customer creates an account with mobile number and password.
2. Customer submits an eligible order for an available date.
3. Cash orders await confirmation; verified online/wallet payments confirm securely.
4. Admin can assign a confirmed order to enabled delivery staff.
5. Staff records delivery, cash collected, returned cans and optional proof.
6. Admin clears remaining dues/cans with `All Done`; new orders remain blocked until prior liabilities are cleared.

Customer-owned records are accessed through an opaque session token and the
`customer-api` Edge Function. Public mobile-number-only access is disabled.

## External services

- Razorpay is integrated; real-money testing requires the client's Live keys.
- Fast2SMS/DLT triggers are integrated; delivery depends on the client's approved account, balance and template configuration.
- Closed-app push is intentionally not included. Notifications work inside the app without Firebase.

See [setup notes](docs/setup-notes.md), [project scope](docs/project-scope.md) and
[ownership/handover](docs/ownership-and-handover.md).
