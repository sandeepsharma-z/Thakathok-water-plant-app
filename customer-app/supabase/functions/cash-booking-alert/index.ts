import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
const localNumber = (value: unknown) => {
  const digits = String(value ?? "").replace(/\D/g, "");
  return digits.length > 10 ? digits.slice(-10) : digits;
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);

  try {
    const input = await request.json();
    const bookingId = String(input.booking_id ?? "");
    if (!bookingId) return json({ error: "Missing booking." }, 400);

    const db = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    const [{ data: booking }, { data: settings }] = await Promise.all([
      db
        .from("bookings")
        .select("*")
        .eq("id", bookingId)
        .eq("payment_method", "cash")
        .eq("status", "pending")
        .maybeSingle(),
      db
        .from("settings")
        .select("fast2sms_api_key,sms_template_cash_alert,plant_phone")
        .eq("id", 1)
        .maybeSingle(),
    ]);
    if (!booking) return json({ error: "Cash booking not found." }, 404);

    const { data: existing } = await db
      .from("sms_logs")
      .select("id")
      .eq("booking_id", booking.id)
      .eq("sms_type", "cash_booking_owner")
      .eq("status", "sent")
      .limit(1)
      .maybeSingle();
    if (existing) return json({ sent: false, skipped: true });

    const apiKey = String(settings?.fast2sms_api_key ?? "");
    const templateId = String(settings?.sms_template_cash_alert ?? "");
    const ownerMobile = localNumber(settings?.plant_phone);
    let sent = false;
    let providerMessage = "";
    let requestId: string | null = null;

    if (!apiKey || !templateId || ownerMobile.length !== 10) {
      providerMessage =
        "Fast2SMS key, Cash Booking template ID or owner mobile is missing.";
    } else {
      const body = new URLSearchParams({
        authorization: apiKey,
        route: "dlt",
        sender_id: "MAHWAP",
        message: templateId,
        // Template variables: Booking ID, customer, mobile, cans, advance.
        variables_values: [
          booking.booking_code,
          booking.customer_name || "Customer",
          localNumber(booking.mobile),
          booking.cans,
          booking.advance,
        ].join("|") + "|",
        numbers: ownerMobile,
        flash: "0",
      });
      try {
        const response = await fetch("https://www.fast2sms.com/dev/bulkV2", {
          method: "POST",
          headers: { "Content-Type": "application/x-www-form-urlencoded" },
          body,
        });
        const provider = await response.json();
        sent = response.ok && provider?.return === true;
        requestId = provider?.request_id ?? null;
        providerMessage = Array.isArray(provider?.message)
          ? provider.message.join(" ")
          : String(provider?.message ?? (sent ? "SMS accepted." : "SMS rejected."));
      } catch {
        providerMessage = "Could not connect to Fast2SMS.";
      }
    }

    await db.from("sms_logs").insert({
      booking_id: booking.id,
      booking_code: booking.booking_code,
      mobile: ownerMobile,
      sms_type: "cash_booking_owner",
      template_id: templateId,
      status: sent ? "sent" : "failed",
      provider_request_id: requestId,
      provider_message: providerMessage,
    });
    return json({ sent, message: providerMessage });
  } catch (error) {
    return json(
      { error: error instanceof Error ? error.message : "Alert failed." },
      500,
    );
  }
});
