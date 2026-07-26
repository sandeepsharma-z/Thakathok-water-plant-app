import { createAdminClient } from "@/lib/supabase/admin";
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
  const supabase = createAdminClient();
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

/** Low-level DLT send. Returns true on Fast2SMS success. */
async function sendDlt(
  apiKey: string,
  templateId: string,
  numbers: string,
  variables: (string | number)[],
): Promise<boolean> {
  if (!apiKey || !templateId || !numbers) return false;
  const body = new URLSearchParams({
    authorization: apiKey,
    route: "dlt",
    sender_id: SENDER_ID,
    message: templateId,
    variables_values: variables.map((v) => String(v)).join("|") + "|",
    numbers,
    flash: "0",
  });
  try {
    const res = await fetch(FAST2SMS_URL, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body,
    });
    const json = (await res.json()) as { return?: boolean };
    return json.return === true;
  } catch {
    return false;
  }
}

/**
 * Order Confirmation → customer. Variables: Booking ID, Cans, Date, Balance.
 * Best-effort: returns false silently if keys/templates aren't configured yet.
 */
export async function sendOrderConfirmation(b: Booking): Promise<boolean> {
  const s = await getSmsSettings();
  if (!s) return false;
  return sendDlt(s.fast2sms_api_key, s.sms_template_order, toLocalNumber(b.mobile), [
    b.booking_code,
    b.cans,
    b.event_date,
    b.balance,
  ]);
}

/** Delivery Confirmation → customer. Variables: Booking ID, Cans, Contact. */
export async function sendDeliveryConfirmation(b: Booking): Promise<boolean> {
  const s = await getSmsSettings();
  if (!s) return false;
  return sendDlt(
    s.fast2sms_api_key,
    s.sms_template_delivery,
    toLocalNumber(b.mobile),
    [b.booking_code, b.cans, s.plant_phone],
  );
}

/** Pending Dues Reminder → customer. Variables: Balance, Booking ID. */
export async function sendDuesReminder(b: Booking): Promise<boolean> {
  const s = await getSmsSettings();
  if (!s) return false;
  return sendDlt(s.fast2sms_api_key, s.sms_template_dues, toLocalNumber(b.mobile), [
    b.balance,
    b.booking_code,
  ]);
}
