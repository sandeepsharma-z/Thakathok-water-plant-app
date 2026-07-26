import { CalendarClock, MapPin, Phone } from "lucide-react";

import { Card, EmptyState, StatTile } from "@/components/ui";
import { createClient } from "@/lib/supabase/server";
import { formatDate, rupees, type Booking } from "@/lib/types";

export const dynamic = "force-dynamic";

// Confirmed bookings still owe the 70% balance (cash on delivery).
export default async function PendingDuesPage() {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("bookings")
    .select("*")
    .eq("status", "confirmed")
    .order("event_date", { ascending: true });
  const dues = ((data ?? []) as Booking[]).filter((b) => b.balance > 0);
  const totalDue = dues.reduce((s, b) => s + b.balance, 0);

  return (
    <>
      <header>
        <h1 className="text-[27px] font-extrabold tracking-tight text-ink">
          Pending Dues
        </h1>
        <p className="mt-1 text-[13px] text-ink-muted">
          The 70% balance still to be collected on confirmed orders.
        </p>
      </header>

      <div className="mt-5 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <StatTile
          label="Total pending dues"
          value={totalDue}
          icon="rupee"
          accent="warn"
          money
          index={0}
        />
        <StatTile
          label="Orders with balance"
          value={dues.length}
          icon="clipboard"
          accent="brand"
          index={1}
        />
      </div>

      {error || dues.length === 0 ? (
        <Card className="mt-5">
          <EmptyState
            icon="check"
            title="No pending dues"
            body="Balances from confirmed orders will show here until the cash on delivery is collected."
          />
        </Card>
      ) : (
        <div className="mt-5 grid gap-3">
          {dues.map((b) => (
            <Card key={b.id} className="p-4">
              <div className="flex flex-wrap items-center justify-between gap-3">
                <div className="min-w-0">
                  <p className="text-[15px] font-extrabold text-brand">
                    {b.booking_code}
                  </p>
                  <div className="mt-1 flex flex-wrap items-center gap-x-4 gap-y-1 text-[12px] text-ink-muted">
                    <span className="inline-flex items-center gap-1.5">
                      <CalendarClock className="h-3.5 w-3.5" />
                      {formatDate(b.event_date)}
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
                </div>
                <div className="text-right">
                  <p className="text-[11px] text-ink-faint">Balance due</p>
                  <p className="text-[18px] font-extrabold text-warn">
                    {rupees(b.balance)}
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
