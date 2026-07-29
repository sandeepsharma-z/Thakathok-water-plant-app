"use server";

import { revalidatePath } from "next/cache";

import {
  sendDeliveryConfirmation,
  sendDuesReminder,
  sendOrderConfirmation,
} from "@/lib/sms";
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

export async function markAdminNotificationsRead(): Promise<void> {
  const supabase = await requireAdmin();
  const { error } = await supabase
    .from("admin_notifications")
    .update({ read_at: new Date().toISOString() })
    .is("read_at", null);
  if (error) throw error;
  revalidatePath("/");
}

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

/** Complete a confirmed booking and send its approved DLT delivery SMS. */
export async function markBookingDelivered(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const id = String(formData.get("id") ?? "");
  if (!id) return { error: "Missing booking." };

  let booking: Booking | null = null;
  try {
    const supabase = await requireAdmin();
    const { data: existing, error: readError } = await supabase
      .from("bookings")
      .select("*")
      .eq("id", id)
      .maybeSingle();
    if (readError) throw readError;
    booking = (existing as Booking) ?? null;
    if (!booking) return { error: "Booking not found." };
    if (booking.status === "delivered") {
      return { error: "This booking is already marked as delivered." };
    }
    if (booking.status !== "confirmed") {
      return { error: "Only confirmed bookings can be marked delivered." };
    }

    const { data, error } = await supabase
      .from("bookings")
      .update({ status: "delivered" })
      .eq("id", id)
      .eq("status", "confirmed")
      .select("*")
      .maybeSingle();
    if (error) throw error;
    booking = (data as Booking) ?? null;
  } catch (error) {
    return {
      error:
        error instanceof Error &&
        error.message.includes("INSUFFICIENT_CAN_STOCK")
          ? "Not enough cans are reserved. Add stock in Cans Management first."
          : "Could not mark this booking as delivered.",
    };
  }

  const sms = booking
    ? await sendDeliveryConfirmation(booking)
    : { sent: false, message: "Booking updated, but SMS was not sent." };
  revalidatePath("/", "layout");
  return sms.sent
    ? { ok: "Marked delivered and delivery SMS sent." }
    : {
        ok: `Marked delivered. SMS not sent: ${sms.message}`,
      };
}

export async function markBookingAllDone(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const id = String(formData.get("id") ?? "");
  if (!id) return { error: "Missing booking." };
  try {
    const supabase = await requireAdmin();
    const { data, error } = await supabase.rpc("mark_booking_all_done", {
      p_booking_id: id,
    });
    if (error) {
      const message = error.message.includes("PAYMENT_PENDING")
        ? "Collect the pending balance first."
        : error.message.includes("CANS_PENDING")
          ? "Record all empty can returns first."
          : error.message.includes("DELIVERY_NOT_COMPLETE")
            ? "Mark this booking as delivered first."
            : "Could not mark this booking All Done.";
      return { error: message };
    }
    revalidatePath("/", "layout");
    return (data as { already_done?: boolean })?.already_done
      ? { ok: "This booking is already All Done." }
      : { ok: "Booking marked All Done. Customer can place a new order." };
  } catch {
    return { error: "Could not mark this booking All Done." };
  }
}

export async function sendDuesReminderAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const id = String(formData.get("id") ?? "");
  if (!id) return { error: "Missing booking." };
  try {
    const supabase = await requireAdmin();
    const { data, error } = await supabase
      .from("bookings")
      .select("*")
      .eq("id", id)
      .eq("status", "confirmed")
      .gt("balance", 0)
      .maybeSingle();
    if (error) throw error;
    if (!data) return { error: "No pending balance found for this booking." };
    const result = await sendDuesReminder(data as Booking);
    revalidatePath("/pending-dues");
    return result.sent
      ? { ok: "Pending dues reminder sent." }
      : result.skipped
        ? { ok: result.message }
        : { error: result.message };
  } catch {
    return { error: "Could not send the dues reminder." };
  }
}

export async function sendBulkDuesReminders(
  _prev: ActionState,
  _formData: FormData,
): Promise<ActionState> {
  try {
    const supabase = await requireAdmin();
    const { data, error } = await supabase
      .from("bookings")
      .select("*")
      .eq("status", "confirmed")
      .gt("balance", 0);
    if (error) throw error;
    const bookings = (data ?? []) as Booking[];
    if (bookings.length === 0) {
      return { error: "There are no pending dues to remind." };
    }
    const results = await Promise.all(
      bookings.map((booking) => sendDuesReminder(booking)),
    );
    const sent = results.filter((result) => result.sent).length;
    const skipped = results.filter((result) => result.skipped).length;
    const failed = results.length - sent - skipped;
    revalidatePath("/pending-dues");
    if (sent === 0 && failed > 0) {
      return {
        error: `No SMS sent. ${failed} failed${skipped ? ` and ${skipped} were skipped` : ""}.`,
      };
    }
    return {
      ok: `${sent} reminder${sent === 1 ? "" : "s"} sent${skipped ? `, ${skipped} skipped (already sent today)` : ""}${failed ? `, ${failed} failed` : ""}.`,
    };
  } catch {
    return { error: "Could not send bulk dues reminders." };
  }
}

/** Cancel a booking and free the date again. */
export async function collectBookingBalance(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const bookingId = String(formData.get("booking_id") ?? "");
  const method = String(formData.get("method") ?? "");
  const reference = String(formData.get("reference") ?? "").trim();
  const note = String(formData.get("note") ?? "").trim();
  if (!bookingId) return { error: "Missing booking." };
  if (!["cash", "upi", "bank", "other"].includes(method)) {
    return { error: "Choose a valid collection method." };
  }
  try {
    const supabase = await requireAdmin();
    const { data, error } = await supabase.rpc("collect_booking_balance", {
      p_booking_id: bookingId,
      p_method: method,
      p_reference: reference,
      p_note: note,
    });
    if (error) throw error;
    const result = data as {
      amount?: number;
      already_collected?: boolean;
    } | null;
    revalidatePath("/", "layout");
    revalidatePath("/pending-dues");
    revalidatePath("/payments");
    revalidatePath("/bookings");
    return result?.already_collected
      ? { ok: "This balance was already collected." }
      : { ok: `Balance payment of ₹${result?.amount ?? 0} collected.` };
  } catch {
    return { error: "Could not collect this balance. Please try again." };
  }
}

export async function cancelBooking(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const id = String(formData.get("id") ?? "");
  const reason = String(formData.get("reason") ?? "").trim();
  if (!id) return { error: "Missing booking." };
  if (reason.length < 3) return { error: "Enter a cancellation reason." };

  try {
    const supabase = await requireAdmin();
    const { data, error } = await supabase.rpc("cancel_booking_by_admin", {
      p_booking_id: id,
      p_reason: reason,
    });
    if (error) {
      const message = error.message.includes("CANCELLATION_NOT_ALLOWED")
        ? "Only pending or confirmed bookings can be cancelled."
        : error.message.includes("BOOKING_NOT_FOUND")
          ? "Booking not found."
          : "Could not cancel this booking.";
      return { error: message };
    }
    const result = data as {
      already_cancelled?: boolean;
      advance_retained?: number;
    } | null;
    revalidatePath("/", "layout");
    return result?.already_cancelled
      ? { ok: "This booking is already cancelled." }
      : {
          ok: `Booking cancelled. Advance record of ₹${result?.advance_retained ?? 0} was preserved.`,
        };
  } catch {
    return { error: "Could not cancel this booking." };
  }
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
  const smsTemplateCashAlert = String(
    formData.get("sms_template_cash_alert") ?? "",
  ).trim();
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
        sms_template_cash_alert: smsTemplateCashAlert,
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
