-- ════════════════════════════════════════════════════════
-- BHSS Website — Supabase Setup
-- Run this entire file in the Supabase SQL Editor once.
-- Dashboard → SQL Editor → New query → paste → Run
-- ════════════════════════════════════════════════════════

-- 1. CREATE TABLES

create table if not exists public.members (
  id             text        primary key,
  committee_id   text        not null,
  first_name     text        not null,
  last_name      text        not null,
  role           text        not null default '',
  is_coordinator boolean     not null default false,
  photo          text        not null default '',
  created_at     timestamptz not null default now()
);

-- Note: column is named "committee" (not committee_id) to match the front-end
create table if not exists public.page_resources (
  id           text        primary key,
  committee    text        not null,
  title        text        not null,
  url          text        not null,
  sort_order   int         not null default 0,
  created_at   timestamptz not null default now()
);

-- 2. ENABLE ROW LEVEL SECURITY

alter table public.members        enable row level security;
alter table public.page_resources enable row level security;

-- 3. SECURITY POLICIES
-- Public visitors can READ everything.
-- Only a logged-in admin can CREATE / UPDATE / DELETE.

create policy "public_read" on public.members        for select to anon      using (true);
create policy "public_read" on public.page_resources for select to anon      using (true);

create policy "admin_write" on public.members        for all    to authenticated using (true) with check (true);
create policy "admin_write" on public.page_resources for all    to authenticated using (true) with check (true);
