import {
  FileText,
  Send,
  ShoppingCart,
  UserPlus,
  Droplets,
  LineChart as LineChartIcon,
  type LucideIcon,
} from "lucide-react";

import {
  CANS_SUMMARY,
  PAYMENT_SUMMARY,
  QUICK_ACTIONS,
  RECENT_ORDERS,
  TOP_BRANCHES,
} from "@/lib/dashboard-data";

const AVATAR_COLORS = [
  "from-[#2f7cf6] to-[#5b9bff]",
  "from-[#1aa971] to-[#3fd39a]",
  "from-[#9b6cf0] to-[#b99bf7]",
  "from-[#f0a013] to-[#ffc255]",
  "from-[#ef4b6c] to-[#ff7d97]",
];

function initials(name: string) {
  return name
    .split(" ")
    .map((p) => p[0])
    .slice(0, 2)
    .join("")
    .toUpperCase();
}

/* ── Recent orders ────────────────────────────────────────────────── */
export function RecentOrders() {
  return (
    <div className="rounded-2xl border border-line bg-surface p-5 shadow-soft">
      <div className="mb-3 flex items-center justify-between">
        <h3 className="text-[15px] font-bold text-ink">Recent Orders</h3>
        <a href="#" className="text-[12.5px] font-semibold text-brand hover:underline">
          View All
        </a>
      </div>
      <ul className="divide-y divide-line">
        {RECENT_ORDERS.map((o, i) => (
          <li key={o.id} className="flex items-center gap-3 py-2.5">
            <div
              className={`grid h-10 w-10 shrink-0 place-items-center rounded-full bg-gradient-to-br text-[12px] font-bold text-white ${AVATAR_COLORS[i % AVATAR_COLORS.length]}`}
            >
              {initials(o.name)}
            </div>
            <div className="min-w-0 flex-1">
              <p className="truncate text-[13px] font-semibold text-ink">{o.name}</p>
              <p className="text-[11.5px] text-ink-faint">{o.id}</p>
            </div>
            <div className="flex flex-col items-end gap-1">
              <Badge status={o.status} />
              <span className="text-[11px] text-ink-faint">{o.time}</span>
            </div>
            <span className="ml-1 w-[62px] text-right text-[13px] font-bold text-ink">
              {o.amt}
            </span>
          </li>
        ))}
      </ul>
      <button className="mt-3 w-full rounded-xl bg-gradient-to-r from-[#2f6fe6] to-[#2f8bf0] py-2.5 text-[13px] font-bold text-white shadow-[0_10px_20px_-10px_rgba(0,79,218,0.9)]">
        View All Orders
      </button>
    </div>
  );
}

function Badge({ status }: { status: string }) {
  const on = status === "Delivered";
  return (
    <span
      className={`rounded-full px-2 py-0.5 text-[10.5px] font-bold ${
        on ? "bg-[#e5f7ef] text-[#1aa971]" : "bg-[#fff3dd] text-[#b26a00]"
      }`}
    >
      {status}
    </span>
  );
}

/* ── Top performing branches ──────────────────────────────────────── */
export function TopBranches() {
  return (
    <div className="rounded-2xl border border-line bg-surface p-5 shadow-soft">
      <div className="mb-4 flex items-center justify-between">
        <h3 className="text-[15px] font-bold text-ink">Top Performing Branches</h3>
        <span className="rounded-lg border border-line px-2.5 py-1 text-[11.5px] font-semibold text-ink-muted">
          By Revenue
        </span>
      </div>
      <ul className="space-y-3.5">
        {TOP_BRANCHES.map((b, i) => (
          <li key={b.name} className="flex items-center gap-3">
            <span className="grid h-6 w-6 shrink-0 place-items-center rounded-full bg-tint text-[11px] font-bold text-brand">
              {i + 1}
            </span>
            <div className="min-w-0 flex-1">
              <div className="flex items-center justify-between">
                <span className="text-[13px] font-semibold text-ink">{b.name}</span>
                <span className="text-[13px] font-bold text-ink">
                  ₹{b.revenue.toLocaleString("en-IN")}
                </span>
              </div>
              <div className="mt-1.5 h-1.5 w-full overflow-hidden rounded-full bg-tint">
                <div
                  className="h-full rounded-full bg-gradient-to-r from-[#2f7cf6] to-[#37b6ff]"
                  style={{ width: `${(b.revenue / b.max) * 100}%` }}
                />
              </div>
            </div>
          </li>
        ))}
      </ul>
      <a
        href="#"
        className="mt-4 block text-center text-[12.5px] font-semibold text-brand hover:underline"
      >
        View All Branches
      </a>
    </div>
  );
}

/* ── Cans summary ─────────────────────────────────────────────────── */
export function CansSummary() {
  return (
    <div className="rounded-2xl border border-line bg-surface p-5 shadow-soft">
      <h3 className="mb-4 text-[15px] font-bold text-ink">Cans Summary</h3>
      <div className="flex flex-col items-center gap-6 sm:flex-row sm:items-center">
        {/* water ring */}
        <div className="relative grid h-[150px] w-[150px] shrink-0 place-items-center">
          <div className="absolute inset-0 rounded-full bg-[conic-gradient(from_0deg,#37b6ff,#2f7cf6,#00c2ff,#37b6ff)] opacity-90 blur-[1px]" />
          <div className="absolute inset-[10px] rounded-full bg-surface" />
          <div className="absolute inset-[6px] rounded-full ring-2 ring-[#bfe0ff]" />
          <div className="relative text-center">
            <p className="text-[26px] font-extrabold leading-none text-ink">
              {CANS_SUMMARY.total}
            </p>
            <p className="text-[12px] text-ink-muted">Total Cans</p>
          </div>
        </div>
        <ul className="flex-1 space-y-2.5">
          {CANS_SUMMARY.rows.map((r) => (
            <li key={r.label} className="flex items-center justify-between">
              <span className="flex items-center gap-2 text-[12.5px] text-ink-body">
                <span className="h-2.5 w-2.5 rounded-full" style={{ background: r.color }} />
                {r.label}
              </span>
              <span className="text-[13px] font-bold text-ink">{r.value}</span>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}

/* ── Payment summary ──────────────────────────────────────────────── */
export function PaymentSummary() {
  return (
    <div className="rounded-2xl border border-line bg-surface p-5 shadow-soft">
      <div className="mb-4 flex items-center justify-between">
        <h3 className="text-[15px] font-bold text-ink">Payment Summary</h3>
        <span className="rounded-lg border border-line px-2.5 py-1 text-[11.5px] font-semibold text-ink-muted">
          This Month
        </span>
      </div>
      <div className="grid grid-cols-2 gap-3">
        <div className="col-span-2 rounded-xl bg-[#eef4ff] p-3.5">
          <p className="text-[11.5px] text-ink-muted">Total Collected</p>
          <p className="mt-0.5 text-[20px] font-extrabold text-ink">
            {PAYMENT_SUMMARY.totalCollected}
          </p>
          <p className="text-[11px] font-semibold text-[#1aa971]">
            ↑ {PAYMENT_SUMMARY.totalDelta}
          </p>
        </div>
        {PAYMENT_SUMMARY.breakdown.map((b) => (
          <div key={b.label} className="rounded-xl p-3.5" style={{ background: b.bg }}>
            <p className="text-[11.5px]" style={{ color: b.fg }}>
              {b.label}
            </p>
            <p className="mt-0.5 text-[16px] font-extrabold text-ink">{b.value}</p>
            <p className="text-[11px] text-ink-muted">{b.pct}</p>
          </div>
        ))}
      </div>
    </div>
  );
}

/* ── Quick actions ────────────────────────────────────────────────── */
const QA_ICONS: Record<string, LucideIcon> = {
  "add-order": ShoppingCart,
  "add-customer": UserPlus,
  "add-expense": FileText,
  cans: Droplets,
  sms: Send,
  reports: LineChartIcon,
};

export function QuickActions() {
  return (
    <div className="rounded-2xl border border-line bg-surface p-5 shadow-soft">
      <h3 className="mb-4 text-[15px] font-bold text-ink">Quick Actions</h3>
      <div className="grid grid-cols-3 gap-3 sm:grid-cols-6">
        {QUICK_ACTIONS.map((a) => {
          const Icon = QA_ICONS[a.icon] ?? ShoppingCart;
          return (
            <button
              key={a.label}
              className="group flex flex-col items-center gap-2 rounded-2xl border border-transparent p-3 transition hover:border-line hover:bg-canvas"
            >
              <span
                className="grid h-12 w-12 place-items-center rounded-2xl transition group-hover:scale-105"
                style={{ background: a.bg, color: a.color }}
              >
                <Icon className="h-5 w-5" />
              </span>
              <span className="text-center text-[11.5px] font-semibold text-ink-body">
                {a.label}
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
}
