"use client";

import { motion } from "framer-motion";
import { Bell, CalendarDays, Moon, Search, Sun } from "lucide-react";
import { useTheme } from "next-themes";
import { useEffect, useState } from "react";

export function Topbar({
  title,
  name,
  subtitle,
  avatarUrl,
}: {
  title: string;
  name: string;
  subtitle?: string;
  avatarUrl?: string | null;
}) {
  const { resolvedTheme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);
  const isDark = mounted && resolvedTheme === "dark";

  const today = new Date().toLocaleDateString("en-IN", {
    day: "numeric",
    month: "short",
    year: "numeric",
  });

  return (
    <div className="relative">
      <div
        aria-hidden
        className="pointer-events-none absolute -right-8 -top-16 h-48 w-96 opacity-60"
        style={{
          background:
            "radial-gradient(220px 120px at 80% 40%, rgba(55,182,255,0.35), rgba(0,162,255,0.12) 45%, transparent 72%)",
        }}
      />

      <div className="relative flex flex-wrap items-center gap-3">
        <div className="mr-auto">
          <h1 className="text-[26px] font-extrabold tracking-tight text-ink">
            {title}
          </h1>
          <p className="mt-0.5 text-[13px] text-ink-muted">
            {subtitle ?? (
              <>
                Welcome back, {name}! <span className="align-middle">👋</span>
              </>
            )}
          </p>
        </div>

        <div className="order-3 w-full lg:order-2 lg:w-[320px]">
          <div className="flex h-11 items-center gap-2 rounded-xl border border-line bg-surface px-3.5 shadow-soft">
            <Search className="h-4 w-4 text-ink-faint" />
            <input
              placeholder="Search anything…"
              className="h-full w-full bg-transparent text-[13px] text-ink outline-none placeholder:text-ink-faint"
            />
          </div>
        </div>

        <div className="order-2 flex items-center gap-2.5 lg:order-3">
          <button className="hidden h-11 items-center gap-2 rounded-xl border border-line bg-surface px-3.5 text-[12.5px] font-semibold text-ink-body shadow-soft sm:flex">
            <CalendarDays className="h-4 w-4 text-brand" />
            {today}
          </button>
          <button className="relative grid h-11 w-11 place-items-center rounded-xl border border-line bg-surface text-ink-body shadow-soft">
            <Bell className="h-[18px] w-[18px]" />
            <span className="absolute -right-1 -top-1 grid h-4 min-w-4 place-items-center rounded-full bg-[#ef4b6c] px-1 text-[9px] font-bold text-white">
              6
            </span>
          </button>
          <button
            onClick={() => setTheme(isDark ? "light" : "dark")}
            className="grid h-11 w-11 place-items-center rounded-xl border border-line bg-surface text-ink-body shadow-soft"
            aria-label="Toggle theme"
            suppressHydrationWarning
          >
            {isDark ? (
              <Sun className="h-[18px] w-[18px]" />
            ) : (
              <Moon className="h-[18px] w-[18px]" />
            )}
          </button>
          <motion.div
            whileHover={{ scale: 1.05 }}
            className="relative grid h-11 w-11 shrink-0 place-items-center overflow-hidden rounded-full bg-gradient-to-br from-[#004fda] to-[#37b6ff] text-[13px] font-bold text-white shadow-[0_8px_18px_-8px_rgba(0,79,218,0.9)]"
          >
            {avatarUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={avatarUrl} alt="" className="h-full w-full object-cover" />
            ) : (
              name.slice(0, 1).toUpperCase()
            )}
          </motion.div>
        </div>
      </div>
    </div>
  );
}
