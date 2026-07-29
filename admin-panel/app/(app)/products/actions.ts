"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export type ProductState = { ok?: string; error?: string };
const text = (data: FormData, key: string) =>
  String(data.get(key) ?? "").trim();

export async function updateProducts(
  _previous: ProductState,
  formData: FormData,
): Promise<ProductState> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { error: "Not signed in." };

  try {
    const count = Math.max(0, Math.min(20, Number(formData.get("count")) || 0));
    const products = await Promise.all(
      Array.from({ length: count }, async (_, index) => {
        let imageUrl = text(formData, `current_${index}`);
        const file = formData.get(`file_${index}`);
        if (file instanceof File && file.size > 0) {
          if (!file.type.startsWith("image/") || file.size > 5 * 1024 * 1024) {
            throw new Error("Images must be under 5 MB.");
          }
          const ext = (file.name.split(".").pop() || "png").toLowerCase();
          const path = `products/${Date.now()}-${crypto.randomUUID()}.${ext}`;
          const { error } = await supabase.storage
            .from("home-content")
            .upload(path, file, { contentType: file.type });
          if (error) throw error;
          imageUrl = supabase.storage
            .from("home-content")
            .getPublicUrl(path).data.publicUrl;
        }
        const cansRaw = text(formData, `cans_${index}`);
        return {
          name: text(formData, `name_${index}`),
          quantity_label: text(formData, `quantity_${index}`),
          cans: cansRaw ? Number(cansRaw) : null,
          image_url: imageUrl,
          description: text(formData, `description_${index}`),
          ideal_for: text(formData, `ideal_${index}`),
          enabled: formData.get(`enabled_${index}`) === "on",
        };
      }),
    );
    if (
      products.length === 0 ||
      products.some(
        (item) =>
          !item.name ||
          !item.quantity_label ||
          !item.image_url ||
          !item.description ||
          !item.ideal_for ||
          (item.cans !== null &&
            (!Number.isInteger(item.cans) || item.cans <= 0)),
      )
    ) {
      return { error: "Complete every product field with valid values." };
    }
    const { error } = await supabase
      .from("settings")
      .update({ home_products: products, updated_at: new Date().toISOString() })
      .eq("id", 1);
    if (error) throw error;
  } catch (error) {
    return {
      error:
        error instanceof Error && error.message.includes("5 MB")
          ? error.message
          : "Could not save products.",
    };
  }
  revalidatePath("/products");
  return { ok: "Products updated in the customer app." };
}
