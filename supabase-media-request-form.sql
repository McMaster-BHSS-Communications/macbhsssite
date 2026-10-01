-- ─────────────────────────────────────────────────────────────────────────────
-- Media Request form (2026-10-01)
--
-- Adds the "media_request" row to bhss_forms: the web version of HeartyBot's
-- /media-request command, built from the COMMS: Media Consolidation Protocols
-- (14-day lead time, 7-day absolute minimum, what is / isn't Comms' scope).
-- Open to everyone on /student-groups (NOT in GATED_FORM_IDS). Submissions land
-- in bhss_form_submissions like every other form and show in the admin
-- "Form Submissions" panel.
--
-- Safe to re-run: upserts the row. Edit the wording in admin → Form Builder
-- afterwards if you like (re-running this file will overwrite those edits).
-- ─────────────────────────────────────────────────────────────────────────────

insert into public.bhss_forms (id, title, description, fields)
values (
  'media_request',
  'Request Media from Communications',
  $desc$<p>Use this form to ask Communications to create and post media on <strong>@macbhss</strong>. @macbhss is the BHSS's <em>information authority</em>: it handles event details, hiring, program-wide announcements and administrative documents. Committee accounts handle additional content (recaps, reels, series posts, Meet the Team).</p>
<h4>Lead time</h4>
<ul>
<li><strong>Submit at least 14 days (2 weeks)</strong> before the intended post date so Comms can prepare and allocate time.</li>
<li><strong>Absolute minimum: 7 days (1 week).</strong> Requests inside this window can be delayed and may not be fulfilled before your event.</li>
</ul>
<h4>Should you submit a request?</h4>
<p><strong>Submit one for:</strong> event details, hiring and main posters; extensions for hiring, events and applications; reminder posts; marketing campaigns; program-wide or non-committee-specific announcements; collaborative events (internal or external); content reels from the student body; commemorative days; administrative documents. <em>Rule of thumb: if it relates to HHSP broadly or needs the attention of the full student body, submit a request.</em></p>
<p><strong>Not needed for:</strong> additional promo (reels, stories), event recaps, direct committee &times; external collaborations, wellness/advice series, or Meet the Team posts. If you'd like @macbhss to repost, let us know in the notes below. <strong>Year Council events are outside Comms' scope</strong> (hiring for council roles may be posted at the Coordinator's discretion).</p>
<p>Banners use the committee's colour; if more than three committees are involved, or the post is program-wide, the general banner is used.</p>$desc$,
  '[
    {"id":"requester_name","label":"Your Name","type":"text","required":true},
    {"id":"requester_email","label":"Your Email","type":"text","required":true,"help":"So Comms can follow up with you."},
    {"id":"committee","label":"Committee or Group","type":"select","options":["Academics","Chair","Communications","EDI","External","Financial","Internal","Logistics & Elections","Social","SRA","Multiple committees / General","BAG or external group"],"required":true},
    {"id":"topic","label":"Topic","type":"text","required":true,"help":"What is the post about?"},
    {"id":"post_date","label":"Intended Post Date","type":"date","required":true,"help":"Ideally 14+ days from today; 7 days is the absolute minimum."},
    {"id":"event_date","label":"Event Date","type":"text","required":true,"help":"Type n/a if not applicable."},
    {"id":"event_time","label":"Event Time","type":"text","required":true,"help":"Type n/a if not applicable."},
    {"id":"location","label":"Location","type":"text","required":true,"help":"Type n/a if not applicable."},
    {"id":"caption","label":"Caption","type":"textarea","required":false,"help":"Caption you would like on the post, if you have one."},
    {"id":"design_requests","label":"Image / Design Requests","type":"textarea","required":false,"help":"Specific design or image requests."},
    {"id":"notes","label":"Additional Notes","type":"textarea","required":false,"help":"E.g. you would like @macbhss to repost your own promo."}
  ]'::jsonb
)
on conflict (id) do update
  set title = excluded.title,
      description = excluded.description,
      fields = excluded.fields;
