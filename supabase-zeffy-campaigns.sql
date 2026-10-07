-- ════════════════════════════════════════════════════════════════════════════
-- BHSS Website — Zeffy campaigns (admin-managed)
-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor → New query).
--
-- One row per Zeffy campaign. Drives two things:
--   1. /shop — every row with show_on_shop = true is embedded as its own
--      titled section, stacked in sort_order.
--   2. zeffy-order-sync Edge Function — every row with sync_orders = true and
--      a campaign_id is polled for orders (kind 'store' → orders,
--      'ticket' → ticket_orders). The ZEFFY_*_CAMPAIGN_IDS secrets still work
--      as a fallback and are merged in.
-- Managed from admin.html → Store → Zeffy Campaigns. Safe to re-run.
-- ════════════════════════════════════════════════════════════════════════════

create table if not exists public.zeffy_campaigns (
  id            uuid        primary key default gen_random_uuid(),
  title         text        not null,
  description   text        not null default '',
  embed_path    text        not null,               -- e.g. /embed/ticketing/hhshop-2
  campaign_id   text,                               -- Zeffy API campaign id (for order sync)
  kind          text        not null default 'store' check (kind in ('store', 'ticket')),
  show_on_shop  boolean     not null default true,
  sync_orders   boolean     not null default true,
  sort_order    integer     not null default 0,
  created_at    timestamptz not null default now()
);

alter table public.zeffy_campaigns enable row level security;

drop policy if exists "public_read_visible" on public.zeffy_campaigns;
drop policy if exists "admin_all"           on public.zeffy_campaigns;

-- Anon only sees campaigns that are live on /shop.
create policy "public_read_visible" on public.zeffy_campaigns
  for select to anon using (show_on_shop);
create policy "admin_all" on public.zeffy_campaigns
  for all to authenticated using (true) with check (true);

-- Seed the store that was previously hardcoded in shop.html. campaign_id is
-- left empty — fill it in from admin (it's the value currently in the
-- ZEFFY_STORE_CAMPAIGN_IDS secret).
insert into public.zeffy_campaigns (title, embed_path, kind, sort_order)
select 'HHSP Store', '/embed/ticketing/hhshop-2', 'store', 0
where not exists (
  select 1 from public.zeffy_campaigns where embed_path = '/embed/ticketing/hhshop-2'
);
