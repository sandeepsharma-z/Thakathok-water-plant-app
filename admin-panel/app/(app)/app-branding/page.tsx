import { ImageIcon } from "lucide-react";
import { PageHead, buttonClass, inputClass } from "@/components/management-ui";
import { Card } from "@/components/ui";
import { createClient } from "@/lib/supabase/server";
import { saveAppBranding } from "./actions";

export const dynamic="force-dynamic";
export default async function AppBrandingPage(){
 const db=await createClient();const {data}=await db.from("settings").select("app_branding").eq("id",1).single();const b=(data?.app_branding??{}) as Record<string,string>;
 return <><PageHead title="App Branding" body="Update the customer app logo and brand identity."/><form action={saveAppBranding} className="mt-6 max-w-4xl space-y-5">
  <Card className="p-5"><div className="flex items-center gap-3"><ImageIcon className="h-6 w-6 text-brand"/><h2 className="font-extrabold text-ink">Logo & names</h2></div><div className="mt-5 space-y-4"><label className="text-[12px] font-bold text-ink">Brand name<input name="brand_name" defaultValue={b.brand_name} required className={inputClass}/></label><label className="text-[12px] font-bold text-ink">Plant display name<input name="plant_display_name" defaultValue={b.plant_display_name} required className={inputClass}/></label><div className="flex items-center gap-4"><div className="grid h-24 w-24 place-items-center overflow-hidden rounded-2xl border border-line bg-canvas">{b.logo_url?.startsWith("http")?<img src={b.logo_url} alt="" className="h-full w-full object-contain"/>:<ImageIcon className="h-8 w-8 text-ink-faint"/>}</div><div className="flex-1"><input type="hidden" name="logo_current" value={b.logo_url}/><input type="file" name="logo_file" accept="image/png,image/jpeg,image/webp" className="w-full text-[12px]"/></div></div></div></Card>
  <div className="sticky bottom-4 rounded-2xl border border-line bg-surface/95 p-4 shadow-xl backdrop-blur"><button className={buttonClass}>Save App Branding</button></div></form></>;
}

