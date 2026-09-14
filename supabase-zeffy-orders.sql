-- ════════════════════════════════════════════════════════════════════════════
-- BHSS Website — Zeffy order sync
-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor → New query).
--
-- Extends `orders` and adds `ticket_orders` so paid Zeffy purchases (merch
-- store + committee event tickets) can be synced in by the scheduled
-- `zeffy-order-sync` Edge Function and show up in admin.html.
--
-- Zeffy has no webhook on this account, so sync is pull-based: a scheduled
-- Edge Function polls the Zeffy API and upserts here. `zeffy_payment_id` is
-- unique so re-polling the same payment is a no-op (idempotent).
-- Safe to re-run.
-- ════════════════════════════════════════════════════════════════════════════

-- ── orders: tag rows with where they came from ────────────────────────────
alter table public.orders
  add column if not exists source           text not null default 'site',
  add column if not exists zeffy_payment_id text;

-- Plain (non-partial) unique index — required for the sync function's
-- `upsert(..., { onConflict: 'zeffy_payment_id' })` to work: Postgres's
-- ON CONFLICT needs a real unique constraint/index on the exact column, and
-- won't match a partial index. NULLs (site-sourced orders) don't count as
-- duplicates under a plain unique index, so this is safe.
drop index if exists orders_zeffy_payment_id_idx;
create unique index if not exists orders_zeffy_payment_id_key
  on public.orders (zeffy_payment_id);


-- ── ticket_orders: committee event ticket sales via Zeffy ─────────────────
create table if not exists public.ticket_orders (
  id                uuid        primary key default gen_random_uuid(),
  order_ref         text        not null,
  name              text        not null,
  email             text        not null,
  event_name        text        not null,
  zeffy_campaign_id text        not null,
  items             jsonb       not null default '[]',
  total             numeric     not null default 0,
  status            text        not null default 'paid',
  source            text        not null default 'zeffy',
  zeffy_payment_id  text,
  created_at        timestamptz not null default now()
);

create unique index if not exists ticket_orders_zeffy_payment_id_key
  on public.ticket_orders (zeffy_payment_id);
create index if not exists ticket_orders_created_at_idx on public.ticket_orders (created_at desc);

alter table public.ticket_orders enable row level security;

drop policy if exists "admin_select" on public.ticket_orders;
drop policy if exists "admin_update" on public.ticket_orders;
drop policy if exists "admin_delete" on public.ticket_orders;

-- No anon access at all — there's no client-side ticket form on the site;
-- every row is written by the zeffy-order-sync Edge Function using the
-- service role key, which bypasses RLS entirely.
create policy "admin_select" on public.ticket_orders for select to authenticated using (true);
create policy "admin_update" on public.ticket_orders for update to authenticated using (true) with check (true);
create policy "admin_delete" on public.ticket_orders for delete to authenticated using (true);


-- ── zeffy_sync_state: bookkeeping for the scheduled sync ──────────────────
-- One row per Zeffy campaign being synced. `last_seen_payment_id` is the
-- newest payment's id from the previous run; the sync function pages back
-- through /payments (sorted newest-first) until it hits this id, then stops
-- — avoids re-processing the whole campaign's history every run.
create table if not exists public.zeffy_sync_state (
  campaign_id           text primary key,
  last_seen_payment_id  text,
  last_synced_at        timestamptz
);

alter table public.zeffy_sync_state enable row level security;

drop policy if exists "admin_all" on public.zeffy_sync_state;
create policy "admin_all" on public.zeffy_sync_state for all to authenticated using (true) with check (true);
-- No anon policy — only the Edge Function (service role) and logged-in admins touch this.


-- ── Scheduled invocation ───────────────────────────────────────────────────
-- Runs every 5 minutes. Uses pg_cron + pg_net, both free, running inside
-- this project's existing Postgres — no separate billing. The Edge Function
-- itself is called ~8,640 times/month at this interval, well under the free
-- plan's 500,000/month included invocations.
create extension if not exists pg_cron;
create extension if not exists pg_net;

select cron.schedule(
  'zeffy-order-sync',
  '*/5 * * * *',
  $$
  select net.http_post(
    url := 'https://lnqbcatlepeagnjmktpk.supabase.co/functions/v1/zeffy-order-sync',
    headers := jsonb_build_object('Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxucWJjYXRsZXBlYWduam1rdHBrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA2MjIyNDgsImV4cCI6MjA5NjE5ODI0OH0.FdpteU8bG3ymIvZ7ao9KzU-XJD4DeTBf_idmzsjuiN0')
  );
  $$
);
