"use server";

import {revalidatePath} from "next/cache";
import {redirect} from "next/navigation";
import {createClient} from "@/lib/supabase/server";
import {sendDeliveryConfirmation} from "@/lib/sms";
import type {Booking} from "@/lib/types";

export type StaffState={ok?:string;error?:string};
const staffEmail=(mobile:string)=>`staff.${mobile.replace(/\D/g,"")}@mahalakshmiwaterplant.com`;

export async function staffSignIn(_previous:StaffState,form:FormData):Promise<StaffState>{
  const mobile=String(form.get("mobile")??"").replace(/\D/g,"");
  const password=String(form.get("password")??"");
  if(mobile.length!==10||password.length<6)return{error:"Enter your valid mobile number and password."};
  const db=await createClient();
  const{error}=await db.auth.signInWithPassword({email:staffEmail(mobile),password});
  if(error)return{error:"Login failed. Check your mobile number and password."};
  const{data:{user}}=await db.auth.getUser();
  const{data:staff}=await db.from("delivery_staff").select("enabled").eq("user_id",user?.id??"").maybeSingle();
  if(!staff?.enabled){await db.auth.signOut();return{error:"This staff account is disabled. Contact the admin."};}
  revalidatePath("/staff");
  redirect("/staff");
}

export async function staffSignOut(){
  const db=await createClient();
  await db.auth.signOut();
  redirect("/staff/login");
}

export async function completeDelivery(_previous:StaffState,form:FormData):Promise<StaffState>{
  try{
    const db=await createClient();
    const{data:{user}}=await db.auth.getUser();
    if(!user)return{error:"Your session expired. Please login again."};
    const bookingId=String(form.get("booking_id")??"");
    const cash=Math.max(0,Number(form.get("cash_collected")??0));
    const returned=Math.max(0,Number(form.get("empty_cans_returned")??0));
    let photoUrl="";
    const photo=form.get("proof_photo");
    if(photo instanceof File&&photo.size>0){
      if(photo.size>5*1024*1024)return{error:"Delivery photo must be smaller than 5 MB."};
      const ext=(photo.name.split(".").pop()||"jpg").toLowerCase();
      const path=`${user.id}/${bookingId}-${Date.now()}.${ext}`;
      const{error:uploadError}=await db.storage.from("delivery-proofs").upload(path,photo,{upsert:false,contentType:photo.type});
      if(uploadError)return{error:`Could not upload delivery photo: ${uploadError.message}`};
      photoUrl=db.storage.from("delivery-proofs").getPublicUrl(path).data.publicUrl;
    }
    const{error}=await db.rpc("complete_staff_delivery",{
      p_booking_id:bookingId,
      p_cash_collected:Number.isFinite(cash)?Math.round(cash):0,
      p_empty_cans_returned:Number.isFinite(returned)?Math.round(returned):0,
      p_photo_url:photoUrl||null,
      p_signature:String(form.get("customer_signature")??"")||null,
      p_notes:String(form.get("notes")??"").trim(),
    });
    if(error){
      const message=error.message.includes("INSUFFICIENT_CAN_STOCK")?"Inventory does not have enough reserved cans. Ask admin to add stock.":error.message.includes("CASH_EXCEEDS_BALANCE")||error.message.includes("COLLECT_FULL_BALANCE")?"Cash collected must match the full pending balance.":error.message.includes("EXCEEDS_PENDING_CANS")?"Returned cans exceed the pending cans.":"Could not complete this delivery. Please try again.";
      return{error:message};
    }
    const{data:booking}=await db.from("bookings").select("*").eq("id",bookingId).maybeSingle();
    if(booking){try{await sendDeliveryConfirmation(booking as Booking);}catch{/* delivery remains complete */}}
    revalidatePath("/staff");
    return{ok:"Delivery details saved successfully."};
  }catch{
    return{error:"Could not complete this delivery. Please try again."};
  }
}
