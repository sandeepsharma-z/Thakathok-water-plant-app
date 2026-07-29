"use server";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export type NotifyState={ok?:string;error?:string};
export async function sendNotification(_previous:NotifyState, form:FormData):Promise<NotifyState>{
  const title=String(form.get("title")??"").trim();
  const body=String(form.get("body")??"").trim();
  const audience=String(form.get("audience")??"selected");
  const type=String(form.get("notification_type")??"custom");
  const actionType=String(form.get("action_type")??"none");
  const village=String(form.get("village")??"");
  const selected=form.getAll("mobiles").map(String);
  if(!title||!body)return{error:"Enter a notification title and message."};
  const db=await createClient();
  const {data:{user}}=await db.auth.getUser();
  if(!user)return{error:"Your admin session has expired."};
  const [{data:customers},{data:bookings}]=await Promise.all([
    db.from("customers").select("mobile,name,village"),
    db.from("bookings").select("mobile,customer_name,village,status,payment_method,balance")
  ]);
  const all=new Map<string,{name:string;village:string}>();
  for(const c of customers??[])all.set(c.mobile,{name:c.name,village:c.village});
  for(const b of bookings??[])if(!all.has(b.mobile))all.set(b.mobile,{name:b.customer_name,village:b.village});
  let targets:string[]=[];
  if(audience==="all")targets=[...all.keys()];
  else if(audience==="village")targets=[...all].filter(([,v])=>v.village===village).map(([m])=>m);
  else if(audience==="pending_dues")targets=[...new Set((bookings??[]).filter(b=>b.status==="confirmed"&&Number(b.balance)>0).map(b=>b.mobile))];
  else if(audience==="cash_pending")targets=[...new Set((bookings??[]).filter(b=>b.payment_method==="cash"&&b.status==="pending").map(b=>b.mobile))];
  else targets=[...new Set(selected)];
  if(!targets.length)return{error:"No eligible customers found for this audience."};
  await db.from("customers").upsert(targets.map(m=>({mobile:m,name:all.get(m)?.name??"",village:all.get(m)?.village??""})),{onConflict:"mobile",ignoreDuplicates:true});
  const {data:campaign,error}=await db.from("notification_campaigns").insert({
    title,body,notification_type:type,action_type:actionType,
    action_value:String(form.get("action_value")??"").trim(),audience,created_by:user.id
  }).select("id").single();
  if(error||!campaign)return{error:"Could not create the notification campaign."};
  const {error:recipientError}=await db.from("customer_notifications").insert(targets.map(m=>({campaign_id:campaign.id,mobile:m})));
  if(recipientError){await db.from("notification_campaigns").delete().eq("id",campaign.id);return{error:"Could not deliver notifications. Please try again."};}
  revalidatePath("/sms");
  return{ok:`Notification sent to ${targets.length} customer${targets.length===1?"":"s"}.`};
}
