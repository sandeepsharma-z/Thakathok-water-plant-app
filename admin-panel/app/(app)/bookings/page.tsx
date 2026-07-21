import Link from "next/link";

import { BookingCard } from "@/components/booking-card";
import { Card, EmptyState } from "@/components/ui";
import { createClient } from "@/lib/supabase/server";
import type { Booking, BookingStatus } from "@/lib/types";

export const dynamic = "force-dynamic";

const TABS: { key: string; label: string }[] = [
  { key: "pending", label: "Pending" },
  { key: "confirmed", label: "Confirmed" },
  { key: "cancelled", label: "Cancelled" },
  { key: "all", label: "All" },
];

export default async function BookingsPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string }>;
}) {
  const { status } = await searchParams;
  const active = TABS.some((t) => t.key === status) ? status! : "pending";

  const supabase = await createClient();
  let query = supabase.from("bookings").select("*");
  if (active !== "all") query = query.eq("status", active as BookingStatus);
  const { data, error } = await query.order("created_at", { ascending: false });

  const bookings = (data ?? []) as Booking[];

  return (
    <>
      <header>
        <h1 className="text-[26px] font-extrabold tracking-tight text-ink">
          Bookings
        </h1>
        <p className="mt-1 text-[13px] text-ink-muted">
          Every bulk order enquiry, newest first.
        </p>
      </header>

      {/* Filters — one row above the content */}
      <div className="mt-5 flex flex-wrap gap-2">
        {TABS.map((t) => {
          const on = t.key === active;
          return (
            <Link
              key={t.key}
              href={`/bookings?status=${t.key}`}
              aria-current={on ? "page" : undefined}
              className={`rounded-full px-4 py-2 text-[12.5px] font-semibold transition ${
                on
                  ? "bg-brand text-white shadow-[0_8px_18px_-10px_rgba(0,79,218,0.9)]"
                  : "border border-line bg-surface text-ink-body hover:bg-tint"
              }`}
            >
              {t.label}
            </Link>
          );
        })}
      </div>

      {error ? (
        <Card className="mt-5">
          <EmptyState
            icon={<span className="text-2xl">⚠</span>}
            title="Could not load bookings"
            body="Check the connection, and make sure the database tables have been created by running supabase/schema.sql."
          />
        </Card>
      ) : bookings.length === 0 ? (
        <Card className="mt-5">
          <EmptyState
            icon={<span className="text-2xl">☰</span>}
            title={`No ${active === "all" ? "" : active} bookings`}
            body="New enquiries from the app will appear here as soon as customers place them."
          />
        </Card>
      ) : (
        <div className="mt-5 grid gap-4">
          {bookings.map((b) => (
            <BookingCard key={b.id} booking={b} />
          ))}
        </div>
      )}
    </>
  );
}
