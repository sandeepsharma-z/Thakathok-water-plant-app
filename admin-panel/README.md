# Admin Panel — Mahalakshmi Water Plant

Web dashboard for the plant owner: work the bookings queue, confirm cash advances,
and set the per-can rate and delivery charge.

Built with **Next.js 16** (App Router) + **Supabase**, styled to match the
[customer app](../customer-app)'s blue water theme.

---

## Screens

| Route | What it does |
|-------|--------------|
| `/login` | Supabase Auth sign-in — only the owner has an account |
| `/` | Dashboard — KPI tiles + the bookings that need action |
| `/bookings` | Every booking, filtered by Pending / Confirmed / Cancelled / All |
| `/settings` | Per-can rate and delivery charge |

### What the owner can do
- See at a glance how many bookings are **awaiting confirmation**, how many are
  **confirmed**, how many events are **upcoming**, and the **advance collected**
- **Confirm** a booking once the 30% cash advance is in hand — this blocks the date
- **Cancel** a booking, which frees the date again
- Change the **per-can rate** and **delivery charge** (customers see the rate but
  cannot edit it)

---

## Getting started

### 1. Environment
```bash
cp .env.example .env.local
```
Fill in from Supabase Dashboard → Project Settings → API:
```
NEXT_PUBLIC_SUPABASE_URL=...
NEXT_PUBLIC_SUPABASE_ANON_KEY=...
```
> Only the publishable (anon) key goes here. The `service_role` key must never be
> committed or exposed to the browser.

### 2. Database
Run [`../customer-app/supabase/schema.sql`](../customer-app/supabase/schema.sql)
once in the Supabase SQL Editor. It creates `settings` and `bookings`, and the RLS
policies that let a signed-in admin update them.

### 3. Create the owner's login
Supabase Dashboard → **Authentication → Users → Add user**
(email + password, tick **Auto Confirm User**).

### 4. Run
```bash
npm install
npm run dev     # http://localhost:3000
npm run build   # production build
```

---

## How auth works

1. **`proxy.ts`** — Next.js 16 renamed Middleware to *Proxy*. It refreshes the
   Supabase session cookie and bounces signed-out visitors to `/login`. This is an
   **optimistic** check only.
2. **`app/(app)/layout.tsx`** re-checks the session server-side before rendering
   anything.
3. **Server Actions** in `app/actions.ts` check the session again before every write.
4. **Row Level Security** in Postgres is the real guard — the anon key can create and
   read bookings, but only an authenticated user can confirm one or change the rates.

---

## Project layout

```
app/
  (app)/          authenticated area — dashboard, bookings, settings
  login/          sign-in page + auth server actions
  actions.ts      confirm / cancel booking, update settings
  globals.css     brand theme tokens (Tailwind v4 @theme)
components/
  nav.tsx         sidebar (desktop) + top bar & tabs (mobile)
  booking-card.tsx
  settings-form.tsx
  ui.tsx          StatusPill, StatTile, Card, EmptyState
lib/
  supabase/       server + browser clients
  types.ts        Booking / Settings types and formatters
proxy.ts          session refresh + route protection
```

---

## Design notes

- Palette mirrors the Flutter app: brand `#004FDA`, canvas `#F5F9FF`, tint `#EBF4FD`,
  ink `#0E2A47`. Poppins throughout.
- **Status is never colour-alone** — every pill carries an icon and a word, so it
  still reads for colour-blind users and in grayscale print.
- Status colours (pending / confirmed / cancelled / delivered) are reserved and are
  not reused for anything decorative.
- Fully responsive: sidebar on desktop, top bar + bottom tabs on a phone.

---

## Still to build

- **WhatsApp / Telegram alert** to the plant when a cash booking comes in
- **DLT SMS** on confirmation (entity `1201178254504457702`, header `MAHWAP`,
  templates already approved)
- **24-hour auto-cancel** for cash bookings whose advance never arrives — a cron
  route that flips them to `cancelled` and unblocks the date
- Blocked-date calendar view
