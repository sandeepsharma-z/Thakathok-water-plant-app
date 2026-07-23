"use server";

import { revalidatePath } from "next/cache";

import { createClient } from "@/lib/supabase/server";

export type ProfileState = { ok?: string; error?: string };

export async function updateProfile(
  _prev: ProfileState,
  formData: FormData,
): Promise<ProfileState> {
  const name = String(formData.get("name") ?? "").trim();
  if (!name) return { error: "Enter your name." };

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { error: "Not signed in." };

  const meta: Record<string, string> = { full_name: name };

  const file = formData.get("avatar");
  if (file instanceof File && file.size > 0) {
    if (file.size > 3 * 1024 * 1024) {
      return { error: "Image too large — keep it under 3 MB." };
    }
    const ext = (file.name.split(".").pop() || "png").toLowerCase();
    const path = `${user.id}/${Date.now()}.${ext}`;
    const { error: upErr } = await supabase.storage
      .from("avatars")
      .upload(path, file, { upsert: true, contentType: file.type });
    if (upErr) return { error: "Could not upload the image. Try again." };

    const { data: pub } = supabase.storage.from("avatars").getPublicUrl(path);
    meta.avatar_url = pub.publicUrl;
  }

  const { error } = await supabase.auth.updateUser({ data: meta });
  if (error) return { error: "Could not save. Try again." };

  revalidatePath("/", "layout");
  return { ok: "Profile updated." };
}
