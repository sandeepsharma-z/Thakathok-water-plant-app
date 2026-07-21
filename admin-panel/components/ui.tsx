import type { BookingStatus } from "@/lib/types";

/* ── Status pill ──────────────────────────────────────────────────────
   Status is never colour-alone: every pill carries an icon and a word. */

const STATUS: Record<
  BookingStatus,
  { label: string; icon: string; cls: string }
> = {
  pending: {
    label: "Pending",
    icon: "⏳",
    cls: "bg-warn-bg text-warn ring-amber-200",
  },
  confirmed: {
    label: "Confirmed",
    icon: "✓",
    cls: "bg-ok-bg text-ok ring-emerald-200",
  },
  delivered: {
    label: "Delivered",
    icon: "🚚",
    cls: "bg-tint text-brand ring-blue-200",
  },
  cancelled: {
    label: "Cancelled",
    icon: "✕",
    cls: "bg-danger-bg text-danger ring-red-200",
  },
};

export function StatusPill({ status }: { status: BookingStatus }) {
  const s = STATUS[status] ?? STATUS.pending;
  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-[11px] font-bold tracking-wide ring-1 ring-inset ${s.cls}`}
    >
      <span aria-hidden>{s.icon}</span>
      {s.label}
    </span>
  );
}

/* ── Card ─────────────────────────────────────────────────────────── */

export function Card({
  children,
  className = "",
}: {
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <div
      className={`rounded-2xl border border-line bg-surface shadow-[0_1px_2px_rgba(14,42,71,0.04),0_8px_24px_-12px_rgba(14,42,71,0.12)] ${className}`}
    >
      {children}
    </div>
  );
}

/* ── Stat tile ────────────────────────────────────────────────────────
   label (sentence case) · value (semibold, proportional figures) ·
   optional hint. No sparkline — these are counts, not trends. */

export function StatTile({
  label,
  value,
  hint,
  icon,
  accent = "brand",
}: {
  label: string;
  value: string | number;
  hint?: string;
  icon: React.ReactNode;
  accent?: "brand" | "ok" | "warn";
}) {
  const ring = {
    brand: "bg-tint text-brand",
    ok: "bg-ok-bg text-ok",
    warn: "bg-warn-bg text-warn",
  }[accent];

  return (
    <Card className="p-5">
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <p className="text-[12.5px] font-medium text-ink-muted">{label}</p>
          <p className="mt-2 text-[30px] font-semibold leading-none text-ink">
            {value}
          </p>
          {hint ? (
            <p className="mt-2 text-[11.5px] text-ink-faint">{hint}</p>
          ) : null}
        </div>
        <span
          className={`grid h-10 w-10 shrink-0 place-items-center rounded-xl ${ring}`}
          aria-hidden
        >
          {icon}
        </span>
      </div>
    </Card>
  );
}

/* ── Empty / error state ──────────────────────────────────────────── */

export function EmptyState({
  icon,
  title,
  body,
}: {
  icon: React.ReactNode;
  title: string;
  body: string;
}) {
  return (
    <div className="grid place-items-center px-6 py-20 text-center">
      <div className="grid h-14 w-14 place-items-center rounded-2xl bg-tint text-brand">
        {icon}
      </div>
      <h3 className="mt-4 text-base font-semibold text-ink">{title}</h3>
      <p className="mt-1 max-w-sm text-[13px] text-ink-muted">{body}</p>
    </div>
  );
}
