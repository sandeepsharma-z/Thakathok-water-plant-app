"use client";

import { useActionState } from "react";
import { useFormStatus } from "react-dom";

import {
  adjustCanInventory,
  recordCanReturn,
  type InventoryActionState,
} from "@/app/(app)/management-actions";
import { buttonClass, inputClass } from "@/components/management-ui";

function Submit({ label }: { label: string }) {
  const { pending } = useFormStatus();
  return (
    <button disabled={pending} className={buttonClass}>
      {pending ? "Working..." : label}
    </button>
  );
}

function Result({ state }: { state: InventoryActionState }) {
  const message = state.error ?? state.ok;
  if (!message) return null;
  return (
    <p
      className={`text-[11px] font-semibold ${
        state.error ? "text-danger" : "text-ok"
      }`}
    >
      {message}
    </p>
  );
}

export function InventoryAdjustmentForm({
  branches,
}: {
  branches: { id: string; name: string }[];
}) {
  const [state, action] = useActionState<InventoryActionState, FormData>(
    adjustCanInventory,
    {},
  );
  return (
    <form action={action} className="mt-4 grid gap-3 md:grid-cols-5">
      <select required name="branch_id" className={inputClass}>
        {branches.map((branch) => (
          <option key={branch.id} value={branch.id}>
            {branch.name}
          </option>
        ))}
      </select>
      <select name="action" className={inputClass}>
        <option value="add">Add new cans</option>
        <option value="remove">Remove from stock</option>
        <option value="damage">Mark available as damaged</option>
        <option value="repair">Repair damaged cans</option>
      </select>
      <input
        required
        name="quantity"
        type="number"
        min="1"
        placeholder="Quantity"
        className={inputClass}
      />
      <input
        name="note"
        placeholder="Reason / reference"
        className={inputClass}
      />
      <Submit label="Update Inventory" />
      <div className="md:col-span-5">
        <Result state={state} />
      </div>
    </form>
  );
}

export function CanReturnForm({
  bookingId,
  pending,
}: {
  bookingId: string;
  pending: number;
}) {
  const [state, action] = useActionState<InventoryActionState, FormData>(
    recordCanReturn,
    {},
  );
  return (
    <form
      action={action}
      className="mt-3 grid items-center gap-2 sm:grid-cols-[.65fr_.65fr_1.3fr_auto]"
    >
      <input type="hidden" name="booking_id" value={bookingId} />
      <input
        name="returned"
        type="number"
        min="0"
        max={pending}
        defaultValue="0"
        aria-label="Returned cans"
        placeholder="Returned"
        className={inputClass}
      />
      <input
        name="damaged"
        type="number"
        min="0"
        max={pending}
        defaultValue="0"
        aria-label="Damaged cans"
        placeholder="Damaged"
        className={inputClass}
      />
      <input name="note" placeholder="Return note" className={inputClass} />
      <Submit label="Record Return" />
      <div className="sm:col-span-4">
        <Result state={state} />
      </div>
    </form>
  );
}

