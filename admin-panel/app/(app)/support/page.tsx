import { MessageCircle, Phone } from "lucide-react";

import { Card } from "@/components/ui";
import { createClient } from "@/lib/supabase/server";
import type { Settings } from "@/lib/types";

export const dynamic = "force-dynamic";

function intlPhone(raw: string): string {
  const d = (raw ?? "").replace(/\D/g, "");
  return d.length === 10 ? `91${d}` : d;
}

export default async function SupportPage() {
  const supabase = await createClient();
  const { data } = await supabase
    .from("settings")
    .select("plant_phone, plant_name")
    .eq("id", 1)
    .maybeSingle();
  const s = (data as Pick<Settings, "plant_phone" | "plant_name">) ?? null;
  const phone = s?.plant_phone ?? "";
  const intl = intlPhone(phone);

  return (
    <>
      <header>
        <h1 className="text-[27px] font-extrabold tracking-tight text-ink">
          Support
        </h1>
        <p className="mt-1 text-[13px] text-ink-muted">
          Your plant contact and quick help.
        </p>
      </header>

      <Card className="mt-6 p-5">
        <h2 className="text-[15px] font-bold text-ink">
          {s?.plant_name || "Mahalakshmi Water Plant"}
        </h2>
        <p className="mt-1 text-[12.5px] text-ink-muted">
          This is the number shown to customers in the app for calls, WhatsApp
          and SMS. Change it anytime in Settings.
        </p>
        <div className="mt-4 flex flex-wrap gap-3">
          <a
            href={`tel:+${intl}`}
            className="inline-flex h-11 items-center gap-2 rounded-2xl border border-line bg-surface px-5 text-[13px] font-bold text-ink transition hover:bg-tint"
          >
            <Phone className="h-4 w-4 text-brand" />
            +91 {phone}
          </a>
          <a
            href={`https://wa.me/${intl}`}
            target="_blank"
            rel="noreferrer"
            className="inline-flex h-11 items-center gap-2 rounded-2xl bg-gradient-to-r from-[#12855a] to-[#2fbd83] px-5 text-[13px] font-bold text-white transition hover:brightness-105"
          >
            <MessageCircle className="h-4 w-4" />
            WhatsApp
          </a>
        </div>
      </Card>

      <Card className="mt-4 p-5">
        <h2 className="text-[15px] font-bold text-ink">Need app help?</h2>
        <p className="mt-2 text-[12.5px] text-ink-muted">
          For any issue with the admin panel or app — payments, SMS, or a
          booking that looks wrong — reach out to your developer with the
          booking code and a screenshot.
        </p>
      </Card>
    </>
  );
}
