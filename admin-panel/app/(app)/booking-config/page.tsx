import { CalendarRange, CreditCard, ListChecks, Percent } from "lucide-react";
import { PageHead, buttonClass, inputClass } from "@/components/management-ui";
import { Card } from "@/components/ui";
import { createClient } from "@/lib/supabase/server";
import { saveBookingConfig } from "./actions";

export const dynamic = "force-dynamic";
const area = `${inputClass} min-h-28 py-3`;
const field = (label:string,name:string,value:string,help?:string) => <label className="text-[12px] font-bold text-ink">{label}<textarea name={name} defaultValue={value} required className={area}/>{help?<span className="mt-1 block text-[10px] font-normal text-ink-faint">{help}</span>:null}</label>;

export default async function BookingConfigPage() {
  const db = await createClient();
  const { data } = await db.from("settings").select("advance_percent,booking_event_types,booking_quantity_options,payment_content").eq("id",1).single();
  const payment = (data?.payment_content ?? {}) as Record<string,string>;
  return <><PageHead title="Booking Configuration" body="Control advance ratio, event types, quantity choices and customer payment instructions."/>
    <form action={saveBookingConfig} className="mt-6 space-y-5">
      <div className="grid gap-5 xl:grid-cols-3">
        <Card className="p-5"><div className="flex items-center gap-3"><Percent className="h-6 w-6 text-brand"/><div><h2 className="font-extrabold text-ink">Advance rule</h2><p className="text-[11px] text-ink-muted">Balance is calculated automatically.</p></div></div><label className="mt-5 block text-[12px] font-bold text-ink">Advance percentage<input name="advance_percent" type="number" min="1" max="100" required defaultValue={data?.advance_percent ?? 30} className={inputClass}/></label><p className="mt-3 rounded-xl bg-tint p-3 text-[11px] text-ink-body">{data?.advance_percent ?? 30}% advance · {100-Number(data?.advance_percent ?? 30)}% balance</p></Card>
        <Card className="p-5"><div className="flex items-center gap-3"><CalendarRange className="h-6 w-6 text-brand"/><h2 className="font-extrabold text-ink">Event types</h2></div><div className="mt-4">{field("One option per line","event_types",((data?.booking_event_types as string[])??[]).join("\n"),"Shown in the booking form and Shop By Need mapping.")}</div></Card>
        <Card className="p-5"><div className="flex items-center gap-3"><ListChecks className="h-6 w-6 text-brand"/><h2 className="font-extrabold text-ink">Can quantities</h2></div><div className="mt-4">{field("One quantity per line","quantities",((data?.booking_quantity_options as number[])??[]).join("\n"),"Custom quantity is always available automatically.")}</div></Card>
      </div>
      <Card className="p-5"><div className="flex items-center gap-3"><CreditCard className="h-6 w-6 text-brand"/><div><h2 className="font-extrabold text-ink">Payment instructions</h2><p className="text-[11px] text-ink-muted">Use {"{advance}"}, {"{plant_name}"} and {"{plant_phone}"} as live placeholders.</p></div></div><div className="mt-5 grid gap-4 lg:grid-cols-2">
        {field("Advance warning","advance_warning",payment.advance_warning??"")}
        {field("Cash sheet heading","cash_heading",payment.cash_heading??"")}
        {field("Cash step 1","cash_step_1",payment.cash_step_1??"")}
        {field("Cash step 2","cash_step_2",payment.cash_step_2??"")}
        {field("Cash step 3","cash_step_3",payment.cash_step_3??"")}
        {field("Cash warning notice","cash_notice",payment.cash_notice??"")}
        {field("Cash confirmation button","cash_button",payment.cash_button??"")}
        {field("Online confirmed message","confirmed_message",payment.confirmed_message??"")}
        {field("Cash pending message","pending_message",payment.pending_message??"")}
        {field("Non-refundable note","non_refundable_note",payment.non_refundable_note??"")}
      </div></Card>
      <div className="sticky bottom-4 rounded-2xl border border-line bg-surface/95 p-4 shadow-xl backdrop-blur"><button className={buttonClass}>Save Booking Configuration</button></div>
    </form></>;
}

