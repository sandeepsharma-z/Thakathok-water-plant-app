import {redirect} from "next/navigation";
import {createClient} from "@/lib/supabase/server";
import {signOut} from "./actions";
import {DeliveryForm} from "@/components/delivery-form";
import {CalendarDays,LogOut,MapPin,Navigation,Phone,Truck} from "lucide-react";

export const dynamic="force-dynamic";

export default async function StaffHome(){
  const db=await createClient();
  const{data:{user}}=await db.auth.getUser();
  if(!user)redirect("/login");
  const{data:staff}=await db.from("delivery_staff").select("*").eq("user_id",user.id).maybeSingle();
  if(!staff?.enabled){await db.auth.signOut();redirect("/login?disabled=1");}
  const{data}=await db.from("bookings").select("*,delivery_records(*)")
    .eq("assigned_staff_id",staff.id).in("status",["confirmed","delivered"])
    .order("event_date",{ascending:true});
  const bookings=data??[];
  const today=new Date().toISOString().slice(0,10);
  return <main className="min-h-dvh pb-12">
    <header className="bg-gradient-to-br from-[#0646b8] via-[#0874e7] to-[#25a9f4] px-5 pb-8 pt-5 text-white shadow-xl">
      <div className="mx-auto max-w-3xl">
        <div className="flex items-center justify-between gap-4">
          <div><p className="text-[10px] font-bold tracking-[.2em] text-white/70">THAKATHOK DELIVERY</p><h1 className="mt-1 text-2xl font-black">{staff.name}</h1><p className="text-xs text-white/75">{staff.email}</p></div>
          <form action={signOut}><button title="Sign out" className="grid h-11 w-11 place-items-center rounded-2xl bg-white/15 backdrop-blur"><LogOut className="h-5 w-5"/></button></form>
        </div>
        <div className="mt-5 grid grid-cols-3 gap-2">{[
          ["Assigned",bookings.length],["Today",bookings.filter(x=>x.event_date===today).length],["Delivered",bookings.filter(x=>x.status==="delivered").length],
        ].map(([label,value])=><div key={label} className="rounded-2xl bg-white/13 px-3 py-3 text-center backdrop-blur"><p className="text-xl font-black">{value}</p><p className="text-[9px] font-bold text-white/70">{label}</p></div>)}</div>
      </div>
    </header>
    <section className="mx-auto max-w-3xl px-4 pt-6">
      <div className="mb-4"><h2 className="text-xl font-black">My Assigned Orders</h2><p className="mt-1 text-xs text-slate-500">Only orders assigned to your account are shown.</p></div>
      {bookings.length===0?<div className="rounded-[28px] border border-blue-100 bg-white p-10 text-center shadow-sm"><Truck className="mx-auto h-10 w-10 text-blue-500"/><h3 className="mt-3 font-extrabold">No assigned orders</h3><p className="mt-1 text-xs text-slate-500">New assignments will appear here.</p></div>:
      <div className="space-y-4">{bookings.map(booking=>{
        const record=booking.delivery_records?.[0];
        return <article key={booking.id} className="overflow-hidden rounded-[28px] border border-blue-100 bg-white p-5 shadow-[0_18px_50px_-35px_rgba(0,91,216,.6)]">
          <div className="flex items-start justify-between gap-3"><div><p className="text-sm font-black text-blue-600">{booking.booking_code}</p><h3 className="mt-1 text-lg font-black">{booking.customer_name}</h3><p className="text-xs text-slate-500">{booking.cans} cans · {booking.event_type}</p></div><span className={`rounded-full px-3 py-1 text-[10px] font-black uppercase ${booking.status==="delivered"?"bg-emerald-100 text-emerald-700":"bg-blue-100 text-blue-700"}`}>{booking.status}</span></div>
          <div className="mt-4 grid gap-2 rounded-2xl bg-blue-50/70 p-4 text-xs text-slate-600">
            <p className="flex gap-2"><CalendarDays className="h-4 w-4 text-blue-600"/><b className="text-slate-800">{new Date(`${booking.event_date}T00:00:00`).toLocaleDateString("en-IN",{day:"2-digit",month:"short",year:"numeric"})} · {booking.event_time}</b></p>
            <p className="flex gap-2"><MapPin className="h-4 w-4 shrink-0 text-blue-600"/>{booking.address}, {booking.village}</p>
            <div className="flex flex-wrap gap-3 pt-1"><a className="flex items-center gap-1 font-bold text-blue-700" href={`tel:+91${booking.mobile}`}><Phone className="h-4 w-4"/>Call Customer</a><a target="_blank" className="flex items-center gap-1 font-bold text-blue-700" href={`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(`${booking.address}, ${booking.village}`)}`}><Navigation className="h-4 w-4"/>Open Map</a></div>
          </div>
          {record?<p className="mt-3 rounded-xl bg-emerald-50 px-3 py-2 text-[11px] font-bold text-emerald-700">Saved: ₹{record.cash_collected} cash · {record.empty_cans_returned} empty cans returned</p>:null}
          <DeliveryForm bookingId={booking.id} balance={booking.balance} cans={booking.cans}/>
        </article>;
      })}</div>}
    </section>
  </main>;
}
