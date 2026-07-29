import Link from "next/link";
import { CalendarDays, ChevronLeft, ChevronRight, Lock, Trash2 } from "lucide-react";

import { Card, EmptyState } from "@/components/ui";
import { PageHead, buttonClass, inputClass } from "@/components/management-ui";
import { createClient } from "@/lib/supabase/server";
import { blockDate, unblockDate } from "./actions";

export const dynamic = "force-dynamic";

function validMonth(value?: string) {
  return /^\d{4}-\d{2}$/.test(value ?? "")
    ? value!
    : new Date().toISOString().slice(0, 7);
}

function shiftMonth(month: string, amount: number) {
  const [year, index] = month.split("-").map(Number);
  const date = new Date(year, index - 1 + amount, 1);
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
}

export default async function CalendarPage({
  searchParams,
}: {
  searchParams: Promise<{ month?: string }>;
}) {
  const { month: rawMonth } = await searchParams;
  const month = validMonth(rawMonth);
  const [year, monthNumber] = month.split("-").map(Number);
  const first = `${month}-01`;
  const next = shiftMonth(month, 1);
  const db = await createClient();
  const { data } = await db
    .from("blocked_dates")
    .select("blocked_date,reason,source,booking_id,bookings(booking_code,customer_name)")
    .gte("blocked_date", first)
    .lt("blocked_date", `${next}-01`)
    .order("blocked_date");
  const rows = data ?? [];
  const byDate = new Map(rows.map((row) => [row.blocked_date, row]));
  const startWeekday = new Date(year, monthNumber - 1, 1).getDay();
  const days = new Date(year, monthNumber, 0).getDate();
  const cells = Array.from({ length: startWeekday + days }, (_, index) =>
    index < startWeekday ? null : index - startWeekday + 1,
  );
  const label = new Date(year, monthNumber - 1, 1).toLocaleDateString("en-IN", {
    month: "long",
    year: "numeric",
  });

  return (
    <>
      <PageHead
        title="Blocked Dates"
        body="Block unavailable event dates. Confirmed bookings are blocked automatically and cancelled bookings are released."
      />
      <Card className="mt-5 p-5">
        <h2 className="font-extrabold text-ink">Block a date</h2>
        <form action={blockDate} className="mt-4 grid gap-3 md:grid-cols-[220px_1fr_auto]">
          <input name="blocked_date" type="date" min={new Date().toISOString().slice(0, 10)} required className={inputClass} />
          <input name="reason" placeholder="Reason, holiday or maintenance" className={inputClass} />
          <button className={buttonClass}><Lock className="h-4 w-4" />Block Date</button>
        </form>
      </Card>

      <Card className="mt-5 overflow-hidden">
        <div className="flex items-center justify-between border-b border-line p-5">
          <Link href={`/calendar?month=${shiftMonth(month, -1)}`} className="grid h-10 w-10 place-items-center rounded-xl border border-line text-ink-body hover:bg-tint"><ChevronLeft className="h-5 w-5" /></Link>
          <h2 className="flex items-center gap-2 text-[17px] font-extrabold text-ink"><CalendarDays className="h-5 w-5 text-brand" />{label}</h2>
          <Link href={`/calendar?month=${next}`} className="grid h-10 w-10 place-items-center rounded-xl border border-line text-ink-body hover:bg-tint"><ChevronRight className="h-5 w-5" /></Link>
        </div>
        <div className="grid grid-cols-7 border-b border-line bg-canvas text-center text-[11px] font-bold text-ink-muted">
          {["Sun","Mon","Tue","Wed","Thu","Fri","Sat"].map((day) => <div key={day} className="p-3">{day}</div>)}
        </div>
        <div className="grid grid-cols-7">
          {cells.map((day, index) => {
            if (!day) return <div key={`blank-${index}`} className="min-h-24 border-b border-r border-line bg-canvas/50" />;
            const iso = `${month}-${String(day).padStart(2, "0")}`;
            const blocked = byDate.get(iso);
            const booking = blocked?.bookings as unknown as { booking_code?: string; customer_name?: string } | null;
            return (
              <div key={iso} className={`min-h-24 border-b border-r border-line p-2 ${blocked ? blocked.source === "booking" ? "bg-warn-bg" : "bg-danger-bg" : "bg-surface"}`}>
                <p className="text-[12px] font-extrabold text-ink">{day}</p>
                {blocked ? <div className="mt-2"><p className={`text-[10px] font-extrabold uppercase ${blocked.source === "booking" ? "text-warn" : "text-danger"}`}>{blocked.source === "booking" ? "Booked" : "Blocked"}</p><p className="mt-0.5 line-clamp-2 text-[10px] text-ink-muted">{booking?.booking_code ?? blocked.reason}</p></div> : null}
              </div>
            );
          })}
        </div>
      </Card>

      <Card className="mt-5 overflow-hidden">
        <div className="border-b border-line p-5"><h2 className="font-extrabold text-ink">Unavailable dates this month</h2></div>
        {rows.length === 0 ? <EmptyState icon="calendar" title="No dates blocked" body="This month is currently open for bookings." /> : (
          <div className="divide-y divide-line">
            {rows.map((row) => {
              const booking = row.bookings as unknown as { booking_code?: string; customer_name?: string } | null;
              return <div key={row.blocked_date} className="flex flex-wrap items-center gap-4 px-5 py-4"><div className="grid h-11 w-11 place-items-center rounded-2xl bg-tint font-extrabold text-brand">{new Date(`${row.blocked_date}T00:00:00`).getDate()}</div><div className="min-w-0 flex-1"><p className="font-extrabold text-ink">{new Date(`${row.blocked_date}T00:00:00`).toLocaleDateString("en-IN",{day:"numeric",month:"long",year:"numeric"})}</p><p className="text-[11px] text-ink-muted">{row.source === "booking" ? `${booking?.booking_code ?? "Confirmed booking"} · ${booking?.customer_name ?? ""}` : row.reason}</p></div>{row.source === "manual" ? <form action={unblockDate}><input type="hidden" name="blocked_date" value={row.blocked_date} /><button className="inline-flex h-10 items-center gap-2 rounded-xl border border-danger/20 px-3 text-[11px] font-bold text-danger hover:bg-danger-bg"><Trash2 className="h-4 w-4" />Unblock</button></form> : <span className="rounded-full bg-warn-bg px-3 py-1 text-[10px] font-bold text-warn">Managed by booking</span>}</div>;
            })}
          </div>
        )}
      </Card>
    </>
  );
}

