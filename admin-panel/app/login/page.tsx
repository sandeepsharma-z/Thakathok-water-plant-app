"use client";

import Image from "next/image";
import { useActionState } from "react";
import { useFormStatus } from "react-dom";

import { signIn, type LoginState } from "./actions";

function SubmitButton() {
  const { pending } = useFormStatus();
  return (
    <button
      type="submit"
      disabled={pending}
      className="mt-2 h-12 w-full rounded-xl bg-brand text-[14px] font-bold tracking-wide text-white shadow-[0_8px_20px_-8px_rgba(0,79,218,0.7)] transition hover:bg-brand-dark disabled:opacity-60"
    >
      {pending ? "Signing in…" : "LOGIN"}
    </button>
  );
}

export default function LoginPage() {
  const [state, formAction] = useActionState<LoginState, FormData>(signIn, {});

  return (
    <main className="relative grid min-h-dvh place-items-center overflow-hidden px-5 py-10">
      {/* Soft water-themed backdrop */}
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 -z-10 bg-[radial-gradient(1100px_520px_at_50%_-10%,#dcebff_0%,transparent_60%),radial-gradient(700px_400px_at_110%_110%,#e8f4ff_0%,transparent_55%)]"
      />

      <div className="w-full max-w-[400px] animate-rise">
        <div className="flex flex-col items-center text-center">
          <Image
            src="/logo.png"
            alt=""
            width={84}
            height={84}
            priority
            className="drop-shadow-[0_10px_24px_rgba(0,79,218,0.25)]"
          />
          <h1 className="mt-4 text-[26px] font-extrabold tracking-tight text-brand">
            Admin Panel
          </h1>
          <p className="mt-1 text-[13px] text-ink-muted">
            Mahalakshmi Water Plant
          </p>
        </div>

        <form
          action={formAction}
          className="mt-8 rounded-2xl border border-line bg-surface p-6 shadow-[0_1px_2px_rgba(14,42,71,0.04),0_18px_44px_-24px_rgba(14,42,71,0.28)]"
        >
          <label
            htmlFor="email"
            className="block text-[13px] font-semibold text-ink"
          >
            Email
          </label>
          <input
            id="email"
            name="email"
            type="email"
            autoComplete="email"
            required
            placeholder="you@example.com"
            className="mt-2 h-12 w-full rounded-xl border border-line bg-canvas px-3.5 text-[14px] text-ink outline-none transition placeholder:text-ink-faint focus:border-brand focus:ring-4 focus:ring-brand/10"
          />

          <label
            htmlFor="password"
            className="mt-5 block text-[13px] font-semibold text-ink"
          >
            Password
          </label>
          <input
            id="password"
            name="password"
            type="password"
            autoComplete="current-password"
            required
            placeholder="Your password"
            className="mt-2 h-12 w-full rounded-xl border border-line bg-canvas px-3.5 text-[14px] text-ink outline-none transition placeholder:text-ink-faint focus:border-brand focus:ring-4 focus:ring-brand/10"
          />

          {state.error ? (
            <p
              role="alert"
              className="mt-4 rounded-xl bg-danger-bg px-3 py-2.5 text-[12.5px] font-semibold text-danger"
            >
              {state.error}
            </p>
          ) : null}

          <SubmitButton />
        </form>

        <p className="mt-5 text-center text-[11.5px] text-ink-faint">
          Only the water plant owner can sign in here.
        </p>
      </div>
    </main>
  );
}
