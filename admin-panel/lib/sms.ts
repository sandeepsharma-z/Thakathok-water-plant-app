import { createClient } from "@/lib/supabase/server";
import type { Booking } from "@/lib/types";

// Fast2SMS DLT (Route) endpoint. The API key + template IDs live in the
// `settings` row and are read server-side only — never exposed to the client.
const FAST2SMS_URL = "https://www.fast2sms.com/dev/bulkV2";
const SENDER_ID = "MAHWAP";

interface SmsSettings {
  fast2sms_api_key: string;
  sms_template_order: string;
  sms_template_delivery: string;
  sms_template_dues: string;
  plant_phone: string;
}

async function getSmsSettings(): Promise<SmsSettings | null> {
  const supabase = await createClient();
  const { data } = await supabase
    .from("settings")
    .select(
      "fast2sms_api_key, sms_template_order, sms_template_delivery, sms_template_dues, plant_phone",
    )
    .eq("id", 1)
    .maybeSingle();
  return (data as SmsSettings) ?? null;
}

/** 10-digit Indian mobile for Fast2SMS (strips +91 / spaces). */
function toLocalNumber(raw: string): string {
  const d = (raw ?? "").replace(/\D/g, "");
  return d.length > 10 ? d.slice(-10) : d;
}

export interface SmsSendResult {
  sent: boolean;
  skipped?: boolean;
  message: string;
}

interface ProviderResult extends SmsSendResult {
  requestId?: string;
}

/** Low-level DLT send. */
async function sendDlt(
  apiKey: string,
  templateId: string,
  numbers: string,
  variables: (string | number)[],
): Promise<ProviderResult> {
  if (!apiKey) {
    return { sent: false, message: "Fast2SMS API key is not configured." };
  }
  if (!templateId || !numbers) {
    return { sent: false, message: "SMS template or mobile number is missing." };
  }
  const body = {
    route: "dlt",
    sender_id: SENDER_ID,
    message: templateId,
    variables_values: variables.map((v) => String(v)).join("|") + "|",
    numbers,
    flash: "0",
  };
  try {
    const res = await fetch(FAST2SMS_URL, {
      method: "POST",
      headers: {
        authorization: apiKey.trim(),
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    });
    const json = (await res.json()) as {
      return?: boolean;
      request_id?: string;
      message?: string | string[];
    };
    const message = Array.isArray(json.message)
      ? json.message.join(" ")
      : String(json.message ?? "");
    return {
      sent: res.ok && json.return === true,
      requestId: json.request_id,
      message:
        message ||
        (res.ok && json.return === true
          ? "SMS accepted by Fast2SMS."
          : "Fast2SMS rejected the SMS."),
    };
  } catch {
    return { sent: false, message: "Could not connect to Fast2SMS." };
  }
}

async function wasRecentlySent(
  bookingId: string,
  smsType: string,
  withinHours?: number,
) {
  const supabase = await createClient();
  let query = supabase
    .from("sms_logs")
    .select("id")
    .eq("booking_id", bookingId)
    .eq("sms_type", smsType)
    .eq("status", "sent");
  if (withinHours) {
    query = query.gte(
      "created_at",
      new Date(Date.now() - withinHours * 60 * 60 * 1000).toISOString(),
    );
  }
  const { data } = await query.limit(1).maybeSingle();
  return Boolean(data);
}

async function logSms(
  booking: Booking,
  smsType: string,
  templateId: string,
  result: ProviderResult,
) {
  const supabase = await createClient();
  await supabase.from("sms_logs").insert({
    booking_id: booking.id,
    booking_code: booking.booking_code,
    mobile: toLocalNumber(booking.mobile),
    sms_type: smsType,
    template_id: templateId,
    status: result.skipped ? "skipped" : result.sent ? "sent" : "failed",
    provider_request_id: result.requestId ?? null,
    provider_message: result.message,
  });
}

async function sendBookingSms(
  booking: Booking,
  smsType: "order_confirmation" | "delivery_confirmation" | "dues_reminder",
  templateId: string,
  apiKey: string,
  variables: (string | number)[],
  duplicateWindowHours?: number,
): Promise<SmsSendResult> {
  if (
    await wasRecentlySent(booking.id, smsType, duplicateWindowHours)
  ) {
    const result: ProviderResult = {
      sent: false,
      skipped: true,
      message:
        smsType === "dues_reminder"
          ? "A dues reminder was already sent in the last 24 hours."
          : "This SMS was already sent.",
    };
    await logSms(booking, smsType, templateId, result);
    return result;
  }
  const result = await sendDlt(
    apiKey,
    templateId,
    toLocalNumber(booking.mobile),
    variables,
  );
  await logSms(booking, smsType, templateId, result);
  return result;
}

/**
 * Order Confirmation → customer.
 * Approved DLT variables: Customer name, Booking ID.
 * Best-effort: returns false silently if keys/templates aren't configured yet.
 */
export async function sendOrderConfirmation(
  b: Booking,
): Promise<SmsSendResult> {
  const s = await getSmsSettings();
  if (!s) return { sent: false, message: "SMS settings are unavailable." };
  return sendBookingSms(
    b,
    "order_confirmation",
    s.sms_template_order,
    s.fast2sms_api_key,
    [b.customer_name, b.booking_code],
  );
}

/**
 * Delivery Confirmation → customer.
 * Approved DLT variables: Customer name, Pending amount.
 */
export async function sendDeliveryConfirmation(
  b: Booking,
): Promise<SmsSendResult> {
  const s = await getSmsSettings();
  if (!s) return { sent: false, message: "SMS settings are unavailable." };
  return sendBookingSms(
    b,
    "delivery_confirmation",
    s.sms_template_delivery,
    s.fast2sms_api_key,
    [b.customer_name, b.balance],
  );
}

/**
 * Pending Dues Reminder → customer.
 * Approved DLT variables: Customer name, Pending amount.
 */
export async function sendDuesReminder(
  b: Booking,
): Promise<SmsSendResult> {
  const s = await getSmsSettings();
  if (!s) return { sent: false, message: "SMS settings are unavailable." };
  return sendBookingSms(
    b,
    "dues_reminder",
    s.sms_template_dues,
    s.fast2sms_api_key,
    [b.customer_name, b.balance],
    24,
  );
}
