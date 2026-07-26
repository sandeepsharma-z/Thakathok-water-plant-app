"use client";

import { motion } from "framer-motion";
import {
  CheckCircle2,
  CreditCard,
  Droplet,
  Eye,
  EyeOff,
  KeyRound,
  MessageSquareText,
  Phone,
  Save,
  TicketPercent,
  Truck,
} from "lucide-react";
import type { LucideIcon } from "lucide-react";
import { useActionState, useState, useTransition } from "react";
import { useFormStatus } from "react-dom";

import {
  toggleOfferVisibility,
  updateSettings,
  type ActionState,
} from "@/app/actions";
import type { Settings } from "@/lib/types";

function SaveButton() {
  const { pending } = useFormStatus();
  return (
    <button
      type="submit"
      disabled={pending}
      className="inline-flex h-12 items-center gap-2 rounded-2xl bg-gradient-to-r from-[#004fda] to-[#2e8bf0] px-8 text-[14px] font-bold tracking-wide text-white shadow-[0_14px_30px_-12px_rgba(0,79,218,0.8)] transition hover:brightness-105 disabled:opacity-70"
    >
      <Save className="h-4 w-4" />
      {pending ? "Saving…" : "Save changes"}
    </button>
  );
}

export function SettingsForm({ settings }: { settings: Settings }) {
  const [state, action] = useActionState<ActionState, FormData>(
    updateSettings,
    {},
  );
  const [offerVisible, setOfferVisible] = useState(settings.offer_enabled);
  const [visibilityState, setVisibilityState] = useState<ActionState>({});
  const [visibilityPending, startVisibilityTransition] = useTransition();

  function changeOfferVisibility(enabled: boolean) {
    const previous = offerVisible;
    setOfferVisible(enabled);
    setVisibilityState({});
    startVisibilityTransition(async () => {
      const result = await toggleOfferVisibility(enabled);
      setVisibilityState(result);
      if (result.error) setOfferVisible(previous);
    });
  }

  return (
    <form action={action} className="mt-6">
      <div className="grid gap-5 lg:grid-cols-2">
        <Field
          name="per_can_rate"
          label="Per can rate"
          Icon={Droplet}
          accent="brand"
          defaultValue={settings.per_can_rate}
          hint="Customers see this on the enquiry form but cannot edit it. Update it per season or village."
        />
        <Field
          name="delivery_charge"
          label="Delivery charge"
          Icon={Truck}
          accent="aqua"
          defaultValue={settings.delivery_charge}
          min={0}
          hint={`Charged only on orders under ${settings.delivery_free_threshold} cans. ${settings.free_delivery_village} is always free — set 0 to remove it everywhere.`}
        />
      </div>

      <section className="mt-9 rounded-[28px] border border-brand/20 bg-brand/[0.035] p-5 shadow-soft sm:p-6">
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
        <div>
          <h2 className="text-[18px] font-extrabold tracking-tight text-ink">
            Weekend Splash Offer
          </h2>
          <p className="mt-1 text-[12.5px] text-ink-muted">
            Home card, right-side coupon code and payment discount control.
          </p>
        </div>
        <label className="inline-flex cursor-pointer items-center gap-3 rounded-2xl border border-line bg-surface px-4 py-3">
          <input
            type="checkbox"
            name="offer_enabled"
            checked={offerVisible}
            disabled={visibilityPending}
            onChange={(event) => changeOfferVisibility(event.target.checked)}
            className="peer sr-only"
          />
          <span className="relative h-6 w-11 rounded-full bg-slate-300 transition peer-checked:bg-brand after:absolute after:left-1 after:top-1 after:h-4 after:w-4 after:rounded-full after:bg-white after:shadow after:transition-transform peer-checked:after:translate-x-5" />
          {offerVisible ? (
            <Eye className="h-4 w-4 text-brand" />
          ) : (
            <EyeOff className="h-4 w-4 text-ink-muted" />
          )}
          <span className="text-[13px] font-bold text-ink">
            {offerVisible ? "Shown on app" : "Hidden from app"}
          </span>
        </label>
      </div>
      {visibilityState.error || visibilityState.ok ? (
        <p
          role={visibilityState.error ? "alert" : "status"}
          className={`mt-3 rounded-2xl px-4 py-2.5 text-[12px] font-semibold ${
            visibilityState.error
              ? "bg-danger-bg text-danger"
              : "bg-ok-bg text-ok"
          }`}
        >
          {visibilityState.error ?? visibilityState.ok}
        </p>
      ) : null}

      <div
        className={`mt-5 grid gap-5 transition-opacity lg:grid-cols-2 ${
          offerVisible ? "opacity-100" : "opacity-55"
        }`}
      >
        <TextField
          name="offer_title"
          label="Offer title"
          Icon={TicketPercent}
          defaultValue={settings.offer_title}
          hint="Shown as the main heading on the customer home screen."
        />
        <TextField
          name="offer_code"
          label="Right-side coupon code"
          Icon={TicketPercent}
          defaultValue={settings.offer_code}
          hint="Shown in the card's right-side code box; customers enter it at payment."
        />
        <TextField
          name="offer_description"
          label="Offer description"
          Icon={MessageSquareText}
          defaultValue={settings.offer_description}
          hint="Short line shown below the offer title."
        />
        <div className="grid gap-5 sm:grid-cols-2">
          <OfferNumberField
            name="offer_discount_percent"
            label="Discount"
            defaultValue={settings.offer_discount_percent}
            min={1}
            max={100}
            suffix="%"
          />
          <OfferNumberField
            name="offer_min_subtotal"
            label="Minimum subtotal"
            defaultValue={settings.offer_min_subtotal}
            min={0}
            prefix="₹"
          />
        </div>
      </div>
      <p className="mt-4 rounded-2xl bg-surface px-4 py-3 text-[12px] leading-relaxed text-ink-muted">
        {offerVisible
          ? "After saving, the card remains visible and the latest code/rules are checked when a customer taps Apply."
          : "After saving, the complete offer section is hidden and this coupon code is rejected at payment."}
      </p>
      </section>

      <h2 className="mt-9 text-[17px] font-extrabold tracking-tight text-ink">
        Contact &amp; Integrations
      </h2>
      <p className="mt-1 text-[12.5px] text-ink-muted">
        Your own contact number and payment / SMS keys. These stay private and
        are never shown to customers.
      </p>

      <div className="mt-4 grid gap-5 lg:grid-cols-2">
        <TextField
          name="plant_phone"
          label="Contact / WhatsApp number"
          Icon={Phone}
          defaultValue={settings.plant_phone}
          placeholder="8080739807"
          hint="Used for the Call button, WhatsApp button, SMS sender and cash-booking alerts."
        />
        <TextField
          name="razorpay_key_id"
          label="Razorpay Key ID"
          Icon={CreditCard}
          defaultValue={settings.razorpay_key_id}
          placeholder="rzp_live_xxxxxxxxxxxx"
          hint="From your Razorpay Dashboard → Settings → API Keys. Used to collect the 30% online advance."
        />
        <TextField
          name="razorpay_key_secret"
          label="Razorpay Key Secret"
          Icon={KeyRound}
          defaultValue={settings.razorpay_key_secret}
          placeholder="••••••••••••••••"
          secret
          hint="The secret paired with your Key ID. Keep it private."
        />
        <TextField
          name="fast2sms_api_key"
          label="Fast2SMS API Key (DLT / Route)"
          Icon={MessageSquareText}
          defaultValue={settings.fast2sms_api_key}
          placeholder="Your Fast2SMS DLT API key"
          secret
          hint="Use the DLT (Route) API key — needed to send template SMS via Header MAHWAP."
        />
      </div>

      <h2 className="mt-9 text-[17px] font-extrabold tracking-tight text-ink">
        DLT SMS Template IDs
      </h2>
      <p className="mt-1 text-[12.5px] text-ink-muted">
        The approved DLT template IDs under Header MAHWAP. Update these if you
        submit new templates.
      </p>

      <div className="mt-4 grid gap-5 lg:grid-cols-3">
        <TextField
          name="sms_template_order"
          label="Order Confirmation"
          Icon={MessageSquareText}
          defaultValue={settings.sms_template_order}
          placeholder="1207178316043909799"
          hint="Sent when a booking is confirmed."
        />
        <TextField
          name="sms_template_delivery"
          label="Delivery Confirmation"
          Icon={MessageSquareText}
          defaultValue={settings.sms_template_delivery}
          placeholder="1207178316251051882"
          hint="Sent when an order is delivered."
        />
        <TextField
          name="sms_template_dues"
          label="Pending Dues Reminder"
          Icon={MessageSquareText}
          defaultValue={settings.sms_template_dues}
          placeholder="1207178316198620329"
          hint="Sent to remind about the balance."
        />
      </div>

      <div className="mt-6 flex flex-wrap items-center gap-4">
        <SaveButton />
        {state.error ? (
          <motion.p
            initial={{ opacity: 0, x: -6 }}
            animate={{ opacity: 1, x: 0 }}
            role="alert"
            className="rounded-2xl bg-danger-bg px-3.5 py-2.5 text-[12.5px] font-semibold text-danger"
          >
            {state.error}
          </motion.p>
        ) : null}
        {state.ok ? (
          <motion.p
            initial={{ opacity: 0, x: -6 }}
            animate={{ opacity: 1, x: 0 }}
            role="status"
            className="inline-flex items-center gap-1.5 rounded-2xl bg-ok-bg px-3.5 py-2.5 text-[12.5px] font-semibold text-ok"
          >
            <CheckCircle2 className="h-4 w-4" />
            {state.ok}
          </motion.p>
        ) : null}
      </div>
    </form>
  );
}

function OfferNumberField({
  name,
  label,
  defaultValue,
  min,
  max,
  prefix,
  suffix,
}: {
  name: string;
  label: string;
  defaultValue: number;
  min: number;
  max?: number;
  prefix?: string;
  suffix?: string;
}) {
  return (
    <div className="rounded-3xl border border-line bg-surface p-5 shadow-soft">
      <label htmlFor={name} className="text-[13px] font-bold text-ink">
        {label}
      </label>
      <div className="mt-4 flex items-center rounded-2xl border border-line bg-canvas px-3.5 focus-within:border-brand focus-within:ring-4 focus-within:ring-brand/10">
        {prefix ? <span className="font-bold text-ink-muted">{prefix}</span> : null}
        <input
          id={name}
          name={name}
          type="number"
          min={min}
          max={max}
          required
          defaultValue={defaultValue}
          className="tnum h-12 min-w-0 flex-1 bg-transparent px-2 text-[17px] font-bold text-ink outline-none"
        />
        {suffix ? <span className="font-bold text-ink-muted">{suffix}</span> : null}
      </div>
    </div>
  );
}

function Field({
  name,
  label,
  defaultValue,
  hint,
  Icon,
  accent,
  min = 1,
}: {
  name: string;
  label: string;
  defaultValue: number;
  hint: string;
  Icon: LucideIcon;
  accent: "brand" | "aqua";
  min?: number;
}) {
  const chip =
    accent === "brand"
      ? "from-[#004fda] to-[#3e93f5]"
      : "from-[#00a2ff] to-[#37b6ff]";
  return (
    <motion.div
      initial={{ opacity: 0, y: 14 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.45 }}
      className="rounded-3xl border border-line bg-surface p-5 shadow-soft"
    >
      <div className="flex items-center gap-3">
        <span
          className={`grid h-10 w-10 place-items-center rounded-2xl bg-gradient-to-br text-white shadow-lg ${chip}`}
        >
          <Icon className="h-5 w-5" strokeWidth={2.2} />
        </span>
        <label htmlFor={name} className="text-[14px] font-bold text-ink">
          {label}
        </label>
      </div>

      <div className="mt-4 flex items-center gap-2 rounded-2xl border border-line bg-canvas px-3.5 focus-within:border-brand focus-within:ring-4 focus-within:ring-brand/10">
        <span className="text-[17px] font-bold text-ink-muted">₹</span>
        <input
          id={name}
          name={name}
          type="number"
          inputMode="numeric"
          min={min}
          required
          defaultValue={defaultValue}
          className="tnum h-12 w-full bg-transparent text-[18px] font-bold text-ink outline-none"
        />
      </div>
      <p className="mt-2.5 text-[11.5px] leading-relaxed text-ink-faint">
        {hint}
      </p>
    </motion.div>
  );
}

function TextField({
  name,
  label,
  defaultValue,
  hint,
  Icon,
  placeholder,
  secret = false,
}: {
  name: string;
  label: string;
  defaultValue: string;
  hint: string;
  Icon: LucideIcon;
  placeholder?: string;
  secret?: boolean;
}) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 14 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.45 }}
      className="rounded-3xl border border-line bg-surface p-5 shadow-soft"
    >
      <div className="flex items-center gap-3">
        <span className="grid h-10 w-10 place-items-center rounded-2xl bg-gradient-to-br from-[#004fda] to-[#3e93f5] text-white shadow-lg">
          <Icon className="h-5 w-5" strokeWidth={2.2} />
        </span>
        <label htmlFor={name} className="text-[14px] font-bold text-ink">
          {label}
        </label>
      </div>

      <div className="mt-4 flex items-center gap-2 rounded-2xl border border-line bg-canvas px-3.5 focus-within:border-brand focus-within:ring-4 focus-within:ring-brand/10">
        <input
          id={name}
          name={name}
          type={secret ? "password" : "text"}
          autoComplete="off"
          spellCheck={false}
          placeholder={placeholder}
          defaultValue={defaultValue}
          className="h-12 w-full bg-transparent text-[15px] font-semibold text-ink outline-none placeholder:text-ink-faint placeholder:font-normal"
        />
      </div>
      <p className="mt-2.5 text-[11.5px] leading-relaxed text-ink-faint">
        {hint}
      </p>
    </motion.div>
  );
}
