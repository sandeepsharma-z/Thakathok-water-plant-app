import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors={
  "Access-Control-Allow-Origin":"*",
  "Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type",
};
const json=(body:unknown,status=200)=>new Response(JSON.stringify(body),{
  status,headers:{...cors,"Content-Type":"application/json"},
});
const digits=(value:unknown)=>String(value??"").replace(/\D/g,"");
const hex=(bytes:ArrayBuffer)=>[...new Uint8Array(bytes)].map(v=>v.toString(16).padStart(2,"0")).join("");
const dateOnly=(value:unknown)=>String(value??"");

Deno.serve(async(req)=>{
  if(req.method==="OPTIONS")return new Response("ok",{headers:cors});
  if(req.method!=="POST")return json({error:"Method not allowed"},405);
  try{
    const db=createClient(Deno.env.get("SUPABASE_URL")!,Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    const input=await req.json();
    const action=String(input.action??"");
    const mobile=digits(input.mobile);
    const token=String(input.session_token??"");
    if(!/^\d{10}$/.test(mobile)||token.length<32)return json({error:"Please login again."},401);
    const tokenHash=hex(await crypto.subtle.digest("SHA-256",new TextEncoder().encode(token)));
    const{data:session}=await db.from("customer_sessions").select("mobile").eq("token_hash",tokenHash).eq("mobile",mobile).gt("expires_at",new Date().toISOString()).maybeSingle();
    if(!session)return json({error:"Your session has expired. Please login again."},401);

    if(action==="profile"){
      const{data,error}=await db.from("customers").select("mobile,name,village,address,avatar_url,wallet_balance").eq("mobile",mobile).single();
      if(error)throw error;return json({profile:data});
    }
    if(action==="update_profile"){
      const name=String(input.name??"").trim(),village=String(input.village??"").trim(),address=String(input.address??"").trim();
      if(name.length<2||name.length>100||village.length>100||address.length>500)return json({error:"Enter valid profile details."},400);
      const{data,error}=await db.from("customers").update({name,village,address,updated_at:new Date().toISOString()}).eq("mobile",mobile).select("mobile,name,village,address,avatar_url").single();
      if(error)throw error;return json({profile:data});
    }
    if(action==="avatar"){
      const encoded=String(input.image_base64??"");
      const extension=String(input.extension??"jpg").toLowerCase().replace(/[^a-z0-9]/g,"");
      if(!encoded)return json({error:"Photo is missing."},400);
      const binary=Uint8Array.from(atob(encoded),c=>c.charCodeAt(0));
      if(binary.byteLength>2*1024*1024)return json({error:"Photo must be smaller than 2 MB."},400);
      const path=`${mobile}/${crypto.randomUUID()}.${extension||"jpg"}`;
      const{error:uploadError}=await db.storage.from("customer-avatars").upload(path,binary,{contentType:extension==="png"?"image/png":"image/jpeg",upsert:false});
      if(uploadError)throw uploadError;
      const url=db.storage.from("customer-avatars").getPublicUrl(path).data.publicUrl;
      const{error}=await db.from("customers").update({avatar_url:url,updated_at:new Date().toISOString()}).eq("mobile",mobile);
      if(error)throw error;return json({avatar_url:url});
    }
    if(action==="remove_avatar"){
      const{error}=await db.from("customers").update({avatar_url:null,updated_at:new Date().toISOString()}).eq("mobile",mobile);
      if(error)throw error;return json({ok:true});
    }
    if(action==="bookings"){
      const{data,error}=await db.from("bookings").select("*").eq("mobile",mobile).order("created_at",{ascending:false});
      if(error)throw error;return json({bookings:data??[]});
    }
    if(action==="summary"){
      const[{data:customer},{data:bookings,error}]=await Promise.all([
        db.from("customers").select("wallet_balance").eq("mobile",mobile).single(),
        db.from("bookings").select("status,balance").eq("mobile",mobile),
      ]);
      if(error)throw error;
      const pending=(bookings??[]).filter(b=>["confirmed","delivered"].includes(b.status)).reduce((sum,b)=>sum+Number(b.balance??0),0);
      return json({wallet_balance:Number(customer?.wallet_balance??0),pending_dues:pending});
    }
    if(action==="eligibility"){
      const{data,error}=await db.rpc("get_customer_order_eligibility",{p_mobile:mobile});
      if(error)throw error;return json({eligibility:data});
    }
    if(action==="notifications"){
      const{data,error}=await db.from("customer_notifications").select("id,read_at,created_at,notification_campaigns(title,body,notification_type,action_type)").eq("mobile",mobile).is("deleted_at",null).order("created_at",{ascending:false});
      if(error)throw error;return json({notifications:data??[]});
    }
    if(action==="notifications_update"){
      const operation=String(input.operation??"");
      let query=db.from("customer_notifications").update({
        ...(operation==="mark_all"||operation==="remove_all"?{read_at:new Date().toISOString()}:{}),
        ...(operation==="remove"||operation==="remove_all"?{deleted_at:new Date().toISOString()}:{}),
      }).eq("mobile",mobile);
      if(operation==="remove")query=query.eq("id",String(input.id??""));
      else if(operation==="remove_all"){
        const ids=Array.isArray(input.ids)?input.ids.map(String):[];
        if(!ids.length)return json({ok:true});query=query.in("id",ids);
      }else if(operation!=="mark_all")return json({error:"Invalid notification action."},400);
      const{error}=await query;if(error)throw error;return json({ok:true});
    }
    if(action==="wallet"){
      const[{data:customer},{data:transactions,error}]=await Promise.all([
        db.from("customers").select("wallet_balance").eq("mobile",mobile).single(),
        db.from("wallet_transactions").select("*").eq("mobile",mobile).order("created_at",{ascending:false}).limit(50),
      ]);
      if(error)throw error;return json({balance:Number(customer?.wallet_balance??0),transactions:transactions??[]});
    }
    if(action==="cash_booking"){
      const{data:eligible,error:eligibilityError}=await db.rpc("get_customer_order_eligibility",{p_mobile:mobile});
      if(eligibilityError)throw eligibilityError;
      if(!eligible?.eligible)return json({error:String(eligible?.reason??"Your previous order must be completed first.")},409);
      const cans=Number(input.cans),name=String(input.name??"").trim(),eventType=String(input.event_type??"").trim(),village=String(input.village??"").trim(),address=String(input.address??"").trim(),eventDate=dateOnly(input.event_date),eventTime=String(input.event_time??"").trim();
      if(!name||!eventType||!address||!eventTime||!Number.isInteger(cans)||cans<1||cans>10000||!/^\d{4}-\d{2}-\d{2}$/.test(eventDate))return json({error:"Invalid booking details."},400);
      const[{data:blocked},{data:settings,error:settingsError},{data:villageRow}]=await Promise.all([
        db.from("blocked_dates").select("blocked_date").eq("blocked_date",eventDate).maybeSingle(),
        db.from("settings").select("per_can_rate,delivery_charge,delivery_free_threshold,free_delivery_village,offer_enabled,offer_code,offer_discount_percent,offer_min_subtotal,advance_percent").eq("id",1).single(),
        db.from("villages").select("delivery_charge").eq("name",village).eq("enabled",true).maybeSingle(),
      ]);
      if(settingsError)throw settingsError;if(blocked)return json({error:"This event date is no longer available."},409);if(!villageRow)return json({error:"The selected village is unavailable."},409);
      const rate=Number(settings.per_can_rate),subtotal=cans*rate,delivery=village===settings.free_delivery_village||cans>=Number(settings.delivery_free_threshold)?0:Number(villageRow.delivery_charge??settings.delivery_charge);
      const entered=String(input.offer_code??"").trim().toUpperCase();let code="",percent=0,discount=0;
      if(entered){if(!settings.offer_enabled)return json({error:"This offer is no longer active."},409);if(entered!==String(settings.offer_code).trim().toUpperCase())return json({error:"The offer code has changed."},409);if(subtotal<Number(settings.offer_min_subtotal))return json({error:`Minimum subtotal of Rs.${settings.offer_min_subtotal} is required.`},409);code=entered;percent=Number(settings.offer_discount_percent);discount=Math.round(subtotal*percent/100);}
      const total=subtotal-discount+delivery,advance=Math.round(total*Number(settings.advance_percent)/100),balance=total-advance;
      if(Number(input.expected_advance)!==advance)return json({error:"Pricing changed. Refresh and try again."},409);
      const d=new Date(`${eventDate}T00:00:00Z`),months=["JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"],bookingCode=`THK${cans}${months[d.getUTCMonth()]}${d.getUTCDate()}`;
      const{data:booking,error}=await db.from("bookings").insert({booking_code:bookingCode,customer_name:name,event_type:eventType,cans,per_can_rate:rate,subtotal,delivery_charge:delivery,grand_total:total,advance,balance,village,mobile,address,event_date:eventDate,event_time:eventTime,payment_method:"cash",offer_code:code||null,offer_discount_percent:percent,discount_amount:discount,status:"pending"}).select("id,booking_code").single();
      if(error)throw error;
      fetch(`${Deno.env.get("SUPABASE_URL")}/functions/v1/cash-booking-alert`,{method:"POST",headers:{Authorization:`Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`,"Content-Type":"application/json"},body:JSON.stringify({booking_id:booking.id})}).catch(()=>{});
      return json({booking_code:booking.booking_code});
    }
    return json({error:"Unknown action."},400);
  }catch(error){return json({error:error instanceof Error?error.message:"Customer service failed."},500);}
});
