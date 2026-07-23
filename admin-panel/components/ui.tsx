"use client";

import { motion } from "framer-motion";
import {
  AlertTriangle,
  CalendarClock,
  CheckCircle2,
  ClipboardList,
  Clock,
  IndianRupee,
  Truck,
  XCircle,
  type LucideIcon,
} from "lucide-react";

import { CountUp } from "@/components/count-up";
import type { BookingStatus } from "@/lib/types";

/* Icon registry — server components pass a string key (a component reference
   can't cross the server→client boundary). */
export type IconName =
  | "clock"
  | "check"
  | "calendar"
  | "rupee"
  | "clipboard"
  | "alert";

const ICONS: Record<IconName, LucideIcon> = {
  clock: Clock,
  check: CheckCircle2,
  calendar: CalendarClock,
  rupee: IndianRupee,
  clipboard: ClipboardList,
  alert: AlertTriangle,
};

/* ── Status pill — icon + word, never colour alone ─────────────────── */

const STATUS: Record<
  BookingStatus,
  { label: string; Icon: LucideIcon; cls: string }
> = {
  pending: {
    label: "Pending",
    Icon: Clock,
    cls: "bg-warn-bg text-warn ring-amber-200/70",
  },
  confirmed: {
    label: "Confirmed",
    Icon: CheckCircle2,
    cls: "bg-ok-bg text-ok ring-emerald-200/70",
  },
  delivered: {
    label: "Delivered",
    Icon: Truck,
    cls: "bg-tint text-brand ring-blue-200/70",
  },
  cancelled: {
    label: "Cancelled",
    Icon: XCircle,
    cls: "bg-danger-bg text-danger ring-rose-200/70",
  },
};

export function StatusPill({ status }: { status: BookingStatus }) {
  const s = STATUS[status] ?? STATUS.pending;
  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-[11px] font-bold tracking-wide ring-1 ring-inset ${s.cls}`}
    >
      <s.Icon className="h-3.5 w-3.5" strokeWidth={2.5} />
      {s.label}
    </span>
  );
}

/* ── Card ──────────────────────────────────────────────────────────── */

export function Card({
  children,
  className = "",
}: {
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <div
      className={`rounded-3xl border border-line bg-surface shadow-soft ${className}`}
    >
      {children}
    </div>
  );
}

/* ── Stat tile — gradient icon chip, count-up value, accent glow ───── */

type Accent = "brand" | "ok" | "warn" | "aqua";

const ACCENTS: Record<
  Accent,
  { chip: string; glow: string; ring: string }
> = {
  brand: {
    chip: "from-[#004fda] to-[#3e93f5]",
    glow: "rgba(0,79,218,0.20)",
    ring: "group-hover:ring-[#004fda]/30",
  },
  aqua: {
    chip: "from-[#00a2ff] to-[#37b6ff]",
    glow: "rgba(0,162,255,0.22)",
    ring: "group-hover:ring-[#00a2ff]/30",
  },
  ok: {
    chip: "from-[#12855a] to-[#2fbd83]",
    glow: "rgba(18,133,90,0.20)",
    ring: "group-hover:ring-emerald-400/30",
  },
  warn: {
    chip: "from-[#e08a00] to-[#ffb43d]",
    glow: "rgba(224,138,0,0.20)",
    ring: "group-hover:ring-amber-400/30",
  },
};

export function StatTile({
  label,
  value,
  hint,
  icon,
  accent = "brand",
  money = false,
  index = 0,
}: {
  label: string;
  value: number;
  hint?: string;
  icon: IconName;
  accent?: Accent;
  money?: boolean;
  index?: number;
}) {
  const a = ACCENTS[accent];
  const Icon = ICONS[icon];
  return (
    <motion.div
      initial={{ opacity: 0, y: 18 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5, delay: index * 0.08, ease: [0.16, 1, 0.3, 1] }}
      className={`group relative overflow-hidden rounded-3xl border border-line bg-surface p-5 shadow-soft ring-1 ring-transparent transition-all duration-300 hover:-translate-y-1 hover:shadow-float ${a.ring}`}
    >
      {/* corner glow */}
      <div
        className="pointer-events-none absolute -right-8 -top-8 h-28 w-28 rounded-full blur-2xl transition-opacity duration-300 group-hover:opacity-100"
        style={{ background: a.glow, opacity: 0.6 }}
      />
      <div className="relative flex items-start justify-between gap-3">
        <div className="min-w-0">
          <p className="text-[12.5px] font-medium text-ink-muted">{label}</p>
          <p className="mt-2 text-[32px] font-bold leading-none text-ink">
            <CountUp value={value} prefix={money ? "₹" : ""} />
          </p>
          {hint ? (
            <p className="mt-2 text-[11.5px] text-ink-faint">{hint}</p>
          ) : null}
        </div>
        <div
          className={`grid h-12 w-12 shrink-0 place-items-center rounded-2xl bg-gradient-to-br text-white shadow-lg ${a.chip}`}
        >
          <Icon className="h-6 w-6" strokeWidth={2.2} />
        </div>
      </div>
    </motion.div>
  );
}

/* ── Empty state ───────────────────────────────────────────────────── */

export function EmptyState({
  icon,
  title,
  body,
}: {
  icon: IconName;
  title: string;
  body: string;
}) {
  const Icon = ICONS[icon];
  return (
    <div className="grid place-items-center px-6 py-16 text-center">
      <div className="grid h-16 w-16 place-items-center rounded-3xl bg-gradient-to-br from-[#eaf3ff] to-[#d8e9ff] text-brand">
        <Icon className="h-8 w-8" strokeWidth={2} />
      </div>
      <h3 className="mt-4 text-base font-semibold text-ink">{title}</h3>
      <p className="mt-1 max-w-sm text-[13px] text-ink-muted">{body}</p>
    </div>
  );
}
