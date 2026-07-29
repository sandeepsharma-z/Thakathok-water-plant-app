"use client";

import {
  CalendarDays,
  Check,
  ChevronRight,
  Eye,
  MapPin,
  Pencil,
  Phone,
  ReceiptText,
  StickyNote,
  Trash2,
  User,
  Wallet,
  X,
} from "lucide-react";
import { useActionState, useEffect, useState } from "react";
import { useFormStatus } from "react-dom";

import { deleteCustomer, saveCustomer, type ActionState } from "@/app/actions";
import { formatDate, rupees, type Booking } from "@/lib/types";

function SaveBtn() {
  const { pending } = useFormStatus();
  return (
    <button
      type="submit"
      disabled={pending}
      className="inline-flex h-11 flex-1 items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-[#004fda] to-[#2e8bf0] px-5 text-[13px] font-bold text-white shadow-[0_10px_24px_-12px_rgba(0,79,218,.8)] transition hover:brightness-105 disabled:opacity-60"
    >
      <Check className="h-4 w-4" />
      {pending ? "Saving…" : "Save changes"}
    </button>
  );
}

function CustomerAvatar({
  avatarUrl,
  name,
  large = false,
}: {
  avatarUrl: string | null;
  name: string;
  large?: boolean;
}) {
  const [failed, setFailed] = useState(false);
  const size = large ? "h-20 w-20" : "h-14 w-14";
  const initial = (name.trim()[0] ?? "?").toUpperCase();

  return (
    <div
      className={`${size} grid shrink-0 place-items-center overflow-hidden rounded-2xl bg-gradient-to-br from-[#e7f0ff] to-[#d9ebff] text-[18px] font-extrabold text-brand ring-1 ring-brand/15 ${large ? "rounded-3xl text-[26px]" : ""}`}
    >
      {avatarUrl && !failed ? (
        <img
          src={avatarUrl}
          alt={`${name || "Customer"} profile`}
          className="h-full w-full object-cover"
          onError={() => setFailed(true)}
        />
      ) : name.trim() ? (
        initial
      ) : (
        <User className={large ? "h-8 w-8" : "h-6 w-6"} />
      )}
    </div>
  );
}

export function CustomerRow({
  mobile,
  name,
  note,
  count,
  spent,
  villages,
  address,
  avatarUrl,
  bookings,
  walletBalance,
  walletTransactions,
  registered = false,
}: {
  mobile: string;
  name: string;
  note: string;
  count: number;
  spent: number;
  villages: string[];
  address: string;
  avatarUrl: string | null;
  bookings: Booking[];
  walletBalance: number;
  walletTransactions: Array<{
    id: string;
    type: string;
    amount: number;
    balance_after: number;
    description: string;
    created_at: string;
  }>;
  registered?: boolean;
}) {
  const [viewOpen, setViewOpen] = useState(false);
  const [editOpen, setEditOpen] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [state, action] = useActionState<ActionState, FormData>(saveCustomer, {});
  const [deleteState, deleteAction] = useActionState<ActionState, FormData>(
    deleteCustomer,
    {},
  );
  const displayName = name.trim() || "Unnamed customer";

  useEffect(() => {
    if (state.ok || deleteState.ok) {
      setEditOpen(false);
      setConfirmDelete(false);
    }
  }, [state.ok, deleteState.ok]);

  return (
    <>
      <article className="group overflow-hidden rounded-3xl border border-line bg-surface shadow-soft transition duration-300 hover:-translate-y-0.5 hover:border-brand/20 hover:shadow-float">
        <div className="flex flex-col gap-5 p-5 lg:flex-row lg:items-center">
          <div className="flex min-w-0 flex-1 items-center gap-4">
            <CustomerAvatar avatarUrl={avatarUrl} name={name} />
            <div className="min-w-0">
              <div className="flex flex-wrap items-center gap-2">
                <h3 className="truncate text-[16px] font-extrabold text-ink">
                  {displayName}
                </h3>
                {registered ? (
                  <span className="rounded-full bg-ok-bg px-2.5 py-1 text-[9px] font-extrabold tracking-[.08em] text-ok">
                    REGISTERED
                  </span>
                ) : (
                  <span className="rounded-full bg-warn-bg px-2.5 py-1 text-[9px] font-extrabold tracking-[.08em] text-warn">
                    BOOKING ONLY
                  </span>
                )}
              </div>
              <div className="mt-1.5 flex flex-wrap items-center gap-x-4 gap-y-1 text-[12px] text-ink-muted">
                <a
                  href={`tel:+91${mobile}`}
                  className="inline-flex items-center gap-1.5 font-semibold hover:text-brand"
                >
                  <Phone className="h-3.5 w-3.5 text-brand" />
                  +91 {mobile}
                </a>
                {villages.length ? (
                  <span className="inline-flex items-center gap-1.5">
                    <MapPin className="h-3.5 w-3.5 text-brand" />
                    {villages.join(", ")}
                  </span>
                ) : null}
              </div>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-2 sm:flex sm:items-center">
            <Metric icon={ReceiptText} label="Bookings" value={`${count}`} />
            <Metric icon={Wallet} label="Lifetime value" value={rupees(spent)} />
          </div>

          <div className="flex gap-2 lg:border-l lg:border-line lg:pl-5">
            <button
              onClick={() => setViewOpen(true)}
              className="inline-flex h-11 flex-1 items-center justify-center gap-2 rounded-xl bg-brand px-4 text-[12.5px] font-bold text-white shadow-[0_10px_24px_-12px_rgba(0,79,218,.9)] transition hover:brightness-105 lg:flex-none"
            >
              <Eye className="h-4 w-4" />
              View
            </button>
            <button
              onClick={() => setEditOpen(true)}
              className="inline-flex h-11 flex-1 items-center justify-center gap-2 rounded-xl border border-line px-4 text-[12.5px] font-bold text-ink-body transition hover:border-brand/25 hover:bg-tint lg:flex-none"
            >
              <Pencil className="h-4 w-4 text-brand" />
              Edit
            </button>
          </div>
        </div>
      </article>

      {viewOpen ? (
        <Modal onClose={() => setViewOpen(false)} maxWidth="max-w-3xl">
          <div className="flex items-start justify-between gap-4">
            <div className="flex min-w-0 items-center gap-4">
              <CustomerAvatar avatarUrl={avatarUrl} name={name} large />
              <div className="min-w-0">
                <h2 className="truncate text-[22px] font-extrabold text-ink">
                  {displayName}
                </h2>
                <a
                  href={`tel:+91${mobile}`}
                  className="mt-1 inline-flex items-center gap-1.5 text-[13px] font-semibold text-brand"
                >
                  <Phone className="h-4 w-4" /> +91 {mobile}
                </a>
                <p className="mt-1 text-[11px] font-semibold uppercase tracking-[.12em] text-ink-faint">
                  {registered ? "Registered customer" : "Booking customer"}
                </p>
              </div>
            </div>
            <CloseButton onClick={() => setViewOpen(false)} />
          </div>

          <div className="mt-6 grid gap-3 sm:grid-cols-3">
            <Summary label="Total bookings" value={`${count}`} icon={ReceiptText} />
            <Summary label="Lifetime value" value={rupees(spent)} icon={Wallet} />
            <Summary
              label="Latest booking"
              value={bookings[0] ? formatDate(bookings[0].event_date) : "None"}
              icon={CalendarDays}
            />
          </div>

          <div className="mt-5 grid gap-3 sm:grid-cols-2">
            <InfoCard icon={MapPin} label="Village / Area">
              {villages.join(", ") || "Not provided"}
            </InfoCard>
            <InfoCard icon={MapPin} label="Address / Hall">
              {address || "Not provided"}
            </InfoCard>
            <InfoCard icon={StickyNote} label="Admin note">
              {note || "No note added"}
            </InfoCard>
          </div>

          <div className="mt-6 flex items-center justify-between">
            <h3 className="text-[15px] font-extrabold text-ink">
              Booking history
            </h3>
            <span className="text-[11.5px] font-semibold text-ink-faint">
              {bookings.length} total
            </span>
          </div>
          <div className="mt-3 max-h-64 space-y-2 overflow-y-auto pr-1">
            {bookings.length ? (
              bookings.map((booking) => (
                <div
                  key={booking.id}
                  className="flex flex-wrap items-center justify-between gap-3 rounded-2xl border border-line bg-canvas p-3.5"
                >
                  <div>
                    <p className="text-[13px] font-extrabold text-brand">
                      {booking.booking_code}
                    </p>
                    <p className="mt-0.5 text-[11.5px] text-ink-muted">
                      {formatDate(booking.event_date)} · {booking.cans} cans ·{" "}
                      {booking.village}
                    </p>
                    <p className="mt-1 text-[10.5px] font-semibold uppercase text-ink-faint">
                      {booking.payment_method} payment · Advance{" "}
                      {rupees(booking.advance)} · Balance{" "}
                      {rupees(booking.balance)}
                    </p>
                    {booking.offer_code ? (
                      <p className="mt-1 text-[10.5px] text-ok">
                        Offer {booking.offer_code} · Saved{" "}
                        {rupees(booking.discount_amount)}
                      </p>
                    ) : null}
                  </div>
                  <div className="text-right">
                    <p className="text-[13px] font-extrabold text-ink">
                      {rupees(booking.grand_total)}
                    </p>
                    <p className="text-[10px] font-bold uppercase text-ink-faint">
                      {booking.status}
                    </p>
                  </div>
                </div>
              ))
            ) : (
              <div className="rounded-2xl border border-dashed border-line py-8 text-center text-[12.5px] text-ink-faint">
                No bookings from this customer yet.
              </div>
            )}
          </div>

          <div className="mt-6 flex items-center justify-between">
            <h3 className="text-[15px] font-extrabold text-ink">
              Wallet & payment history
            </h3>
            <span className="text-[11.5px] font-semibold text-brand">
              Balance {rupees(walletBalance)}
            </span>
          </div>
          <div className="mt-3 max-h-48 space-y-2 overflow-y-auto pr-1">
            {walletTransactions.length ? walletTransactions.map((transaction) => (
              <div key={transaction.id} className="flex items-center justify-between rounded-2xl border border-line bg-canvas p-3.5">
                <div>
                  <p className="text-[12px] font-bold text-ink">{transaction.description || "Wallet transaction"}</p>
                  <p className="mt-0.5 text-[10.5px] text-ink-faint">{new Date(transaction.created_at).toLocaleString("en-IN")} · Balance {rupees(transaction.balance_after)}</p>
                </div>
                <p className={`text-[13px] font-extrabold ${transaction.type === "credit" ? "text-ok" : "text-danger"}`}>
                  {transaction.type === "credit" ? "+" : "-"}{rupees(transaction.amount)}
                </p>
              </div>
            )) : <div className="rounded-2xl border border-dashed border-line py-6 text-center text-[12px] text-ink-faint">No wallet transactions yet.</div>}
          </div>

          <button
            onClick={() => {
              setViewOpen(false);
              setEditOpen(true);
            }}
            className="mt-5 inline-flex h-11 items-center gap-2 rounded-xl border border-line px-4 text-[12.5px] font-bold text-ink-body hover:bg-tint"
          >
            <Pencil className="h-4 w-4 text-brand" />
            Edit customer
            <ChevronRight className="h-4 w-4" />
          </button>
        </Modal>
      ) : null}

      {editOpen ? (
        <Modal onClose={() => setEditOpen(false)} maxWidth="max-w-md">
          <div className="flex items-start justify-between">
            <div>
              <h3 className="text-[19px] font-extrabold text-ink">
                Edit customer
              </h3>
              <p className="mt-1 text-[12px] text-ink-muted">+91 {mobile}</p>
            </div>
            <CloseButton onClick={() => setEditOpen(false)} />
          </div>

          <form action={action} className="mt-5 space-y-4">
            <input type="hidden" name="mobile" value={mobile} />
            <FormField
              name="name"
              label="Customer name"
              defaultValue={name}
              placeholder="Customer full name"
              icon={User}
            />
            <FormField
              name="note"
              label="Admin note"
              defaultValue={note}
              placeholder="Add a helpful note"
              icon={StickyNote}
            />
            {state.error ? (
              <p className="text-[12px] font-semibold text-danger">
                {state.error}
              </p>
            ) : null}
            <div className="flex gap-3">
              <button
                type="button"
                onClick={() => setEditOpen(false)}
                className="h-11 rounded-xl border border-line px-5 text-[13px] font-semibold text-ink-body hover:bg-tint"
              >
                Cancel
              </button>
              <SaveBtn />
            </div>
          </form>

          {registered ? (
            <div className="mt-5 border-t border-line pt-4">
              {confirmDelete ? (
                <div className="rounded-2xl bg-danger-bg p-3">
                  <p className="text-[12px] font-semibold text-danger">
                    Delete this profile? Existing bookings will remain.
                  </p>
                  <div className="mt-3 flex gap-2">
                    <button
                      onClick={() => setConfirmDelete(false)}
                      className="h-10 rounded-xl border border-line bg-surface px-4 text-[12px] font-bold text-ink"
                    >
                      Keep
                    </button>
                    <form action={deleteAction}>
                      <input type="hidden" name="mobile" value={mobile} />
                      <button className="inline-flex h-10 items-center gap-1.5 rounded-xl bg-danger px-4 text-[12px] font-bold text-white">
                        <Trash2 className="h-3.5 w-3.5" /> Delete
                      </button>
                    </form>
                  </div>
                </div>
              ) : (
                <button
                  onClick={() => setConfirmDelete(true)}
                  className="inline-flex items-center gap-1.5 text-[12px] font-semibold text-danger hover:underline"
                >
                  <Trash2 className="h-3.5 w-3.5" />
                  Delete customer profile
                </button>
              )}
              {deleteState.error ? (
                <p className="mt-2 text-[12px] font-semibold text-danger">
                  {deleteState.error}
                </p>
              ) : null}
            </div>
          ) : null}
        </Modal>
      ) : null}
    </>
  );
}

function Metric({
  icon: Icon,
  label,
  value,
}: {
  icon: React.ElementType;
  label: string;
  value: string;
}) {
  return (
    <div className="min-w-[118px] rounded-2xl bg-canvas px-4 py-3">
      <p className="flex items-center gap-1.5 text-[10.5px] text-ink-faint">
        <Icon className="h-3.5 w-3.5 text-brand" /> {label}
      </p>
      <p className="mt-1 text-[15px] font-extrabold text-ink">{value}</p>
    </div>
  );
}

function Summary({
  icon: Icon,
  label,
  value,
}: {
  icon: React.ElementType;
  label: string;
  value: string;
}) {
  return (
    <div className="rounded-2xl border border-line bg-canvas p-4">
      <Icon className="h-5 w-5 text-brand" />
      <p className="mt-3 text-[10.5px] text-ink-faint">{label}</p>
      <p className="mt-0.5 text-[16px] font-extrabold text-ink">{value}</p>
    </div>
  );
}

function InfoCard({
  icon: Icon,
  label,
  children,
}: {
  icon: React.ElementType;
  label: string;
  children: React.ReactNode;
}) {
  return (
    <div className="rounded-2xl border border-line p-4">
      <p className="flex items-center gap-2 text-[10.5px] font-bold uppercase tracking-[.08em] text-ink-faint">
        <Icon className="h-4 w-4 text-brand" /> {label}
      </p>
      <p className="mt-2 text-[13px] font-semibold text-ink-body">{children}</p>
    </div>
  );
}

function FormField({
  name,
  label,
  defaultValue,
  placeholder,
  icon: Icon,
}: {
  name: string;
  label: string;
  defaultValue: string;
  placeholder: string;
  icon: React.ElementType;
}) {
  return (
    <div>
      <label htmlFor={name} className="text-[12px] font-bold text-ink">
        {label}
      </label>
      <div className="mt-1.5 flex items-center gap-2 rounded-xl border border-line bg-canvas px-3.5 focus-within:border-brand focus-within:ring-4 focus-within:ring-brand/10">
        <Icon className="h-4 w-4 text-ink-faint" />
        <input
          id={name}
          name={name}
          defaultValue={defaultValue}
          placeholder={placeholder}
          autoComplete="off"
          className="h-12 w-full bg-transparent text-[13.5px] font-semibold text-ink outline-none placeholder:font-normal placeholder:text-ink-faint"
        />
      </div>
    </div>
  );
}

function Modal({
  children,
  onClose,
  maxWidth,
}: {
  children: React.ReactNode;
  onClose: () => void;
  maxWidth: string;
}) {
  return (
    <div
      className="fixed inset-0 z-50 grid place-items-center overflow-y-auto bg-[#07101f]/70 p-4 backdrop-blur-md"
      onMouseDown={onClose}
    >
      <div
        className={`my-6 w-full ${maxWidth} rounded-3xl border border-line bg-surface p-6 shadow-float`}
        onMouseDown={(event) => event.stopPropagation()}
      >
        {children}
      </div>
    </div>
  );
}

function CloseButton({ onClick }: { onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      className="grid h-9 w-9 shrink-0 place-items-center rounded-xl text-ink-muted transition hover:bg-tint"
      aria-label="Close"
    >
      <X className="h-4 w-4" />
    </button>
  );
}
