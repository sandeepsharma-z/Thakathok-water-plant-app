import { CalendarClock, MapPin, Phone } from "lucide-react";

import { Card, EmptyState, StatTile } from "@/components/ui";
import { createClient } from "@/lib/supabase/server";
import { formatDate, type Booking } from "@/lib/types";

export const dynamic = "force-dynamic";

export default async function DeliveryManagementPage() {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("bookings")
    .select("*")
    .eq("status", "confirmed")
    .order("event_date", { ascending: true });
  const bookings = (data ?? []) as Booking[];

  const today = new Date().toISOString().slice(0, 10);
  const upcoming = bookings.filter((b) => b.event_date >= today);
  const totalCans = bookings.reduce((s, b) => s + b.cans, 0);

  return (
    <>
      <header>
        <h1 className="text-[27px] font-extrabold tracking-tight text-ink">
          Delivery Management
        </h1>
        <p className="mt-1 text-[13px] text-ink-muted">
          Confirmed orders to fulfil, by event date.
        </p>
      </header>

      <div className="mt-5 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <StatTile
          label="Upcoming deliveries"
          value={upcoming.length}
          icon="truck"
          accent="brand"
          index={0}
        />
        <StatTile
          label="Confirmed orders"
          value={bookings.length}
          icon="check"
          accent="ok"
          index={1}
        />
        <StatTile
          label="Cans to deliver"
          value={totalCans}
          icon="package"
          accent="aqua"
          index={2}
        />
      </div>

      {error || bookings.length === 0 ? (
        <Card className="mt-5">
          <EmptyState
            icon="truck"
            title="No deliveries scheduled"
            body="Once you confirm a booking, it appears here as a delivery to fulfil."
          />
        </Card>
      ) : (
        <div className="mt-5 grid gap-3">
          {bookings.map((b) => (
            <Card key={b.id} className="p-4">
              <div className="flex flex-wrap items-center justify-between gap-3">
                <div className="min-w-0">
                  <p className="text-[15px] font-extrabold text-brand">
                    {b.booking_code}
                  </p>
                  <div className="mt-1 flex flex-wrap items-center gap-x-4 gap-y-1 text-[12px] text-ink-muted">
                    <span className="inline-flex items-center gap-1.5">
                      <CalendarClock className="h-3.5 w-3.5" />
                      {formatDate(b.event_date)} · {b.event_time}
                    </span>
                    <span className="inline-flex items-center gap-1.5">
                      <MapPin className="h-3.5 w-3.5" />
                      {b.village}
                    </span>
                    <span className="inline-flex items-center gap-1.5">
                      <Phone className="h-3.5 w-3.5" />
                      +91 {b.mobile}
                    </span>
                  </div>
                  <p className="mt-1 text-[12px] text-ink-faint">
                    {b.address}
                  </p>
                </div>
                <div className="rounded-2xl bg-tint px-4 py-2 text-center">
                  <p className="text-[11px] text-ink-muted">Cans</p>
                  <p className="text-[18px] font-extrabold text-ink">
                    {b.cans}
                  </p>
                </div>
              </div>
            </Card>
          ))}
        </div>
      )}
    </>
  );
}
