"use client";

import { motion } from "framer-motion";
import {
  CalendarDays,
  Check,
  MapPin,
  Phone,
  Truck,
  Wallet,
  X,
} from "lucide-react";
import { useActionState } from "react";
import { useFormStatus } from "react-dom";

import { cancelBooking, confirmBooking, type ActionState } from "@/app/actions";
import { StatusPill } from "@/components/ui";
import { formatDate, rupees, type Booking } from "@/lib/types";

function ActionButton({
  label,
  tone,
  icon,
}: {
  label: string;
  tone: "ok" | "ghost";
  icon: React.ReactNode;
}) {
  const { pending } = useFormStatus();
  const cls =
    tone === "ok"
      ? "bg-gradient-to-r from-[#12855a] to-[#2fbd83] text-white shadow-[0_10px_20px_-10px_rgba(18,133,90,0.9)] hover:brightness-105"
      : "border border-line text-ink-body hover:bg-danger-bg hover:text-danger hover:border-danger/30";
  return (
    <button
      type="submit"
      disabled={pending}
      className={`inline-flex h-10 items-center gap-1.5 rounded-2xl px-4 text-[12.5px] font-bold transition disabled:opacity-60 ${cls}`}
    >
      {pending ? "…" : icon}
      {pending ? "Working" : label}
    </button>
  );
}

export function BookingCard({
  booking: b,
  index = 0,
}: {
  booking: Booking;
  index?: number;
}) {
  const [confirmState, confirmAction] = useActionState<ActionState, FormData>(
    confirmBooking,
    {},
  );
  const [cancelState, cancelAction] = useActionState<ActionState, FormData>(
    cancelBooking,
    {},
  );
  const error = confirmState.error ?? cancelState.error;

  const isPending = b.status === "pending";
  const isCash = b.payment_method === "cash";

  return (
    <motion.article
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.45, delay: Math.min(index * 0.05, 0.4) }}
      className="group relative overflow-hidden rounded-3xl border border-line bg-surface p-5 shadow-soft transition-all duration-300 hover:-translate-y-0.5 hover:shadow-float"
    >
      {/* accent bar */}
      <span
        className="absolute inset-y-0 left-0 w-1.5 bg-gradient-to-b from-[#004fda] to-[#37b6ff] opacity-70"
        aria-hidden
      />

      <header className="flex flex-wrap items-center justify-between gap-3 pl-2">
        <div>
          <h3 className="text-[17px] font-extrabold tracking-tight text-gradient">
            {b.booking_code}
          </h3>
          <p className="mt-0.5 text-[12px] text-ink-muted">
            {b.event_type} · {b.cans} cans × ₹{b.per_can_rate}
          </p>
        </div>
        <StatusPill status={b.status} />
      </header>

      <div className="mt-4 grid grid-cols-1 gap-x-6 gap-y-2.5 pl-2 sm:grid-cols-2">
        <Detail Icon={CalendarDays} label="Event">
          {formatDate(b.event_date)} · {b.event_time}
        </Detail>
        <Detail Icon={MapPin} label="Village">
          {b.village}
        </Detail>
        <Detail Icon={Phone} label="Mobile">
          <a
            href={`tel:+91${b.mobile}`}
            className="font-semibold text-brand hover:underline"
          >
            +91 {b.mobile}
          </a>
        </Detail>
        <Detail Icon={isCash ? Wallet : Truck} label="Payment">
          {isCash ? "Cash on delivery" : "Online (UPI)"}
        </Detail>
      </div>

      <p className="mt-2 pl-2 text-[12px] text-ink-muted">
        <span className="text-ink-faint">Address: </span>
        {b.address}
      </p>

      <div className="mt-4 flex flex-wrap items-end justify-between gap-4 border-t border-line pt-4 pl-2">
        <div className="flex gap-6">
          <Figure label="Total" value={rupees(b.grand_total)} />
          <Figure label="Advance 30%" value={rupees(b.advance)} accent />
          <Figure label="Balance COD" value={rupees(b.balance)} />
        </div>

        {isPending ? (
          <div className="flex flex-wrap items-center gap-2">
            <form action={cancelAction}>
              <input type="hidden" name="id" value={b.id} />
              <ActionButton
                label="Cancel"
                tone="ghost"
                icon={<X className="h-4 w-4" />}
              />
            </form>
            <form action={confirmAction}>
              <input type="hidden" name="id" value={b.id} />
              <ActionButton
                label={`Confirm · ${rupees(b.advance)}`}
                tone="ok"
                icon={<Check className="h-4 w-4" strokeWidth={3} />}
              />
            </form>
          </div>
        ) : null}
      </div>

      {b.delivery_charge > 0 ? (
        <p className="mt-3 ml-2 inline-flex items-center gap-1.5 rounded-xl bg-warn-bg px-3 py-1.5 text-[11.5px] font-medium text-warn">
          <Truck className="h-3.5 w-3.5" />
          Delivery {rupees(b.delivery_charge)} — under 25 cans
        </p>
      ) : null}

      {error ? (
        <p role="alert" className="mt-3 pl-2 text-[12px] font-semibold text-danger">
          {error}
        </p>
      ) : null}
    </motion.article>
  );
}

function Detail({
  Icon,
  label,
  children,
}: {
  Icon: React.ElementType;
  label: string;
  children: React.ReactNode;
}) {
  return (
    <div className="flex items-start gap-2">
      <Icon className="mt-0.5 h-4 w-4 shrink-0 text-brand/70" />
      <div className="min-w-0">
        <p className="text-[10.5px] text-ink-faint">{label}</p>
        <p className="text-[13px] font-semibold text-ink">{children}</p>
      </div>
    </div>
  );
}

function Figure({
  label,
  value,
  accent,
}: {
  label: string;
  value: string;
  accent?: boolean;
}) {
  return (
    <div>
      <p className="text-[10.5px] text-ink-faint">{label}</p>
      <p
        className={`text-[16px] font-extrabold ${accent ? "text-gradient" : "text-ink"}`}
      >
        {value}
      </p>
    </div>
  );
}
