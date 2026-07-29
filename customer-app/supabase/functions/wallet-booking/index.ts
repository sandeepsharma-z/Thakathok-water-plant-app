import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { sendImmediateOrderConfirmation } from "../_shared/order-confirmation-sms.ts";
const cors={"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type"};
const json=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:{...cors,"Content-Type":"application/json"}});
const digits=(v:unknown)=>String(v??"").replace(/\D/g,"");
const hex=(b:ArrayBuffer)=>[...new Uint8Array(b)].map(v=>v.toString(16).padStart(2,"0")).join("");
Deno.serve(async req=>{
 if(req.method==="OPTIONS")return new Response("ok",{headers:cors}); if(req.method!=="POST")return json({error:"Method not allowed"},405);
 try{
  const db=createClient(Deno.env.get("SUPABASE_URL")!,Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);const i=await req.json();
  const mobile=digits(i.mobile),token=String(i.session_token??""),requestId=String(i.request_id??"");
  if(!/^\d{10}$/.test(mobile)||token.length<32||!requestId)return json({error:"Please login again to pay from your wallet."},401);
  const tokenHash=hex(await crypto.subtle.digest("SHA-256",new TextEncoder().encode(token)));
  const {data:session}=await db.from("customer_sessions").select("mobile").eq("token_hash",tokenHash).eq("mobile",mobile).gt("expires_at",new Date().toISOString()).maybeSingle();
  if(!session)return json({error:"Your session has expired. Please login again."},401);
  const {data:eligibility,error:eligibilityError}=await db.rpc("get_customer_order_eligibility",{p_mobile:mobile});
  if(eligibilityError)throw eligibilityError;
  if(!eligibility?.eligible)return json({error:String(eligibility?.reason??"Your previous order must be completed first.")},409);
  const {data:blockedDate}=await db.from("blocked_dates").select("blocked_date").eq("blocked_date",String(i.event_date??"")).maybeSingle();
  if(blockedDate)return json({error:"This event date is no longer available. Please choose another date."},409);
  const {data:s,error:se}=await db.from("settings").select("per_can_rate,delivery_charge,delivery_free_threshold,free_delivery_village,offer_enabled,offer_code,offer_discount_percent,offer_min_subtotal,advance_percent").eq("id",1).single();if(se)throw se;
  const cans=Number(i.cans),name=String(i.name??"").trim(),eventType=String(i.event_type??"").trim(),village=String(i.village??"").trim(),address=String(i.address??"").trim(),eventDate=String(i.event_date??""),eventTime=String(i.event_time??"").trim();
  if(!name||!eventType||!address||!eventTime||!Number.isInteger(cans)||cans<1||cans>10000||!/^\d{4}-\d{2}-\d{2}$/.test(eventDate))return json({error:"Invalid booking details."},400);
  const {data:v}=await db.from("villages").select("delivery_charge").eq("name",village).eq("enabled",true).maybeSingle();if(!v)return json({error:"The selected delivery village is no longer available."},409);
  const rate=Number(s.per_can_rate),subtotal=cans*rate,delivery=village===s.free_delivery_village||cans>=Number(s.delivery_free_threshold)?0:Number(v.delivery_charge??s.delivery_charge);
  const entered=String(i.offer_code??"").trim().toUpperCase();let code="",percent=0,discount=0;
  if(entered){if(!s.offer_enabled)return json({error:"This offer is no longer active."},409);if(entered!==String(s.offer_code).trim().toUpperCase())return json({error:"The offer code has changed. Remove it and try again."},409);if(subtotal<Number(s.offer_min_subtotal))return json({error:`Minimum subtotal of ₹${s.offer_min_subtotal} is required for this offer.`},409);code=entered;percent=Number(s.offer_discount_percent);discount=Math.round(subtotal*percent/100);}
  const total=subtotal-discount+delivery,advance=Math.round(total*Number(s.advance_percent)/100),balance=total-advance;if(Number(i.expected_advance)!==advance)return json({error:"Pricing has changed. Go back, refresh the order and try again."},409);
  const d=new Date(`${eventDate}T00:00:00Z`),months=["JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"];const bookingCode=`THK${cans}${months[d.getUTCMonth()]}${d.getUTCDate()}`;
  const payload={booking_code:bookingCode,customer_name:name,event_type:eventType,cans,per_can_rate:rate,subtotal,delivery_charge:delivery,grand_total:total,advance,balance,village,mobile,address,event_date:eventDate,event_time:eventTime,offer_code:code,offer_discount_percent:percent,discount_amount:discount};
  const {data,error}=await db.rpc("pay_booking_from_wallet",{p_mobile:mobile,p_token_hash:tokenHash,p_request_id:requestId,p_payload:payload});
  if(error){if(error.message.includes("INSUFFICIENT_BALANCE"))return json({error:"Your wallet balance is insufficient for this advance."},409);if(error.message.includes("INVALID_SESSION"))return json({error:"Your session has expired. Please login again."},401);throw error;}
  if(data?.booking_id&&!data?.already_paid)await sendImmediateOrderConfirmation(db,String(data.booking_id));
  return json({success:true,...data});
 }catch(e){return json({error:e instanceof Error?e.message:"Wallet payment failed."},500);}
});
