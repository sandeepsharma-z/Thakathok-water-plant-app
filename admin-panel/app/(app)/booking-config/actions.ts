"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

const text = (form: FormData, key: string) => String(form.get(key) ?? "").trim();

export async function saveBookingConfig(form: FormData) {
  const advancePercent = Number(form.get("advance_percent"));
  const eventTypes = text(form, "event_types").split(/\r?\n|,/).map((v) => v.trim()).filter(Boolean);
  const quantities = text(form, "quantities").split(/\r?\n|,/).map(Number).filter((v) => Number.isInteger(v) && v > 0);
  if (!Number.isInteger(advancePercent) || advancePercent < 1 || advancePercent > 100) throw new Error("Advance must be between 1% and 100%.");
  if (!eventTypes.length || !quantities.length) throw new Error("Add at least one event type and quantity.");
  const paymentContent = {
    advance_warning: text(form, "advance_warning"),
    cash_heading: text(form, "cash_heading"),
    cash_step_1: text(form, "cash_step_1"),
    cash_step_2: text(form, "cash_step_2"),
    cash_step_3: text(form, "cash_step_3"),
    cash_notice: text(form, "cash_notice"),
    cash_button: text(form, "cash_button"),
    confirmed_message: text(form, "confirmed_message"),
    pending_message: text(form, "pending_message"),
    non_refundable_note: text(form, "non_refundable_note"),
  };
  if (Object.values(paymentContent).some((value) => !value)) throw new Error("Complete every payment instruction field.");
  const db = await createClient();
  const { error } = await db.from("settings").update({
    advance_percent: advancePercent,
    booking_event_types: eventTypes,
    booking_quantity_options: [...new Set(quantities)].sort((a,b)=>a-b),
    payment_content: paymentContent,
    updated_at: new Date().toISOString(),
  }).eq("id", 1);
  if (error) throw error;
  revalidatePath("/booking-config");
}

