import { CheckCircle2, XCircle } from "lucide-react";
import Link from "next/link";

import { Card } from "@/components/ui";
import { createClient } from "@/lib/supabase/server";
import type { Settings } from "@/lib/types";

export const dynamic = "force-dynamic";

function StatusRow({ label, value, ok }: { label: string; value: string; ok: boolean }) {
  return (
    <div className="flex items-center justify-between gap-3 border-b border-line py-3 last:border-b-0">
      <div>
        <p className="text-[13.5px] font-semibold text-ink">{label}</p>
        <p className="text-[12px] text-ink-muted">{value}</p>
      </div>
      <span
        className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-[11px] font-bold ${
          ok ? "bg-ok-bg text-ok" : "bg-warn-bg text-warn"
        }`}
      >
        {ok ? (
          <CheckCircle2 className="h-3.5 w-3.5" />
        ) : (
          <XCircle className="h-3.5 w-3.5" />
        )}
        {ok ? "Set" : "Not set"}
      </span>
    </div>
  );
}

export default async function SmsPage() {
  const supabase = await createClient();
  const { data } = await supabase
    .from("settings")
    .select("*")
    .eq("id", 1)
    .maybeSingle();
  const s = (data as Settings) ?? null;

  const keySet = !!s?.fast2sms_api_key;

  return (
    <>
      <header>
        <h1 className="text-[27px] font-extrabold tracking-tight text-ink">
          SMS &amp; Notifications
        </h1>
        <p className="mt-1 text-[13px] text-ink-muted">
          DLT SMS status via Fast2SMS (Header MAHWAP).
        </p>
      </header>

      <Card className="mt-6 p-5">
        <h2 className="text-[15px] font-bold text-ink">Configuration</h2>
        <div className="mt-2">
          <StatusRow
            label="Fast2SMS API key"
            value={keySet ? "Connected" : "Add it in Settings to start sending SMS"}
            ok={keySet}
          />
          <StatusRow
            label="Order Confirmation template"
            value={s?.sms_template_order || "—"}
            ok={!!s?.sms_template_order}
          />
          <StatusRow
            label="Delivery Confirmation template"
            value={s?.sms_template_delivery || "—"}
            ok={!!s?.sms_template_delivery}
          />
          <StatusRow
            label="Pending Dues Reminder template"
            value={s?.sms_template_dues || "—"}
            ok={!!s?.sms_template_dues}
          />
        </div>
        <Link
          href="/settings"
          className="mt-5 inline-flex h-11 items-center rounded-2xl bg-gradient-to-r from-[#004fda] to-[#2e8bf0] px-6 text-[13px] font-bold text-white shadow-[0_12px_26px_-12px_rgba(0,79,218,0.8)] transition hover:brightness-105"
        >
          Manage in Settings
        </Link>
      </Card>

      <Card className="mt-4 p-5">
        <h2 className="text-[15px] font-bold text-ink">How it works</h2>
        <ul className="mt-2 space-y-2 text-[12.5px] text-ink-muted">
          <li>• When you confirm a booking, an Order Confirmation SMS is sent to the customer.</li>
          <li>• SMS only send once your Fast2SMS DLT key is added in Settings.</li>
          <li>• Templates must be approved on the DLT portal under Header MAHWAP.</li>
        </ul>
      </Card>
    </>
  );
}
