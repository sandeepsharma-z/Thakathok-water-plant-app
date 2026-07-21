import Link from "next/link";

import { BookingCard } from "@/components/booking-card";
import { Card, EmptyState, StatTile } from "@/components/ui";
import { createClient } from "@/lib/supabase/server";
import { rupees, type Booking } from "@/lib/types";

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
        <PageHead
          title="Dashboard"
          subtitle="Today's bookings at a glance."
        />
        <Card className="mt-6">
          <EmptyState
            icon={<span className="text-2xl">⚠</span>}
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
  const advanceCollected = confirmed.reduce((sum, b) => sum + b.advance, 0);

  return (
    <>
      <PageHead title="Dashboard" subtitle="Today's bookings at a glance." />

      <section className="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatTile
          label="Awaiting confirmation"
          value={pending.length}
          hint="Cash advance not received yet"
          accent="warn"
          icon={<span className="text-lg">⏳</span>}
        />
        <StatTile
          label="Confirmed bookings"
          value={confirmed.length}
          hint="Dates are blocked"
          accent="ok"
          icon={<span className="text-lg">✓</span>}
        />
        <StatTile
          label="Upcoming events"
          value={upcoming.length}
          hint="Today or later"
          icon={<span className="text-lg">📅</span>}
        />
        <StatTile
          label="Advance collected"
          value={rupees(advanceCollected)}
          hint="From confirmed bookings"
          icon={<span className="text-lg">₹</span>}
        />
      </section>

      <section className="mt-9">
        <div className="flex items-end justify-between gap-4">
          <div>
            <h2 className="text-[17px] font-bold text-ink">Needs your action</h2>
            <p className="mt-0.5 text-[12.5px] text-ink-muted">
              Confirm a booking only after the cash advance is in hand.
            </p>
          </div>
          <Link
            href="/bookings"
            className="shrink-0 text-[12.5px] font-semibold text-brand hover:underline"
          >
            All bookings →
          </Link>
        </div>

        {pending.length === 0 ? (
          <Card className="mt-4">
            <EmptyState
              icon={<span className="text-2xl">✓</span>}
              title="Nothing pending"
              body="Every booking has been dealt with. New enquiries will show up here."
            />
          </Card>
        ) : (
          <div className="mt-4 grid gap-4">
            {pending.slice(0, 5).map((b) => (
              <BookingCard key={b.id} booking={b} />
            ))}
          </div>
        )}
      </section>
    </>
  );
}

function PageHead({ title, subtitle }: { title: string; subtitle: string }) {
  return (
    <header>
      <h1 className="text-[26px] font-extrabold tracking-tight text-ink">
        {title}
      </h1>
      <p className="mt-1 text-[13px] text-ink-muted">{subtitle}</p>
    </header>
  );
}
