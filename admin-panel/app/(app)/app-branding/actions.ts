"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export async function saveAppBranding(form: FormData) {
  const db = await createClient();
  const brandName = String(form.get("brand_name") ?? "").trim();
  const plantDisplayName = String(form.get("plant_display_name") ?? "").trim();
  let logoUrl = String(form.get("logo_current") ?? "").trim();
  const logo = form.get("logo_file");
  if (!brandName || !plantDisplayName) throw new Error("Complete all branding fields.");
  if (logo instanceof File && logo.size > 0) {
    if (!logo.type.startsWith("image/") || logo.size > 5*1024*1024) throw new Error("Logo must be an image under 5 MB.");
    const extension=(logo.name.split(".").pop()||"png").toLowerCase();
    const path=`branding/${Date.now()}-${crypto.randomUUID()}.${extension}`;
    const { error }=await db.storage.from("home-content").upload(path,logo,{contentType:logo.type});
    if(error) throw error;
    logoUrl=db.storage.from("home-content").getPublicUrl(path).data.publicUrl;
  }
  const { error }=await db.from("settings").update({app_branding:{brand_name:brandName,plant_display_name:plantDisplayName,logo_url:logoUrl,primary_color:"#004FDA",accent_color:"#37B6FF"},updated_at:new Date().toISOString()}).eq("id",1);
  if(error) throw error;
  revalidatePath("/app-branding");
}

