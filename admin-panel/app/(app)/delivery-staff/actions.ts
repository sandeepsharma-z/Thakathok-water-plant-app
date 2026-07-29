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

export async function createDeliveryStaff(
  _previous:StaffActionState,form:FormData,
):Promise<StaffActionState>{
  try{
    const db=await adminClient();
    const{data,error}=await db.functions.invoke("manage-delivery-staff",{body:{
      name:String(form.get("name")??"").trim(),
      email:String(form.get("email")??"").trim().toLowerCase(),
      mobile:String(form.get("mobile")??"").replace(/\D/g,""),
      password:String(form.get("password")??""),
    }});
    if(error||data?.error)return{error:data?.error??"Could not create delivery staff."};
    revalidatePath("/delivery-staff");
    return{ok:"Delivery staff account created."};
  }catch(error){
    return{error:error instanceof Error?error.message:"Could not create staff."};
  }
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
