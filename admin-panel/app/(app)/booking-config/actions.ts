"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

const text = (form: FormData, key: string) => String(form.get(key) ?? "").trim();

export async function saveBookingConfig(form: FormData) {
  const advancePercent = Number(form.get("advance_percent"));
  const minimumNoticeMinutes = Number(form.get("minimum_notice_minutes"));
  const maxCansPerDay = Number(form.get("max_cans_per_day"));
  const emptyCanReturnHours = Number(form.get("empty_can_return_hours"));
  const lostDamagedCanCharge = Number(form.get("lost_damaged_can_charge"));
  const eventTypes = text(form, "event_types").split(/\r?\n|,/).map((v) => v.trim()).filter(Boolean);
  const quantities = text(form, "quantities").split(/\r?\n|,/).map(Number).filter((v) => Number.isInteger(v) && v > 0);
  if (!Number.isInteger(advancePercent) || advancePercent < 1 || advancePercent > 100) throw new Error("Advance must be between 1% and 100%.");
  if (![30,60,120,180].includes(minimumNoticeMinutes)) throw new Error("Choose a valid minimum notice.");
  if (!Number.isInteger(maxCansPerDay) || maxCansPerDay < 1) throw new Error("Daily can limit must be at least 1.");
  if (!Number.isInteger(emptyCanReturnHours) || emptyCanReturnHours < 1) throw new Error("Return window must be at least 1 hour.");
  if (!Number.isInteger(lostDamagedCanCharge) || lostDamagedCanCharge < 0) throw new Error("Lost/damaged charge cannot be negative.");
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
    minimum_notice_minutes: minimumNoticeMinutes,
    max_cans_per_day: maxCansPerDay,
    empty_can_return_hours: emptyCanReturnHours,
    lost_damaged_can_charge: lostDamagedCanCharge,
    booking_event_types: eventTypes,
    booking_quantity_options: [...new Set(quantities)].sort((a,b)=>a-b),
    payment_content: paymentContent,
    updated_at: new Date().toISOString(),
  }).eq("id", 1);
  if (error) throw error;
  revalidatePath("/booking-config");
}

