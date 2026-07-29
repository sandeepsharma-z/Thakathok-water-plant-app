"use client";

import {useActionState} from "react";
import {KeyRound,Pencil,Trash2} from "lucide-react";
import {
  deleteDeliveryStaff,
  resetDeliveryStaffPassword,
  updateDeliveryStaff,
  type StaffActionState,
} from "@/app/(app)/delivery-staff/actions";
import {inputClass} from "@/components/management-ui";

const initial:StaffActionState={};

function Result({state}:{state:StaffActionState}){
  if(!state.error&&!state.ok)return null;
  return <p className={`mt-3 text-[11px] font-bold ${state.error?"text-danger":"text-ok"}`}>{state.error??state.ok}</p>;
}

export function DeliveryStaffManager({staff}:{staff:{id:string;name:string;email:string|null;mobile:string}}){
  const[editState,editAction,editing]=useActionState(updateDeliveryStaff,initial);
  const[passwordState,passwordAction,resetting]=useActionState(resetDeliveryStaffPassword,initial);
  const[deleteState,deleteAction,deleting]=useActionState(deleteDeliveryStaff,initial);
  return <div className="mt-3 space-y-2">
    <details className="group rounded-xl border border-line bg-white">
      <summary className="flex cursor-pointer list-none items-center gap-2 px-4 py-3 text-[12px] font-bold text-brand"><Pencil className="h-4 w-4"/>Edit staff details</summary>
      <form action={editAction} className="grid gap-2 border-t border-line p-3 sm:grid-cols-2">
        <input type="hidden" name="staff_id" value={staff.id}/>
        <input name="name" required defaultValue={staff.name} className={inputClass} placeholder="Full name"/>
        <input name="email" required type="email" defaultValue={staff.email??""} className={inputClass} placeholder="Login email"/>
        <input name="mobile" required inputMode="numeric" maxLength={10} defaultValue={staff.mobile} className={inputClass} placeholder="Mobile"/>
        <button disabled={editing} className="rounded-xl bg-brand px-4 py-2.5 text-[12px] font-extrabold text-white">{editing?"Saving...":"Save Changes"}</button>
        <div className="sm:col-span-2"><Result state={editState}/></div>
      </form>
    </details>
    <details className="group rounded-xl border border-line bg-white">
      <summary className="flex cursor-pointer list-none items-center gap-2 px-4 py-3 text-[12px] font-bold text-ink"><KeyRound className="h-4 w-4"/>Reset password</summary>
      <form action={passwordAction} className="border-t border-line p-3">
        <input type="hidden" name="staff_id" value={staff.id}/>
        <div className="flex gap-2"><input name="password" required type="password" minLength={8} className={inputClass} placeholder="New password (8+ characters)"/><button disabled={resetting} className="shrink-0 rounded-xl bg-ink px-4 text-[12px] font-extrabold text-white">{resetting?"Resetting...":"Reset"}</button></div>
        <Result state={passwordState}/>
      </form>
    </details>
    <details className="group rounded-xl border border-rose-200 bg-white">
      <summary className="flex cursor-pointer list-none items-center gap-2 px-4 py-3 text-[12px] font-bold text-danger"><Trash2 className="h-4 w-4"/>Delete staff login</summary>
      <form action={deleteAction} className="border-t border-rose-100 p-3">
        <input type="hidden" name="staff_id" value={staff.id}/>
        <p className="mb-2 text-[10px] text-ink-muted">Delivery history will be preserved. Active orders must be reassigned first. Type DELETE to confirm.</p>
        <div className="flex gap-2"><input name="confirmation" required className={inputClass} placeholder="Type DELETE"/><button disabled={deleting} className="shrink-0 rounded-xl bg-danger px-4 text-[12px] font-extrabold text-white">{deleting?"Deleting...":"Delete"}</button></div>
        <Result state={deleteState}/>
      </form>
    </details>
  </div>;
}
