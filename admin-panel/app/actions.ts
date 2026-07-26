"use server";

import { revalidatePath } from "next/cache";

import { sendOrderConfirmation } from "@/lib/sms";
import { createClient } from "@/lib/supabase/server";
import type { Booking } from "@/lib/types";

/** Guard every mutation at the data source, not just in the proxy. */
async function requireAdmin() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) throw new Error("Not signed in");
  return supabase;
}

export type ActionState = { ok?: string; error?: string };

export async function toggleOfferVisibility(
  enabled: boolean,
): Promise<ActionState> {
  try {
    const supabase = await requireAdmin();
    const { error } = await supabase
      .from("settings")
      .update({
        offer_enabled: enabled,
        updated_at: new Date().toISOString(),
      })
      .eq("id", 1);
    if (error) throw error;
  } catch {
    return { error: "Could not update offer visibility. Try again." };
  }

  revalidatePath("/settings");
  return {
    ok: enabled
      ? "Offer is now shown on the customer app."
      : "Offer is now hidden from the customer app.",
  };
}

/** Mark a booking confirmed — used once the cash advance is received. */
export async function confirmBooking(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const id = String(formData.get("id") ?? "");
  if (!id) return { error: "Missing booking." };

  let booking: Booking | null = null;
  try {
    const supabase = await requireAdmin();
    const { data, error } = await supabase
      .from("bookings")
      .update({ status: "confirmed" })
      .eq("id", id)
      .select("*")
      .maybeSingle();
    if (error) throw error;
    booking = (data as Booking) ?? null;
  } catch {
    return { error: "Could not confirm. Please try again." };
  }

  // Fire the Order Confirmation SMS (best-effort — never blocks the confirm).
  if (booking) {
    try {
      await sendOrderConfirmation(booking);
    } catch {
      /* SMS failure must not fail the confirmation */
    }
  }

  revalidatePath("/", "layout");
  return { ok: "Booking confirmed." };
}

/** Cancel a booking and free the date again. */
export async function cancelBooking(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const id = String(formData.get("id") ?? "");
  if (!id) return { error: "Missing booking." };

  try {
    const supabase = await requireAdmin();
    const { error } = await supabase
      .from("bookings")
      .update({ status: "cancelled" })
      .eq("id", id);
    if (error) throw error;
  } catch {
    return { error: "Could not cancel. Please try again." };
  }

  revalidatePath("/", "layout");
  return { ok: "Booking cancelled." };
}

/** Save/edit a customer's name & note (keyed by mobile). */
export async function saveCustomer(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const mobile = String(formData.get("mobile") ?? "").replace(/\D/g, "");
  const name = String(formData.get("name") ?? "").trim();
  const note = String(formData.get("note") ?? "").trim();
  if (mobile.length < 10) return { error: "Invalid mobile." };

  try {
    const supabase = await requireAdmin();
    const { error } = await supabase.from("customers").upsert(
      { mobile, name, note, updated_at: new Date().toISOString() },
      { onConflict: "mobile" },
    );
    if (error) throw error;
  } catch {
    return { error: "Could not save. Please try again." };
  }

  revalidatePath("/", "layout");
  return { ok: "Saved." };
}

/** Delete a customer's saved profile (name/note). Bookings are untouched. */
export async function deleteCustomer(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const mobile = String(formData.get("mobile") ?? "").replace(/\D/g, "");
  if (mobile.length < 10) return { error: "Invalid mobile." };

  try {
    const supabase = await requireAdmin();
    const { error } = await supabase
      .from("customers")
      .delete()
      .eq("mobile", mobile);
    if (error) throw error;
  } catch {
    return { error: "Could not delete. Please try again." };
  }

  revalidatePath("/", "layout");
  return { ok: "Customer removed." };
}

/** Update the admin-controlled pricing. */
export async function updateSettings(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const perCanRate = Number(formData.get("per_can_rate"));
  const deliveryCharge = Number(formData.get("delivery_charge"));
  // Contact + integration keys — the owner manages these herself.
  const contactRaw = String(formData.get("plant_phone") ?? "").trim();
  const contactDigits = contactRaw.replace(/\D/g, "");
  const razorpayKeyId = String(formData.get("razorpay_key_id") ?? "").trim();
  const razorpayKeySecret = String(
    formData.get("razorpay_key_secret") ?? "",
  ).trim();
  const fast2smsApiKey = String(formData.get("fast2sms_api_key") ?? "").trim();
  const smsTemplateOrder = String(
    formData.get("sms_template_order") ?? "",
  ).trim();
  const smsTemplateDelivery = String(
    formData.get("sms_template_delivery") ?? "",
  ).trim();
  const smsTemplateDues = String(formData.get("sms_template_dues") ?? "").trim();
  const offerEnabled = formData.get("offer_enabled") === "on";
  const offerTitle = String(formData.get("offer_title") ?? "").trim();
  const offerDescription = String(
    formData.get("offer_description") ?? "",
  ).trim();
  const offerCode = String(formData.get("offer_code") ?? "")
    .trim()
    .toUpperCase();
  const offerDiscountPercent = Number(
    formData.get("offer_discount_percent"),
  );
  const offerMinSubtotal = Number(formData.get("offer_min_subtotal"));

  if (!Number.isFinite(perCanRate) || perCanRate <= 0) {
    return { error: "Enter a valid per-can rate." };
  }
  if (!Number.isFinite(deliveryCharge) || deliveryCharge < 0) {
    return { error: "Delivery charge must be 0 or more." };
  }
  if (contactDigits.length < 10 || contactDigits.length > 12) {
    return { error: "Enter a valid contact number (10 digits)." };
  }
  if (!offerTitle || !offerDescription || !offerCode) {
    return { error: "Complete all Weekend Splash offer fields." };
  }
  if (
    !Number.isInteger(offerDiscountPercent) ||
    offerDiscountPercent < 1 ||
    offerDiscountPercent > 100
  ) {
    return { error: "Offer discount must be between 1% and 100%." };
  }
  if (!Number.isInteger(offerMinSubtotal) || offerMinSubtotal < 0) {
    return { error: "Offer minimum subtotal must be 0 or more." };
  }

  try {
    const supabase = await requireAdmin();
    const { error } = await supabase
      .from("settings")
      .update({
        per_can_rate: Math.round(perCanRate),
        delivery_charge: Math.round(deliveryCharge),
        plant_phone: contactDigits,
        razorpay_key_id: razorpayKeyId,
        razorpay_key_secret: razorpayKeySecret,
        fast2sms_api_key: fast2smsApiKey,
        sms_template_order: smsTemplateOrder,
        sms_template_delivery: smsTemplateDelivery,
        sms_template_dues: smsTemplateDues,
        offer_enabled: offerEnabled,
        offer_title: offerTitle,
        offer_description: offerDescription,
        offer_code: offerCode,
        offer_discount_percent: offerDiscountPercent,
        offer_min_subtotal: offerMinSubtotal,
        updated_at: new Date().toISOString(),
      })
      .eq("id", 1);
    if (error) throw error;
  } catch {
    return { error: "Could not save. Please try again." };
  }

  revalidatePath("/", "layout");
  return { ok: "Settings saved." };
}
