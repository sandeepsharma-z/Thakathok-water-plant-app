# DLT SMS Template Guide — ThakaThok / Mahalakshmi Water Plant

For the client (Rupali Ma'am) to submit on the Jio DLT portal, matching the new
bulk-order app flow. Existing setup is **Active**:

- **Entity ID:** 1201178254504457702 (MAHALAKSHMI WATER PLANT)
- **Header / Sender ID:** MAHWAP
- **Category:** Transactional / Service-Implicit (booking-related, not promotional)

## How DLT templates work (quick notes)

1. Every SMS the app sends must match a **pre-approved** template exactly.
2. Dynamic parts (booking id, cans, amount, date) are written as `{#var#}` in the
   template. Each `{#var#}` can hold up to 30 characters.
3. Keep templates under 160 characters where possible (1 SMS credit).
4. Submit all 3 below under Header **MAHWAP**, category **Transactional**.
5. After approval, share each template's **Template ID** — we plug them into the
   app so the right SMS goes out automatically.

---

## Template 1 — Order Confirmation
*Sent when a booking is confirmed (online paid instantly, or cash confirmed by admin).*

```
Namaste, your booking {#var#} for {#var#} cans on {#var#} is CONFIRMED. Balance Rs {#var#} payable on delivery. Our staff will call you shortly. - Mahalakshmi Water Plant
```

Variables in order: `{#var#}` = Booking ID, Cans, Event date, Balance amount.

---

## Template 2 — Delivery Confirmation
*Sent when the order is marked delivered.*

```
Your order {#var#} of {#var#} cans has been delivered. Thank you for choosing Mahalakshmi Water Plant. For any help call {#var#}.
```

Variables in order: `{#var#}` = Booking ID, Cans, Contact number.

---

## Template 3 — Pending Dues Reminder
*Sent to remind the customer of the balance (70% cash on delivery).*

```
Reminder: Rs {#var#} balance is pending for your booking {#var#} with Mahalakshmi Water Plant. Kindly keep it ready on delivery. - MAHWAP
```

Variables in order: `{#var#}` = Balance amount, Booking ID.

---

## After approval

Please share the 3 new **Template IDs** (like the earlier ones, e.g.
`1207178316043909799`). We will add them in the app so:

- Online payment success → **Template 1** auto-sent to customer.
- Admin taps "Confirm" on a cash booking → **Template 1** auto-sent.
- Admin marks "Delivered" → **Template 2** auto-sent.
- Balance reminder → **Template 3** (manual or scheduled).

The **Fast2SMS DLT (Route) API key** goes into the Admin Panel → Settings, so you
control it yourself. No key is ever hard-coded in the app.
