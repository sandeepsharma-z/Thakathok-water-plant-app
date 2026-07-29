"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export async function blockDate(formData: FormData) {
  const blockedDate = String(formData.get("blocked_date") ?? "");
  const reason = String(formData.get("reason") ?? "").trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(blockedDate)) return;
  const db = await createClient();
  const { error } = await db.from("blocked_dates").insert({
    blocked_date: blockedDate,
    reason: reason || "Unavailable",
    source: "manual",
  });
  if (error) throw new Error(
    error.message.includes("duplicate")
      ? "This date is already blocked."
      : "Could not block this date.",
  );
  revalidatePath("/calendar");
}

export async function unblockDate(formData: FormData) {
  const blockedDate = String(formData.get("blocked_date") ?? "");
  if (!/^\d{4}-\d{2}-\d{2}$/.test(blockedDate)) return;
  const db = await createClient();
  const { error } = await db
    .from("blocked_dates")
    .delete()
    .eq("blocked_date", blockedDate)
    .eq("source", "manual");
  if (error) throw new Error("Could not unblock this date.");
  revalidatePath("/calendar");
}

