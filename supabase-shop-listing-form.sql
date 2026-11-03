-- ─────────────────────────────────────────────────────────────────────────────
-- HHShop Listing Request form (2026-11-02)
--
-- Adds the "shop_request" row to bhss_forms: BAGs/committees ask BHSS to list
-- merch or event tickets on the HHShop (/shop). Fields mirror admin → Store →
-- Zeffy Campaigns' "Add Campaign" form (title, description, type, sort/dates),
-- minus the Zeffy link / Campaign ID, which BHSS fills in after creating the
-- Zeffy form. Locked to signed-in BAGs/committees on /student-groups
-- (GATED_FORM_IDS).
--
-- Safe to re-run: upserts the row. Re-running overwrites Form Builder edits.
-- ─────────────────────────────────────────────────────────────────────────────

insert into public.bhss_forms (id, title, description, fields)
values (
  'shop_request',
  'List Something on the HHShop',
  $desc$<p><em>Only available to signed-in BAGs and committees.</em> BHSS offers affiliated groups a way to sell merch or event tickets through the HHShop, our online store. You don't need your own website or payment account.</p>
<h4>How it works</h4>
<ol>
<li><strong>Submit this request</strong> with your item or event details, price and the dates you want the sale to run. Please submit at least <strong>3 weeks</strong> before you want to start selling.</li>
<li><strong>We set up your listing.</strong> Your item or event gets its own section on the shop page, with a description and an online checkout form powered by Zeffy.</li>
<li><strong>Buyers pay on the shop page.</strong> They check out securely without leaving the page. Zeffy doesn't charge fees to nonprofits, so nothing is deducted from your sales.</li>
<li><strong>We send you your orders.</strong> When your run ends, we'll send you a spreadsheet of every order.</li>
<li><strong>You get paid by cheque.</strong> BHSS collects the payments during the run. Once it closes, we'll issue a cheque for the full total, which your group's designated contact can pick up through our standard cheque pickup process.</li>
<li><strong>You deliver to buyers.</strong> Getting merch or tickets to buyers is your group's responsibility.</li>
</ol>
<h4>Good to know</h4>
<ul>
<li>Listings can include a short description with formatting and links, so buyers know exactly what they're getting.</li>
<li>Both merch and ticketed events are supported.</li>
<li>We'll take your listing down when your sale ends.</li>
<li>At checkout, Zeffy shows buyers an optional tip prompt. It's entirely optional, and any tip goes to Zeffy, not to BHSS or your group. Buyers can set it to $0, so let your customers know if they ask.</li>
</ul>$desc$,
  '[
    {"id":"requester_name","label":"Your Name","type":"text","required":true},
    {"id":"requester_email","label":"Your Email","type":"text","required":true,"help":"So we can follow up with you about your listing."},
    {"id":"group_name","label":"BAG or Committee Name","type":"text","required":true},
    {"id":"listing_type","label":"What are you selling?","type":"select","options":["Merchandise","Event tickets"],"required":true,"help":"Merch is listed as a store; ticketed events are listed as tickets."},
    {"id":"listing_title","label":"Listing Title","type":"text","required":true,"help":"The heading shown above your listing on the shop page, e.g. \"Formal Tickets\" or \"Club Hoodies\"."},
    {"id":"listing_description","label":"Listing Description","type":"textarea","required":true,"help":"Shown under the title so buyers know exactly what they are getting. Include anything they should know, such as sizes, event date and location, or pickup details."},
    {"id":"items_prices","label":"Items / Ticket Tiers and Prices","type":"textarea","required":true,"help":"One per line, e.g. \"Hoodie (S-XL) - $40\" or \"General admission - $15\"."},
    {"id":"quantity_limits","label":"Quantity Limits (optional)","type":"textarea","required":false,"help":"Maximum number available per item or tier, if any."},
    {"id":"sale_start","label":"Sale Start Date","type":"date","required":true,"help":"The day you want the listing to go live. Please allow at least 3 weeks from today."},
    {"id":"sale_end","label":"Sale End Date","type":"date","required":true,"help":"The day the listing should be taken down. Your cheque is issued after this date."},
    {"id":"delivery_plan","label":"Pickup / Delivery Plan","type":"textarea","required":true,"help":"How and where buyers will receive their merch or tickets. Getting items to buyers is your group''s responsibility."},
    {"id":"cheque_contact","label":"Designated Cheque Pickup Contact","type":"text","required":true,"help":"The name of the person from your group who will pick up the cheque through our standard cheque pickup process."},
    {"id":"tip_ack","label":"I understand that Zeffy shows buyers an optional tip prompt, and that any tip goes to Zeffy rather than BHSS or my group.","type":"checkbox","required":true},
    {"id":"notes","label":"Additional Notes","type":"textarea","required":false}
  ]'::jsonb
)
on conflict (id) do update
  set title = excluded.title,
      description = excluded.description,
      fields = excluded.fields;
