import { Card, EmptyState, StatTile } from "@/components/ui";
import { PageHead, inputClass } from "@/components/management-ui";
import { ReportExportButtons } from "@/components/report-export-buttons";
import { createClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

function monthValue(value?: string) {
  return /^\d{4}-\d{2}$/.test(value ?? "")
    ? value!
    : new Date().toISOString().slice(0, 7);
}

export default async function ReportsPage({
  searchParams,
}: {
  searchParams: Promise<{ month?: string }>;
}) {
  const { month: rawMonth } = await searchParams;
  const month = monthValue(rawMonth);
  const [year, monthIndex] = month.split("-").map(Number);
  const nextDate = new Date(Date.UTC(year, monthIndex, 1));
  const nextMonth = nextDate.toISOString().slice(0, 7);
  const start = `${month}-01T00:00:00.000Z`;
  const end = `${nextMonth}-01T00:00:00.000Z`;
  const db = await createClient();
  const [{ data: bookings }, { data: expenses }, { data: inventory }] =
    await Promise.all([
      db.from("bookings").select("booking_code,customer_name,mobile,village,status,grand_total,advance,balance,cans,created_at").gte("created_at", start).lt("created_at", end).order("created_at"),
      db.from("expenses").select("amount,category,description,expense_date").gte("expense_date", `${month}-01`).lt("expense_date", `${nextMonth}-01`).order("expense_date"),
      db.from("can_inventory").select("total_cans,available_cans,out_for_delivery,damaged_cans"),
    ]);
  const bs = bookings ?? [];
  const es = expenses ?? [];
  const active = bs.filter((booking) => booking.status !== "cancelled");
  const revenue = active.reduce((sum, booking) => sum + Number(booking.grand_total), 0);
  const collected = active.reduce((sum, booking) => sum + Number(booking.advance), 0);
  const dues = active.reduce((sum, booking) => sum + Number(booking.balance), 0);
  const cans = active.reduce((sum, booking) => sum + Number(booking.cans), 0);
  const expense = es.reduce((sum, item) => sum + Number(item.amount), 0);
  const stock = {
    total: inventory?.reduce((sum, item) => sum + item.total_cans, 0) ?? 0,
    available: inventory?.reduce((sum, item) => sum + item.available_cans, 0) ?? 0,
    out: inventory?.reduce((sum, item) => sum + item.out_for_delivery, 0) ?? 0,
    damaged: inventory?.reduce((sum, item) => sum + item.damaged_cans, 0) ?? 0,
  };
  const label = new Date(year, monthIndex - 1, 1).toLocaleDateString("en-IN", { month: "long", year: "numeric" });
  const villageMap = new Map<string, { orders: number; revenue: number; cans: number }>();
  for (const booking of active) {
    const value = villageMap.get(booking.village) ?? { orders: 0, revenue: 0, cans: 0 };
    value.orders += 1; value.revenue += Number(booking.grand_total); value.cans += Number(booking.cans);
    villageMap.set(booking.village, value);
  }
  const categoryMap = new Map<string, number>();
  for (const item of es) categoryMap.set(item.category, (categoryMap.get(item.category) ?? 0) + Number(item.amount));
  const summary = { bookings: active.length, cans, revenue, collected, dues, expenses: expense, margin: revenue - expense };

  return (
    <>
      <PageHead title="Reports & Analytics" body="Month-wise business totals with downloadable PDF and Excel reports." />
      <Card className="mt-5 flex flex-wrap items-end justify-between gap-4 p-5">
        <form className="flex flex-wrap items-end gap-3">
          <label className="text-[12px] font-bold text-ink">Report month<input type="month" name="month" defaultValue={month} className={`mt-2 block ${inputClass}`} /></label>
          <button className="h-11 rounded-xl bg-brand px-5 text-[12px] font-extrabold text-white">View Report</button>
        </form>
        <ReportExportButtons month={month} label={label} summary={summary} bookings={bs} expenses={es} inventory={stock} />
      </Card>
      <h2 className="mt-6 text-[18px] font-extrabold text-ink">{label}</h2>
      <div className="mt-4 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatTile label="Bookings" value={active.length} icon="clipboard" />
        <StatTile label="Cans booked" value={cans} icon="package" accent="aqua" />
        <StatTile label="Gross booking value" value={revenue} icon="rupee" money accent="ok" />
        <StatTile label="Advance collected" value={collected} icon="wallet" money />
        <StatTile label="Pending dues" value={dues} icon="alert" money accent="warn" />
        <StatTile label="Total expenses" value={expense} icon="alert" money accent="warn" />
        <StatTile label="Estimated margin" value={revenue - expense} icon="check" money accent="ok" />
        <StatTile label="Cancelled bookings" value={bs.length - active.length} icon="clipboard" />
      </div>
      <div className="mt-5 grid gap-5 xl:grid-cols-2">
        <Card className="p-5"><h2 className="font-extrabold text-ink">Village performance</h2>{villageMap.size === 0 ? <EmptyState icon="clipboard" title="No booking data" body={`No bookings were created in ${label}.`} /> : <div className="mt-4 divide-y divide-line">{[...villageMap.entries()].sort((a,b)=>b[1].revenue-a[1].revenue).map(([name,value])=><div key={name} className="grid grid-cols-[1fr_auto_auto] gap-4 py-3 text-[12px]"><span className="font-bold text-ink">{name}</span><span>{value.orders} orders · {value.cans} cans</span><span className="font-extrabold text-brand">₹{value.revenue.toLocaleString("en-IN")}</span></div>)}</div>}</Card>
        <Card className="p-5"><h2 className="font-extrabold text-ink">Expense breakdown</h2>{categoryMap.size === 0 ? <EmptyState icon="rupee" title="No expenses" body={`No expenses were recorded in ${label}.`} /> : <div className="mt-4 divide-y divide-line">{[...categoryMap.entries()].sort((a,b)=>b[1]-a[1]).map(([name,value])=><div key={name} className="flex justify-between py-3 text-[12px]"><span className="font-bold text-ink">{name}</span><span className="font-extrabold text-danger">₹{value.toLocaleString("en-IN")}</span></div>)}</div>}</Card>
      </div>
      <Card className="mt-5 p-5"><h2 className="font-extrabold text-ink">Current inventory snapshot</h2><div className="mt-4 grid gap-3 sm:grid-cols-4">{[["Total",stock.total],["Available",stock.available],["Out",stock.out],["Damaged",stock.damaged]].map(([label,value])=><div key={String(label)} className="rounded-2xl bg-canvas p-4"><p className="text-[11px] text-ink-muted">{label}</p><p className="mt-1 text-2xl font-extrabold text-ink">{value}</p></div>)}</div></Card>
    </>
  );
}
