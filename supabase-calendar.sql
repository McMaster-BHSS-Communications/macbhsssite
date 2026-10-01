-- ═══════════════════════════════════════════════════════════════════
-- BHSS Calendar — Notion → Supabase sync (2026-10-01)
--
-- Run in Supabase Dashboard → SQL Editor. Safe to re-run.
--
-- Notion is the source of truth. The `sync-notion-calendar` Edge Function
-- (supabase/functions/sync-notion-calendar/index.ts) copies every row with
-- "Public?" checked from the two Notion databases into `calendar_events`.
-- The public site (calendar.html, homepage "Upcoming") only ever reads this
-- table; nothing on the site writes to it.
--
-- Part 1 (table + RLS) runs as-is.
-- Part 2 (cron) has two placeholders to fill in — see the notes there.
-- ═══════════════════════════════════════════════════════════════════

-- ── PART 1: TABLES + RLS ───────────────────────────────────────────

create table if not exists public.calendar_events (
  notion_id  text primary key,                 -- Notion page id
  source     text not null check (source in ('events', 'academic')),
  title      text not null,
  start_at   timestamptz not null,
  end_at     timestamptz,
  all_day    boolean not null default false,   -- true when Notion date has no time
  category   text,                             -- events: committee name(s) / 'BAG' / 'General'; academic: Type
  levels     text[] not null default '{}',     -- academic only: I, II, III, IV, All
  bag_name   text,                             -- events only
  synced_at  timestamptz not null default now()
);

create index if not exists calendar_events_start_idx on public.calendar_events (start_at);

-- One-row status table so admin can show "last synced …".
create table if not exists public.calendar_sync_status (
  id             int primary key default 1 check (id = 1),
  last_synced_at timestamptz,
  trigger        text,                         -- 'cron' | 'manual'
  added          int,
  updated        int,
  removed        int,
  error          text
);
insert into public.calendar_sync_status (id) values (1) on conflict do nothing;

alter table public.calendar_events      enable row level security;
alter table public.calendar_sync_status enable row level security;

-- Public site: read-only. Only the Edge Function (service role, bypasses RLS)
-- writes these tables.
drop policy if exists "public_read" on public.calendar_events;
create policy "public_read" on public.calendar_events for select to anon, authenticated using (true);

drop policy if exists "admin_read" on public.calendar_sync_status;
create policy "admin_read" on public.calendar_sync_status for select to authenticated using (true);


-- ── PART 2: SCHEDULED SYNC (every 6 hours) ─────────────────────────
-- Requires the pg_cron and pg_net extensions
-- (Dashboard → Database → Extensions → enable both).
--
-- Before running this part, replace:
--   <PROJECT_REF>  → lnqbcatlepeagnjmktpk
--   <CRON_SECRET>  → the same random string you saved as the CRON_SECRET
--                    Edge Function secret
-- Do NOT commit the filled-in secret to git.

-- select cron.unschedule('sync-notion-calendar');   -- uncomment to remove/replace the job

select cron.schedule(
  'sync-notion-calendar',
  '0 */6 * * *',
  $$
  select net.http_post(
    url     := 'https://lnqbcatlepeagnjmktpk.supabase.co/functions/v1/sync-notion-calendar',
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-cron-secret', '<CRON_SECRET>'),
    body    := '{}'::jsonb
  );
  $$
);
