"use client";

import {useActionState} from "react";
import Image from "next/image";
import {LockKeyhole,Phone,Truck} from "lucide-react";
import {staffSignIn,type StaffState} from "../actions";

const initial:StaffState={};
export default function StaffLoginPage(){
  const[state,action,pending]=useActionState(staffSignIn,initial);
  return <main className="min-h-dvh bg-[radial-gradient(circle_at_top,#d9edff_0,#eef5ff_42%,#f8fbff_100%)] px-4 py-8">
    <div className="mx-auto flex min-h-[calc(100dvh-4rem)] max-w-md items-center">
      <section className="w-full overflow-hidden rounded-[28px] border border-white/80 bg-white shadow-[0_24px_70px_-28px_rgba(0,79,218,.45)]">
        <div className="bg-[linear-gradient(135deg,#004fda,#168bea)] px-7 pb-8 pt-9 text-white">
          <div className="flex items-center gap-3"><span className="grid h-14 w-14 place-items-center rounded-2xl bg-white shadow-lg"><Image src="/logo.png" alt="ThakaThok" width={38} height={38}/></span><div><p className="text-xl font-extrabold">ThakaThok</p><p className="text-[10px] font-semibold tracking-[.2em] text-white/70">DELIVERY STAFF</p></div></div>
          <div className="mt-7 flex items-center gap-3"><Truck className="h-7 w-7"/><div><h1 className="text-2xl font-extrabold">Welcome back</h1><p className="mt-1 text-xs text-white/75">Login to view today&apos;s assigned orders.</p></div></div>
        </div>
        <form action={action} className="space-y-4 p-7">
          <label className="block text-xs font-bold text-ink">Mobile Number<div className="mt-2 flex items-center rounded-2xl border border-line bg-canvas px-4 focus-within:border-brand"><Phone className="h-5 w-5 text-brand"/><span className="ml-3 text-sm font-semibold text-ink">+91</span><input name="mobile" required inputMode="numeric" maxLength={10} className="min-w-0 flex-1 bg-transparent px-2 py-4 text-sm text-ink outline-none" placeholder="10-digit mobile"/></div></label>
          <label className="block text-xs font-bold text-ink">Password<div className="mt-2 flex items-center rounded-2xl border border-line bg-canvas px-4 focus-within:border-brand"><LockKeyhole className="h-5 w-5 text-brand"/><input name="password" required type="password" minLength={6} className="min-w-0 flex-1 bg-transparent px-3 py-4 text-sm text-ink outline-none" placeholder="Enter password"/></div></label>
          {state.error&&<p className="rounded-xl bg-danger-bg px-4 py-3 text-xs font-semibold text-danger">{state.error}</p>}
          <button disabled={pending} className="w-full rounded-2xl bg-[linear-gradient(90deg,#004fda,#168bea)] py-4 text-sm font-extrabold text-white shadow-lg shadow-blue-200 disabled:opacity-60">{pending?"Signing in...":"LOGIN TO MY ORDERS"}</button>
          <p className="text-center text-[10px] text-ink-faint">Access is provided by the plant administrator.</p>
        </form>
      </section>
    </div>
  </main>;
}

