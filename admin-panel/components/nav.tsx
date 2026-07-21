"use client";

import Image from "next/image";
import Link from "next/link";
import { usePathname } from "next/navigation";

import { signOut } from "@/app/login/actions";

const LINKS = [
  { href: "/", label: "Dashboard", icon: "▦" },
  { href: "/bookings", label: "Bookings", icon: "☰" },
  { href: "/settings", label: "Rates & Charges", icon: "⚙" },
];

export function Nav({ email }: { email: string }) {
  const pathname = usePathname();

  return (
    <>
      {/* Sidebar — desktop */}
      <aside className="fixed inset-y-0 left-0 z-30 hidden w-[248px] flex-col border-r border-line bg-surface lg:flex">
        <div className="flex items-center gap-3 px-5 py-6">
          <Image src="/logo.png" alt="" width={40} height={40} />
          <div className="min-w-0">
            <p className="truncate text-[14px] font-extrabold leading-tight text-brand">
              Mahalakshmi
            </p>
            <p className="truncate text-[10.5px] font-medium tracking-wide text-ink-muted">
              WATER PLANT
            </p>
          </div>
        </div>

        <nav className="flex-1 px-3">
          {LINKS.map((l) => {
            const active =
              l.href === "/" ? pathname === "/" : pathname.startsWith(l.href);
            return (
              <Link
                key={l.href}
                href={l.href}
                aria-current={active ? "page" : undefined}
                className={`mb-1 flex items-center gap-3 rounded-xl px-3 py-2.5 text-[13.5px] font-semibold transition ${
                  active
                    ? "bg-brand text-white shadow-[0_8px_18px_-10px_rgba(0,79,218,0.9)]"
                    : "text-ink-body hover:bg-tint"
                }`}
              >
                <span aria-hidden className="text-[15px] opacity-90">
                  {l.icon}
                </span>
                {l.label}
              </Link>
            );
          })}
        </nav>

        <div className="border-t border-line p-3">
          <p className="truncate px-2 pb-2 text-[11px] text-ink-faint">
            {email}
          </p>
          <form action={signOut}>
            <button
              type="submit"
              className="w-full rounded-xl border border-line px-3 py-2 text-[12.5px] font-semibold text-ink-body transition hover:border-danger/30 hover:bg-danger-bg hover:text-danger"
            >
              Sign out
            </button>
          </form>
        </div>
      </aside>

      {/* Top bar — mobile */}
      <header className="sticky top-0 z-30 flex items-center gap-3 border-b border-line bg-surface/90 px-4 py-3 backdrop-blur lg:hidden">
        <Image src="/logo.png" alt="" width={32} height={32} />
        <p className="flex-1 text-[14px] font-extrabold text-brand">
          Mahalakshmi
        </p>
        <form action={signOut}>
          <button
            type="submit"
            className="rounded-lg border border-line px-2.5 py-1.5 text-[11.5px] font-semibold text-ink-body"
          >
            Sign out
          </button>
        </form>
      </header>

      {/* Bottom tabs — mobile */}
      <nav className="fixed inset-x-0 bottom-0 z-30 flex border-t border-line bg-surface/95 backdrop-blur lg:hidden">
        {LINKS.map((l) => {
          const active =
            l.href === "/" ? pathname === "/" : pathname.startsWith(l.href);
          return (
            <Link
              key={l.href}
              href={l.href}
              aria-current={active ? "page" : undefined}
              className={`flex flex-1 flex-col items-center gap-0.5 py-2.5 text-[10.5px] font-semibold ${
                active ? "text-brand" : "text-ink-muted"
              }`}
            >
              <span aria-hidden className="text-[15px]">
                {l.icon}
              </span>
              {l.label.split(" ")[0]}
            </Link>
          );
        })}
      </nav>
    </>
  );
}
