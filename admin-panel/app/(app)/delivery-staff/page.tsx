import {Camera,FileSignature,IndianRupee,PackageCheck,Phone,Truck,UserPlus} from "lucide-react";
import {DeliveryStaffCreateForm} from "@/components/delivery-staff-create-form";
import {PageHead} from "@/components/management-ui";
import {Card,EmptyState,StatTile} from "@/components/ui";
import {createClient} from "@/lib/supabase/server";
import {toggleDeliveryStaff} from "./actions";

export const dynamic="force-dynamic";
export default async function DeliveryStaffPage(){
  const db=await createClient();
  const[{data:staff},{data:records}]=await Promise.all([
    db.from("delivery_staff").select("*").order("created_at"),
    db.from("delivery_records").select("*,bookings(booking_code,customer_name,mobile),delivery_staff(name)").order("delivered_at",{ascending:false}).limit(50),
  ]);
  const rows=staff??[];
  const count=(id:string)=>(records??[]).filter(record=>record.staff_id===id).length;
  return <>
    <PageHead title="Delivery Staff" body="Create secure staff logins, manage availability and review completed deliveries."/>
    <div className="mt-5 grid gap-4 sm:grid-cols-3">
      <StatTile label="Total staff" value={rows.length} icon="users" index={0}/>
      <StatTile label="Active staff" value={rows.filter(x=>x.enabled).length} icon="check" accent="ok" index={1}/>
      <StatTile label="Completed deliveries" value={(records??[]).length} icon="truck" accent="aqua" index={2}/>
    </div>
    <Card className="mt-5 p-5">
      <div className="flex items-center gap-3"><UserPlus className="h-6 w-6 text-brand"/><div><h2 className="font-extrabold text-ink">Add delivery staff</h2><p className="text-[11px] text-ink-muted">Staff signs in at /staff/login using this mobile number and password.</p></div></div>
      <DeliveryStaffCreateForm/>
    </Card>
    <div className="mt-5 grid gap-4 lg:grid-cols-2">
      {rows.length===0?<Card className="lg:col-span-2"><EmptyState icon="users" title="No delivery staff yet" body="Create the first staff login above."/></Card>:rows.map(person=>
        <Card key={person.id} className="p-5">
          <div className="flex items-start justify-between gap-4">
            <div className="flex min-w-0 items-center gap-3">
              <span className="grid h-12 w-12 shrink-0 place-items-center rounded-2xl bg-tint text-lg font-extrabold text-brand">{person.name.slice(0,1).toUpperCase()}</span>
              <div className="min-w-0"><p className="truncate font-extrabold text-ink">{person.name}</p><p className="mt-1 flex items-center gap-1 text-[12px] text-ink-muted"><Phone className="h-3.5 w-3.5"/>+91 {person.mobile}</p></div>
            </div>
            <span className={`rounded-full px-3 py-1 text-[10px] font-extrabold ${person.enabled?"bg-ok-bg text-ok":"bg-danger-bg text-danger"}`}>{person.enabled?"ACTIVE":"DISABLED"}</span>
          </div>
          <div className="mt-4 flex items-center justify-between rounded-xl bg-canvas px-4 py-3"><span className="flex items-center gap-2 text-[12px] text-ink-muted"><Truck className="h-4 w-4"/>Completed deliveries</span><strong className="text-ink">{count(person.id)}</strong></div>
          <form action={toggleDeliveryStaff} className="mt-4">
            <input type="hidden" name="id" value={person.id}/><input type="hidden" name="enabled" value={String(!person.enabled)}/>
            <button className={`w-full rounded-xl border px-4 py-2.5 text-[12px] font-bold ${person.enabled?"border-rose-200 text-danger hover:bg-danger-bg":"border-emerald-200 text-ok hover:bg-ok-bg"}`}>{person.enabled?"Disable login":"Enable login"}</button>
          </form>
        </Card>)}
    </div>
    <Card className="mt-5 overflow-hidden">
      <div className="border-b border-line px-5 py-4"><h2 className="font-extrabold text-ink">Recent delivery activity</h2><p className="text-[11px] text-ink-muted">Cash, empty-can returns and customer proof recorded by staff.</p></div>
      {(records??[]).length===0?<EmptyState icon="truck" title="No completed staff deliveries" body="Delivery proof and collection activity will appear here."/>:<div className="divide-y divide-line">{(records??[]).map(record=><div key={record.id} className="grid gap-4 px-5 py-4 md:grid-cols-[1.2fr_1fr_auto] md:items-center">
        <div><p className="text-[13px] font-extrabold text-brand">{record.bookings?.booking_code}</p><p className="text-[12px] font-bold text-ink">{record.bookings?.customer_name}</p><p className="text-[10px] text-ink-muted">Delivered by {record.delivery_staff?.name} · {new Date(record.delivered_at).toLocaleString("en-IN")}</p></div>
        <div className="flex flex-wrap gap-2 text-[10px] font-bold"><span className="flex items-center gap-1 rounded-full bg-ok-bg px-2.5 py-1 text-ok"><IndianRupee className="h-3 w-3"/>₹{record.cash_collected} cash</span><span className="flex items-center gap-1 rounded-full bg-tint px-2.5 py-1 text-brand"><PackageCheck className="h-3 w-3"/>{record.empty_cans_returned} cans</span></div>
        <div className="flex gap-2">{record.proof_photo_url&&<a href={record.proof_photo_url} target="_blank" rel="noreferrer" className="grid h-9 w-9 place-items-center rounded-xl bg-tint text-brand" title="View delivery photo"><Camera className="h-4 w-4"/></a>}{record.customer_signature&&<a href={record.customer_signature} target="_blank" rel="noreferrer" className="grid h-9 w-9 place-items-center rounded-xl bg-tint text-brand" title="View signature"><FileSignature className="h-4 w-4"/></a>}</div>
      </div>)}</div>}
    </Card>
  </>;
}
