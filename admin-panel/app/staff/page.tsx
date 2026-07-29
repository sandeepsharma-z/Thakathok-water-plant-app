import {redirect} from "next/navigation";
import {CalendarDays,LogOut,MapPin,Navigation,Phone,Truck} from "lucide-react";
import Image from "next/image";
import {createClient} from "@/lib/supabase/server";
import {StaffDeliveryForm} from "@/components/staff-delivery-form";
import {staffSignOut} from "./actions";

export const dynamic="force-dynamic";
export default async function StaffOrdersPage(){
  const db=await createClient();
  const{data:{user}}=await db.auth.getUser();
  if(!user)redirect("/staff/login");
  const{data:staff}=await db.from("delivery_staff").select("*").eq("user_id",user.id).maybeSingle();
  if(!staff?.enabled){await db.auth.signOut();redirect("/staff/login");}
  const{data}=await db.from("bookings").select("*,delivery_records(*)").eq("assigned_staff_id",staff.id).in("status",["confirmed","delivered"]).order("event_date",{ascending:true});
  const bookings=data??[];
  const today=new Date().toISOString().slice(0,10);
  return <main className="min-h-dvh bg-canvas pb-10">
    <header className="sticky top-0 z-20 bg-[linear-gradient(135deg,#004fda,#168bea)] px-4 pb-6 pt-4 text-white shadow-lg">
      <div className="mx-auto max-w-2xl"><div className="flex items-center justify-between"><div className="flex items-center gap-3"><span className="grid h-11 w-11 place-items-center rounded-xl bg-white"><Image src="/logo.png" alt="" width={30} height={30}/></span><div><p className="text-[10px] font-semibold tracking-[.16em] text-white/70">DELIVERY STAFF</p><h1 className="text-lg font-extrabold">{staff.name}</h1></div></div><form action={staffSignOut}><button className="grid h-10 w-10 place-items-center rounded-xl bg-white/15" title="Logout"><LogOut className="h-5 w-5"/></button></form></div>
      <div className="mt-5 grid grid-cols-3 gap-2">{[["Assigned",bookings.length],["Today",bookings.filter(x=>x.event_date===today).length],["Delivered",bookings.filter(x=>x.status==="delivered").length]].map(([label,value])=><div key={label} className="rounded-2xl bg-white/12 px-3 py-3 text-center backdrop-blur"><p className="text-xl font-extrabold">{value}</p><p className="text-[9px] font-semibold text-white/70">{label}</p></div>)}</div></div>
    </header>
    <section className="mx-auto max-w-2xl space-y-4 px-4 pt-5">
      <div><h2 className="text-xl font-extrabold text-ink">My Assigned Orders</h2><p className="text-[11px] text-ink-muted">Complete delivery, cash and empty-can details in one place.</p></div>
      {bookings.length===0?<div className="rounded-[24px] border border-line bg-white px-6 py-14 text-center shadow-sm"><Truck className="mx-auto h-12 w-12 text-brand/40"/><h3 className="mt-4 font-extrabold text-ink">No assigned orders</h3><p className="mt-1 text-xs text-ink-muted">New assignments from admin will appear here.</p></div>:bookings.map(booking=>{
        const record=Array.isArray(booking.delivery_records)?booking.delivery_records[0]:booking.delivery_records;
        const delivered=booking.status==="delivered";
        return <article key={booking.id} className="overflow-hidden rounded-[24px] border border-line bg-white p-4 shadow-[0_12px_35px_-25px_rgba(0,79,218,.5)]">
          <div className="flex items-start justify-between gap-3"><div><span className={`rounded-full px-2.5 py-1 text-[9px] font-extrabold ${delivered?"bg-ok-bg text-ok":"bg-warn-bg text-warn"}`}>{delivered?"DELIVERED":"READY TO DELIVER"}</span><h3 className="mt-2 text-lg font-extrabold text-brand">{booking.booking_code}</h3><p className="text-sm font-bold text-ink">{booking.customer_name}</p></div><div className="rounded-2xl bg-tint px-4 py-2 text-center"><p className="text-xl font-extrabold text-ink">{booking.cans}</p><p className="text-[9px] text-ink-muted">CANS</p></div></div>
          <div className="mt-4 grid gap-2 rounded-2xl bg-canvas p-3 text-[11px] text-ink-muted"><p className="flex items-center gap-2"><CalendarDays className="h-4 w-4 text-brand"/><strong className="text-ink">{new Date(`${booking.event_date}T00:00:00`).toLocaleDateString("en-IN",{day:"2-digit",month:"short",year:"numeric"})} · {booking.event_time}</strong></p><p className="flex items-start gap-2"><MapPin className="mt-0.5 h-4 w-4 shrink-0 text-brand"/>{booking.address}, {booking.village}</p><a href={`tel:+91${booking.mobile}`} className="flex items-center gap-2 font-semibold text-brand"><Phone className="h-4 w-4"/>+91 {booking.mobile}</a><a href={`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(`${booking.address}, ${booking.village}`)}`} target="_blank" className="flex items-center gap-2 font-semibold text-brand"><Navigation className="h-4 w-4"/>Open location in Maps</a></div>
          <div className="mt-3 flex justify-between rounded-xl border border-line px-3 py-2 text-[11px]"><span className="text-ink-muted">Pending cash</span><strong className="text-warn">₹{booking.balance}</strong></div>
          {record&&<p className="mt-3 rounded-xl bg-ok-bg px-3 py-2 text-[10px] font-semibold text-ok">Saved: ₹{record.cash_collected} cash · {record.empty_cans_returned} empty cans returned</p>}
          <StaffDeliveryForm bookingId={booking.id} balance={booking.balance} cans={booking.cans} delivered={delivered}/>
        </article>;
      })}
    </section>
  </main>;
}
