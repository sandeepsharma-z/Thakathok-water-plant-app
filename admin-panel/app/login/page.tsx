"use client";

import { motion } from "framer-motion";
import {
  ArrowRight,
  Droplets,
  Eye,
  EyeOff,
  Lock,
  Mail,
  ShieldCheck,
  Sparkles,
  Waves,
} from "lucide-react";
import Image from "next/image";
import { useActionState, useState } from "react";
import { useFormStatus } from "react-dom";

import { WaterBackground } from "@/components/water-bg";
import { signIn, type LoginState } from "./actions";

function SubmitButton() {
  const { pending } = useFormStatus();
  return (
    <button
      type="submit"
      disabled={pending}
      className="group relative mt-2 flex h-12 w-full items-center justify-center gap-2 overflow-hidden rounded-2xl bg-gradient-to-r from-[#004fda] to-[#2e8bf0] text-[14px] font-bold tracking-wide text-white shadow-[0_14px_30px_-12px_rgba(0,79,218,0.8)] transition-all hover:-translate-y-0.5 hover:shadow-[0_18px_36px_-12px_rgba(0,79,218,0.9)] hover:brightness-105 active:translate-y-0 disabled:opacity-70"
    >
      <span className="shimmer absolute inset-0" />
      <span className="relative">{pending ? "Signing in…" : "LOGIN"}</span>
      {!pending && (
        <ArrowRight className="relative h-4 w-4 transition-transform group-hover:translate-x-1" />
      )}
    </button>
  );
}

const FEATURES = [
  { Icon: Sparkles, text: "Confirm cash bookings in one tap" },
  { Icon: Waves, text: "Live rates & delivery-charge control" },
  { Icon: ShieldCheck, text: "Secure — protected by row-level security" },
];

export default function LoginPage() {
  const [state, formAction] = useActionState<LoginState, FormData>(signIn, {});
  const [show, setShow] = useState(false);

  return (
    <main className="grid min-h-dvh lg:grid-cols-2">
      {/* ── Left: brand showcase ─────────────────────────────────── */}
      <section className="animate-gradient relative hidden overflow-hidden bg-[linear-gradient(135deg,#00256e_0%,#004fda_45%,#0a7bd6_100%)] lg:block">
        <WaterBackground bubbles={18} />
        {/* wave at bottom */}
        <svg
          className="absolute inset-x-0 bottom-0 h-40 w-full text-white/10"
          viewBox="0 0 1440 320"
          preserveAspectRatio="none"
          aria-hidden
        >
          <path
            fill="currentColor"
            d="M0,192L48,197.3C96,203,192,213,288,202.7C384,192,480,160,576,165.3C672,171,768,213,864,224C960,235,1056,213,1152,192C1248,171,1344,149,1392,138.7L1440,128L1440,320L0,320Z"
          />
        </svg>

        <div className="relative z-10 flex h-full flex-col justify-between p-12">
          <motion.div
            initial={{ opacity: 0, y: -14 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="flex items-center gap-3"
          >
            <div className="grid h-12 w-12 place-items-center rounded-2xl bg-white shadow-lg ring-1 ring-white/40">
              <Image src="/logo.png" alt="" width={32} height={32} />
            </div>
            <div>
              <p className="text-[16px] font-extrabold leading-tight text-white">
                Mahalakshmi Water Plant
              </p>
              <p className="text-[11px] tracking-[0.2em] text-white/70">
                THAKATHOK · ADMIN
              </p>
            </div>
          </motion.div>

          <div>
            <motion.div
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.7, delay: 0.15 }}
              className="animate-float mb-6 inline-grid h-20 w-20 place-items-center rounded-3xl bg-white/15 backdrop-blur-md ring-1 ring-white/25"
            >
              <Droplets className="h-10 w-10 text-white" />
            </motion.div>
            <motion.h1
              initial={{ opacity: 0, y: 16 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.25 }}
              className="max-w-md text-[34px] font-extrabold leading-tight text-white"
            >
              Run your bulk-water business from one calm dashboard.
            </motion.h1>
            <ul className="mt-8 space-y-3">
              {FEATURES.map((f, i) => (
                <motion.li
                  key={f.text}
                  initial={{ opacity: 0, x: -14 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ duration: 0.5, delay: 0.4 + i * 0.1 }}
                  className="flex items-center gap-3 text-[13.5px] text-white/90"
                >
                  <span className="grid h-8 w-8 place-items-center rounded-xl bg-white/15 ring-1 ring-white/20">
                    <f.Icon className="h-4 w-4" />
                  </span>
                  {f.text}
                </motion.li>
              ))}
            </ul>
          </div>

          <p className="text-[11px] text-white/60">
            © {new Date().getFullYear()} Mahalakshmi Water Plant
          </p>
        </div>
      </section>

      {/* ── Right: login form ────────────────────────────────────── */}
      <section className="relative grid place-items-center overflow-hidden bg-canvas px-5 py-10">
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0 bg-[radial-gradient(900px_500px_at_50%_-10%,#dcebff_0%,transparent_60%)]"
        />
        <motion.div
          initial={{ opacity: 0, y: 22 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
          className="relative w-full max-w-[400px]"
        >
          {/* mobile logo */}
          <div className="mb-6 flex flex-col items-center text-center lg:hidden">
            <div className="grid h-16 w-16 place-items-center rounded-3xl bg-gradient-to-br from-[#eaf3ff] to-white shadow-soft ring-1 ring-line">
              <Image src="/logo.png" alt="" width={40} height={40} />
            </div>
          </div>

          <h2 className="text-center text-[26px] font-extrabold tracking-tight text-ink lg:text-left">
            Welcome back 👋
          </h2>
          <p className="mt-1 text-center text-[13px] text-ink-muted lg:text-left">
            Sign in to the Mahalakshmi admin panel
          </p>

          <form
            action={formAction}
            className="glass mt-7 rounded-3xl border border-white/60 p-6 shadow-float"
          >
            <label
              htmlFor="email"
              className="block text-[13px] font-semibold text-ink"
            >
              Email
            </label>
            <div className="group mt-2 flex items-center gap-2.5 rounded-2xl border border-line bg-white/70 px-3.5 transition focus-within:border-brand focus-within:ring-4 focus-within:ring-brand/10">
              <Mail className="h-[18px] w-[18px] text-ink-faint transition group-focus-within:text-brand" />
              <input
                id="email"
                name="email"
                type="email"
                autoComplete="email"
                required
                placeholder="you@example.com"
                className="h-12 w-full bg-transparent text-[14px] text-ink outline-none placeholder:text-ink-faint"
              />
            </div>

            <label
              htmlFor="password"
              className="mt-5 block text-[13px] font-semibold text-ink"
            >
              Password
            </label>
            <div className="group mt-2 flex items-center gap-2.5 rounded-2xl border border-line bg-white/70 px-3.5 transition focus-within:border-brand focus-within:ring-4 focus-within:ring-brand/10">
              <Lock className="h-[18px] w-[18px] text-ink-faint transition group-focus-within:text-brand" />
              <input
                id="password"
                name="password"
                type={show ? "text" : "password"}
                autoComplete="current-password"
                required
                placeholder="Your password"
                className="h-12 w-full bg-transparent text-[14px] text-ink outline-none placeholder:text-ink-faint"
              />
              <button
                type="button"
                onClick={() => setShow((s) => !s)}
                className="text-ink-faint transition hover:text-brand"
                aria-label={show ? "Hide password" : "Show password"}
              >
                {show ? (
                  <EyeOff className="h-[18px] w-[18px]" />
                ) : (
                  <Eye className="h-[18px] w-[18px]" />
                )}
              </button>
            </div>

            {state.error ? (
              <motion.p
                initial={{ opacity: 0, y: -6 }}
                animate={{ opacity: 1, y: 0 }}
                role="alert"
                className="mt-4 rounded-2xl bg-danger-bg px-3 py-2.5 text-[12.5px] font-semibold text-danger"
              >
                {state.error}
              </motion.p>
            ) : null}

            <SubmitButton />
          </form>

          <p className="mt-5 flex items-center justify-center gap-1.5 text-[11.5px] text-ink-faint">
            <ShieldCheck className="h-3.5 w-3.5" />
            Only the water-plant owner can sign in here.
          </p>
        </motion.div>
      </section>
    </main>
  );
}
