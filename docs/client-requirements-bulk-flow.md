# Client Requirements — Bulk Order Flow (Final)

> Source: Messages shared by the client (Mahalakshmi Water Plant) for the ThakaThok app.
> This is the client-approved FINAL flow and supersedes the generic "1-can add to cart"
> retail model described in the original scope. Water is sold as **bulk orders only**
> (weddings, functions, events).

## 0. Key Business Change

- **Plant name:** Mahalakshmi Water Plant (selling water through the ThakaThok app).
- **Model:** Bulk-order-only. **Remove the "1 Can / Add to Cart" retail flow completely.**
- Replace it with a **Bulk Order Enquiry Form + 30% non-refundable advance**.
- No full payment gateway checkout — only **Enquiry + 30% Advance**.

---

## 1. Home Page

- Mahalakshmi Water Plant logo.
- Plant name **"Mahalakshmi Water Plant"** shown below the logo.
- Single button: **[ REQUEST BULK ORDER FOR EVENT ]**
- No "Add to Cart" anywhere.

## 2. Bulk Order Enquiry Form

Fields (in order):

1. **Event Type** — Dropdown: Wedding / Birthday / Other
2. **Number of Cans** — Dropdown: 20 / 50 / 100 / 150 / Custom
3. **Per Can Rate** — Set by admin only; customer sees it but **cannot edit**. e.g. ₹45/Can
4. **Total Amount** — Auto-calculated (No. of Cans × Per Can Rate), **read-only**
5. **Event Date + Time** — Calendar + time picker
6. **Mobile Number** — +91 XXXXX XXXXX
7. **Village / Area** — Dropdown, 7 villages only:
   - Kasara Balkunda
   - Sardarwadi
   - Tambala
   - Chilwantwadi
   - Pirupatelvadi
   - Devi Hallali (a.k.a. "Hallali")
   - Mamdapur
8. **Address / Hall Name** — Text box

## 3. Payment Screen — 30% Advance

Shown after form submit. Order summary:

```
Order Summary:
100 Cans x ₹XX/Can = ₹XXXX Total
[ + Delivery Charge = ₹XXX ]   <- only when applicable, see Section 6

30% Advance to Confirm Booking: ₹XXX
Balance 70% Cash on Delivery:   ₹XXX
```

- **⚠️ 30% Advance is NON-REFUNDABLE** — must appear in **red, bold, above** the 30% advance line.
- **If cancelled, date will not be unblocked.**

### Two Payment Options

**Option 1 — Pay Online (UPI / GPay / PhonePe)**
- Button: `[ PAY ₹XXXX ONLINE — UPI/GPay/PhonePe ]`
- Instant confirm — **Booking Confirmed immediately after payment** (Amazon Pay style).

**Option 2 — Pay Cash to Mahalakshmi Water Plant**
- Button: `[ PAY ₹XXXX CASH TO MAHALAKSHMI WATER PLANT ]`
- Manual confirm. After clicking, show:
  ```
  Cash Payment Selected
  1. Note down Booking ID: THK100MAY20
  2. Pay ₹XXXX cash to Mahalakshmi Water Plant within 24 hours
  3. Call/WhatsApp 91XXXXXXXXXX with Booking ID

  ⚠️ Booking will be CONFIRMED only after cash received.
  Date not blocked until advance paid.
  ```
- After clicking `[ I WILL PAY CASH ]`, the **plant/admin** receives a WhatsApp/Telegram message:
  ```
  New Cash Booking:
  THK100MAY20, 100 Cans, 20 May. Waiting for ₹XXX cash.
  ```
- Admin presses **Confirm Booking** in the Admin Panel only after cash is received.
  **Only then** is the confirmation SMS sent to the customer.

## 4. Booking Confirmed Screen

```
✅ Booking Confirmed!
ID: THK100MAY20
Date: XX May, XXAM blocked

Mahalakshmi Water Plant staff will call you in 5 mins.
Note: Advance paid is non-refundable as per policy.
```

- DLT SMS goes out with these details (see Section 7).
- Booking ID format observed: `THK<cans>MAY<date>` e.g. `THK100MAY20`, `THK50MAY15`.

## 5. Admin Panel — Key Rules

1. **Per Can Rate** — Only admin can change; updated per season/village.
2. **No Refund rule** — Displayed in red bold above the 30% advance line.
3. **Cash Booking auto-cancel** — If cash not confirmed within 24 hours, booking is
   **auto-cancelled** and the **date is unblocked** again.
4. **No payment gateway checkout** — Only Enquiry + 30% Advance.
5. Date is **blocked only after advance is paid/confirmed**.

## 6. Delivery Charge Rule

1. If order is **less than 25 cans**, a **delivery charge** applies.
2. Delivery charge amount is **set by admin** (e.g. ₹200 / ₹300), changeable by distance/diesel.
3. Applies to **6 villages** — every village **except Kasara Balkunda**:
   - **Kasara Balkunda → Free delivery** (admin can keep 0)
   - Sardarwadi, Tambala, Chilwantwadi, Pirupatelvadi, Hallali, Mamdapur → delivery charge applies
4. If order is **25 cans or more**, the delivery charge line **does not appear** (Total = Cans × Rate only).

Example payment screen with delivery charge:

```
Order Summary:
20 Cans x ₹45/Can = ₹900
+ Delivery Charge  = ₹200
= ₹1,100 Total

30% Advance to Confirm Booking: ₹330
Balance 70% COD:                ₹770

⚠️ 30% Advance is NON-REFUNDABLE
⚠️ 25 Can पेक्षा कमी Order साठी Delivery Charge Apply
[ PAY ₹330 ONLINE ]  [ PAY CASH TO MAHALAKSHMI WATER PLANT ]
```

**Admin Panel settings for this:**
1. Per Can Rate — admin sets.
2. Delivery Charge — admin sets; 0 allowed (used for Kasara Balkunda).

## 7. DLT SMS / OTP Setup (client-provided)

- **Entity ID:** 1201178254504457702
- **Header / Sender ID:** MAHWAP
- **Template IDs:**
  1. Order Confirmation: 1207178316043909799
  2. Delivery Confirmation: 1207178316251051882
  3. Pending Dues Reminder: 1207178316198620329

Note: Header + templates already submitted. Client is willing to submit **new templates**
matching the new app structure if we provide a template guide.

---

## Open Items / To Confirm With Client

- New DLT template content wording for the bulk-order confirmation flow (client asked for a guide).
- Exact WhatsApp/Telegram notification integration for cash bookings (which channel + API).
- Whether "Devi Hallali" and "Hallali" are the same village (delivery-charge list uses "Hallali").
