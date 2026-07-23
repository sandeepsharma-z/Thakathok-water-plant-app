import { createClient } from "@/lib/supabase/server";

export type Profile = { name: string; email: string; avatarUrl: string | null };

/** The signed-in admin's display name + avatar, from Supabase Auth metadata. */
export async function getProfile(): Promise<Profile> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  const meta = (user?.user_metadata ?? {}) as Record<string, string>;
  const email = user?.email ?? "";
  const name =
    meta.full_name?.trim() || (email ? email.split("@")[0] : "Admin");
  const avatarUrl = meta.avatar_url || null;
  return { name, email, avatarUrl };
}
