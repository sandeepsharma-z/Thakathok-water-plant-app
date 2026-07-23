"use client";

import { motion } from "framer-motion";
import { Activity, PieChart as PieIcon } from "lucide-react";
import {
  Area,
  AreaChart,
  Cell,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

import { Card } from "@/components/ui";
import type { Booking } from "@/lib/types";

const DAY = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

// Status colours mirror the reserved status palette (never decorative reuse).
const STATUS_COLORS: Record<string, string> = {
  Pending: "#e0a000",
  Confirmed: "#12855a",
  Cancelled: "#d92d54",
};

export function DashboardCharts({ bookings }: { bookings: Booking[] }) {
  // Last 7 days of booking volume, by created_at.
  const today = new Date();
  const trend = Array.from({ length: 7 }).map((_, i) => {
    const d = new Date(today);
    d.setDate(today.getDate() - (6 - i));
    const key = d.toISOString().slice(0, 10);
    const count = bookings.filter(
      (b) => (b.created_at ?? "").slice(0, 10) === key,
    ).length;
    return { day: DAY[d.getDay()], count };
  });

  const statusData = (["Pending", "Confirmed", "Cancelled"] as const)
    .map((name) => ({
      name,
      value: bookings.filter((b) => b.status === name.toLowerCase()).length,
    }))
    .filter((s) => s.value > 0);

  const totalForDonut = statusData.reduce((s, d) => s + d.value, 0);

  return (
    <div className="grid gap-4 lg:grid-cols-5">
      {/* Trend — spans 3 */}
      <motion.div
        initial={{ opacity: 0, y: 18 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay: 0.1 }}
        className="lg:col-span-3"
      >
        <Card className="p-5">
          <div className="mb-3 flex items-center gap-2">
            <span className="grid h-8 w-8 place-items-center rounded-xl bg-tint text-brand">
              <Activity className="h-4 w-4" />
            </span>
            <div>
              <h3 className="text-[14px] font-bold text-ink">
                Bookings this week
              </h3>
              <p className="text-[11px] text-ink-faint">Last 7 days</p>
            </div>
          </div>
          <div className="h-[210px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart
                data={trend}
                margin={{ top: 8, right: 8, left: -22, bottom: 0 }}
              >
                <defs>
                  <linearGradient id="fillTrend" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#004fda" stopOpacity={0.35} />
                    <stop offset="100%" stopColor="#004fda" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <XAxis
                  dataKey="day"
                  tickLine={false}
                  axisLine={false}
                  tick={{ fontSize: 11, fill: "#6b7c93" }}
                  dy={6}
                />
                <YAxis
                  allowDecimals={false}
                  tickLine={false}
                  axisLine={false}
                  tick={{ fontSize: 11, fill: "#9aa8bd" }}
                  width={34}
                />
                <Tooltip
                  cursor={{ stroke: "#c7d7ee", strokeWidth: 1 }}
                  contentStyle={{
                    borderRadius: 14,
                    border: "1px solid #e2ebf8",
                    boxShadow: "0 12px 30px -12px rgba(11,37,69,0.28)",
                    fontSize: 12,
                  }}
                  labelStyle={{ fontWeight: 700, color: "#0b2545" }}
                />
                <Area
                  type="monotone"
                  dataKey="count"
                  name="Bookings"
                  stroke="#004fda"
                  strokeWidth={2.5}
                  fill="url(#fillTrend)"
                  dot={{ r: 3, fill: "#004fda", strokeWidth: 0 }}
                  activeDot={{ r: 5, stroke: "#fff", strokeWidth: 2 }}
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </Card>
      </motion.div>

      {/* Status donut — spans 2 */}
      <motion.div
        initial={{ opacity: 0, y: 18 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay: 0.18 }}
        className="lg:col-span-2"
      >
        <Card className="flex h-full flex-col p-5">
          <div className="mb-3 flex items-center gap-2">
            <span className="grid h-8 w-8 place-items-center rounded-xl bg-tint text-brand">
              <PieIcon className="h-4 w-4" />
            </span>
            <div>
              <h3 className="text-[14px] font-bold text-ink">By status</h3>
              <p className="text-[11px] text-ink-faint">All bookings</p>
            </div>
          </div>

          {totalForDonut === 0 ? (
            <div className="flex flex-1 items-center justify-center py-8 text-center text-[12.5px] text-ink-faint">
              No bookings yet
            </div>
          ) : (
            <div className="flex flex-1 items-center gap-3">
              <div className="relative h-[160px] w-[160px] shrink-0">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={statusData}
                      dataKey="value"
                      nameKey="name"
                      innerRadius={52}
                      outerRadius={74}
                      paddingAngle={3}
                      stroke="none"
                    >
                      {statusData.map((s) => (
                        <Cell key={s.name} fill={STATUS_COLORS[s.name]} />
                      ))}
                    </Pie>
                    <Tooltip
                      contentStyle={{
                        borderRadius: 14,
                        border: "1px solid #e2ebf8",
                        fontSize: 12,
                      }}
                    />
                  </PieChart>
                </ResponsiveContainer>
                <div className="pointer-events-none absolute inset-0 grid place-items-center">
                  <div className="text-center">
                    <p className="text-[22px] font-bold leading-none text-ink">
                      {totalForDonut}
                    </p>
                    <p className="text-[10px] text-ink-faint">total</p>
                  </div>
                </div>
              </div>
              <ul className="flex-1 space-y-2">
                {statusData.map((s) => (
                  <li
                    key={s.name}
                    className="flex items-center justify-between text-[12px]"
                  >
                    <span className="flex items-center gap-2 text-ink-body">
                      <span
                        className="h-2.5 w-2.5 rounded-full"
                        style={{ background: STATUS_COLORS[s.name] }}
                      />
                      {s.name}
                    </span>
                    <span className="font-bold text-ink">{s.value}</span>
                  </li>
                ))}
              </ul>
            </div>
          )}
        </Card>
      </motion.div>
    </div>
  );
}
