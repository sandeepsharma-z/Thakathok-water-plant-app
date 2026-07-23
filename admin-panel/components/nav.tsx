"use client";

import { motion } from "framer-motion";
import {
  LayoutDashboard,
  ClipboardList,
  SlidersHorizontal,
  LogOut,
  type LucideIcon,
} from "lucide-react";
import Image from "next/image";
import Link from "next/link";
import { usePathname } from "next/navigation";

import { signOut } from "@/app/login/actions";

const LINKS: { href: string; label: string; short: string; Icon: LucideIcon }[] =
  [
    { href: "/", label: "Dashboard", short: "Home", Icon: LayoutDashboard },
    {
      href: "/bookings",
      label: "Bookings",
      short: "Bookings",
      Icon: ClipboardList,
    },
    {
      href: "/settings",
      label: "Rates & Charges",
      short: "Rates",
      Icon: SlidersHorizontal,
    },
  ];

export function Nav({ email }: { email: string }) {
  const pathname = usePathname();
  const isActive = (href: string) =>
    href === "/" ? pathname === "/" : pathname.startsWith(href);

  return (
    <>
      {/* Sidebar — desktop */}
      <aside className="fixed inset-y-0 left-0 z-30 hidden w-[256px] flex-col border-r border-line bg-surface/80 backdrop-blur-xl lg:flex">
        {/* brand */}
        <div className="flex items-center gap-3 px-5 py-6">
          <div className="relative">
            <div className="absolute inset-0 rounded-2xl bg-brand/25 blur-md" />
            <div className="relative grid h-11 w-11 place-items-center rounded-2xl bg-gradient-to-br from-[#eaf3ff] to-white ring-1 ring-line">
              <Image src="/logo.png" alt="" width={30} height={30} />
            </div>
          </div>
          <div className="min-w-0">
            <p className="truncate text-[15px] font-extrabold leading-tight text-gradient">
              Mahalakshmi
            </p>
            <p className="truncate text-[10px] font-semibold tracking-[0.18em] text-ink-muted">
              WATER PLANT
            </p>
          </div>
        </div>

        <nav className="flex-1 px-3">
          {LINKS.map((l, i) => {
            const active = isActive(l.href);
            return (
              <Link key={l.href} href={l.href} className="relative block">
                {active && (
                  <motion.span
                    layoutId="nav-active"
                    className="absolute inset-0 rounded-2xl bg-gradient-to-r from-[#004fda] to-[#2e7bf0] shadow-[0_10px_22px_-10px_rgba(0,79,218,0.9)]"
                    transition={{ type: "spring", stiffness: 420, damping: 34 }}
                  />
                )}
                <span
                  className={`relative z-10 mb-1 flex items-center gap-3 rounded-2xl px-3.5 py-3 text-[13.5px] font-semibold transition-colors ${
                    active ? "text-white" : "text-ink-body hover:bg-tint"
                  }`}
                >
                  <l.Icon
                    className="h-[18px] w-[18px]"
                    strokeWidth={active ? 2.5 : 2}
                  />
                  {l.label}
                </span>
              </Link>
            );
          })}
        </nav>

        <div className="border-t border-line p-3">
          <div className="mb-2 flex items-center gap-2.5 rounded-2xl bg-tint/60 px-3 py-2.5">
            <div className="grid h-8 w-8 place-items-center rounded-full bg-gradient-to-br from-[#004fda] to-[#37b6ff] text-[12px] font-bold text-white">
              {email.slice(0, 1).toUpperCase()}
            </div>
            <div className="min-w-0">
              <p className="truncate text-[11.5px] font-semibold text-ink">
                Admin
              </p>
              <p className="truncate text-[10px] text-ink-faint">{email}</p>
            </div>
          </div>
          <form action={signOut}>
            <button
              type="submit"
              className="flex w-full items-center justify-center gap-2 rounded-2xl border border-line px-3 py-2.5 text-[12.5px] font-semibold text-ink-body transition hover:border-danger/30 hover:bg-danger-bg hover:text-danger"
            >
              <LogOut className="h-4 w-4" />
              Sign out
            </button>
          </form>
        </div>
      </aside>

      {/* Top bar — mobile */}
      <header className="sticky top-0 z-30 flex items-center gap-3 border-b border-line bg-surface/80 px-4 py-3 backdrop-blur-xl lg:hidden">
        <div className="grid h-9 w-9 place-items-center rounded-xl bg-gradient-to-br from-[#eaf3ff] to-white ring-1 ring-line">
          <Image src="/logo.png" alt="" width={24} height={24} />
        </div>
        <p className="flex-1 text-[15px] font-extrabold text-gradient">
          Mahalakshmi
        </p>
        <form action={signOut}>
          <button
            type="submit"
            className="grid h-9 w-9 place-items-center rounded-xl border border-line text-ink-body"
          >
            <LogOut className="h-4 w-4" />
          </button>
        </form>
      </header>

      {/* Bottom tabs — mobile */}
      <nav className="fixed inset-x-0 bottom-0 z-30 flex border-t border-line bg-surface/85 backdrop-blur-xl lg:hidden">
        {LINKS.map((l) => {
          const active = isActive(l.href);
          return (
            <Link
              key={l.href}
              href={l.href}
              className={`flex flex-1 flex-col items-center gap-1 py-2.5 text-[10.5px] font-semibold ${
                active ? "text-brand" : "text-ink-muted"
              }`}
            >
              <l.Icon className="h-5 w-5" strokeWidth={active ? 2.5 : 2} />
              {l.short}
            </Link>
          );
        })}
      </nav>
    </>
  );
}
