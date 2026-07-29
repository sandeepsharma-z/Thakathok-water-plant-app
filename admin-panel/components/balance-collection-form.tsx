"use client";

import { BadgeIndianRupee } from "lucide-react";
import { useActionState } from "react";
import { useFormStatus } from "react-dom";

import {
  collectBookingBalance,
  type ActionState,
} from "@/app/actions";
import { inputClass } from "@/components/management-ui";

function CollectButton({ amount }: { amount: number }) {
  const { pending } = useFormStatus();
  return (
    <button
      disabled={pending}
      className="inline-flex h-10 items-center justify-center gap-1.5 rounded-xl bg-gradient-to-r from-[#12855a] to-[#2fbd83] px-4 text-[11.5px] font-extrabold text-white shadow-soft disabled:opacity-60"
    >
      <BadgeIndianRupee className="h-4 w-4" />
      {pending ? "Collecting..." : `Collect ₹${amount.toLocaleString("en-IN")}`}
    </button>
  );
}

export function BalanceCollectionForm({
  bookingId,
  amount,
}: {
  bookingId: string;
  amount: number;
}) {
  const [state, action] = useActionState<ActionState, FormData>(
    collectBookingBalance,
    {},
  );
  return (
    <div className="mt-3 rounded-2xl border border-ok/15 bg-ok-bg/40 p-3">
      <form
        action={action}
        className="grid items-center gap-2 md:grid-cols-[.7fr_1fr_1.2fr_auto]"
      >
        <input type="hidden" name="booking_id" value={bookingId} />
        <select name="method" className={inputClass} defaultValue="cash">
          <option value="cash">Cash</option>
          <option value="upi">UPI</option>
          <option value="bank">Bank transfer</option>
          <option value="other">Other</option>
        </select>
        <input
          name="reference"
          placeholder="Reference / transaction ID"
          className={inputClass}
        />
        <input
          name="note"
          placeholder="Collection note"
          className={inputClass}
        />
        <CollectButton amount={amount} />
      </form>
      {state.error || state.ok ? (
        <p
          className={`mt-2 text-[11px] font-semibold ${
            state.error ? "text-danger" : "text-ok"
          }`}
        >
          {state.error ?? state.ok}
        </p>
      ) : null}
    </div>
  );
}
