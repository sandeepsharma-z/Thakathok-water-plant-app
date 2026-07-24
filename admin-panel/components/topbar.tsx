"use client";

import { motion } from "framer-motion";
import { Bell, CalendarDays, Check, Moon, Search, Sun } from "lucide-react";
import { useTheme } from "next-themes";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useRef, useState } from "react";

const rupee = (n: number) => `₹${n.toLocaleString("en-IN")}`;

type PendingItem = {
  code: string;
  village: string;
  cans: number;
  advance: number;
  time: string;
};

export function Topbar({
  title,
  name,
  subtitle,
  avatarUrl,
  notifications = 0,
  pendingItems = [],
}: {
  title: string;
  name: string;
  subtitle?: string;
  avatarUrl?: string | null;
  notifications?: number;
  pendingItems?: PendingItem[];
}) {
  const router = useRouter();
  const { resolvedTheme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [query, setQuery] = useState("");
  const [bellOpen, setBellOpen] = useState(false);
  const bellRef = useRef<HTMLDivElement>(null);

  useEffect(() => setMounted(true), []);
  const isDark = mounted && resolvedTheme === "dark";

  // close the bell dropdown on outside click
  useEffect(() => {
    function onDoc(e: MouseEvent) {
      if (bellRef.current && !bellRef.current.contains(e.target as Node)) {
        setBellOpen(false);
      }
    }
    document.addEventListener("mousedown", onDoc);
    return () => document.removeEventListener("mousedown", onDoc);
  }, []);

  const today = new Date().toLocaleDateString("en-IN", {
    day: "numeric",
    month: "short",
    year: "numeric",
  });

  function submitSearch(e: React.FormEvent) {
    e.preventDefault();
    const q = query.trim();
    router.push(q ? `/bookings?q=${encodeURIComponent(q)}` : "/bookings");
  }

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

        {/* search */}
        <form
          onSubmit={submitSearch}
          className="order-3 w-full lg:order-2 lg:w-[320px]"
        >
          <div className="flex h-11 items-center gap-2 rounded-xl border border-line bg-surface px-3.5 shadow-soft focus-within:border-brand focus-within:ring-4 focus-within:ring-brand/10">
            <button type="submit" aria-label="Search" className="text-ink-faint hover:text-brand">
              <Search className="h-4 w-4" />
            </button>
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search bookings (code, village, mobile)…"
              className="h-full w-full bg-transparent text-[13px] text-ink outline-none placeholder:text-ink-faint"
            />
          </div>
        </form>

        <div className="order-2 flex items-center gap-2.5 lg:order-3">
          <button className="hidden h-11 items-center gap-2 rounded-xl border border-line bg-surface px-3.5 text-[12.5px] font-semibold text-ink-body shadow-soft sm:flex">
            <CalendarDays className="h-4 w-4 text-brand" />
            {today}
          </button>

          {/* notifications */}
          <div ref={bellRef} className="relative">
            <button
              onClick={() => setBellOpen((o) => !o)}
              className="relative grid h-11 w-11 place-items-center rounded-xl border border-line bg-surface text-ink-body shadow-soft"
              aria-label="Notifications"
            >
              <Bell className="h-[18px] w-[18px]" />
              {notifications > 0 ? (
                <span className="absolute -right-1 -top-1 grid h-4 min-w-4 place-items-center rounded-full bg-[#ef4b6c] px-1 text-[9px] font-bold text-white">
                  {notifications > 9 ? "9+" : notifications}
                </span>
              ) : null}
            </button>

            {bellOpen ? (
              <motion.div
                initial={{ opacity: 0, y: 8, scale: 0.98 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                transition={{ duration: 0.15 }}
                className="absolute right-0 top-13 z-50 mt-2 w-[320px] overflow-hidden rounded-2xl border border-line bg-surface shadow-float"
              >
                <div className="flex items-center justify-between border-b border-line px-4 py-3">
                  <p className="text-[13.5px] font-bold text-ink">Notifications</p>
                  <span className="rounded-full bg-warn-bg px-2 py-0.5 text-[10.5px] font-bold text-warn">
                    {notifications} pending
                  </span>
                </div>
                {pendingItems.length === 0 ? (
                  <div className="px-4 py-8 text-center text-[12.5px] text-ink-faint">
                    You&apos;re all caught up 🎉
                  </div>
                ) : (
                  <ul className="max-h-[300px] overflow-y-auto">
                    {pendingItems.map((p) => (
                      <li key={p.code}>
                        <Link
                          href="/bookings?status=pending"
                          onClick={() => setBellOpen(false)}
                          className="flex items-start gap-3 px-4 py-3 transition hover:bg-tint"
                        >
                          <span className="mt-0.5 grid h-8 w-8 shrink-0 place-items-center rounded-full bg-warn-bg text-warn">
                            <Check className="h-4 w-4" />
                          </span>
                          <div className="min-w-0 flex-1">
                            <p className="text-[12.5px] font-semibold text-ink">
                              {p.code} needs confirmation
                            </p>
                            <p className="text-[11px] text-ink-muted">
                              {p.village} · {p.cans} cans · advance {rupee(p.advance)}
                            </p>
                          </div>
                          <span className="shrink-0 text-[10.5px] text-ink-faint">
                            {p.time}
                          </span>
                        </Link>
                      </li>
                    ))}
                  </ul>
                )}
                <Link
                  href="/bookings?status=pending"
                  onClick={() => setBellOpen(false)}
                  className="block border-t border-line py-2.5 text-center text-[12.5px] font-semibold text-brand hover:bg-tint"
                >
                  View all pending
                </Link>
              </motion.div>
            ) : null}
          </div>

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

          <Link href="/profile">
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
          </Link>
        </div>
      </div>
    </div>
  );
}
