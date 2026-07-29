"use server";

import { revalidatePath } from "next/cache";

import { createClient } from "@/lib/supabase/server";

export type HomeContentState = { ok?: string; error?: string };

async function imageUrl(
  supabase: Awaited<ReturnType<typeof createClient>>,
  formData: FormData,
  fileKey: string,
  currentKey: string,
) {
  const current = String(formData.get(currentKey) ?? "");
  const file = formData.get(fileKey);
  if (!(file instanceof File) || file.size === 0) return current;
  if (!file.type.startsWith("image/") || file.size > 5 * 1024 * 1024) {
    throw new Error("Images must be under 5 MB.");
  }
  const ext = (file.name.split(".").pop() || "png").toLowerCase();
  const path = `admin/${Date.now()}-${crypto.randomUUID()}.${ext}`;
  const { error } = await supabase.storage
    .from("home-content")
    .upload(path, file, { contentType: file.type });
  if (error) throw error;
  return supabase.storage.from("home-content").getPublicUrl(path).data.publicUrl;
}

const text = (data: FormData, key: string) =>
  String(data.get(key) ?? "").trim();
const enabled = (data: FormData, key: string) => data.get(key) === "on";

export async function updateHomeContent(
  _previous: HomeContentState,
  formData: FormData,
): Promise<HomeContentState> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { error: "Not signed in." };

  try {
    const heroCount = Math.max(
      0,
      Math.min(12, Number(formData.get("hero_count")) || 0),
    );
    const heroes = await Promise.all(
      Array.from({ length: heroCount }, async (_, index) => ({
        image_url: await imageUrl(
          supabase,
          formData,
          `hero_file_${index}`,
          `hero_current_${index}`,
        ),
        enabled: enabled(formData, `hero_enabled_${index}`),
        action: "none",
      })),
    );
    if (heroes.length === 0 || heroes.some((item) => !item.image_url)) {
      return { error: "Keep at least one hero banner with an image." };
    }
    const promos = await Promise.all(
      [0, 1].map(async (index) => ({
        image_url: await imageUrl(
          supabase,
          formData,
          `promo_file_${index}`,
          `promo_current_${index}`,
        ),
        enabled: enabled(formData, `promo_enabled_${index}`),
        action: index === 0 ? "order" : "none",
      })),
    );
    const categories = await Promise.all(
      [0, 1, 2, 3].map(async (index) => ({
        name: text(formData, `category_name_${index}`),
        image_url: await imageUrl(
          supabase,
          formData,
          `category_file_${index}`,
          `category_current_${index}`,
        ),
        event_type: text(formData, `category_event_${index}`) || "Other",
        custom_quantity: enabled(formData, `category_custom_${index}`),
        enabled: enabled(formData, `category_enabled_${index}`),
      })),
    );
    const faqs = [0, 1, 2, 3, 4]
      .map((index) => ({
        question: text(formData, `faq_question_${index}`),
        answer: text(formData, `faq_answer_${index}`),
      }))
      .filter((faq) => faq.question && faq.answer);
    const support = {
      heading: text(formData, "support_heading"),
      description: text(formData, "support_description"),
      section_title: text(formData, "support_section_title"),
      faqs,
    };
    const searchPhrases = text(formData, "search_phrases")
      .split(/\r?\n/)
      .map((item) => item.trim())
      .filter(Boolean)
      .slice(0, 10);
    const homeUi = {
      greeting_tagline: text(formData, "greeting_tagline"),
      popular_heading: text(formData, "popular_heading"),
      shop_heading: text(formData, "shop_heading"),
      search_phrases: searchPhrases,
      quick_actions: [0,1,2,3,4].map((index) => ({
        title: text(formData, `quick_title_${index}`),
        subtitle: text(formData, `quick_subtitle_${index}`),
      })),
      trust_items: [0,1,2,3].map((index) => ({
        title: text(formData, `trust_title_${index}`),
      })),
    };
    if (!homeUi.greeting_tagline || !homeUi.popular_heading ||
        !homeUi.shop_heading || searchPhrases.length === 0 ||
        homeUi.quick_actions.some((item) => !item.title || !item.subtitle) ||
        homeUi.trust_items.some((item) => !item.title)) {
      return { error: "Complete all home text, shortcut and trust-strip fields." };
    }

    if (!support.heading || !support.description || !support.section_title) {
      return { error: "Complete the support headings." };
    }

    const { error } = await supabase
      .from("settings")
      .update({
        home_hero_banners: heroes,
        home_promo_banners: promos,
        home_categories: categories,
        home_ui_content: homeUi,
        support_content: support,
        updated_at: new Date().toISOString(),
      })
      .eq("id", 1);
    if (error) throw error;
  } catch (error) {
    return {
      error:
        error instanceof Error && error.message.includes("5 MB")
          ? error.message
          : "Could not save home content. Try again.",
    };
  }

  revalidatePath("/home-content");
  return { ok: "Home screen and support content updated." };
}
