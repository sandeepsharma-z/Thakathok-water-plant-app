"use client";

import { useActionState } from "react";
import { useFormStatus } from "react-dom";

import { cancelBooking, confirmBooking, type ActionState } from "@/app/actions";
import { StatusPill } from "@/components/ui";
import { formatDate, rupees, type Booking } from "@/lib/types";

function ActionButton({
  label,
  tone,
}: {
  label: string;
  tone: "ok" | "ghost";
}) {
  const { pending } = useFormStatus();
  const cls =
    tone === "ok"
      ? "bg-ok text-white hover:brightness-110 shadow-[0_8px_18px_-10px_rgba(22,107,64,0.9)]"
      : "border border-line text-ink-body hover:bg-danger-bg hover:text-danger hover:border-danger/30";
  return (
    <button
      type="submit"
      disabled={pending}
      className={`h-10 rounded-xl px-4 text-[12.5px] font-bold transition disabled:opacity-60 ${cls}`}
    >
      {pending ? "Working…" : label}
    </button>
  );
}

export function BookingCard({ booking: b }: { booking: Booking }) {
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
    <article className="rounded-2xl border border-line bg-surface p-5 shadow-[0_1px_2px_rgba(14,42,71,0.04),0_8px_24px_-16px_rgba(14,42,71,0.18)] transition hover:shadow-[0_1px_2px_rgba(14,42,71,0.04),0_14px_32px_-18px_rgba(14,42,71,0.3)]">
      <header className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h3 className="text-[17px] font-extrabold tracking-tight text-brand">
            {b.booking_code}
          </h3>
          <p className="mt-0.5 text-[12px] text-ink-muted">
            {b.event_type} · {b.cans} cans
          </p>
        </div>
        <StatusPill status={b.status} />
      </header>

      <dl className="mt-4 grid grid-cols-1 gap-x-6 gap-y-2 sm:grid-cols-2">
        <Row label="Event date">
          {formatDate(b.event_date)} · {b.event_time}
        </Row>
        <Row label="Village">{b.village}</Row>
        <Row label="Mobile">
          <a
            href={`tel:+91${b.mobile}`}
            className="font-semibold text-brand hover:underline"
          >
            +91 {b.mobile}
          </a>
        </Row>
        <Row label="Payment">{isCash ? "Cash" : "Online (UPI)"}</Row>
        <Row label="Address" wide>
          {b.address}
        </Row>
      </dl>

      <div className="mt-4 flex flex-wrap items-end justify-between gap-4 border-t border-line pt-4">
        <div className="flex gap-6">
          <Figure label="Total" value={rupees(b.grand_total)} />
          <Figure label="Advance (30%)" value={rupees(b.advance)} accent />
          <Figure label="Balance (COD)" value={rupees(b.balance)} />
        </div>

        {isPending ? (
          <div className="flex flex-wrap items-center gap-2">
            <form action={cancelAction}>
              <input type="hidden" name="id" value={b.id} />
              <ActionButton label="Cancel" tone="ghost" />
            </form>
            <form action={confirmAction}>
              <input type="hidden" name="id" value={b.id} />
              <ActionButton
                label={`Confirm — ${rupees(b.advance)} received`}
                tone="ok"
              />
            </form>
          </div>
        ) : null}
      </div>

      {b.delivery_charge > 0 ? (
        <p className="mt-3 rounded-lg bg-warn-bg px-3 py-2 text-[11.5px] font-medium text-warn">
          Delivery charge {rupees(b.delivery_charge)} applied — under 25 cans.
        </p>
      ) : null}

      {error ? (
        <p role="alert" className="mt-3 text-[12px] font-semibold text-danger">
          {error}
        </p>
      ) : null}
    </article>
  );
}

function Row({
  label,
  children,
  wide,
}: {
  label: string;
  children: React.ReactNode;
  wide?: boolean;
}) {
  return (
    <div className={wide ? "sm:col-span-2" : undefined}>
      <dt className="text-[11px] text-ink-faint">{label}</dt>
      <dd className="text-[13px] font-semibold text-ink">{children}</dd>
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
      <p className="text-[11px] text-ink-faint">{label}</p>
      <p
        className={`text-[16px] font-extrabold ${accent ? "text-brand" : "text-ink"}`}
      >
        {value}
      </p>
    </div>
  );
}
