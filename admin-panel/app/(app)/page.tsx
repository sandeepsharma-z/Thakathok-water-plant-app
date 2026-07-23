import { ArrowRight } from "lucide-react";
import Link from "next/link";

import { BookingCard } from "@/components/booking-card";
import { DashboardCharts } from "@/components/dashboard-charts";
import { Card, EmptyState, StatTile } from "@/components/ui";
import { createClient } from "@/lib/supabase/server";
import type { Booking } from "@/lib/types";

export const dynamic = "force-dynamic";

export default async function DashboardPage() {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("bookings")
    .select("*")
    .order("created_at", { ascending: false });

  if (error) {
    return (
      <>
        <Head />
        <Card className="mt-6">
          <EmptyState
            icon="clock"
            title="Could not load bookings"
            body="Check the connection, and make sure the database tables have been created by running supabase/schema.sql."
          />
        </Card>
      </>
    );
  }

  const bookings = (data ?? []) as Booking[];
  const pending = bookings.filter((b) => b.status === "pending");
  const confirmed = bookings.filter((b) => b.status === "confirmed");
  const today = new Date().toISOString().slice(0, 10);
  const upcoming = confirmed.filter((b) => b.event_date >= today);
  const advance = confirmed.reduce((s, b) => s + b.advance, 0);

  return (
    <>
      <Head />

      <section className="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatTile
          label="Awaiting confirmation"
          value={pending.length}
          hint="Cash advance not received yet"
          accent="warn"
          icon="clock"
          index={0}
        />
        <StatTile
          label="Confirmed bookings"
          value={confirmed.length}
          hint="Dates are blocked"
          accent="ok"
          icon="check"
          index={1}
        />
        <StatTile
          label="Upcoming events"
          value={upcoming.length}
          hint="Today or later"
          accent="aqua"
          icon="calendar"
          index={2}
        />
        <StatTile
          label="Advance collected"
          value={advance}
          hint="From confirmed bookings"
          accent="brand"
          icon="rupee"
          money
          index={3}
        />
      </section>

      <section className="mt-6">
        <DashboardCharts bookings={bookings} />
      </section>

      <section className="mt-8">
        <div className="flex items-end justify-between gap-4">
          <div>
            <h2 className="text-[18px] font-bold text-ink">Needs your action</h2>
            <p className="mt-0.5 text-[12.5px] text-ink-muted">
              Confirm a booking only after the cash advance is in hand.
            </p>
          </div>
          <Link
            href="/bookings"
            className="inline-flex shrink-0 items-center gap-1 rounded-full bg-tint px-3.5 py-2 text-[12.5px] font-semibold text-brand transition hover:bg-tint-strong"
          >
            All bookings <ArrowRight className="h-3.5 w-3.5" />
          </Link>
        </div>

        {pending.length === 0 ? (
          <Card className="mt-4">
            <EmptyState
              icon="check"
              title="All caught up"
              body="Every booking has been dealt with. New enquiries will show up here."
            />
          </Card>
        ) : (
          <div className="mt-4 grid gap-4">
            {pending.slice(0, 5).map((b, i) => (
              <BookingCard key={b.id} booking={b} index={i} />
            ))}
          </div>
        )}
      </section>
    </>
  );
}

function Head() {
  return (
    <header>
      <h1 className="text-[27px] font-extrabold tracking-tight text-ink">
        Dashboard
      </h1>
    </header>
  );
}
