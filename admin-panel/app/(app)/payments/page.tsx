import { CalendarClock, CreditCard, Wallet } from "lucide-react";

import { Card, EmptyState, StatTile } from "@/components/ui";
import { createClient } from "@/lib/supabase/server";
import { formatDate, rupees, type Booking } from "@/lib/types";

export const dynamic = "force-dynamic";

// Advance collected on confirmed bookings (online instantly, cash on confirm).
export default async function PaymentsPage() {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("bookings")
    .select("*")
    .eq("status", "confirmed")
    .order("created_at", { ascending: false });
  const paid = (data ?? []) as Booking[];

  const totalAdvance = paid.reduce((s, b) => s + b.advance, 0);
  const onlineTotal = paid
    .filter((b) => b.payment_method === "online")
    .reduce((s, b) => s + b.advance, 0);
  const cashTotal = paid
    .filter((b) => b.payment_method === "cash")
    .reduce((s, b) => s + b.advance, 0);

  return (
    <>
      <header>
        <h1 className="text-[27px] font-extrabold tracking-tight text-ink">
          Payments &amp; Collections
        </h1>
        <p className="mt-1 text-[13px] text-ink-muted">
          The 30% advance collected on confirmed orders.
        </p>
      </header>

      <div className="mt-5 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <StatTile
          label="Advance collected"
          value={totalAdvance}
          icon="wallet"
          accent="ok"
          money
          index={0}
        />
        <StatTile
          label="Online (Razorpay)"
          value={onlineTotal}
          icon="rupee"
          accent="brand"
          money
          index={1}
        />
        <StatTile
          label="Cash"
          value={cashTotal}
          icon="rupee"
          accent="aqua"
          money
          index={2}
        />
      </div>

      {error || paid.length === 0 ? (
        <Card className="mt-5">
          <EmptyState
            icon="wallet"
            title="No collections yet"
            body="Advance payments from confirmed bookings will be listed here."
          />
        </Card>
      ) : (
        <div className="mt-5 grid gap-3">
          {paid.map((b) => {
            const online = b.payment_method === "online";
            return (
              <Card key={b.id} className="p-4">
                <div className="flex flex-wrap items-center justify-between gap-3">
                  <div className="min-w-0">
                    <p className="text-[15px] font-extrabold text-brand">
                      {b.booking_code}
                    </p>
                    <div className="mt-1 flex flex-wrap items-center gap-x-4 gap-y-1 text-[12px] text-ink-muted">
                      <span className="inline-flex items-center gap-1.5">
                        {online ? (
                          <CreditCard className="h-3.5 w-3.5" />
                        ) : (
                          <Wallet className="h-3.5 w-3.5" />
                        )}
                        {online ? "Online · Razorpay" : "Cash"}
                      </span>
                      <span className="inline-flex items-center gap-1.5">
                        <CalendarClock className="h-3.5 w-3.5" />
                        {formatDate(b.event_date)}
                      </span>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-[11px] text-ink-faint">Advance paid</p>
                    <p className="text-[18px] font-extrabold text-ok">
                      {rupees(b.advance)}
                    </p>
                  </div>
                </div>
              </Card>
            );
          })}
        </div>
      )}
    </>
  );
}
