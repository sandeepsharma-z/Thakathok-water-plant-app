"use client";

import { motion } from "framer-motion";
import {
  ArrowDownRight,
  ArrowUpRight,
  Droplet,
  IndianRupee,
  Package,
  TriangleAlert,
  Wallet,
  type LucideIcon,
} from "lucide-react";
import {
  Area,
  AreaChart,
  Cell,
  Line,
  LineChart,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

import { ORDER_STATUS, ORDERS_TREND, STATS } from "@/lib/dashboard-data";

const STAT_ICONS: Record<string, LucideIcon> = {
  orders: Package,
  revenue: Droplet,
  collections: Wallet,
  dues: TriangleAlert,
  cans: Droplet,
};

/* ── 5 stat cards with sparklines ─────────────────────────────────── */
export function StatCards() {
  return (
    <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 xl:grid-cols-5">
      {STATS.map((s, i) => {
        const Icon = STAT_ICONS[s.icon] ?? Package;
        const data = s.spark.map((v, x) => ({ x, v }));
        return (
          <motion.div
            key={s.key}
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.45, delay: i * 0.07 }}
            className="rounded-2xl border border-line bg-surface p-4 shadow-soft"
          >
            <div className="flex items-start justify-between">
              <div>
                <p className="text-[12px] text-ink-muted">{s.label}</p>
                <p className="mt-1 text-[22px] font-extrabold text-ink">
                  {s.value}
                </p>
              </div>
              <span
                className="grid h-10 w-10 place-items-center rounded-xl"
                style={{ background: s.tint, color: s.color }}
              >
                <Icon className="h-5 w-5" />
              </span>
            </div>
            <div className="mt-1 flex items-center gap-1 text-[11.5px] font-semibold">
              <span
                className="inline-flex items-center"
                style={{ color: s.up ? "#1aa971" : "#ef4b6c" }}
              >
                {s.up ? (
                  <ArrowUpRight className="h-3.5 w-3.5" />
                ) : (
                  <ArrowDownRight className="h-3.5 w-3.5" />
                )}
                {s.delta}
              </span>
              <span className="text-ink-faint">from yesterday</span>
            </div>
            <div className="-mb-1 mt-1 h-10 w-full">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={data} margin={{ top: 4, bottom: 0, left: 0, right: 0 }}>
                  <defs>
                    <linearGradient id={`sp-${s.key}`} x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor={s.color} stopOpacity={0.35} />
                      <stop offset="100%" stopColor={s.color} stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <Area
                    type="monotone"
                    dataKey="v"
                    stroke={s.color}
                    strokeWidth={2}
                    fill={`url(#sp-${s.key})`}
                    dot={false}
                  />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </motion.div>
        );
      })}
    </div>
  );
}

/* ── Orders overview line chart ───────────────────────────────────── */
export function OrdersOverview() {
  return (
    <div className="h-[300px] w-full">
      <ResponsiveContainer width="100%" height="100%">
        <LineChart data={ORDERS_TREND} margin={{ top: 12, right: 10, left: -16, bottom: 0 }}>
          <XAxis
            dataKey="day"
            tickLine={false}
            axisLine={false}
            tick={{ fontSize: 11, fill: "#6b7c93" }}
            dy={8}
          />
          <YAxis
            tickLine={false}
            axisLine={false}
            tick={{ fontSize: 11, fill: "#9aa8bd" }}
            ticks={[0, 200, 400, 600, 800, 1000]}
            tickFormatter={(v) => (v === 1000 ? "1K" : `${v}`)}
          />
          <Tooltip
            contentStyle={{
              borderRadius: 12,
              border: "1px solid #e2ebf8",
              fontSize: 12,
              boxShadow: "0 12px 28px -12px rgba(11,37,69,0.28)",
            }}
          />
          <Line
            type="monotone"
            dataKey="orders"
            name="Orders"
            stroke="#2f7cf6"
            strokeWidth={2.5}
            dot={{ r: 3.5, fill: "#2f7cf6", strokeWidth: 0 }}
            activeDot={{ r: 5 }}
          />
          <Line
            type="monotone"
            dataKey="delivered"
            name="Delivered"
            stroke="#1aa971"
            strokeWidth={2.5}
            dot={{ r: 3.5, fill: "#1aa971", strokeWidth: 0 }}
            activeDot={{ r: 5 }}
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}

/* ── Orders by status donut ───────────────────────────────────────── */
export function OrdersStatusDonut() {
  const total = ORDER_STATUS.reduce((s, d) => s + d.value, 0);
  return (
    <div className="flex flex-col items-center gap-5 sm:flex-row">
      <div className="relative h-[190px] w-[190px] shrink-0">
        <ResponsiveContainer width="100%" height="100%">
          <PieChart>
            <Pie
              data={ORDER_STATUS}
              dataKey="value"
              nameKey="name"
              innerRadius={62}
              outerRadius={88}
              paddingAngle={2}
              stroke="none"
              startAngle={90}
              endAngle={-270}
            >
              {ORDER_STATUS.map((s) => (
                <Cell key={s.name} fill={s.color} />
              ))}
            </Pie>
            <Tooltip
              contentStyle={{ borderRadius: 12, border: "1px solid #e2ebf8", fontSize: 12 }}
            />
          </PieChart>
        </ResponsiveContainer>
        <div className="pointer-events-none absolute inset-0 grid place-items-center">
          <div className="text-center">
            <p className="text-[26px] font-extrabold leading-none text-ink">
              {total.toLocaleString("en-IN")}
            </p>
            <p className="text-[12px] text-ink-faint">Total</p>
          </div>
        </div>
      </div>
      <ul className="flex-1 space-y-3">
        {ORDER_STATUS.map((s) => (
          <li key={s.name} className="flex items-start gap-2.5">
            <span
              className="mt-1 h-2.5 w-2.5 shrink-0 rounded-full"
              style={{ background: s.color }}
            />
            <div>
              <p className="text-[13px] font-semibold text-ink">{s.name}</p>
              <p className="text-[12px] text-ink-muted">
                {s.value} ({s.pct})
              </p>
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}
