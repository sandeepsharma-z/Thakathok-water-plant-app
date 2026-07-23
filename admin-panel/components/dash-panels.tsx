import {
  ClipboardList,
  Clock,
  Droplet,
  Droplets,
  MapPin,
  SlidersHorizontal,
  Wallet,
  type LucideIcon,
} from "lucide-react";
import Link from "next/link";

import { rupee } from "@/lib/dashboard-queries";

const VILLAGE_COLORS = [
  "from-[#2f7cf6] to-[#5b9bff]",
  "from-[#1aa971] to-[#3fd39a]",
  "from-[#9b6cf0] to-[#b99bf7]",
  "from-[#f0a013] to-[#ffc255]",
  "from-[#12b0c9] to-[#4fd6e6]",
];

type Recent = {
  code: string;
  village: string;
  mobile: string;
  cans: number;
  amount: number;
  status: string;
  time: string;
};

/* ── Recent bookings ──────────────────────────────────────────────── */
export function RecentBookings({ items }: { items: Recent[] }) {
  return (
    <div className="rounded-2xl border border-line bg-surface p-5 shadow-soft">
      <div className="mb-3 flex items-center justify-between">
        <h3 className="text-[15px] font-bold text-ink">Recent Bookings</h3>
        <Link href="/bookings" className="text-[12.5px] font-semibold text-brand hover:underline">
          View All
        </Link>
      </div>

      {items.length === 0 ? (
        <p className="py-8 text-center text-[13px] text-ink-faint">
          No bookings yet
        </p>
      ) : (
        <ul className="divide-y divide-line">
          {items.map((o, i) => (
            <li key={o.code} className="flex items-center gap-3 py-2.5">
              <div
                className={`grid h-10 w-10 shrink-0 place-items-center rounded-full bg-gradient-to-br text-white ${VILLAGE_COLORS[i % VILLAGE_COLORS.length]}`}
              >
                <Droplet className="h-4 w-4" />
              </div>
              <div className="min-w-0 flex-1">
                <p className="truncate text-[12.5px] font-bold text-ink">
                  {o.code}
                </p>
                <p className="truncate text-[11px] text-ink-faint">
                  {o.village} · {o.time}
                </p>
              </div>
              <div className="flex shrink-0 flex-col items-end gap-1">
                <Badge status={o.status} />
                <span className="text-[13px] font-bold text-ink">
                  {rupee(o.amount)}
                </span>
              </div>
            </li>
          ))}
        </ul>
      )}

      <Link
        href="/bookings"
        className="mt-3 block rounded-xl bg-gradient-to-r from-[#2f6fe6] to-[#2f8bf0] py-2.5 text-center text-[13px] font-bold text-white shadow-[0_10px_20px_-10px_rgba(0,79,218,0.9)]"
      >
        View All Bookings
      </Link>
    </div>
  );
}

function Badge({ status }: { status: string }) {
  const map: Record<string, string> = {
    confirmed: "bg-[#e5f7ef] text-[#12855a]",
    pending: "bg-[#fff3dd] text-[#b26a00]",
    cancelled: "bg-[#fdecef] text-[#d92d54]",
    delivered: "bg-[#eef4ff] text-[#2f6fe6]",
  };
  return (
    <span
      className={`rounded-full px-2 py-0.5 text-[10px] font-bold capitalize ${map[status] ?? map.pending}`}
    >
      {status}
    </span>
  );
}

/* ── Top villages ─────────────────────────────────────────────────── */
export function TopVillages({
  items,
  max,
}: {
  items: { name: string; count: number; revenue: number }[];
  max: number;
}) {
  return (
    <div className="rounded-2xl border border-line bg-surface p-5 shadow-soft">
      <div className="mb-4 flex items-center justify-between">
        <h3 className="text-[15px] font-bold text-ink">Top Villages</h3>
        <span className="rounded-lg border border-line px-2.5 py-1 text-[11.5px] font-semibold text-ink-muted">
          By Revenue
        </span>
      </div>
      {items.length === 0 ? (
        <p className="py-6 text-center text-[13px] text-ink-faint">
          No bookings yet
        </p>
      ) : (
        <ul className="space-y-3.5">
          {items.map((b, i) => (
            <li key={b.name} className="flex items-center gap-3">
              <span className="grid h-6 w-6 shrink-0 place-items-center rounded-full bg-tint text-[11px] font-bold text-brand">
                {i + 1}
              </span>
              <div className="min-w-0 flex-1">
                <div className="flex items-center justify-between">
                  <span className="flex items-center gap-1.5 text-[13px] font-semibold text-ink">
                    <MapPin className="h-3.5 w-3.5 text-brand/70" />
                    {b.name}
                  </span>
                  <span className="text-[13px] font-bold text-ink">
                    {rupee(b.revenue)}
                  </span>
                </div>
                <div className="mt-1.5 h-1.5 w-full overflow-hidden rounded-full bg-tint">
                  <div
                    className="h-full rounded-full bg-gradient-to-r from-[#2f7cf6] to-[#37b6ff]"
                    style={{ width: `${Math.max(6, (b.revenue / max) * 100)}%` }}
                  />
                </div>
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

/* ── Cans summary ─────────────────────────────────────────────────── */
export function CansSummary({
  total,
  confirmed,
  pending,
  bookings,
}: {
  total: number;
  confirmed: number;
  pending: number;
  bookings: number;
}) {
  const rows = [
    { label: "In confirmed orders", value: confirmed, color: "#1aa971" },
    { label: "In pending orders", value: pending, color: "#f0a013" },
    { label: "Total bookings", value: bookings, color: "#2f7cf6" },
  ];
  return (
    <div className="rounded-2xl border border-line bg-surface p-5 shadow-soft">
      <h3 className="mb-4 text-[15px] font-bold text-ink">Cans Booked</h3>
      <div className="flex flex-col items-center gap-6 sm:flex-row">
        <div className="relative grid h-[150px] w-[150px] shrink-0 place-items-center">
          <div className="absolute inset-0 rounded-full bg-[conic-gradient(from_0deg,#37b6ff,#2f7cf6,#00c2ff,#37b6ff)] opacity-90 blur-[1px]" />
          <div className="absolute inset-[10px] rounded-full bg-surface" />
          <div className="absolute inset-[6px] rounded-full ring-2 ring-[#bfe0ff]" />
          <div className="relative text-center">
            <p className="text-[26px] font-extrabold leading-none text-ink">
              {total.toLocaleString("en-IN")}
            </p>
            <p className="text-[12px] text-ink-muted">Total Cans</p>
          </div>
        </div>
        <ul className="flex-1 space-y-2.5">
          {rows.map((r) => (
            <li key={r.label} className="flex items-center justify-between">
              <span className="flex items-center gap-2 text-[12.5px] text-ink-body">
                <span className="h-2.5 w-2.5 rounded-full" style={{ background: r.color }} />
                {r.label}
              </span>
              <span className="text-[13px] font-bold text-ink">
                {r.value.toLocaleString("en-IN")}
              </span>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}

/* ── Payment summary ──────────────────────────────────────────────── */
export function PaymentSummary({
  total,
  online,
  cash,
}: {
  total: number;
  online: { amt: number; pct: number };
  cash: { amt: number; pct: number };
}) {
  return (
    <div className="rounded-2xl border border-line bg-surface p-5 shadow-soft">
      <div className="mb-4 flex items-center justify-between">
        <h3 className="text-[15px] font-bold text-ink">Advance Collected</h3>
        <span className="rounded-lg border border-line px-2.5 py-1 text-[11.5px] font-semibold text-ink-muted">
          All time
        </span>
      </div>
      <div className="grid grid-cols-2 gap-3">
        <div className="col-span-2 rounded-xl bg-tint p-3.5">
          <p className="text-[11.5px] text-ink-muted">Total Collected</p>
          <p className="mt-0.5 text-[20px] font-extrabold text-ink">{rupee(total)}</p>
        </div>
        <div className="rounded-xl bg-tint p-3.5">
          <p className="flex items-center gap-1.5 text-[11.5px] font-semibold text-ink-body">
            <span className="h-2 w-2 rounded-full bg-[#1aa971]" />
            Cash
          </p>
          <p className="mt-0.5 text-[16px] font-extrabold text-ink">{rupee(cash.amt)}</p>
          <p className="text-[11px] text-ink-muted">{cash.pct}%</p>
        </div>
        <div className="rounded-xl bg-tint p-3.5">
          <p className="flex items-center gap-1.5 text-[11.5px] font-semibold text-ink-body">
            <span className="h-2 w-2 rounded-full bg-[#9b6cf0]" />
            Online / UPI
          </p>
          <p className="mt-0.5 text-[16px] font-extrabold text-ink">{rupee(online.amt)}</p>
          <p className="text-[11px] text-ink-muted">{online.pct}%</p>
        </div>
      </div>
    </div>
  );
}

/* ── Quick actions (links to real pages) ──────────────────────────── */
const QA: { label: string; href: string; Icon: LucideIcon; color: string; bg: string }[] = [
  { label: "All Bookings", href: "/bookings", Icon: ClipboardList, color: "#2f7cf6", bg: "#e7f0ff" },
  { label: "Pending", href: "/bookings?status=pending", Icon: Clock, color: "#f0a013", bg: "#fff3dd" },
  { label: "Confirmed", href: "/bookings?status=confirmed", Icon: Droplets, color: "#1aa971", bg: "#e5f7ef" },
  { label: "Rates & Charges", href: "/settings", Icon: SlidersHorizontal, color: "#9b6cf0", bg: "#f1eafe" },
  { label: "Collections", href: "/bookings?status=confirmed", Icon: Wallet, color: "#12b0c9", bg: "#e2f7fb" },
];

export function QuickActions() {
  return (
    <div className="rounded-2xl border border-line bg-surface p-5 shadow-soft">
      <h3 className="mb-4 text-[15px] font-bold text-ink">Quick Actions</h3>
      <div className="grid grid-cols-3 gap-3 sm:grid-cols-5">
        {QA.map((a) => (
          <Link
            key={a.label}
            href={a.href}
            className="group flex flex-col items-center gap-2 rounded-2xl border border-transparent p-3 transition hover:border-line hover:bg-canvas"
          >
            <span
              className="grid h-12 w-12 place-items-center rounded-2xl transition group-hover:scale-105"
              style={{ background: a.bg, color: a.color }}
            >
              <a.Icon className="h-5 w-5" />
            </span>
            <span className="text-center text-[11.5px] font-semibold text-ink-body">
              {a.label}
            </span>
          </Link>
        ))}
      </div>
    </div>
  );
}
