import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { sendImmediateOrderConfirmation } from "../_shared/order-confirmation-sms.ts";
const cors={"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type"};
const json=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:{...cors,"Content-Type":"application/json"}});
const hex=(bytes:ArrayBuffer)=>[...new Uint8Array(bytes)].map(v=>v.toString(16).padStart(2,"0")).join("");
async function hmac(message:string,secret:string){const key=await crypto.subtle.importKey("raw",new TextEncoder().encode(secret),{name:"HMAC",hash:"SHA-256"},false,["sign"]);return hex(await crypto.subtle.sign("HMAC",key,new TextEncoder().encode(message)));}
const digits=(value:unknown)=>String(value??"").replace(/\D/g,"");

Deno.serve(async(request)=>{
 if(request.method==="OPTIONS")return new Response("ok",{headers:cors});
 if(request.method!=="POST")return json({error:"Method not allowed"},405);
 try{
  const db=createClient(Deno.env.get("SUPABASE_URL")!,Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const input=await request.json(); const action=String(input.action??"");
  const sessionMobile=digits(input.mobile),sessionToken=String(input.session_token??"");
  if(!/^\d{10}$/.test(sessionMobile)||sessionToken.length<32)return json({error:"Please login again."},401);
  const tokenHash=hex(await crypto.subtle.digest("SHA-256",new TextEncoder().encode(sessionToken)));
  const {data:session}=await db.from("customer_sessions").select("mobile").eq("token_hash",tokenHash).eq("mobile",sessionMobile).gt("expires_at",new Date().toISOString()).maybeSingle();
  if(!session)return json({error:"Your session has expired. Please login again."},401);
  const {data:settings,error:settingsError}=await db.from("settings").select("per_can_rate,delivery_charge,delivery_free_threshold,free_delivery_village,razorpay_key_id,razorpay_key_secret,offer_enabled,offer_code,offer_discount_percent,offer_min_subtotal,plant_name,advance_percent").eq("id",1).single();
  if(settingsError)throw settingsError;
  const keyId=String(settings.razorpay_key_id??"").trim(),secret=String(settings.razorpay_key_secret??"").trim();
  if(!(keyId.startsWith("rzp_test_")||keyId.startsWith("rzp_live_"))||secret.length<20)return json({error:"Razorpay credentials are invalid. Add the real Key ID and Key Secret in admin settings."},503);
  const basic=btoa(`${keyId}:${secret}`);

  if(action==="create"){
   const mobile=sessionMobile,cans=Number(input.cans),name=String(input.name??"").trim(),eventType=String(input.event_type??"").trim(),village=String(input.village??"").trim(),address=String(input.address??"").trim(),eventDate=String(input.event_date??""),eventTime=String(input.event_time??"").trim();
   if(!/^\d{10}$/.test(mobile)||!name||!eventType||!address||!eventTime||!Number.isInteger(cans)||cans<1||cans>10000||!/^\d{4}-\d{2}-\d{2}$/.test(eventDate))return json({error:"Invalid booking details."},400);
   const {data:eligibility,error:eligibilityError}=await db.rpc("get_customer_order_eligibility",{p_mobile:mobile});
   if(eligibilityError)throw eligibilityError;
   if(!eligibility?.eligible)return json({error:String(eligibility?.reason??"Your previous order must be completed first.")},409);
   const {data:blockedDate}=await db.from("blocked_dates").select("blocked_date").eq("blocked_date",eventDate).maybeSingle();
   if(blockedDate)return json({error:"This event date is no longer available. Please choose another date."},409);
   const {data:villageRow}=await db.from("villages").select("name,delivery_charge").eq("name",village).eq("enabled",true).maybeSingle();
   if(!villageRow)return json({error:"The selected delivery village is no longer available."},409);
   const rate=Number(settings.per_can_rate),subtotal=cans*rate;
   const deliveryCharge=village===settings.free_delivery_village||cans>=Number(settings.delivery_free_threshold)?0:Number(villageRow.delivery_charge??settings.delivery_charge);
   const submittedCode=String(input.offer_code??"").trim().toUpperCase(); let offerCode="",offerPercent=0,discount=0;
   if(submittedCode){
    if(!settings.offer_enabled)return json({error:"This offer is no longer active."},409);
    if(submittedCode!==String(settings.offer_code).trim().toUpperCase())return json({error:"The offer code has changed. Remove it and try again."},409);
    if(subtotal<Number(settings.offer_min_subtotal))return json({error:`Minimum subtotal of ₹${settings.offer_min_subtotal} is required for this offer.`},409);
    offerCode=submittedCode;offerPercent=Number(settings.offer_discount_percent);discount=Math.round(subtotal*offerPercent/100);
   }
   const grandTotal=subtotal-discount+deliveryCharge,advance=Math.round(grandTotal*Number(settings.advance_percent)/100),balance=grandTotal-advance;
   if(Number(input.expected_advance)!==advance)return json({error:"Pricing has changed. Go back, refresh the order and try again."},409);
   const date=new Date(`${eventDate}T00:00:00Z`);const months=["JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"];const suffix=crypto.randomUUID().replaceAll("-","").slice(0,4).toUpperCase();const bookingCode=`THK${cans}${months[date.getUTCMonth()]}${date.getUTCDate()}${suffix}`;
   const payload={booking_code:bookingCode,customer_name:name,event_type:eventType,cans,per_can_rate:rate,subtotal,delivery_charge:deliveryCharge,grand_total:grandTotal,advance,balance,village,mobile,address,event_date:eventDate,event_time:eventTime,offer_code:offerCode,offer_discount_percent:offerPercent,discount_amount:discount};
   const orderResponse=await fetch("https://api.razorpay.com/v1/orders",{method:"POST",headers:{Authorization:`Basic ${basic}`,"Content-Type":"application/json"},body:JSON.stringify({amount:advance*100,currency:"INR",receipt:`booking_${mobile}_${Date.now()}`.slice(0,40),notes:{purpose:"booking_advance",mobile,booking_code:bookingCode}})});
   const order=await orderResponse.json();
   if(!orderResponse.ok||!order.id){if(orderResponse.status===401)return json({error:"Razorpay authentication failed. Check the keys in admin settings."},503);return json({error:String(order?.error?.description??"Could not create Razorpay order.")},502);}
   const {error}=await db.from("booking_payment_orders").insert({razorpay_order_id:order.id,mobile,amount:advance,booking_payload:payload});if(error)throw error;
   return json({key_id:keyId,order_id:order.id,amount_paise:advance*100,plant_name:settings.plant_name,customer_name:name});
  }

  if(action==="verify"){
   const orderId=String(input.order_id??""),paymentId=String(input.payment_id??""),signature=String(input.signature??"");
   if(!orderId||!paymentId||!signature)return json({error:"Incomplete payment response."},400);
   const {data:bound}=await db.from("booking_payment_orders").select("amount,status,mobile").eq("razorpay_order_id",orderId).eq("mobile",sessionMobile).maybeSingle();if(!bound)return json({error:"Secure payment order not found."},404);
   if(await hmac(`${orderId}|${paymentId}`,secret)!==signature.toLowerCase())return json({error:"Payment signature verification failed."},400);
   const [paymentResponse,orderResponse]=await Promise.all([
    fetch(`https://api.razorpay.com/v1/payments/${encodeURIComponent(paymentId)}`,{headers:{Authorization:`Basic ${basic}`}}),
    fetch(`https://api.razorpay.com/v1/orders/${encodeURIComponent(orderId)}`,{headers:{Authorization:`Basic ${basic}`}})
   ]);
   const payment=await paymentResponse.json(),order=await orderResponse.json();
   if(!paymentResponse.ok||!orderResponse.ok||payment.order_id!==orderId||payment.amount!==Number(bound.amount)*100||payment.currency!=="INR"||payment.status!=="captured"||order.amount!==Number(bound.amount)*100||order.status!=="paid")return json({error:"Payment is not captured and paid yet."},409);
   const {data,error}=await db.rpc("finalize_verified_booking_payment",{p_order_id:orderId,p_payment_id:paymentId});if(error)throw error;
   if(data?.booking_id)await sendImmediateOrderConfirmation(db,String(data.booking_id));
   return json({success:true,...data});
  }
  return json({error:"Unknown action."},400);
 }catch(error){return json({error:error instanceof Error?error.message:"Secure booking payment failed."},500);}
});
