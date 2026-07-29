import { BellRing, CheckCircle2, Send, Users } from "lucide-react";
import { NotificationComposer } from "@/components/notification-composer";
import { Card, EmptyState, StatTile } from "@/components/ui";
import { createClient } from "@/lib/supabase/server";
export const dynamic="force-dynamic";
export default async function NotificationsPage(){
 const db=await createClient();
 const [{data:customerRows},{data:bookings},{data:villageRows},{data:campaigns}]=await Promise.all([
  db.from("customers").select("mobile,name,village").order("name"),
  db.from("bookings").select("mobile,customer_name,village,status,payment_method,balance"),
  db.from("villages").select("name").eq("enabled",true).order("sort_order"),
  db.from("notification_campaigns").select("*,customer_notifications(read_at)").order("created_at",{ascending:false}).limit(100)
 ]);
 const map=new Map<string,{mobile:string;name:string;village:string;due:number;cashPending:boolean}>();
 for(const c of customerRows??[])map.set(c.mobile,{...c,due:0,cashPending:false});
 for(const b of bookings??[]){const c=map.get(b.mobile)??{mobile:b.mobile,name:b.customer_name,village:b.village,due:0,cashPending:false};if(b.status==="confirmed")c.due+=Number(b.balance);if(b.payment_method==="cash"&&b.status==="pending")c.cashPending=true;map.set(b.mobile,c)}
 const customers=[...map.values()]; const sent=(campaigns??[]).reduce((s,c)=>s+c.sent_count,0); const read=(campaigns??[]).reduce((s,c)=>s+(c.customer_notifications??[]).filter((r:{read_at:string|null})=>r.read_at).length,0);
 return <><header><h1 className="text-[27px] font-extrabold tracking-tight text-ink">Notification Center</h1><p className="mt-1 text-[13px] text-ink-muted">Send personal or unlimited bulk in-app notifications and track customer reads.</p></header>
 <div className="mt-5 grid gap-4 sm:grid-cols-3"><StatTile label="Campaigns sent" value={(campaigns??[]).length} icon="sms"/><StatTile label="Customer deliveries" value={sent} icon="users" accent="aqua"/><StatTile label="Notifications read" value={read} icon="check" accent="ok"/></div>
 <div className="mt-6"><NotificationComposer customers={customers} villages={(villageRows??[]).map(v=>v.name)}/></div>
 <Card className="mt-6 overflow-hidden"><div className="border-b border-line p-5"><h2 className="text-[16px] font-extrabold text-ink">Send history</h2></div>{!campaigns?.length?<EmptyState icon="sms" title="No campaigns sent" body="Sent notification campaigns will appear here."/>:<div className="divide-y divide-line">{campaigns.map(c=>{const reads=(c.customer_notifications??[]).filter((r:{read_at:string|null})=>r.read_at).length;return <div key={c.id} className="flex flex-wrap items-center gap-4 p-5"><div className="grid h-11 w-11 place-items-center rounded-2xl bg-tint text-brand"><BellRing className="h-5 w-5"/></div><div className="min-w-0 flex-1"><p className="font-extrabold text-ink">{c.title}</p><p className="mt-1 truncate text-[12px] text-ink-muted">{c.body}</p><p className="mt-1 text-[10px] uppercase text-ink-faint">{c.audience.replaceAll("_"," ")} · {new Date(c.created_at).toLocaleString("en-IN")}</p></div><div className="flex gap-4 text-[11px] font-bold"><span className="inline-flex items-center gap-1 text-brand"><Send className="h-3.5 w-3.5"/>{c.sent_count} sent</span><span className="inline-flex items-center gap-1 text-ok"><CheckCircle2 className="h-3.5 w-3.5"/>{reads} read</span></div></div>})}</div>}</Card></>;
}
