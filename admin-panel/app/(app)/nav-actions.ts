"use server";

import { revalidatePath } from "next/cache";

import { createClient } from "@/lib/supabase/server";

export async function markNavSectionSeen(section: "orders" | "customers") {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return;
  await supabase.from("admin_nav_reads").upsert(
    {
      user_id: user.id,
      section,
      last_seen_at: new Date().toISOString(),
    },
    { onConflict: "user_id,section" },
  );
  revalidatePath("/", "layout");
}

