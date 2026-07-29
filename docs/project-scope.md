# Current Project Scope

## Customer app

- Mobile number + password registration/login (no OTP or Aadhaar).
- Dynamic profile and cropped avatar.
- Admin-controlled home content, branding, labels, products, categories and support.
- Product search, bulk-order form, blocked-date enforcement and offer codes.
- Cash, wallet and Razorpay payment flows with server-verified totals.
- My Bookings, wallet ledger, pending dues and in-app notifications.
- New-order restriction while payment or empty cans remain pending.

## Admin dashboard

- Dashboard and live sidebar counters.
- Bookings, customers, delivery assignments, villages and branches.
- Products, home content, app labels/branding and booking configuration.
- Can inventory, collections, pending dues and expenses.
- Monthly reporting with PDF and Excel export.
- Notification campaigns, calendar blocks and activity logs.
- Razorpay, Fast2SMS/DLT and owner-contact settings.

## Delivery staff panel

- Separate mobile/password login at `/staff/login`.
- Assigned-order list.
- Mark delivered.
- Record cash collected and empty cans returned.
- Optional customer signature/photo proof.
- Scalable staff records and admin enable/disable controls.

## Core rule

A customer cannot place another order while a previous confirmed/delivered order
has a positive balance or cans pending with the customer. Eligibility is restored
only after the admin records the outstanding values as cleared (`All Done`).

## Client-dependent production checks

- Razorpay Live payment: client supplies and enables Live Key ID/Secret.
- Fast2SMS/DLT delivery: client maintains API key, approved route/header/template IDs and sufficient account balance.
- Delivery staff credentials: owner creates each staff account from the dashboard.

## Explicitly excluded

- Aadhaar/eKYC and OTP authentication.
- Paid WhatsApp API.
- Firebase/closed-app push notifications.
- iOS release and store-account fees.
