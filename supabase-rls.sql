-- ════════════════════════════════════════════════════════════════════════════
-- BHSS Website — Row Level Security (RLS) lockdown
-- Run this entire file in the Supabase SQL Editor:
--   Dashboard → SQL Editor → New query → paste → Run
--
-- This is the REAL security boundary for the site. Because the site is a public
-- static page, the anon key in supabase-client.js is visible to everyone — that
-- is expected and safe ONLY if these policies are in place.
--
-- The rules:
--   • anon (the public)      → can READ public content, and INSERT contact messages. Nothing else.
--   • authenticated (admin)  → full read/write. The admin logs in via Supabase Auth
--                              (bhsscom@mcmaster.ca) before any write happens.
--
-- This file is safe to re-run: every policy is dropped and recreated.
-- ════════════════════════════════════════════════════════════════════════════


-- ─────────────────────────────────────────────────────────────────────────────
-- 1. ENABLE RLS ON EVERY TABLE
-- (announcements / members / page_resources were enabled in supabase-setup.sql;
--  re-enabling is a no-op and keeps this file self-contained.)
-- ─────────────────────────────────────────────────────────────────────────────
alter table public.announcements       enable row level security;
alter table public.members             enable row level security;
alter table public.page_resources      enable row level security;
alter table public.products            enable row level security;
alter table public.collections         enable row level security;
alter table public.promo_banners       enable row level security;
alter table public.contact_submissions enable row level security;


-- ─────────────────────────────────────────────────────────────────────────────
-- 2. PUBLIC-READ CONTENT  (announcements, members, page_resources, collections)
--    anon: SELECT only.  authenticated: full write.
-- ─────────────────────────────────────────────────────────────────────────────

-- announcements
drop policy if exists "public_read"  on public.announcements;
drop policy if exists "admin_write"  on public.announcements;
create policy "public_read" on public.announcements for select to anon          using (true);
create policy "admin_write" on public.announcements for all    to authenticated using (true) with check (true);

-- members
drop policy if exists "public_read"  on public.members;
drop policy if exists "admin_write"  on public.members;
create policy "public_read" on public.members for select to anon          using (true);
create policy "admin_write" on public.members for all    to authenticated using (true) with check (true);

-- page_resources
drop policy if exists "public_read"  on public.page_resources;
drop policy if exists "admin_write"  on public.page_resources;
create policy "public_read" on public.page_resources for select to anon          using (true);
create policy "admin_write" on public.page_resources for all    to authenticated using (true) with check (true);

-- collections (store filter tags — all are public)
drop policy if exists "public_read"  on public.collections;
drop policy if exists "admin_write"  on public.collections;
create policy "public_read" on public.collections for select to anon          using (true);
create policy "admin_write" on public.collections for all    to authenticated using (true) with check (true);


-- ─────────────────────────────────────────────────────────────────────────────
-- 3. STORE ITEMS  (products, promo_banners)
--    anon can read ONLY active rows (matches what the storefront queries).
--    authenticated (admin) can read everything and write.
-- ─────────────────────────────────────────────────────────────────────────────

-- products
drop policy if exists "public_read_active" on public.products;
drop policy if exists "admin_all"          on public.products;
create policy "public_read_active" on public.products for select to anon          using (active = true);
create policy "admin_all"          on public.products for all    to authenticated using (true) with check (true);

-- promo_banners
drop policy if exists "public_read_active" on public.promo_banners;
drop policy if exists "admin_all"          on public.promo_banners;
create policy "public_read_active" on public.promo_banners for select to anon          using (active = true);
create policy "admin_all"          on public.promo_banners for all    to authenticated using (true) with check (true);


-- ─────────────────────────────────────────────────────────────────────────────
-- 4. CONTACT SUBMISSIONS  (About-page contact form)
--    anon: INSERT only — they can send a message but can NOT read, edit, or
--          delete anyone's messages (privacy: these contain names + emails).
--    authenticated (admin): full access to read / mark read / delete.
-- ─────────────────────────────────────────────────────────────────────────────
drop policy if exists "anon_insert"  on public.contact_submissions;
drop policy if exists "admin_select" on public.contact_submissions;
drop policy if exists "admin_update" on public.contact_submissions;
drop policy if exists "admin_delete" on public.contact_submissions;
create policy "anon_insert"  on public.contact_submissions for insert to anon          with check (true);
create policy "admin_select" on public.contact_submissions for select to authenticated using (true);
create policy "admin_update" on public.contact_submissions for update to authenticated using (true) with check (true);
create policy "admin_delete" on public.contact_submissions for delete to authenticated using (true);


-- ─────────────────────────────────────────────────────────────────────────────
-- 5. STORAGE: product images bucket
--    Public can VIEW images (so they show on the store). Only the admin can
--    upload / replace / delete them.
--
--    NOTE: also set the "product-images" bucket to PUBLIC in
--    Dashboard → Storage → product-images → ⚙ → Make public,
--    so getPublicUrl() links resolve for visitors.
-- ─────────────────────────────────────────────────────────────────────────────
drop policy if exists "product_images_public_read" on storage.objects;
drop policy if exists "product_images_admin_write"  on storage.objects;
drop policy if exists "product_images_admin_update" on storage.objects;
drop policy if exists "product_images_admin_delete" on storage.objects;

create policy "product_images_public_read"
  on storage.objects for select to anon
  using (bucket_id = 'product-images');

create policy "product_images_admin_write"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'product-images');

create policy "product_images_admin_update"
  on storage.objects for update to authenticated
  using (bucket_id = 'product-images') with check (bucket_id = 'product-images');

create policy "product_images_admin_delete"
  on storage.objects for delete to authenticated
  using (bucket_id = 'product-images');


-- ════════════════════════════════════════════════════════════════════════════
-- DONE. Quick sanity check — list all policies:
--   select schemaname, tablename, policyname, roles, cmd
--   from pg_policies where schemaname in ('public','storage') order by tablename;
-- ════════════════════════════════════════════════════════════════════════════
