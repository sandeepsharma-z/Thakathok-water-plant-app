import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors={
  "Access-Control-Allow-Origin":"*",
  "Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type",
};
const json=(body:unknown,status=200)=>new Response(JSON.stringify(body),{
  status,headers:{...cors,"Content-Type":"application/json"},
});
const digits=(value:unknown)=>String(value??"").replace(/\D/g,"");

Deno.serve(async(req)=>{
  if(req.method==="OPTIONS")return new Response("ok",{headers:cors});
  if(req.method!=="POST")return json({error:"Method not allowed"},405);
  try{
    const url=Deno.env.get("SUPABASE_URL")!;
    const serviceKey=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const auth=req.headers.get("Authorization")??"";
    const admin=createClient(url,serviceKey);
    const caller=createClient(url,Deno.env.get("SUPABASE_ANON_KEY")!,{
      global:{headers:{Authorization:auth}},
    });
    const {data:{user}}=await caller.auth.getUser();
    if(!user)return json({error:"Not signed in"},401);
    const {data:isAdmin}=await admin.from("admin_users").select("user_id").eq("user_id",user.id).maybeSingle();
    if(!isAdmin)return json({error:"Admin access required"},403);

    const input=await req.json();
    const action=String(input.action??"create");
    if(action!=="create"){
      const staffId=String(input.staff_id??"");
      const {data:staff}=await admin.from("delivery_staff").select("*").eq("id",staffId).is("archived_at",null).maybeSingle();
      if(!staff)return json({error:"Delivery staff account not found."},404);

      if(action==="update"){
        const name=String(input.name??"").trim();
        const mobile=digits(input.mobile);
        const email=String(input.email??"").trim().toLowerCase();
        if(name.length<2||mobile.length!==10||!email.includes("@")){
          return json({error:"Enter a valid name, email and 10-digit mobile."},400);
        }
        if(!staff.user_id)return json({error:"This staff login has already been deleted."},409);
        const {error:authError}=await admin.auth.admin.updateUserById(staff.user_id,{
          email,email_confirm:true,user_metadata:{name,mobile,role:"delivery_staff"},
        });
        if(authError)return json({error:authError.message},409);
        const {error:updateError}=await admin.from("delivery_staff").update({
          name,mobile,email,updated_at:new Date().toISOString(),
        }).eq("id",staff.id);
        if(updateError)return json({error:updateError.message},409);
        return json({ok:true});
      }

      if(action==="reset_password"){
        const password=String(input.password??"");
        if(password.length<8)return json({error:"Password must contain at least 8 characters."},400);
        if(!staff.user_id)return json({error:"This staff login has already been deleted."},409);
        const {error}=await admin.auth.admin.updateUserById(staff.user_id,{password});
        if(error)return json({error:error.message},409);
        return json({ok:true});
      }

      if(action==="delete"){
        const {count}=await admin.from("bookings").select("id",{count:"exact",head:true})
          .eq("assigned_staff_id",staff.id).in("status",["pending","confirmed"]);
        if((count??0)>0)return json({
          error:"Reassign or complete this staff member's active orders before deleting the login.",
        },409);
        if(staff.user_id){
          const {error}=await admin.auth.admin.deleteUser(staff.user_id);
          if(error)return json({error:error.message},409);
        }
        const {error}=await admin.from("delivery_staff").update({
          enabled:false,email:null,mobile:`deleted-${staff.id}`,
          archived_at:new Date().toISOString(),updated_at:new Date().toISOString(),
        }).eq("id",staff.id);
        if(error)return json({error:error.message},409);
        return json({ok:true});
      }
      return json({error:"Unsupported action."},400);
    }

    const name=String(input.name??"").trim();
    const mobile=digits(input.mobile);
    const email=String(input.email??"").trim().toLowerCase();
    const password=String(input.password??"");
    if(name.length<2||mobile.length!==10||!email.includes("@")||password.length<8){
      return json({error:"Enter a valid name, email, 10-digit mobile and 8+ character password."},400);
    }
    const {data:created,error:createError}=await admin.auth.admin.createUser({
      email,password,email_confirm:true,
      user_metadata:{name,mobile,role:"delivery_staff"},
    });
    if(createError)return json({error:createError.message},409);
    const {error:profileError}=await admin.from("delivery_staff").insert({
      user_id:created.user.id,name,mobile,email,
    });
    if(profileError){
      await admin.auth.admin.deleteUser(created.user.id);
      throw profileError;
    }
    return json({ok:true,id:created.user.id});
  }catch(error){
    return json({error:error instanceof Error?error.message:"Could not create staff."},500);
  }
});
