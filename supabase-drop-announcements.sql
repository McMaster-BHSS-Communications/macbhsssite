-- ════════════════════════════════════════════════════════════════════════════
-- One-time cleanup: remove the Announcements feature from Supabase.
--
-- The Announcements feature (admin composer, /announcements page, homepage
-- panel) has been removed from the site. This drops the now-unused table and
-- everything tied to it (its RLS policies go with it automatically).
--
-- Run once in: Supabase Dashboard → SQL Editor → New query → paste → Run
-- This is IRREVERSIBLE — all announcement rows are permanently deleted.
-- ════════════════════════════════════════════════════════════════════════════

drop table if exists public.announcements cascade;
