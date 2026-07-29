"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

const text = (f: FormData, key: string) => String(f.get(key) ?? "").trim();
const num = (f: FormData, key: string) => Number(f.get(key) ?? 0);
const refresh = (...paths: string[]) => paths.forEach((p) => revalidatePath(p));

export async function saveVillage(form: FormData) {
  const db = await createClient();
  const id = text(form, "id");
  const row = {
    name: text(form, "name"),
    branch_id: text(form, "branch_id") || null,
    delivery_charge: text(form, "delivery_charge") === "" ? null : num(form, "delivery_charge"),
    enabled: form.get("enabled") === "on",
    sort_order: num(form, "sort_order"),
    updated_at: new Date().toISOString(),
  };
  if (!row.name) return;
  if (id) await db.from("villages").update(row).eq("id", id);
  else await db.from("villages").insert(row);
  refresh("/villages", "/");
}

export async function deleteVillage(form: FormData) {
  const db = await createClient();
  await db.from("villages").delete().eq("id", text(form, "id"));
  refresh("/villages", "/");
}

export async function saveBranch(form: FormData) {
  const db = await createClient();
  const id = text(form, "id");
  const row = {
    name: text(form, "name"), code: text(form, "code").toUpperCase(),
    address: text(form, "address"), phone: text(form, "phone").replace(/\D/g, ""),
    manager_name: text(form, "manager_name"), enabled: form.get("enabled") === "on",
    updated_at: new Date().toISOString(),
  };
  if (!row.name || !row.code) return;
  if (id) await db.from("branches").update(row).eq("id", id);
  else {
    const { data } = await db.from("branches").insert(row).select("id").single();
    if (data) await db.from("can_inventory").insert({ branch_id: data.id });
  }
  refresh("/branches", "/cans", "/villages");
}

export async function deleteBranch(form: FormData) {
  const db = await createClient();
  await db.from("branches").delete().eq("id", text(form, "id"));
  refresh("/branches", "/cans", "/villages");
}

export async function saveInventory(form: FormData) {
  const db = await createClient();
  const branch_id = text(form, "branch_id");
  await db.from("can_inventory").upsert({
    branch_id,
    total_cans: num(form, "total_cans"),
    available_cans: num(form, "available_cans"),
    out_for_delivery: num(form, "out_for_delivery"),
    damaged_cans: num(form, "damaged_cans"),
    updated_at: new Date().toISOString(),
  }, { onConflict: "branch_id" });
  refresh("/cans", "/reports");
}

export type InventoryActionState = { ok?: string; error?: string };

export async function adjustCanInventory(
  _previous: InventoryActionState,
  form: FormData,
): Promise<InventoryActionState> {
  const db = await createClient();
  const branchId = text(form, "branch_id");
  const action = text(form, "action");
  const quantity = num(form, "quantity");
  const note = text(form, "note");
  if (!branchId || !["add", "remove", "damage", "repair"].includes(action)) {
    return { error: "Choose a valid branch and adjustment." };
  }
  if (!Number.isInteger(quantity) || quantity <= 0) {
    return { error: "Enter a valid can quantity." };
  }
  const { error } = await db.rpc("adjust_can_inventory", {
    p_branch_id: branchId,
    p_action: action,
    p_quantity: quantity,
    p_note: note,
  });
  if (error) {
    const message = error.message.includes("INSUFFICIENT_AVAILABLE")
      ? "Not enough available cans for this adjustment."
      : error.message.includes("INSUFFICIENT_DAMAGED")
        ? "Not enough damaged cans to repair."
        : "Could not update can inventory.";
    return { error: message };
  }
  refresh("/cans", "/reports", "/bookings");
  return { ok: "Inventory updated and waiting bookings rechecked." };
}

export async function recordCanReturn(
  _previous: InventoryActionState,
  form: FormData,
): Promise<InventoryActionState> {
  const db = await createClient();
  const bookingId = text(form, "booking_id");
  const returned = num(form, "returned");
  const damaged = num(form, "damaged");
  const note = text(form, "note");
  if (
    !bookingId ||
    !Number.isInteger(returned) ||
    !Number.isInteger(damaged) ||
    returned < 0 ||
    damaged < 0 ||
    returned + damaged <= 0
  ) {
    return { error: "Enter returned or damaged can quantity." };
  }
  const { error } = await db.rpc("record_can_return", {
    p_booking_id: bookingId,
    p_returned: returned,
    p_damaged: damaged,
    p_note: note,
  });
  if (error) {
    const message = error.message.includes("EXCEEDS_PENDING_CANS")
      ? "Return quantity is higher than the pending cans."
      : "Could not record this return.";
    return { error: message };
  }
  refresh("/cans", "/reports", "/bookings");
  return { ok: "Can return recorded successfully." };
}

export async function saveExpense(form: FormData) {
  const db = await createClient();
  const id = text(form, "id");
  const row = {
    branch_id: text(form, "branch_id") || null, category: text(form, "category"),
    amount: num(form, "amount"), expense_date: text(form, "expense_date"),
    description: text(form, "description"), updated_at: new Date().toISOString(),
  };
  if (!row.category || row.amount <= 0) return;
  if (id) await db.from("expenses").update(row).eq("id", id);
  else await db.from("expenses").insert(row);
  refresh("/expenses", "/reports");
}

export async function deleteExpense(form: FormData) {
  const db = await createClient();
  await db.from("expenses").delete().eq("id", text(form, "id"));
  refresh("/expenses", "/reports");
}
