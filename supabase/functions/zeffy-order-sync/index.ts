// BHSS — Zeffy order sync (scheduled Edge Function)
//
// Zeffy has no webhook on this account, so this runs on a schedule (see
// pg_cron setup instructions in supabase-zeffy-orders.sql / README below)
// and pulls new paid payments from the Zeffy API instead of waiting for a push.
//
// Campaign IDs are configured via env vars (comma-separated), not hardcoded,
// so adding a new committee event campaign later doesn't need a redeploy —
// just `supabase secrets set ZEFFY_TICKET_CAMPAIGN_IDS=...`.
//
// Required secrets (set with `supabase secrets set NAME=value`):
//   ZEFFY_API_KEY             — from the Zeffy dashboard
//   ZEFFY_STORE_CAMPAIGN_IDS  — comma-separated campaign id(s) that are the merch store
//   ZEFFY_TICKET_CAMPAIGN_IDS — comma-separated campaign id(s) for event ticket sales (optional)
// SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY are injected automatically by Supabase.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ZEFFY_API_BASE = "https://api.zeffy.com/api/v1";

interface ZeffyBuyer {
  email: string;
  first_name: string;
  last_name: string;
}

interface ZeffyItem {
  rate_title: string;
  amount: number; // cents
}

interface ZeffyPayment {
  id: string;
  created: number; // unix seconds
  amount: number; // cents
  currency: string;
  status: string;
  refund_status: string; // "none" | "partial" | "full"
  description: string; // campaign name
  campaign_id: string;
  buyer: ZeffyBuyer;
  items: ZeffyItem[];
}

interface ZeffyPaymentsPage {
  data: ZeffyPayment[];
  has_more: boolean;
  next_cursor: string | null;
  error?: string;
}

async function fetchZeffyPayments(
  apiKey: string,
  campaignId: string,
  cursor: string | null,
  status: string | null = "succeeded",
): Promise<ZeffyPaymentsPage> {
  const url = new URL(`${ZEFFY_API_BASE}/payments`);
  url.searchParams.set("campaign", campaignId);
  if (status) url.searchParams.set("status", status);
  url.searchParams.set("limit", "100");
  if (cursor) url.searchParams.set("cursor", cursor);

  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${apiKey}` },
  });
  if (!res.ok) {
    throw new Error(`Zeffy API ${res.status} for campaign ${campaignId}: ${await res.text()}`);
  }
  return await res.json();
}

// Pages back through a campaign's payments (newest-first) until it hits the
// last payment id seen on the previous run, or runs out of pages.
async function fetchNewPayments(
  apiKey: string,
  campaignId: string,
  lastSeenPaymentId: string | null,
): Promise<ZeffyPayment[]> {
  const collected: ZeffyPayment[] = [];
  let cursor: string | null = null;

  while (true) {
    const page = await fetchZeffyPayments(apiKey, campaignId, cursor);
    for (const payment of page.data) {
      if (payment.id === lastSeenPaymentId) return collected;
      collected.push(payment);
    }
    if (!page.has_more || !page.next_cursor) break;
    cursor = page.next_cursor;
  }
  return collected;
}

// NOTE: Zeffy's `amount` fields were only ever observed as 0 (free tickets)
// while building this — assumed to be in cents, matching `eligible_amount`
// and the Stripe-style shape of the payment object. Verify against a real
// paid test purchase before trusting this in production; if wrong, this is
// the only line to change.
function centsToDollars(cents: number): number {
  return cents / 100;
}

// Maps a Zeffy payment's refund/status fields to the status we store locally.
// Returns null if it's a normal, unrefunded successful payment (no change needed).
function refundAwareStatus(payment: ZeffyPayment): string | null {
  if (payment.refund_status === "full") return "refunded";
  if (payment.refund_status === "partial") return "partially_refunded";
  if (payment.status !== "succeeded") return payment.status;
  return null;
}

function paymentToOrderRow(payment: ZeffyPayment) {
  return {
    order_ref: payment.id,
    name: `${payment.buyer.first_name} ${payment.buyer.last_name}`.trim(),
    email: payment.buyer.email,
    items: payment.items.map((i) => ({
      name: i.rate_title,
      qty: 1,
      price: centsToDollars(i.amount),
    })),
    total: centsToDollars(payment.amount),
    status: "paid",
    source: "zeffy",
    zeffy_payment_id: payment.id,
  };
}

Deno.serve(async (_req) => {
  const apiKey = Deno.env.get("ZEFFY_API_KEY");
  const storeCampaignIds = (Deno.env.get("ZEFFY_STORE_CAMPAIGN_IDS") || "")
    .split(",").map((s) => s.trim()).filter(Boolean);
  const ticketCampaignIds = (Deno.env.get("ZEFFY_TICKET_CAMPAIGN_IDS") || "")
    .split(",").map((s) => s.trim()).filter(Boolean);

  if (!apiKey) {
    return new Response(JSON.stringify({ error: "ZEFFY_API_KEY not set" }), { status: 500 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const results: Record<string, unknown> = {};

  async function syncCampaign(campaignId: string, table: "orders" | "ticket_orders") {
    const { data: state } = await supabase
      .from("zeffy_sync_state")
      .select("last_seen_payment_id")
      .eq("campaign_id", campaignId)
      .maybeSingle();

    const newPayments = await fetchNewPayments(apiKey, campaignId, state?.last_seen_payment_id ?? null);

    if (newPayments.length) {
      const rows = newPayments.map((p) => {
        const base = paymentToOrderRow(p);
        return table === "ticket_orders"
          ? { ...base, event_name: p.description, zeffy_campaign_id: campaignId }
          : base;
      });

      const { error } = await supabase
        .from(table)
        .upsert(rows, { onConflict: "zeffy_payment_id", ignoreDuplicates: true });
      if (error) throw new Error(`Upsert into ${table} failed: ${error.message}`);

      // newPayments[0] is the newest (API returns newest-first)
      await supabase.from("zeffy_sync_state").upsert({
        campaign_id: campaignId,
        last_seen_payment_id: newPayments[0].id,
        last_synced_at: new Date().toISOString(),
      });
    }

    // Reconcile refund/status changes on payments we've already synced.
    // Only checks the most recent 100 payments per campaign per run (not
    // full history) — refunds happening long after purchase on an older
    // order won't be caught by this, but covers the common case.
    const recentPage = await fetchZeffyPayments(apiKey, campaignId, null, null);
    const paymentsById = new Map(recentPage.data.map((p) => [p.id, p]));
    const knownIds = [...paymentsById.keys()];
    if (knownIds.length) {
      const { data: existingRows } = await supabase
        .from(table)
        .select("zeffy_payment_id, status")
        .eq("source", "zeffy")
        .in("zeffy_payment_id", knownIds);

      for (const row of existingRows ?? []) {
        const payment = paymentsById.get(row.zeffy_payment_id);
        if (!payment) continue;
        const newStatus = refundAwareStatus(payment);
        if (newStatus && newStatus !== row.status) {
          const { error } = await supabase
            .from(table)
            .update({ status: newStatus })
            .eq("zeffy_payment_id", row.zeffy_payment_id);
          if (error) throw new Error(`Refund status update in ${table} failed: ${error.message}`);
        }
      }
    }

    results[campaignId] = { table, synced: newPayments.length };
  }

  for (const id of storeCampaignIds) await syncCampaign(id, "orders");
  for (const id of ticketCampaignIds) await syncCampaign(id, "ticket_orders");

  return new Response(JSON.stringify({ ok: true, results }), {
    headers: { "Content-Type": "application/json" },
  });
});
