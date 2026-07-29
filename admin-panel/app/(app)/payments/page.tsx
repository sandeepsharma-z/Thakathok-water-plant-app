import { CalendarClock, CreditCard, ReceiptIndianRupee } from "lucide-react";

import { Card, EmptyState, StatTile } from "@/components/ui";
import { createClient } from "@/lib/supabase/server";
import { rupees } from "@/lib/types";

export const dynamic = "force-dynamic";

type Collection = {
  id: string;
  booking_id: string;
  collection_type: "advance" | "balance";
  amount: number;
  method: string;
  reference: string;
  note: string;
  collected_at: string;
  bookings:
    | {
        booking_code: string;
        customer_name: string;
        mobile: string;
        status: string;
      }
    | {
        booking_code: string;
        customer_name: string;
        mobile: string;
        status: string;
      }[]
    | null;
};

export default async function PaymentsPage() {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("booking_collections")
    .select(
      "id,booking_id,collection_type,amount,method,reference,note,collected_at,bookings(booking_code,customer_name,mobile,status)",
    )
    .order("collected_at", { ascending: false });
  const collections = (data ?? []) as Collection[];
  const total = collections.reduce((sum, row) => sum + Number(row.amount), 0);
  const advances = collections
    .filter((row) => row.collection_type === "advance")
    .reduce((sum, row) => sum + Number(row.amount), 0);
  const balances = collections
    .filter((row) => row.collection_type === "balance")
    .reduce((sum, row) => sum + Number(row.amount), 0);
  const cash = collections
    .filter((row) => row.method === "cash")
    .reduce((sum, row) => sum + Number(row.amount), 0);

  return (
    <>
      <header>
        <h1 className="text-[27px] font-extrabold tracking-tight text-ink">
          Payments &amp; Collections
        </h1>
        <p className="mt-1 text-[13px] text-ink-muted">
          Immutable history of booking advances and collected balances.
        </p>
      </header>

      <div className="mt-5 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatTile
          label="Total collected"
          value={total}
          icon="rupee"
          accent="ok"
          money
        />
        <StatTile
          label="Booking advances"
          value={advances}
          icon="wallet"
          accent="brand"
          money
        />
        <StatTile
          label="Balances collected"
          value={balances}
          icon="check"
          accent="aqua"
          money
        />
        <StatTile
          label="Cash collected"
          value={cash}
          icon="rupee"
          accent="warn"
          money
        />
      </div>

      {error || collections.length === 0 ? (
        <Card className="mt-5">
          <EmptyState
            icon="wallet"
            title="No collections yet"
            body="Booking advance and balance payments will appear here."
          />
        </Card>
      ) : (
        <Card className="mt-5 overflow-hidden">
          <div className="divide-y divide-line">
            {collections.map((collection) => {
              const booking = Array.isArray(collection.bookings)
                ? collection.bookings[0]
                : collection.bookings;
              return (
                <div
                  key={collection.id}
                  className="flex flex-wrap items-center justify-between gap-4 p-4"
                >
                  <div className="flex min-w-0 items-start gap-3">
                    <div className="grid h-10 w-10 shrink-0 place-items-center rounded-2xl bg-tint text-brand">
                      {collection.method === "online" ? (
                        <CreditCard className="h-5 w-5" />
                      ) : (
                        <ReceiptIndianRupee className="h-5 w-5" />
                      )}
                    </div>
                    <div>
                      <p className="font-extrabold text-brand">
                        {booking?.booking_code}
                      </p>
                      <p className="text-[12px] font-semibold text-ink">
                        {booking?.customer_name} · +91 {booking?.mobile}
                      </p>
                      <p className="mt-0.5 flex flex-wrap items-center gap-1.5 text-[10.5px] text-ink-muted">
                        <CalendarClock className="h-3 w-3" />
                        {new Date(collection.collected_at).toLocaleString(
                          "en-IN",
                        )}
                        {" · "}
                        <span className="capitalize">
                          {collection.collection_type} · {collection.method}
                        </span>
                        {collection.reference
                          ? ` · Ref: ${collection.reference}`
                          : ""}
                      </p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-[10.5px] capitalize text-ink-faint">
                      {collection.collection_type} collected
                    </p>
                    <p className="text-[18px] font-extrabold text-ok">
                      {rupees(collection.amount)}
                    </p>
                  </div>
                </div>
              );
            })}
          </div>
        </Card>
      )}
    </>
  );
}
