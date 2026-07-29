"use client";
import {useActionState} from "react";
import {Mail,LockKeyhole,Truck} from "lucide-react";
import {signIn,type FormState} from "../actions";

export default function LoginPage(){
  const[state,action,pending]=useActionState<FormState,FormData>(signIn,{});
  return <main className="grid min-h-dvh place-items-center p-5">
    <div className="w-full max-w-md overflow-hidden rounded-[32px] border border-blue-100 bg-white shadow-[0_30px_90px_-45px_rgba(0,78,190,.75)]">
      <div className="bg-gradient-to-br from-[#0547ba] via-[#0875e8] to-[#2aacf3] p-7 text-white"><div className="grid h-14 w-14 place-items-center rounded-2xl bg-white/15"><Truck className="h-7 w-7"/></div><p className="mt-6 text-[10px] font-bold tracking-[.2em] text-white/70">MAHALAKSHMI WATER PLANT</p><h1 className="mt-2 text-3xl font-black">Delivery Staff</h1><p className="mt-2 text-sm text-white/75">Sign in to view your assigned orders.</p></div>
      <form action={action} className="space-y-4 p-7">
        <label className="block text-xs font-bold">Staff email<div className="mt-2 flex items-center rounded-2xl border border-blue-100 bg-blue-50/60 px-4"><Mail className="h-4 w-4 text-blue-600"/><input name="email" required type="email" autoComplete="username" className="h-12 flex-1 bg-transparent px-3 outline-none" placeholder="staff@example.com"/></div></label>
        <label className="block text-xs font-bold">Password<div className="mt-2 flex items-center rounded-2xl border border-blue-100 bg-blue-50/60 px-4"><LockKeyhole className="h-4 w-4 text-blue-600"/><input name="password" required minLength={8} type="password" autoComplete="current-password" className="h-12 flex-1 bg-transparent px-3 outline-none" placeholder="Your password"/></div></label>
        {state.error?<p className="rounded-xl bg-red-50 px-3 py-2 text-xs font-bold text-red-600">{state.error}</p>:null}
        <button disabled={pending} className="h-12 w-full rounded-2xl bg-gradient-to-r from-[#075bd8] to-[#1b9cf0] text-sm font-black text-white shadow-lg disabled:opacity-60">{pending?"Signing in...":"SIGN IN"}</button>
        <p className="text-center text-[11px] text-slate-500">Account access is provided by the plant administrator.</p>
      </form>
    </div>
  </main>;
}
