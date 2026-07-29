"use client";

import {useActionState} from "react";
import {createDeliveryStaff,type StaffActionState} from "@/app/(app)/delivery-staff/actions";
import {buttonClass,inputClass} from "@/components/management-ui";

const initial:StaffActionState={};
export function DeliveryStaffCreateForm(){
  const[state,action,pending]=useActionState(createDeliveryStaff,initial);
  return <form action={action} className="mt-4 grid gap-3 md:grid-cols-2 xl:grid-cols-[1.1fr_1.2fr_1fr_1fr_auto]">
    <input name="name" required placeholder="Staff full name" className={inputClass}/>
    <input name="email" required type="email" placeholder="Staff login email" className={inputClass}/>
    <input name="mobile" required inputMode="numeric" maxLength={10} placeholder="10-digit mobile" className={inputClass}/>
    <input name="password" required minLength={8} type="password" placeholder="Temporary password (8+)" className={inputClass}/>
    <button disabled={pending} className={buttonClass}>{pending?"Creating...":"Create Staff Login"}</button>
    {(state.error||state.ok)&&<p className={`md:col-span-2 xl:col-span-5 text-[12px] font-semibold ${state.error?"text-danger":"text-ok"}`}>{state.error??state.ok}</p>}
  </form>;
}

