import { createClient } from "@/lib/supabase/server";
import type { Booking } from "@/lib/types";

const DAY = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
const MON = [
  "Jan", "Feb", "Mar", "Apr", "May", "Jun",
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
];

export type DashboardData = Awaited<ReturnType<typeof getDashboardData>>;

/** All the numbers the dashboard needs, computed from real bulk-order data. */
export async function getDashboardData() {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("bookings")
    .select("*")
    .order("created_at", { ascending: false });

  const bookings = (data ?? []) as Booking[];
  const ok = !error;

  const pending = bookings.filter((b) => b.status === "pending");
  const confirmed = bookings.filter((b) => b.status === "confirmed");
  const cancelled = bookings.filter((b) => b.status === "cancelled");

  const today = new Date().toISOString().slice(0, 10);
  const upcoming = confirmed.filter((b) => b.event_date >= today);

  const advanceCollected = confirmed.reduce((s, b) => s + b.advance, 0);
  const revenue = confirmed.reduce((s, b) => s + b.grand_total, 0);
  const pendingDues = confirmed.reduce((s, b) => s + b.balance, 0);
  const totalCans = bookings.reduce((s, b) => s + b.cans, 0);

  // ── 7-day trend (created_at) ────────────────────────────────────
  const now = new Date();
  const trend = Array.from({ length: 7 }).map((_, i) => {
    const d = new Date(now);
    d.setDate(now.getDate() - (6 - i));
    const key = d.toISOString().slice(0, 10);
    const all = bookings.filter((b) => (b.created_at ?? "").slice(0, 10) === key);
    return {
      day: `${d.getDate()} ${MON[d.getMonth()]}`,
      short: DAY[d.getDay()],
      bookings: all.length,
      confirmed: all.filter((b) => b.status === "confirmed").length,
    };
  });

  // Week-over-week delta for a simple % (this 7d vs prior 7d).
  const wtd = trend.reduce((s, t) => s + t.bookings, 0);
  const priorStart = new Date(now);
  priorStart.setDate(now.getDate() - 13);
  const prior = bookings.filter((b) => {
    const k = (b.created_at ?? "").slice(0, 10);
    const start = priorStart.toISOString().slice(0, 10);
    const end = new Date(now);
    end.setDate(now.getDate() - 7);
    return k >= start && k <= end.toISOString().slice(0, 10);
  }).length;
  const weekDelta =
    prior === 0 ? (wtd > 0 ? 100 : 0) : Math.round(((wtd - prior) / prior) * 100);

  // ── status breakdown ────────────────────────────────────────────
  const statusData = [
    { name: "Confirmed", value: confirmed.length, color: "#1aa971" },
    { name: "Pending", value: pending.length, color: "#f0a013" },
    { name: "Cancelled", value: cancelled.length, color: "#ef4b6c" },
  ].filter((s) => s.value > 0);

  // ── top villages by revenue (confirmed) ─────────────────────────
  const villageMap = new Map<string, { count: number; revenue: number }>();
  for (const b of bookings) {
    const cur = villageMap.get(b.village) ?? { count: 0, revenue: 0 };
    cur.count += 1;
    if (b.status === "confirmed") cur.revenue += b.grand_total;
    villageMap.set(b.village, cur);
  }
  const villages = [...villageMap.entries()]
    .map(([name, v]) => ({ name, ...v }))
    .sort((a, b) => b.revenue - a.revenue || b.count - a.count)
    .slice(0, 5);
  const villageMax = Math.max(1, ...villages.map((v) => v.revenue));

  // ── payment split of the collected advance (confirmed only) ─────
  const online = confirmed.filter((b) => b.payment_method === "online");
  const cash = confirmed.filter((b) => b.payment_method === "cash");
  const onlineAmt = online.reduce((s, b) => s + b.advance, 0);
  const cashAmt = cash.reduce((s, b) => s + b.advance, 0);
  const totalAdvance = onlineAmt + cashAmt || 1;

  // ── recent bookings ─────────────────────────────────────────────
  const recent = bookings.slice(0, 5).map((b) => ({
    code: b.booking_code,
    village: b.village,
    mobile: b.mobile,
    cans: b.cans,
    amount: b.grand_total,
    status: b.status,
    method: b.payment_method,
    time: fmtTime(b.created_at),
  }));

  return {
    ok,
    counts: {
      total: bookings.length,
      pending: pending.length,
      confirmed: confirmed.length,
      cancelled: cancelled.length,
      upcoming: upcoming.length,
    },
    money: { advanceCollected, revenue, pendingDues },
    totalCans,
    confirmedCans: confirmed.reduce((s, b) => s + b.cans, 0),
    pendingCans: pending.reduce((s, b) => s + b.cans, 0),
    trend,
    weekDelta,
    statusData,
    villages,
    villageMax,
    payment: {
      total: advanceCollected,
      online: { amt: onlineAmt, pct: Math.round((onlineAmt / totalAdvance) * 100) },
      cash: { amt: cashAmt, pct: Math.round((cashAmt / totalAdvance) * 100) },
    },
    recent,
  };
}

function fmtTime(iso: string | null | undefined) {
  if (!iso) return "";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  let h = d.getHours();
  const m = d.getMinutes().toString().padStart(2, "0");
  const ap = h < 12 ? "AM" : "PM";
  h = h % 12 || 12;
  return `${h}:${m} ${ap}`;
}

export const rupee = (n: number) => `₹${n.toLocaleString("en-IN")}`;
