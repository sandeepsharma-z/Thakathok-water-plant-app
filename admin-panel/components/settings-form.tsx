"use client";

import { useActionState } from "react";
import { useFormStatus } from "react-dom";

import { updateSettings, type ActionState } from "@/app/actions";
import type { Settings } from "@/lib/types";

function SaveButton() {
  const { pending } = useFormStatus();
  return (
    <button
      type="submit"
      disabled={pending}
      className="h-12 rounded-xl bg-brand px-8 text-[14px] font-bold tracking-wide text-white shadow-[0_8px_20px_-8px_rgba(0,79,218,0.7)] transition hover:bg-brand-dark disabled:opacity-60"
    >
      {pending ? "Saving…" : "SAVE"}
    </button>
  );
}

export function SettingsForm({ settings }: { settings: Settings }) {
  const [state, action] = useActionState<ActionState, FormData>(
    updateSettings,
    {},
  );

  return (
    <form action={action} className="mt-6 grid gap-6 lg:grid-cols-2">
      <Field
        name="per_can_rate"
        label="Per can rate"
        defaultValue={settings.per_can_rate}
        hint="Customers see this on the enquiry form but cannot edit it. Update it per season or village."
      />
      <Field
        name="delivery_charge"
        label="Delivery charge"
        defaultValue={settings.delivery_charge}
        min={0}
        hint={`Charged only on orders under ${settings.delivery_free_threshold} cans. ${settings.free_delivery_village} is always free — set 0 to remove it everywhere.`}
      />

      <div className="lg:col-span-2">
        {state.error ? (
          <p
            role="alert"
            className="mb-4 rounded-xl bg-danger-bg px-3 py-2.5 text-[12.5px] font-semibold text-danger"
          >
            {state.error}
          </p>
        ) : null}
        {state.ok ? (
          <p
            role="status"
            className="mb-4 rounded-xl bg-ok-bg px-3 py-2.5 text-[12.5px] font-semibold text-ok"
          >
            ✓ {state.ok}
          </p>
        ) : null}
        <SaveButton />
      </div>
    </form>
  );
}

function Field({
  name,
  label,
  defaultValue,
  hint,
  min = 1,
}: {
  name: string;
  label: string;
  defaultValue: number;
  hint: string;
  min?: number;
}) {
  return (
    <div className="rounded-2xl border border-line bg-surface p-5">
      <label htmlFor={name} className="block text-[13px] font-semibold text-ink">
        {label}
      </label>
      <div className="mt-3 flex items-center gap-2 rounded-xl border border-line bg-canvas px-3.5 focus-within:border-brand focus-within:ring-4 focus-within:ring-brand/10">
        <span className="text-[15px] font-bold text-ink-muted">₹</span>
        <input
          id={name}
          name={name}
          type="number"
          inputMode="numeric"
          min={min}
          required
          defaultValue={defaultValue}
          className="tnum h-12 w-full bg-transparent text-[16px] font-semibold text-ink outline-none"
        />
      </div>
      <p className="mt-2.5 text-[11.5px] leading-relaxed text-ink-faint">
        {hint}
      </p>
    </div>
  );
}
