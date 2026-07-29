# ThakaThok Delivery Staff Panel

Dedicated staff-only web panel for assigned deliveries.

## Access

- Live: `https://thakathok-delivery.vercel.app`
- Login: staff email and password created by an administrator under **Delivery Staff**

Staff can only view their assigned orders and can record delivery completion,
cash collected, empty cans returned, an optional delivery photo, customer
signature and notes.

## Local development

Copy `.env.example` to `.env.local`, add the Supabase public URL and anon key,
then run:

```bash
npm install
npm run dev
```
