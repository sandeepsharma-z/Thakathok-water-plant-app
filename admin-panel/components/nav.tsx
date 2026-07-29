"use client";

import {
  Activity,
  Bell,
  CalendarDays,
  BookOpenCheck,
  Palette,
  Languages,
  ChevronRight,
  Droplet,
  FileBarChart,
  GitBranch,
  HeadphonesIcon,
  LayoutDashboard,
  PanelsTopLeft,
  LifeBuoy,
  MapPin,
  MoreVertical,
  Package,
  Settings,
  ShoppingCart,
  Truck,
  Users,
  UserRoundCog,
  Wallet,
  type LucideIcon,
} from "lucide-react";
import Image from "next/image";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useRouter } from "next/navigation";

import { markNavSectionSeen } from "@/app/(app)/nav-actions";
import { signOut } from "@/app/login/actions";

type Item = {
  label: string;
  href: string;
  Icon: LucideIcon;
  chevron?: boolean;
  soon?: boolean;
  seenSection?: "orders" | "customers";
};

const ITEMS: Item[] = [
  { label: "Dashboard", href: "/", Icon: LayoutDashboard, chevron: true },
  { label: "Home Screen", href: "/home-content", Icon: PanelsTopLeft },
  { label: "Booking Configuration", href: "/booking-config", Icon: BookOpenCheck },
  { label: "App Branding", href: "/app-branding", Icon: Palette },
  { label: "App Labels", href: "/app-labels", Icon: Languages },
  { label: "Products", href: "/products", Icon: Package },
  {
    label: "Orders",
    href: "/bookings",
    Icon: ShoppingCart,
    seenSection: "orders",
  },
  {
    label: "Customers",
    href: "/customers",
    Icon: Users,
    seenSection: "customers",
  },
  { label: "Delivery Management", href: "/delivery", Icon: Truck },
  { label: "Delivery Staff", href: "/delivery-staff", Icon: UserRoundCog },
  { label: "Blocked Dates", href: "/calendar", Icon: CalendarDays },
  { label: "Village Management", href: "/villages", Icon: MapPin },
  { label: "Cans Management", href: "/cans", Icon: Package },
  { label: "Pending Dues", href: "/pending-dues", Icon: Droplet },
  { label: "Payments & Collections", href: "/payments", Icon: Wallet },
  { label: "Expenses", href: "/expenses", Icon: FileBarChart },
  { label: "Reports & Analytics", href: "/reports", Icon: Activity },
  { label: "Branch Management", href: "/branches", Icon: GitBranch },
  { label: "Notification Center", href: "/sms", Icon: Bell },
  { label: "Settings", href: "/settings", Icon: Settings },
  { label: "Activity Logs", href: "/activity", Icon: LifeBuoy },
  { label: "Support", href: "/support", Icon: HeadphonesIcon },
];

export function Sidebar({
  name,
  avatarUrl,
  villages = 0,
  counts = {},
}: {
  name: string;
  avatarUrl?: string | null;
  villages?: number;
  counts?: Record<string, number>;
}) {
  const pathname = usePathname();
  const router = useRouter();
  const isActive = (href: string) =>
    href === "/" ? pathname === "/" : pathname.startsWith(href);

  return (
    <aside className="fixed inset-y-0 left-0 z-30 hidden w-[250px] flex-col overflow-hidden bg-[linear-gradient(180deg,#1668e6_0%,#0f57cc_55%,#0b49ad_100%)] lg:flex dark:bg-[linear-gradient(180deg,#12213e_0%,#0d1a30_55%,#0a1424_100%)] dark:ring-1 dark:ring-white/5">
      {/* logo */}
      <div className="flex items-center gap-2.5 px-5 py-5">
        <div className="grid h-11 w-11 place-items-center rounded-xl bg-white shadow-md ring-1 ring-white/40">
          <Image src="/logo.png" alt="" width={30} height={30} />
        </div>
        <div>
          <p className="text-[16px] font-extrabold leading-tight text-white">
            ThakaThok
          </p>
          <p className="text-[8.5px] font-semibold tracking-[0.22em] text-white/70">
            WATER DELIVERY
          </p>
        </div>
      </div>

      {/* nav */}
      <nav className="flex-1 overflow-y-auto px-3 pb-2">
        {ITEMS.map((it) => {
          const active = isActive(it.href);
          const count = counts[it.href] ?? 0;
          const cls = `mb-1 flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left text-[13px] font-semibold transition ${
            active
              ? "bg-[linear-gradient(90deg,#4b8ef8,#5f9dff)] text-white shadow-[0_10px_20px_-10px_rgba(0,0,0,0.5)]"
              : "text-white/80 hover:bg-white/10 hover:text-white"
          }`;
          const inner = (
            <>
              <it.Icon className="h-[18px] w-[18px]" strokeWidth={active ? 2.4 : 2} />
              <span className="flex-1">{it.label}</span>
              {count > 0 ? (
                <span
                  className={`grid min-w-6 place-items-center rounded-full px-1.5 py-0.5 text-[9.5px] font-extrabold tabular-nums ${
                    active
                      ? "bg-white text-brand shadow-sm"
                      : "bg-white/18 text-white ring-1 ring-white/15"
                  }`}
                  title={`${count} ${it.label.toLowerCase()}`}
                >
                  {count > 99 ? "99+" : count}
                </span>
              ) : it.soon ? (
                <span className="rounded-full bg-white/15 px-1.5 py-0.5 text-[8.5px] font-bold tracking-wide text-white/80">
                  SOON
                </span>
              ) : it.chevron ? (
                <ChevronRight className="h-4 w-4 opacity-70" />
              ) : null}
            </>
          );
          return (
            <Link
              key={it.label}
              href={it.href}
              className={cls}
              onClick={
                it.seenSection
                  ? async (event) => {
                      event.preventDefault();
                      await markNavSectionSeen(it.seenSection!);
                      router.push(it.href);
                      router.refresh();
                    }
                  : undefined
              }
            >
              {inner}
            </Link>
          );
        })}
      </nav>

      {/* water splash — sits BEHIND the bottom cards (screen blend drops black) */}
      <div
        aria-hidden
        className="pointer-events-none absolute inset-x-0 bottom-0 z-0 h-32"
        style={{
          backgroundImage: "url(/water-splash.png)",
          backgroundSize: "cover",
          backgroundPosition: "center bottom",
          mixBlendMode: "screen",
          opacity: 0.55,
        }}
      />

      {/* bottom cards — frosted blue panels so text stays readable over the splash */}
      <div className="relative z-10 mt-2 space-y-3 px-3 pb-3">
        <div className="flex items-center justify-between rounded-2xl bg-[#0e54c8]/80 px-4 py-3 shadow-lg ring-1 ring-white/20 backdrop-blur-md dark:bg-white/8 dark:ring-white/10">
          <div>
            <p className="text-[10.5px] text-white/75">Villages Served</p>
            <p className="text-[20px] font-extrabold leading-none text-white">
              {villages.toString().padStart(2, "0")}
            </p>
          </div>
          <MapPin className="h-7 w-7 text-white/90" />
        </div>

        <div className="flex items-center gap-2.5 rounded-2xl bg-[#0e54c8]/80 px-3 py-2.5 shadow-lg ring-1 ring-white/15 backdrop-blur-md dark:bg-white/8 dark:ring-white/10">
          <Link
            href="/profile"
            className="grid h-10 w-10 shrink-0 place-items-center overflow-hidden rounded-full bg-white/25 text-[13px] font-bold text-white ring-1 ring-white/30"
          >
            {avatarUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={avatarUrl} alt="" className="h-full w-full object-cover" />
            ) : (
              name.slice(0, 1).toUpperCase()
            )}
          </Link>
          <Link href="/profile" className="min-w-0 flex-1">
            <p className="truncate text-[12.5px] font-bold text-white">{name}</p>
            <p className="text-[10.5px] text-white/75">Super Admin</p>
          </Link>
          <form action={signOut}>
            <button
              type="submit"
              title="Sign out"
              className="grid h-8 w-8 place-items-center rounded-lg text-white/80 hover:bg-white/15 hover:text-white"
            >
              <MoreVertical className="h-4 w-4" />
            </button>
          </form>
        </div>
      </div>
    </aside>
  );
}

/* Minimal mobile top bar (the rich dashboard is desktop-first). */
export function MobileBar({ name }: { name: string }) {
  return (
    <header className="sticky top-0 z-30 flex items-center gap-3 border-b border-line bg-surface/90 px-4 py-3 backdrop-blur lg:hidden">
      <div className="grid h-9 w-9 place-items-center rounded-xl bg-gradient-to-br from-[#eaf3ff] to-white ring-1 ring-line">
        <Image src="/logo.png" alt="" width={24} height={24} />
      </div>
      <p className="flex-1 text-[15px] font-extrabold text-gradient">ThakaThok</p>
      <form action={signOut}>
        <button
          type="submit"
          className="rounded-lg border border-line px-2.5 py-1.5 text-[11.5px] font-semibold text-ink-body"
        >
          Sign out
        </button>
      </form>
    </header>
  );
}
