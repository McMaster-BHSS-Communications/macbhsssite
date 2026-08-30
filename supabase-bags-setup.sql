-- ════════════════════════════════════════════════════════════════════════════
-- BHSS Website — BAGs (BHSS-Affiliated Groups) + Student Events Setup
-- Run this entire file once in: Supabase Dashboard → SQL Editor → New query → Run
--
-- Adds:
--   • public.bags                  — the public /bags directory (admin-managed)
--   • public.bag_auth_codes        — yearly authorization codes (admin-only table)
--   • public.validate_bag_auth_code(text) — RPC anon calls to check a code
--     without ever exposing the codes table itself
--   • public.bhss_forms            — editable field definitions for the 3 forms
--   • public.bhss_form_submissions — student submissions for those forms
--   • Storage bucket policies for "bag-logos"
--
-- MANUAL STEP REQUIRED: before this file's storage policies do anything useful,
-- create a bucket named "bag-logos" in Dashboard → Storage → New bucket, and
-- mark it Public (same as the existing "product-images" bucket), so that
-- getPublicUrl() links resolve for visitors.
-- ════════════════════════════════════════════════════════════════════════════


-- ─────────────────────────────────────────────────────────────────────────────
-- 1. BAGS DIRECTORY
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.bags (
  id            text        primary key,
  name          text        not null,
  description   text        not null default '',
  logo_url      text        not null default '',
  instagram_url text        not null default '',
  active        boolean     not null default true,
  sort_order    int         not null default 0,
  created_at    timestamptz not null default now()
);

alter table public.bags enable row level security;

drop policy if exists "public_read_active" on public.bags;
drop policy if exists "admin_all"          on public.bags;
create policy "public_read_active" on public.bags for select to anon          using (active = true);
create policy "admin_all"          on public.bags for all    to authenticated using (true) with check (true);


-- ─────────────────────────────────────────────────────────────────────────────
-- 2. AUTHORIZATION CODES
--    Admin-only table — anon gets NO direct access, so codes can't be scraped.
--    Validation happens only through the validate_bag_auth_code() RPC below.
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.bag_auth_codes (
  id         text        primary key,
  code       text        not null unique,
  group_name text        null,
  group_type text        null check (group_type in ('committee', 'bag')),
  batch_year int         not null,
  active     boolean     not null default true,
  created_at timestamptz not null default now()
);

alter table public.bag_auth_codes enable row level security;

-- Intentionally no anon policy at all. Only the admin (authenticated) can
-- read/write this table directly.
drop policy if exists "admin_all" on public.bag_auth_codes;
create policy "admin_all" on public.bag_auth_codes for all to authenticated using (true) with check (true);

-- RPC: lets the public site check one code without exposing the table.
drop function if exists public.validate_bag_auth_code(text);
create function public.validate_bag_auth_code(p_code text)
returns table(group_name text, group_type text)
language sql
security definer
set search_path = public
as $$
  select group_name, group_type
  from public.bag_auth_codes
  where code = p_code and active = true
  limit 1;
$$;

grant execute on function public.validate_bag_auth_code(text) to anon, authenticated;


-- ─────────────────────────────────────────────────────────────────────────────
-- 3. FORMS (editable field definitions)
--    fields is a jsonb array of {id, label, type, options, required}
--    type ∈ 'text' | 'textarea' | 'select' | 'date' | 'number' | 'checkbox'
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.bhss_forms (
  id          text        primary key,
  title       text        not null,
  description text        not null default '',
  fields      jsonb       not null default '[]'::jsonb,
  updated_at  timestamptz not null default now()
);

alter table public.bhss_forms enable row level security;

drop policy if exists "public_read" on public.bhss_forms;
drop policy if exists "admin_write" on public.bhss_forms;
create policy "public_read" on public.bhss_forms for select to anon          using (true);
create policy "admin_write" on public.bhss_forms for all    to authenticated using (true) with check (true);

insert into public.bhss_forms (id, title, description, fields) values
(
  'eohss',
  'EOHSS Forms',
  'Environmental & Occupational Health Support Services risk assessment for your event.',
  '[
    {"id":"event_name","label":"Event Name","type":"text","required":true},
    {"id":"event_date","label":"Event Date","type":"date","required":true},
    {"id":"event_location","label":"Event Location","type":"text","required":true},
    {"id":"event_description","label":"Event Description","type":"textarea","required":true},
    {"id":"risk_details","label":"Known Risks or Hazards","type":"textarea","required":false}
  ]'::jsonb
),
(
  'room_booking',
  'Request a Room Booking',
  'Request a space on campus for your event.',
  '[
    {"id":"event_name","label":"Event Name","type":"text","required":true},
    {"id":"preferred_room","label":"Preferred Room / Building","type":"text","required":false},
    {"id":"event_date","label":"Requested Date","type":"date","required":true},
    {"id":"start_time","label":"Start Time","type":"text","required":true},
    {"id":"end_time","label":"End Time","type":"text","required":true},
    {"id":"expected_attendance","label":"Expected Attendance","type":"number","required":true},
    {"id":"additional_notes","label":"Additional Notes","type":"textarea","required":false}
  ]'::jsonb
),
(
  'reimbursement',
  'Request a Reimbursement',
  'Submit a reimbursement request for approved event expenses.',
  '[
    {"id":"event_name","label":"Event Name","type":"text","required":true},
    {"id":"expense_description","label":"Expense Description","type":"textarea","required":true},
    {"id":"amount","label":"Amount ($)","type":"number","required":true},
    {"id":"payment_method","label":"Original Payment Method","type":"select","options":["Personal card/cash","Group card","Other"],"required":true},
    {"id":"receipt_notes","label":"Receipt Notes","type":"textarea","required":false}
  ]'::jsonb
)
on conflict (id) do nothing;


-- ─────────────────────────────────────────────────────────────────────────────
-- 4. FORM SUBMISSIONS
--    answers is a jsonb array of {label, value} — a display-ready snapshot
--    taken at submission time, so later edits to bhss_forms.fields don't
--    corrupt how old submissions are displayed.
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.bhss_form_submissions (
  id           text        primary key,
  form_id      text        not null,
  group_name   text        null,
  group_type   text        null check (group_type in ('committee', 'bag')),
  auth_code    text        null,
  answers      jsonb       not null default '[]'::jsonb,
  status       text        not null default 'new',
  submitted_at timestamptz not null default now()
);

alter table public.bhss_form_submissions enable row level security;

drop policy if exists "public_insert" on public.bhss_form_submissions;
drop policy if exists "admin_select"  on public.bhss_form_submissions;
drop policy if exists "admin_update"  on public.bhss_form_submissions;
drop policy if exists "admin_delete"  on public.bhss_form_submissions;
create policy "public_insert" on public.bhss_form_submissions for insert to public        with check (true);
create policy "admin_select"  on public.bhss_form_submissions for select to authenticated using (true);
create policy "admin_update"  on public.bhss_form_submissions for update to authenticated using (true) with check (true);
create policy "admin_delete"  on public.bhss_form_submissions for delete to authenticated using (true);


-- ─────────────────────────────────────────────────────────────────────────────
-- 5. STORAGE: bag-logos bucket
--    Create the bucket manually first (Dashboard → Storage → New bucket →
--    "bag-logos" → Public), then run this section.
-- ─────────────────────────────────────────────────────────────────────────────
drop policy if exists "bag_logos_public_read"  on storage.objects;
drop policy if exists "bag_logos_admin_write"  on storage.objects;
drop policy if exists "bag_logos_admin_update" on storage.objects;
drop policy if exists "bag_logos_admin_delete" on storage.objects;

create policy "bag_logos_public_read"
  on storage.objects for select to anon
  using (bucket_id = 'bag-logos');

create policy "bag_logos_admin_write"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'bag-logos');

create policy "bag_logos_admin_update"
  on storage.objects for update to authenticated
  using (bucket_id = 'bag-logos') with check (bucket_id = 'bag-logos');

create policy "bag_logos_admin_delete"
  on storage.objects for delete to authenticated
  using (bucket_id = 'bag-logos');


-- ════════════════════════════════════════════════════════════════════════════
-- DONE. Quick sanity check:
--   select schemaname, tablename, policyname, roles, cmd
--   from pg_policies where tablename in
--     ('bags','bag_auth_codes','bhss_forms','bhss_form_submissions')
--   order by tablename;
-- ════════════════════════════════════════════════════════════════════════════
