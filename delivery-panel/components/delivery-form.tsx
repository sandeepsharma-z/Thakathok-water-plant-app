"use client";
import {useActionState,useRef,useState} from "react";
import {Camera,PackageCheck,PenLine,Wallet} from "lucide-react";
import {completeDelivery,type FormState} from "@/app/actions";

export function DeliveryForm({bookingId,balance,cans}:{bookingId:string;balance:number;cans:number}){
  const[state,action,pending]=useActionState<FormState,FormData>(completeDelivery,{});
  const canvas=useRef<HTMLCanvasElement>(null);const[drawing,setDrawing]=useState(false);
  const point=(e:React.PointerEvent<HTMLCanvasElement>)=>{const r=e.currentTarget.getBoundingClientRect();return{x:e.clientX-r.left,y:e.clientY-r.top};};
  const start=(e:React.PointerEvent<HTMLCanvasElement>)=>{const c=canvas.current;if(!c)return;const r=c.getBoundingClientRect();if(c.width!==Math.round(r.width*devicePixelRatio)){c.width=Math.round(r.width*devicePixelRatio);c.height=Math.round(r.height*devicePixelRatio);const x=c.getContext("2d");x?.scale(devicePixelRatio,devicePixelRatio);if(x){x.lineWidth=2;x.lineCap="round";x.strokeStyle="#0b2848";}}const p=point(e),x=c.getContext("2d");x?.beginPath();x?.moveTo(p.x,p.y);setDrawing(true);};
  const move=(e:React.PointerEvent<HTMLCanvasElement>)=>{if(!drawing)return;const p=point(e),x=canvas.current?.getContext("2d");x?.lineTo(p.x,p.y);x?.stroke();};
  return <form action={async(form)=>{if(canvas.current)form.set("customer_signature",canvas.current.toDataURL("image/png"));await action(form);}} className="mt-4 space-y-3 border-t border-blue-100 pt-4">
    <input type="hidden" name="booking_id" value={bookingId}/>
    <div className="grid gap-3 sm:grid-cols-2">
      <label className="rounded-2xl bg-blue-50/60 p-3 text-xs font-bold"><span className="flex gap-2"><Wallet className="h-4 w-4 text-blue-600"/>Cash Collected</span><input name="cash_collected" type="number" min="0" max={balance} defaultValue={0} className="mt-2 h-11 w-full rounded-xl border border-blue-100 bg-white px-3 outline-none"/><small className="font-normal text-slate-500">Pending: ₹{balance}</small></label>
      <label className="rounded-2xl bg-blue-50/60 p-3 text-xs font-bold"><span className="flex gap-2"><PackageCheck className="h-4 w-4 text-blue-600"/>Empty Cans Returned</span><input name="empty_cans_returned" type="number" min="0" max={cans} defaultValue={0} className="mt-2 h-11 w-full rounded-xl border border-blue-100 bg-white px-3 outline-none"/></label>
    </div>
    <label className="block rounded-2xl border border-blue-100 p-3 text-xs font-bold"><span className="flex gap-2"><Camera className="h-4 w-4 text-blue-600"/>Delivery Photo (optional)</span><input name="proof_photo" type="file" accept="image/*" capture="environment" className="mt-2 block w-full text-xs"/></label>
    <div className="rounded-2xl border border-blue-100 p-3"><p className="mb-2 flex gap-2 text-xs font-bold"><PenLine className="h-4 w-4 text-blue-600"/>Customer Signature (optional)</p><canvas ref={canvas} onPointerDown={start} onPointerMove={move} onPointerUp={()=>setDrawing(false)} onPointerCancel={()=>setDrawing(false)} className="h-28 w-full touch-none rounded-xl bg-blue-50/60"/></div>
    <textarea name="notes" placeholder="Delivery notes (optional)" className="min-h-20 w-full rounded-2xl border border-blue-100 p-3 text-xs outline-none"/>
    {state.error||state.ok?<p className={`rounded-xl px-3 py-2 text-xs font-bold ${state.error?"bg-red-50 text-red-600":"bg-emerald-50 text-emerald-700"}`}>{state.error??state.ok}</p>:null}
    <button disabled={pending} className="h-12 w-full rounded-2xl bg-gradient-to-r from-[#075bd8] to-[#1b9cf0] text-sm font-black text-white shadow-lg disabled:opacity-60">{pending?"Saving...":"MARK DELIVERED & SAVE"}</button>
  </form>;
}
