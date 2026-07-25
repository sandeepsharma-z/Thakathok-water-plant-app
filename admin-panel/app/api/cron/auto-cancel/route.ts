import { NextResponse } from "next/server";

import { createAdminClient } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

/**
 * Cancels cash bookings that stayed pending for more than 24 hours — the
 * advance never arrived, so the booking is dropped and its date freed.
 *
 * Vercel Cron calls this on a schedule (see vercel.json) with the header
 * `Authorization: Bearer $CRON_SECRET`, so we reject anything without it.
 */
export async function GET(request: Request) {
  const secret = process.env.CRON_SECRET;
  const auth = request.headers.get("authorization");
  if (secret && auth !== `Bearer ${secret}`) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const cutoff = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();

  try {
    const supabase = createAdminClient();
    const { data, error } = await supabase
      .from("bookings")
      .update({ status: "cancelled" })
      .eq("status", "pending")
      .eq("payment_method", "cash")
      .lt("created_at", cutoff)
      .select("booking_code");

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({
      ok: true,
      cancelled: data?.length ?? 0,
      codes: (data ?? []).map((d) => d.booking_code),
      cutoff,
    });
  } catch (e) {
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "failed" },
      { status: 500 },
    );
  }
}
