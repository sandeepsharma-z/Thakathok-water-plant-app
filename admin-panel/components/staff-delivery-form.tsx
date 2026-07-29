"use client";

import {useActionState,useEffect,useRef,useState} from "react";
import {Camera,CheckCircle2,Eraser,IndianRupee,PackageCheck,PenLine} from "lucide-react";
import {completeDelivery,type StaffState} from "@/app/staff/actions";

const initial:StaffState={};
export function StaffDeliveryForm({bookingId,balance,cans,delivered}:{bookingId:string;balance:number;cans:number;delivered:boolean}){
  const[state,action,pending]=useActionState(completeDelivery,initial);
  const canvas=useRef<HTMLCanvasElement>(null);
  const[drawing,setDrawing]=useState(false);
  const[signature,setSignature]=useState("");
  useEffect(()=>{const el=canvas.current;if(!el)return;const rect=el.getBoundingClientRect();el.width=Math.max(1,Math.round(rect.width*devicePixelRatio));el.height=Math.max(1,Math.round(rect.height*devicePixelRatio));const ctx=el.getContext("2d");ctx?.scale(devicePixelRatio,devicePixelRatio);if(ctx){ctx.lineWidth=2.2;ctx.lineCap="round";ctx.strokeStyle="#0b2545";}},[]);
  const point=(event:React.PointerEvent<HTMLCanvasElement>)=>{const r=event.currentTarget.getBoundingClientRect();return{x:event.clientX-r.left,y:event.clientY-r.top};};
  const start=(event:React.PointerEvent<HTMLCanvasElement>)=>{event.currentTarget.setPointerCapture(event.pointerId);const ctx=canvas.current?.getContext("2d");const p=point(event);ctx?.beginPath();ctx?.moveTo(p.x,p.y);setDrawing(true);};
  const move=(event:React.PointerEvent<HTMLCanvasElement>)=>{if(!drawing)return;const p=point(event);const ctx=canvas.current?.getContext("2d");ctx?.lineTo(p.x,p.y);ctx?.stroke();};
  const end=()=>{setDrawing(false);if(canvas.current)setSignature(canvas.current.toDataURL("image/png"));};
  const clear=()=>{const el=canvas.current;const ctx=el?.getContext("2d");if(el&&ctx)ctx.clearRect(0,0,el.width,el.height);setSignature("");};
  return <form action={action} className="mt-4 space-y-4 border-t border-line pt-4">
    <input type="hidden" name="booking_id" value={bookingId}/><input type="hidden" name="customer_signature" value={signature}/>
    <div className="grid grid-cols-2 gap-3">
      <label className="rounded-2xl bg-canvas p-3 text-[11px] font-bold text-ink"><span className="flex items-center gap-1.5"><IndianRupee className="h-4 w-4 text-ok"/>Cash Collected</span><input name="cash_collected" type="number" min="0" max={balance} defaultValue={balance} className="mt-2 w-full rounded-xl border border-line bg-white px-3 py-2.5 text-sm outline-none focus:border-brand"/><small className="mt-1 block font-normal text-ink-faint">Pending: ₹{balance}</small></label>
      <label className="rounded-2xl bg-canvas p-3 text-[11px] font-bold text-ink"><span className="flex items-center gap-1.5"><PackageCheck className="h-4 w-4 text-brand"/>Empty Cans Returned</span><input name="empty_cans_returned" type="number" min="0" max={cans} defaultValue={0} className="mt-2 w-full rounded-xl border border-line bg-white px-3 py-2.5 text-sm outline-none focus:border-brand"/><small className="mt-1 block font-normal text-ink-faint">Maximum: {cans}</small></label>
    </div>
    <label className="block rounded-2xl border border-dashed border-brand/30 bg-tint p-4 text-[11px] font-bold text-ink"><span className="flex items-center gap-2"><Camera className="h-4 w-4 text-brand"/>Delivery Photo (optional)</span><input name="proof_photo" type="file" accept="image/jpeg,image/png,image/webp" capture="environment" className="mt-3 block w-full text-[11px] text-ink-muted file:mr-3 file:rounded-xl file:border-0 file:bg-brand file:px-3 file:py-2 file:font-bold file:text-white"/></label>
    <div className="rounded-2xl border border-line bg-white p-3"><div className="mb-2 flex items-center justify-between"><span className="flex items-center gap-2 text-[11px] font-bold text-ink"><PenLine className="h-4 w-4 text-brand"/>Customer Signature (optional)</span><button type="button" onClick={clear} className="flex items-center gap-1 text-[10px] font-bold text-danger"><Eraser className="h-3.5 w-3.5"/>Clear</button></div><canvas ref={canvas} onPointerDown={start} onPointerMove={move} onPointerUp={end} onPointerCancel={end} className="h-28 w-full touch-none rounded-xl bg-canvas"/></div>
    <textarea name="notes" rows={2} placeholder="Delivery notes (optional)" className="w-full rounded-2xl border border-line bg-canvas px-4 py-3 text-xs text-ink outline-none focus:border-brand"/>
    {(state.error||state.ok)&&<p className={`rounded-xl px-4 py-3 text-xs font-semibold ${state.error?"bg-danger-bg text-danger":"bg-ok-bg text-ok"}`}>{state.error??state.ok}</p>}
    <button disabled={pending} className="flex w-full items-center justify-center gap-2 rounded-2xl bg-[linear-gradient(90deg,#004fda,#168bea)] py-3.5 text-xs font-extrabold text-white shadow-lg disabled:opacity-60"><CheckCircle2 className="h-5 w-5"/>{pending?"SAVING...":delivered?"UPDATE DELIVERY DETAILS":"MARK DELIVERED & SAVE"}</button>
  </form>;
}

