import { CustomerRow } from "@/components/customer-row";
import { Card, EmptyState, StatTile } from "@/components/ui";
import { createClient } from "@/lib/supabase/server";
import { type Booking } from "@/lib/types";

export const dynamic = "force-dynamic";

interface CustomerTableRow {
  mobile: string;
  name: string;
  note: string;
  village: string;
  address: string;
  avatar_url: string | null;
  wallet_balance: number;
}

interface Agg {
  count: number;
  spent: number;
  villages: Set<string>;
  bookingName: string;
}

export default async function CustomersPage() {
  const supabase = await createClient();

  const [{ data: bookingData }, { data: custData, error }, { data: walletData }] = await Promise.all([
    supabase.from("bookings").select("*").order("created_at", { ascending: false }),
    supabase
      .from("customers")
      .select("mobile, name, note, village, address, avatar_url, wallet_balance"),
    supabase.from("wallet_transactions").select("*").order("created_at", { ascending: false }),
  ]);

  const bookings = (bookingData ?? []) as Booking[];
  const customers = (custData ?? []) as CustomerTableRow[];

  // Aggregate bookings by mobile.
  const agg = new Map<string, Agg>();
  for (const b of bookings) {
    const row =
      agg.get(b.mobile) ??
      ({ count: 0, spent: 0, villages: new Set<string>(), bookingName: b.customer_name ?? "" } satisfies Agg);
    row.count += 1;
    row.spent += b.grand_total;
    row.villages.add(b.village);
    agg.set(b.mobile, row);
  }

  // Registered profiles (from the customers table).
  const reg = new Map<string, CustomerTableRow>();
  for (const c of customers) reg.set(c.mobile, c);

  // Union of everyone — registered profiles AND anyone who has booked.
  const allMobiles = new Set<string>([...reg.keys(), ...agg.keys()]);
  const rows = [...allMobiles]
    .map((mobile) => {
      const a = agg.get(mobile);
      const c = reg.get(mobile);
      const villages = a
        ? [...a.villages]
        : c?.village
          ? [c.village]
          : [];
      return {
        mobile,
        name: (c?.name?.trim() || a?.bookingName || "").trim(),
        note: c?.note ?? "",
        count: a?.count ?? 0,
        spent: a?.spent ?? 0,
        villages,
        registered: !!c,
        address: c?.address ?? "",
        avatarUrl: c?.avatar_url ?? null,
        walletBalance: c?.wallet_balance ?? 0,
        walletTransactions: (walletData ?? []).filter((t) => t.mobile === mobile),
        bookings: bookings.filter((b) => b.mobile === mobile),
      };
    })
    .sort((x, y) => y.count - x.count);

  const lifetime = rows.reduce((s, r) => s + r.spent, 0);

  return (
    <>
      <header>
        <h1 className="text-[27px] font-extrabold tracking-tight text-ink">
          Customers
        </h1>
        <p className="mt-1 text-[13px] text-ink-muted">
          Registered profiles and everyone who has placed a bulk order.
        </p>
      </header>

      <div className="mt-5 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <StatTile label="Total customers" value={rows.length} icon="users" accent="brand" index={0} />
        <StatTile label="Total bookings" value={bookings.length} icon="clipboard" accent="aqua" index={1} />
        <StatTile label="Lifetime value" value={lifetime} icon="rupee" accent="ok" money index={2} />
      </div>

      {error || rows.length === 0 ? (
        <Card className="mt-5">
          <EmptyState
            icon="users"
            title="No customers yet"
            body="Customers appear here when they save their profile in the app or place a bulk order."
          />
        </Card>
      ) : (
        <div className="mt-5 grid gap-3">
          {rows.map((r) => (
            <CustomerRow
              key={r.mobile}
              mobile={r.mobile}
              name={r.name}
              note={r.note}
              count={r.count}
              spent={r.spent}
              villages={r.villages}
              registered={r.registered}
              address={r.address}
              avatarUrl={r.avatarUrl}
              walletBalance={r.walletBalance}
              walletTransactions={r.walletTransactions}
              bookings={r.bookings}
            />
          ))}
        </div>
      )}
    </>
  );
}
