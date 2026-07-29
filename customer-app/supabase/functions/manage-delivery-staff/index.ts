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
