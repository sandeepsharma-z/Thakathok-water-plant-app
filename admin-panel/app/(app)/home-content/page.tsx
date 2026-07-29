import {
  HomeContentForm,
  type HomeContentData,
} from "@/components/home-content-form";
import { Card, EmptyState } from "@/components/ui";
import { createClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export default async function HomeContentPage() {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("settings")
    .select(
      "home_hero_banners,home_promo_banners,home_products,home_categories,support_content,home_ui_content,booking_event_types",
    )
    .eq("id", 1)
    .maybeSingle();

  return (
    <>
      <header>
        <h1 className="text-[27px] font-extrabold tracking-tight text-ink">
          Home Screen
        </h1>
        <p className="mt-1 text-[13px] text-ink-muted">
          Manage customer-app banners, categories and support content.
        </p>
      </header>
      {error || !data ? (
        <Card className="mt-6">
          <EmptyState
            icon="alert"
            title="Could not load home content"
            body="Apply the latest Supabase schema, then reload this page."
          />
        </Card>
      ) : (
        <HomeContentForm content={data as unknown as HomeContentData} />
      )}
    </>
  );
}
