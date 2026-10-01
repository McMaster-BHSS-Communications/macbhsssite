-- ─────────────────────────────────────────────────────────────────────────────
-- Instagram Collab Request form (2026-10-01)
--
-- Adds the "collab_request" row to bhss_forms: BAGs/committees ask for a post
-- on their own account to be collabed on @macbhss for a set time, per the
-- "BAGs and External Groups SOP" in the COMMS: Media Consolidation Protocols.
-- Locked to signed-in BAGs/committees on /student-groups (GATED_FORM_IDS).
--
-- Safe to re-run: upserts the row. Re-running overwrites Form Builder edits.
-- ─────────────────────────────────────────────────────────────────────────────

insert into public.bhss_forms (id, title, description, fields)
values (
  'collab_request',
  'Request an Instagram Collab',
  $desc$<p><em>Only available to signed-in BAGs and committees.</em> @macbhss is a platform for BAGs and community groups to reach the student body. You keep full creative and logistical control: you create and publish the post from your own account, and @macbhss shares it through Instagram's collab feature for a set time.</p>
<h4>How it works</h4>
<ol>
<li>Create and publish the post from <strong>your own account</strong>.</li>
<li>Send a <strong>collaboration invite to @macbhss</strong> and submit this form.</li>
<li>@macbhss accepts the collaboration.</li>
<li>@macbhss <strong>removes the collaboration after a set period</strong> to keep the main grid cohesive.</li>
</ol>
<h4>How long the collab lasts</h4>
<ul>
<li><strong>Reels:</strong> removed from the @macbhss main grid after <strong>4 days</strong>. The reel still gets engagement boosts, stays organized in the account and appears in the Reels tab.</li>
<li><strong>Carousels and image posts:</strong> the collaboration is removed after <strong>4 days</strong>, covering the window when Instagram is still recommending the post. If you're not satisfied with the metrics, you may request a <strong>one-time 4-day extension</strong> (8 days maximum) by direct message to @macbhss any time before the 4-day window ends.</li>
</ul>$desc$,
  '[
    {"id":"requester_name","label":"Your Name","type":"text","required":true},
    {"id":"requester_email","label":"Your Email","type":"text","required":true,"help":"So Comms can follow up with you."},
    {"id":"group_name","label":"BAG or Committee Name","type":"text","required":true},
    {"id":"instagram_handle","label":"Your Group''s Instagram Handle","type":"text","required":true,"help":"The account the post is published from, e.g. @yourbag. This is the account that sends the collab invite to @macbhss."},
    {"id":"post_type","label":"Post Type","type":"select","options":["Reel","Carousel / Image post"],"required":true,"help":"Reels are removed from the main grid after 4 days; carousels and image posts have the collab removed after 4 days."},
    {"id":"post_date","label":"Planned Post Date","type":"date","required":true,"help":"When you plan to publish and send the collab invite."},
    {"id":"extension_reason","label":"Extension Request (optional)","type":"textarea","required":false,"help":"Carousels and image posts only: if you already expect to want a 4-day extension (8 days total), say why. You can also DM @macbhss before the 4-day window ends."},
    {"id":"notes","label":"Additional Notes","type":"textarea","required":false}
  ]'::jsonb
)
on conflict (id) do update
  set title = excluded.title,
      description = excluded.description,
      fields = excluded.fields;
