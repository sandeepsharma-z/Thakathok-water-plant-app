"use server";
import {redirect} from "next/navigation";
import {revalidatePath} from "next/cache";
import {createClient} from "@/lib/supabase/server";

export type FormState={ok?:string;error?:string};

export async function signIn(_state:FormState,form:FormData):Promise<FormState>{
  const email=String(form.get("email")??"").trim().toLowerCase();
  const password=String(form.get("password")??"");
  if(!email.includes("@")||password.length<8)return{error:"Enter your staff email and password."};
  const db=await createClient();
  const{error}=await db.auth.signInWithPassword({email,password});
  if(error)return{error:"Login failed. Check your email and password."};
  const{data:{user}}=await db.auth.getUser();
  const{data:staff}=await db.from("delivery_staff").select("enabled").eq("user_id",user?.id??"").maybeSingle();
  if(!staff?.enabled){await db.auth.signOut();return{error:"This delivery staff account is disabled."};}
  redirect("/");
}
export async function signOut(){const db=await createClient();await db.auth.signOut();redirect("/login");}

export async function completeDelivery(_state:FormState,form:FormData):Promise<FormState>{
  const db=await createClient();
  const{data:{user}}=await db.auth.getUser();
  if(!user)return{error:"Session expired. Please login again."};
  const bookingId=String(form.get("booking_id")??"");
  const cash=Math.max(0,Math.round(Number(form.get("cash_collected")??0)));
  const returned=Math.max(0,Math.round(Number(form.get("empty_cans_returned")??0)));
  let photoUrl="";
  const photo=form.get("proof_photo");
  if(photo instanceof File&&photo.size>0){
    if(photo.size>5*1024*1024)return{error:"Delivery photo must be under 5 MB."};
    const ext=(photo.name.split(".").pop()||"jpg").toLowerCase();
    const path=`${user.id}/${bookingId}-${Date.now()}.${ext}`;
    const{error}=await db.storage.from("delivery-proofs").upload(path,photo,{contentType:photo.type,upsert:false});
    if(error)return{error:"Could not upload delivery photo."};
    photoUrl=db.storage.from("delivery-proofs").getPublicUrl(path).data.publicUrl;
  }
  const{error}=await db.rpc("complete_staff_delivery",{
    p_booking_id:bookingId,p_cash_collected:cash,p_empty_cans_returned:returned,
    p_photo_url:photoUrl||null,p_signature:String(form.get("customer_signature")??"")||null,
    p_notes:String(form.get("notes")??"").trim(),
  });
  if(error){
    const message=error.message.includes("COLLECT_FULL_BALANCE")?"Enter the full pending balance or leave cash as zero.":error.message.includes("EXCEEDS_PENDING_CANS")?"Returned cans exceed the pending cans.":"Could not complete this delivery.";
    return{error:message};
  }
  await db.functions.invoke("staff-delivery-sms",{body:{booking_id:bookingId}}).catch(()=>null);
  revalidatePath("/");
  return{ok:"Delivery saved successfully."};
}
