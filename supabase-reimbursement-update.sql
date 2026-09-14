-- ─────────────────────────────────────────────────────────────────────────────
-- Reimbursement form rewrite (2026-09-14)
--
-- Rewrites the "reimbursement" row in bhss_forms to match Naomi's 2026-2027
-- "Guide to Reimbursements" (the form-spec version — "Include in the
-- description" / "Include in form"), and adds a generic file-upload field
-- type to the bhss_forms system (used here for the receipt + optional budget
-- spreadsheet attachments).
--
-- This is an UPDATE, not an INSERT — the original row was created by
-- supabase-bags-setup.sql's `insert ... on conflict (id) do nothing`, which
-- already ran, so re-running that file would NOT pick up these changes.
-- Run this file instead (and keep it around — treat this file as the source
-- of truth for the reimbursement form going forward; don't hand-edit that
-- original insert in supabase-bags-setup.sql).
--
-- File-upload fields (student-events.html / admin.html) snapshot their
-- answer as the string "__file__:<bucket>/<path>:<filename>" so
-- bhss_form_submissions.answers keeps its existing {label,value} shape.
-- Parsing that string back out is done by parseFileAnswer() (student-events.html)
-- and parseBagFileAnswer() (admin.html).
--
-- Uploads are restricted to PDF only, 20MB max -- enforced client-side
-- (student-events.html) AND at the bucket level below (storage.buckets
-- file_size_limit/allowed_mime_types) as a backstop.
-- ─────────────────────────────────────────────────────────────────────────────

update public.bhss_forms
set
  title = 'Request a Reimbursement',
  description = $desc$<p><em>Please read the following instructions carefully to ensure the reimbursement process is as quick as possible! If you have any questions, please email <a href="mailto:bhssfin@mcmaster.ca">bhssfin@mcmaster.ca</a> or send a DM on Instagram (@naomi.tseng).</em></p>
<h4>Read Before Submitting a Request</h4>
<ul>
<li><strong>For BAGs only:</strong> at the start of your term, designate someone as the point of contact for reimbursements. They must email <a href="mailto:bhssfin@mcmaster.ca">bhssfin@mcmaster.ca</a> to introduce themselves with their first and last name before any requests are made.</li>
<li><strong>For coordinators:</strong> unless otherwise indicated, coordinators (e.g. the Social Coordinator) will reach out for reimbursement requests.</li>
<li>Cheques will only be given to the designated member(s).</li>
<li>Only <strong>one event</strong> may be included per submission — multiple events in one submission will not be accepted and you'll need to resend the form with the correct info. Multiple purchases for the <em>same</em> event can be listed together in one submission.</li>
<li><strong>Reimbursements must be submitted within 4 weeks</strong> of your purchase. If you don't contact us within that window, you may not receive your reimbursement (excluding extenuating circumstances).</li>
<li>Cheque pick-up is held twice a week in the Health Sci lounge: <strong>Thursdays, 12–1pm</strong> and <strong>Tuesdays, 7:30–8:30pm</strong>. Cheques may only be picked up by the person named in the form, within these times, unless there are extenuating circumstances.</li>
</ul>
<h4>Final Reminders</h4>
<ul>
<li>All funds must be used by <strong>April 1st</strong> and submitted for reimbursement by <strong>April 7th, 2027</strong> — the final cheque pick-up for the year. Any leftover funding cannot carry over into the following year.</li>
<li>Reimbursements are done <strong>only by cheque — no e-transfers.</strong></li>
<li>Reimbursements submitted after April 7th, 2027 will not be accepted or considered, even if within 4 weeks of purchase.</li>
<li>Donating part of your BHSS budget to an organization or charity requires <strong>written approval from Naomi (Financial Coordinator) and Titus (Chair)</strong> — contact <a href="mailto:bhssfin@mcmaster.ca">bhssfin@mcmaster.ca</a> with requests.</li>
<li>For large transactions, a cheque can be written directly to the venue/company instead of reimbursing a personal purchase — contact us if you need this.</li>
<li>Cheques should be deposited within <strong>3 weeks</strong> of pick-up; the Financial Coordinator is not responsible for a cheque after it has been picked up.</li>
</ul>$desc$,
  fields = '[
    {"id":"full_name","label":"Full Name","type":"text","required":true,"help":"Government name -- this is the name the cheque will be made out to."},
    {"id":"total_amount","label":"Total Amount You Want to Be Reimbursed ($)","type":"number","required":true,"help":"If multiple people made purchases, only one cheque will be issued for the full amount -- note any extenuating circumstances in the Anything Else field below."},
    {"id":"expense_description","label":"Event and Itemized Expenses","type":"textarea","required":true,"help":"Clearly describe what event the funds were used for and list each item purchased with its price. Example: Prize for Sticky Note Wall Raffle: $30.59, Exam care packages: $404.15, Wellness Cart Restock: $63.96."},
    {"id":"receipt_upload","label":"Receipt(s)","type":"file","required":true,"help":"PDF only, max 20MB. If your receipt is a screenshot, digital receipt, or e-transfer confirmation, please convert/print it to PDF first (most phones and browsers have a Save as PDF option). Please bundle all receipts for this event into a single PDF where possible, rather than uploading several."},
    {"id":"budget_spreadsheet","label":"Budget Spreadsheet (big groups only)","type":"file","required":false,"help":"If you are a big group (e.g. Fashion Show, HSM) or keep your own budget spreadsheet, export/print it to PDF and attach it here along with your receipts. PDF only, max 20MB."},
    {"id":"pickup_default","label":"I will pick up my cheque at the next immediate pick-up time after this form is submitted (Thursdays 12-1pm or Tuesdays 7:30-8:30pm, Health Sci lounge).","type":"checkbox","required":false},
    {"id":"pickup_other","label":"If you cannot make that time, enter the exact date and time you will pick up your cheque","type":"text","required":false,"help":"Must fall within the regular pick-up times listed above."},
    {"id":"additional_notes","label":"Anything Else?","type":"textarea","required":false,"help":"Note any extenuating circumstances -- e.g. multiple purchasers needing separate cheques, or another special request."}
  ]'::jsonb,
  updated_at = now()
where id = 'reimbursement';


-- ─────────────────────────────────────────────────────────────────────────────
-- STORAGE: bhss-form-uploads bucket
--    Generic attachment bucket for any bhss_forms field of type "file"
--    (currently: the reimbursement form's receipt + budget spreadsheet
--    fields). Unlike bag-logos/product-images, this bucket must be kept
--    PRIVATE -- it holds students' purchase receipts, which should not be
--    publicly listable/guessable. Admin reads files via short-lived signed
--    URLs (createSignedUrl), generated on demand in admin.html.
--
-- MANUAL STEP REQUIRED: create a bucket named "bhss-form-uploads" in
-- Dashboard -> Storage -> New bucket, and leave "Public bucket" UNCHECKED,
-- then run the policies below.
--
-- File type/size are restricted to PDF-only, 20MB max (matches the client-side
-- check in student-events.html's submitSeForm, which rejects non-PDF/oversized
-- files before ever attempting an upload) -- this bucket-level limit is a
-- server-side backstop in case that client check is ever bypassed or changed.
-- If a future file-upload field needs a different type/size, either loosen
-- this bucket-wide or split it into a second bucket -- don't just widen this
-- one silently, since the reimbursement flow is intentionally PDF-only.
-- ─────────────────────────────────────────────────────────────────────────────
update storage.buckets
set file_size_limit = 20971520, allowed_mime_types = array['application/pdf']
where id = 'bhss-form-uploads';

drop policy if exists "bhss_form_uploads_public_insert" on storage.objects;
drop policy if exists "bhss_form_uploads_admin_select"  on storage.objects;
drop policy if exists "bhss_form_uploads_admin_update"  on storage.objects;
drop policy if exists "bhss_form_uploads_admin_delete"  on storage.objects;

create policy "bhss_form_uploads_public_insert"
  on storage.objects for insert to public
  with check (bucket_id = 'bhss-form-uploads');

create policy "bhss_form_uploads_admin_select"
  on storage.objects for select to authenticated
  using (bucket_id = 'bhss-form-uploads');

create policy "bhss_form_uploads_admin_update"
  on storage.objects for update to authenticated
  using (bucket_id = 'bhss-form-uploads') with check (bucket_id = 'bhss-form-uploads');

create policy "bhss_form_uploads_admin_delete"
  on storage.objects for delete to authenticated
  using (bucket_id = 'bhss-form-uploads');
