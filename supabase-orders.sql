-- ════════════════════════════════════════════════════════════════════════════
-- BHSS Website — Store Orders table
-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor → New query).
-- Moves store orders from per-browser localStorage to a shared database table,
-- so the admin Store Orders panel shows every order from every device.
--
-- Privacy: orders contain names, emails, and Mac IDs. anon (the public) may only
-- INSERT (place an order) — they can NOT read, edit, or delete any order.
-- Only a logged-in admin (authenticated) can read / update status / delete.
-- Safe to re-run.
-- ════════════════════════════════════════════════════════════════════════════

create table if not exists public.orders (
  id         uuid        primary key default gen_random_uuid(),
  order_ref  text        not null,
  name       text        not null,
  email      text        not null,
  mac_id     text,
  notes      text,
  items      jsonb       not null default '[]',
  total      numeric     not null default 0,
  status     text        not null default 'pending',
  created_at timestamptz not null default now()
);

create index if not exists orders_created_at_idx on public.orders (created_at desc);

alter table public.orders enable row level security;

drop policy if exists "anon_insert"   on public.orders;
drop policy if exists "public_insert" on public.orders;
drop policy if exists "admin_select"  on public.orders;
drop policy if exists "admin_update"  on public.orders;
drop policy if exists "admin_delete"  on public.orders;

-- INSERT is open to everyone (placing an order). "public" covers both the
-- anon role AND a browser that happens to hold an admin session — important
-- because admin.html and shop.html share one origin, so an admin login also
-- makes the shopper "authenticated".
create policy "public_insert" on public.orders for insert to public        with check (true);
create policy "admin_select"  on public.orders for select to authenticated using (true);
create policy "admin_update"  on public.orders for update to authenticated using (true) with check (true);
create policy "admin_delete"  on public.orders for delete to authenticated using (true);
