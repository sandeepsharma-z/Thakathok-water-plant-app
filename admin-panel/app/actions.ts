"use server";

import { revalidatePath } from "next/cache";

import { createClient } from "@/lib/supabase/server";

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

/** Mark a booking confirmed — used once the cash advance is received. */
export async function confirmBooking(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const id = String(formData.get("id") ?? "");
  if (!id) return { error: "Missing booking." };

  try {
    const supabase = await requireAdmin();
    const { error } = await supabase
      .from("bookings")
      .update({ status: "confirmed" })
      .eq("id", id);
    if (error) throw error;
  } catch {
    return { error: "Could not confirm. Please try again." };
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

/** Update the admin-controlled pricing. */
export async function updateSettings(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const perCanRate = Number(formData.get("per_can_rate"));
  const deliveryCharge = Number(formData.get("delivery_charge"));

  if (!Number.isFinite(perCanRate) || perCanRate <= 0) {
    return { error: "Enter a valid per-can rate." };
  }
  if (!Number.isFinite(deliveryCharge) || deliveryCharge < 0) {
    return { error: "Delivery charge must be 0 or more." };
  }

  try {
    const supabase = await requireAdmin();
    const { error } = await supabase
      .from("settings")
      .update({
        per_can_rate: Math.round(perCanRate),
        delivery_charge: Math.round(deliveryCharge),
        updated_at: new Date().toISOString(),
      })
      .eq("id", 1);
    if (error) throw error;
  } catch {
    return { error: "Could not save. Please try again." };
  }

  revalidatePath("/", "layout");
  return { ok: "Rates updated." };
}
