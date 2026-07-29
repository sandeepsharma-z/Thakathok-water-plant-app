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
    const url = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const auth = request.headers.get("Authorization") ?? "";
    const admin = createClient(url, serviceKey);
    const caller = createClient(url, Deno.env.get("SUPABASE_ANON_KEY")!, {
      global: { headers: { Authorization: auth } },
    });
    const { data: { user } } = await caller.auth.getUser();
    if (!user) return json({ error: "Not signed in" }, 401);

    const { data: staff } = await admin
      .from("delivery_staff")
      .select("id,enabled")
      .eq("user_id", user.id)
      .maybeSingle();
    if (!staff?.enabled) return json({ error: "Staff access required" }, 403);

    const input = await request.json();
    const bookingId = String(input.booking_id ?? "");
    if (!bookingId) return json({ error: "Missing booking" }, 400);

    const [{ data: booking }, { data: settings }] = await Promise.all([
      admin
        .from("bookings")
        .select("id,booking_code,customer_name,mobile,balance,status,assigned_staff_id")
        .eq("id", bookingId)
        .eq("assigned_staff_id", staff.id)
        .eq("status", "delivered")
        .maybeSingle(),
      admin
        .from("settings")
        .select("fast2sms_api_key,sms_template_delivery")
        .eq("id", 1)
        .maybeSingle(),
    ]);
    if (!booking) return json({ error: "Assigned delivered booking not found" }, 404);

    const { data: existing } = await admin
      .from("sms_logs")
      .select("id")
      .eq("booking_id", booking.id)
      .eq("sms_type", "delivery_confirmation")
      .eq("status", "sent")
      .limit(1)
      .maybeSingle();
    if (existing) return json({ sent: false, skipped: true });

    const apiKey = String(settings?.fast2sms_api_key ?? "").trim();
    const templateId = String(settings?.sms_template_delivery ?? "").trim();
    const mobile = localNumber(booking.mobile);
    let sent = false;
    let providerMessage = "";
    let requestId: string | null = null;

    if (!apiKey || !templateId || mobile.length !== 10) {
      providerMessage = "Fast2SMS key, delivery template or customer mobile is missing.";
    } else {
      const response = await fetch("https://www.fast2sms.com/dev/bulkV2", {
        method: "POST",
        headers: {
          authorization: apiKey,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          route: "dlt",
          sender_id: "MAHWAP",
          message: templateId,
          variables_values:
            [booking.customer_name || "Customer", booking.balance ?? 0].join("|") + "|",
          numbers: mobile,
          flash: "0",
        }),
      });
      const provider = await response.json();
      sent = response.ok && provider?.return === true;
      requestId = provider?.request_id ?? null;
      providerMessage = Array.isArray(provider?.message)
        ? provider.message.join(" ")
        : String(provider?.message ?? (sent ? "SMS accepted." : "SMS rejected."));
    }

    await admin.from("sms_logs").insert({
      booking_id: booking.id,
      booking_code: booking.booking_code,
      mobile,
      sms_type: "delivery_confirmation",
      template_id: templateId,
      status: sent ? "sent" : "failed",
      provider_request_id: requestId,
      provider_message: providerMessage,
    });
    return json({ sent, message: providerMessage });
  } catch (error) {
    return json(
      { error: error instanceof Error ? error.message : "Delivery SMS failed" },
      500,
    );
  }
});
