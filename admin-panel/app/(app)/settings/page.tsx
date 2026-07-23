import { SettingsForm } from "@/components/settings-form";
import { Card, EmptyState } from "@/components/ui";
import { createClient } from "@/lib/supabase/server";
import type { Settings } from "@/lib/types";

export const dynamic = "force-dynamic";

export default async function SettingsPage() {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("settings")
    .select("*")
    .eq("id", 1)
    .maybeSingle();

  return (
    <>
      <header>
        <h1 className="text-[27px] font-extrabold tracking-tight text-ink">
          Rates &amp; Charges
        </h1>
        <p className="mt-1 text-[13px] text-ink-muted">
          Only you can change these. Customers see the rate but cannot edit it.
        </p>
      </header>

      {error || !data ? (
        <Card className="mt-6">
          <EmptyState
            icon="alert"
            title="Could not load settings"
            body="Run supabase/schema.sql in the Supabase SQL Editor to create the tables, then reload this page."
          />
        </Card>
      ) : (
        <SettingsForm settings={data as Settings} />
      )}
    </>
  );
}
