import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });

const hex = (bytes: ArrayBuffer) =>
  [...new Uint8Array(bytes)]
    .map((value) => value.toString(16).padStart(2, "0"))
    .join("");

async function hmac(message: string, secret: string) {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  return hex(await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(message)));
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);

  try {
    const db = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    const input = await request.json();
    const action = String(input.action ?? "");
    const mobile = String(input.mobile ?? "").replace(/\D/g, "");
    const sessionToken = String(input.session_token ?? "");
    if (!/^\d{10}$/.test(mobile) || sessionToken.length < 32) {
      return json({ error: "Please login again." }, 401);
    }
    const tokenHash = hex(
      await crypto.subtle.digest(
        "SHA-256",
        new TextEncoder().encode(sessionToken),
      ),
    );
    const { data: session } = await db
      .from("customer_sessions")
      .select("mobile")
      .eq("token_hash", tokenHash)
      .eq("mobile", mobile)
      .gt("expires_at", new Date().toISOString())
      .maybeSingle();
    if (!session) {
      return json({ error: "Your session has expired. Please login again." }, 401);
    }

    const { data: settings, error: settingsError } = await db
      .from("settings")
      .select("razorpay_key_id,razorpay_key_secret,plant_name")
      .eq("id", 1)
      .single();
    if (settingsError) throw settingsError;
    const keyId = String(settings.razorpay_key_id ?? "").trim();
    const keySecret = String(settings.razorpay_key_secret ?? "").trim();
    if (!keyId || !keySecret) {
      return json({ error: "Online wallet top-up is not configured yet." }, 503);
    }
    if (
      !(keyId.startsWith("rzp_test_") || keyId.startsWith("rzp_live_")) ||
      keySecret.length < 20
    ) {
      return json(
        {
          error:
            "Razorpay credentials are invalid. Add the real Key ID and Key Secret in admin settings.",
        },
        503,
      );
    }
    const basic = btoa(`${keyId}:${keySecret}`);

    if (action === "create") {
      const amount = Number(input.amount);
      if (!/^\d{10}$/.test(mobile)) {
        return json({ error: "Invalid customer account." }, 400);
      }
      if (!Number.isInteger(amount) || amount < 10 || amount > 100000) {
        return json({ error: "Enter an amount between ₹10 and ₹1,00,000." }, 400);
      }
      const { data: customer } = await db
        .from("customers")
        .select("mobile,name")
        .eq("mobile", mobile)
        .maybeSingle();
      if (!customer) return json({ error: "Customer account not found." }, 404);

      const receipt = `wallet_${mobile}_${Date.now()}`.slice(0, 40);
      const orderResponse = await fetch("https://api.razorpay.com/v1/orders", {
        method: "POST",
        headers: {
          Authorization: `Basic ${basic}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          amount: amount * 100,
          currency: "INR",
          receipt,
          notes: { purpose: "wallet_topup", mobile },
        }),
      });
      const order = await orderResponse.json();
      if (!orderResponse.ok || !order.id) {
        const razorpayMessage = String(
          order?.error?.description ?? order?.error?.reason ?? "",
        ).trim();
        if (orderResponse.status === 401) {
          return json(
            {
              error:
                "Razorpay authentication failed. Check the Key ID and Key Secret saved in admin settings.",
            },
            503,
          );
        }
        return json(
          {
            error: razorpayMessage
              ? `Razorpay order failed: ${razorpayMessage}`
              : "Could not create Razorpay order. Please try again.",
          },
          502,
        );
      }
      const { error } = await db.from("wallet_payment_orders").insert({
        razorpay_order_id: order.id,
        mobile,
        amount,
      });
      if (error) throw error;
      return json({
        key_id: keyId,
        order_id: order.id,
        amount_paise: amount * 100,
        plant_name: settings.plant_name,
        customer_name: customer.name,
      });
    }

    if (action === "verify") {
      const orderId = String(input.order_id ?? "");
      const paymentId = String(input.payment_id ?? "");
      const signature = String(input.signature ?? "");
      if (!orderId || !paymentId || !signature) {
        return json({ error: "Incomplete payment response." }, 400);
      }
      const { data: walletOrder } = await db
        .from("wallet_payment_orders")
        .select("*")
        .eq("razorpay_order_id", orderId)
        .eq("mobile", mobile)
        .maybeSingle();
      if (!walletOrder) return json({ error: "Payment order not found." }, 404);

      const expected = await hmac(`${orderId}|${paymentId}`, keySecret);
      if (expected !== signature.toLowerCase()) {
        return json({ error: "Payment signature verification failed." }, 400);
      }

      const paymentResponse = await fetch(
        `https://api.razorpay.com/v1/payments/${encodeURIComponent(paymentId)}`,
        { headers: { Authorization: `Basic ${basic}` } },
      );
      const payment = await paymentResponse.json();
      if (
        !paymentResponse.ok ||
        payment.order_id !== orderId ||
        payment.amount !== walletOrder.amount * 100 ||
        payment.currency !== "INR" ||
        payment.status !== "captured"
      ) {
        return json({ error: "Payment is not captured yet." }, 409);
      }

      // Razorpay documents that cancelling a UPI payment in Test Mode can be
      // returned as a simulated success (`success@razorpay`). A real UPI app
      // may therefore show a failure while the sandbox payment says captured.
      // Never turn that ambiguous sandbox intent into spendable wallet money.
      if (
        keyId.startsWith("rzp_test_") &&
        payment.method === "upi" &&
        payment.vpa === "success@razorpay"
      ) {
        await db
          .from("wallet_payment_orders")
          .update({ status: "failed" })
          .eq("razorpay_order_id", orderId)
          .eq("status", "created");
        return json(
          {
            error:
              "Test-mode UPI intent cannot be credited safely. Use a Razorpay test card/mock payment, or switch to activated Live Mode for real UPI testing.",
          },
          409,
        );
      }

      const { data, error } = await db.rpc("credit_verified_wallet_payment", {
        p_order_id: orderId,
        p_payment_id: paymentId,
      });
      if (error) throw error;
      return json({ success: true, ...data });
    }

    return json({ error: "Unknown action." }, 400);
  } catch (error) {
    return json(
      { error: error instanceof Error ? error.message : "Wallet service failed." },
      500,
    );
  }
});
