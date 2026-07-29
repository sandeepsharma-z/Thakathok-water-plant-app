type DatabaseClient = {
  from: (table: string) => any;
};

const FAST2SMS_URL = "https://www.fast2sms.com/dev/bulkV2";

/**
 * Sends the approved Order Confirmation DLT template after a server-verified
 * online/wallet booking. SMS failure never rolls back a successful payment.
 */
export async function sendImmediateOrderConfirmation(
  db: DatabaseClient,
  bookingId: string,
) {
  try {
    const [{ data: booking }, { data: settings }, { data: existing }] =
      await Promise.all([
        db
          .from("bookings")
          .select("id,booking_code,customer_name,mobile")
          .eq("id", bookingId)
          .maybeSingle(),
        db
          .from("settings")
          .select("fast2sms_api_key,sms_template_order")
          .eq("id", 1)
          .maybeSingle(),
        db
          .from("sms_logs")
          .select("id")
          .eq("booking_id", bookingId)
          .eq("sms_type", "order_confirmation")
          .eq("status", "sent")
          .limit(1)
          .maybeSingle(),
      ]);
    if (!booking || existing) return;

    const apiKey = String(settings?.fast2sms_api_key ?? "").trim();
    const templateId = String(settings?.sms_template_order ?? "").trim();
    const mobile = String(booking.mobile ?? "").replace(/\D/g, "").slice(-10);
    if (!apiKey || !templateId || mobile.length !== 10) return;

    const response = await fetch(FAST2SMS_URL, {
      method: "POST",
      headers: {
        authorization: apiKey,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        route: "dlt",
        sender_id: "MAHWAP",
        message: templateId,
        // Approved template 221676: Customer name | Booking ID.
        variables_values:
          `${booking.customer_name}|${booking.booking_code}|`,
        numbers: mobile,
        flash: "0",
      }),
    });
    const provider = await response.json();
    const sent = response.ok && provider?.return === true;
    const message = Array.isArray(provider?.message)
      ? provider.message.join(" ")
      : String(provider?.message ?? "");
    await db.from("sms_logs").insert({
      booking_id: booking.id,
      booking_code: booking.booking_code,
      mobile,
      sms_type: "order_confirmation",
      template_id: templateId,
      status: sent ? "sent" : "failed",
      provider_request_id: provider?.request_id ?? null,
      provider_message:
        message || (sent ? "SMS accepted by Fast2SMS." : "SMS rejected."),
    });
  } catch {
    // Payment/booking is authoritative; SMS is best-effort and logged when possible.
  }
}
