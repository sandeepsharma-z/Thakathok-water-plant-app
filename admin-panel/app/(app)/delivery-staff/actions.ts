"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export type StaffActionState={ok?:string;error?:string};

async function adminClient(){
  const db=await createClient();
  const{data:{user}}=await db.auth.getUser();
  if(!user)throw new Error("Not signed in");
  const{data:admin}=await db.from("admin_users").select("user_id").eq("user_id",user.id).maybeSingle();
  if(!admin)throw new Error("Admin access required");
  return db;
}

async function functionError(
  error:unknown,data:unknown,fallback:string,
):Promise<string>{
  if(data&&typeof data==="object"&&"error" in data){
    const message=String((data as {error?:unknown}).error??"").trim();
    if(message)return message;
  }
  if(error&&typeof error==="object"&&"context" in error){
    const context=(error as {context?:unknown}).context;
    if(context instanceof Response){
      try{
        const payload=await context.clone().json() as {error?:unknown};
        const message=String(payload?.error??"").trim();
        if(message)return message;
      }catch{
        try{
          const message=(await context.clone().text()).trim();
          if(message)return message;
        }catch{/* Use the safe fallback below. */}
      }
    }
  }
  if(error instanceof Error&&error.message.trim())return error.message;
  return fallback;
}

export async function createDeliveryStaff(
  _previous:StaffActionState,form:FormData,
):Promise<StaffActionState>{
  try{
    const db=await adminClient();
    const{data,error}=await db.functions.invoke("manage-delivery-staff",{body:{
      action:"create",
      name:String(form.get("name")??"").trim(),
      email:String(form.get("email")??"").trim().toLowerCase(),
      mobile:String(form.get("mobile")??"").replace(/\D/g,""),
      password:String(form.get("password")??""),
    }});
    if(error||data?.error)return{error:await functionError(error,data,"Could not create delivery staff.")};
    revalidatePath("/delivery-staff");
    return{ok:"Delivery staff account created."};
  }catch(error){
    return{error:error instanceof Error?error.message:"Could not create staff."};
  }
}

async function manageStaff(body:Record<string,unknown>,success:string):Promise<StaffActionState>{
  try{
    const db=await adminClient();
    const{data,error}=await db.functions.invoke("manage-delivery-staff",{body});
    if(error||data?.error)return{error:await functionError(error,data,"Could not update delivery staff.")};
    revalidatePath("/delivery-staff");
    return{ok:success};
  }catch(error){
    return{error:error instanceof Error?error.message:"Could not update staff."};
  }
}

export async function updateDeliveryStaff(
  _previous:StaffActionState,form:FormData,
):Promise<StaffActionState>{
  return manageStaff({
    action:"update",staff_id:String(form.get("staff_id")??""),
    name:String(form.get("name")??"").trim(),
    email:String(form.get("email")??"").trim().toLowerCase(),
    mobile:String(form.get("mobile")??"").replace(/\D/g,""),
  },"Staff details updated.");
}

export async function resetDeliveryStaffPassword(
  _previous:StaffActionState,form:FormData,
):Promise<StaffActionState>{
  return manageStaff({
    action:"reset_password",staff_id:String(form.get("staff_id")??""),
    password:String(form.get("password")??""),
  },"Staff password reset successfully.");
}

export async function deleteDeliveryStaff(
  _previous:StaffActionState,form:FormData,
):Promise<StaffActionState>{
  if(String(form.get("confirmation")??"").trim().toUpperCase()!=="DELETE"){
    return{error:"Type DELETE to confirm account removal."};
  }
  return manageStaff({
    action:"delete",staff_id:String(form.get("staff_id")??""),
  },"Staff login deleted.");
}

export async function toggleDeliveryStaff(form:FormData){
  const db=await adminClient();
  const id=String(form.get("id")??"");
  const enabled=String(form.get("enabled"))==="true";
  const{error}=await db.from("delivery_staff").update({enabled,updated_at:new Date().toISOString()}).eq("id",id);
  if(error)throw error;
  revalidatePath("/", "layout");
}

export async function assignDeliveryStaff(form:FormData){
  const db=await adminClient();
  const bookingId=String(form.get("booking_id")??"");
  const staffId=String(form.get("staff_id")??"");
  if(!bookingId||!staffId)throw new Error("Select delivery staff.");
  const{error}=await db.rpc("assign_delivery_staff",{p_booking_id:bookingId,p_staff_id:staffId});
  if(error)throw error;
  revalidatePath("/", "layout");
}
