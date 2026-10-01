-- Allow the 'forms' section on page_resources (added 2026-09-16 to the front-end/admin,
-- but the DB check constraint still only permitted the original three values).
-- Run in Supabase Dashboard -> SQL Editor. Safe to re-run.

alter table public.page_resources
  drop constraint if exists page_resources_section_check;

alter table public.page_resources
  add constraint page_resources_section_check
  check (section in ('administration', 'opportunities', 'students', 'forms'));