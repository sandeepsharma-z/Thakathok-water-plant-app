"use client";

import { motion } from "framer-motion";
import { CheckCircle2, Droplet, Save, Truck } from "lucide-react";
import type { LucideIcon } from "lucide-react";
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
