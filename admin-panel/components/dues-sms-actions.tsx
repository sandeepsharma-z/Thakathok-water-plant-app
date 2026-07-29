"use client";

import { Send, Users } from "lucide-react";
import { useActionState } from "react";
import { useFormStatus } from "react-dom";

import {
  sendBulkDuesReminders,
  sendDuesReminderAction,
  type ActionState,
} from "@/app/actions";

function SubmitButton({
  bulk = false,
}: {
  bulk?: boolean;
}) {
  const { pending } = useFormStatus();
  const Icon = bulk ? Users : Send;
  return (
    <button
      type="submit"
      disabled={pending}
      className={
        bulk
          ? "inline-flex h-11 items-center gap-2 rounded-2xl bg-gradient-to-r from-[#004fda] to-[#168cff] px-5 text-[12px] font-extrabold text-white shadow-soft transition hover:brightness-105 disabled:opacity-60"
          : "inline-flex h-9 items-center gap-1.5 rounded-xl border border-brand/20 bg-tint px-3 text-[11.5px] font-bold text-brand transition hover:border-brand/40 hover:bg-brand hover:text-white disabled:opacity-60"
      }
    >
      <Icon className="h-4 w-4" />
      {pending
        ? "Sending..."
        : bulk
          ? "Send All Due Reminders"
          : "Send Reminder"}
    </button>
  );
}

function Result({ state }: { state: ActionState }) {
  const message = state.error ?? state.ok;
  if (!message) return null;
  return (
    <p
      role={state.error ? "alert" : undefined}
      className={`mt-2 text-[11px] font-semibold ${
        state.error ? "text-danger" : "text-ok"
      }`}
    >
      {message}
    </p>
  );
}

export function DuesReminderButton({ bookingId }: { bookingId: string }) {
  const [state, action] = useActionState<ActionState, FormData>(
    sendDuesReminderAction,
    {},
  );
  return (
    <div className="mt-2 sm:mt-0">
      <form action={action}>
        <input type="hidden" name="id" value={bookingId} />
        <SubmitButton />
      </form>
      <Result state={state} />
    </div>
  );
}

export function BulkDuesReminderButton() {
  const [state, action] = useActionState<ActionState, FormData>(
    sendBulkDuesReminders,
    {},
  );
  return (
    <div>
      <form action={action}>
        <SubmitButton bulk />
      </form>
      <Result state={state} />
    </div>
  );
}

