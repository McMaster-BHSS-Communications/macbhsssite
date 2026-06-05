-- ════════════════════════════════════════════════════════
-- BHSS Website — Supabase Setup
-- Run this entire file in the Supabase SQL Editor once.
-- Dashboard → SQL Editor → New query → paste → Run
-- ════════════════════════════════════════════════════════

-- 1. CREATE TABLES

create table if not exists public.announcements (
  id         text        primary key,
  title      text        not null,
  category   text        not null,
  author     text        not null default 'BHSS McMaster',
  date       timestamptz not null default now(),
  read_time  int         not null default 1,
  excerpt    text        not null,
  body       text        not null,
  image      text        not null default '',
  views      int         not null default 0,
  pinned     boolean     not null default false,
  created_at timestamptz not null default now()
);

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

create table if not exists public.resources (
  id           text        primary key,
  committee_id text        not null,
  title        text        not null,
  url          text        not null,
  sort_order   int         not null default 0,
  created_at   timestamptz not null default now()
);

-- 2. ENABLE ROW LEVEL SECURITY

alter table public.announcements enable row level security;
alter table public.members       enable row level security;
alter table public.resources     enable row level security;

-- 3. ALLOW ALL OPERATIONS
-- The admin page is password-protected at the app level.
-- The anon key is used for both public reads and admin writes.

create policy "allow_all" on public.announcements for all using (true) with check (true);
create policy "allow_all" on public.members       for all using (true) with check (true);
create policy "allow_all" on public.resources     for all using (true) with check (true);

-- 4. MIGRATE EXISTING ANNOUNCEMENTS

insert into public.announcements (id, title, category, author, date, read_time, excerpt, body, image, views, pinned) values
(
  'bhss-elections-campaign-materials',
  'BHSS Elections Campaign Materials',
  'Elections', 'BHSS McMaster', '2026-03-28T00:00:00Z', 1,
  'Hey HHSP! Get excited because the voting period for the 2026/27 BHSS Spring General Election is now open. Find all campaign materials, candidate profiles, and voting information here.',
  'Hey HHSP! Get excited because the voting period for the 2026/27 BHSS Spring General Election is now open. The voting period will run from March 27 at 9:00 AM to March 31 at 9:00 AM. To cast your vote, please refer to the email you will receive from the MSU voting system. Campaign materials from all candidates are linked below. If you have any questions, feel free to reach out to bhssele@mcmaster.ca.',
  'assets/images/banners/log_banner@4x.png', 11, true
),
(
  'Welcome-to-the-new-bhss-website',
  'Welcome to the new BHSS website!',
  'General', 'BHSS McMaster', '2026-03-28T00:00:00Z', 2,
  'The BHSS website has been completely redesigned to offer a smoother, more user-friendly experience for all Health Sci students.',
  'The BHSS website has been completely redesigned to offer a smoother, more user-friendly experience for all Health Sci students. We''re in the process of gathering everything Health Sci and putting it in one place. Over time, this resource will slowly grow and house all things Health Sci, for us, by us. If you notice any issues or have suggestions, please reach out to bhsscom@mcmaster.ca.',
  'assets/images/banners/com_banner@4x.png', 1, false
),
(
  'biannual-formal-bylaw-vote',
  'Biannual Formal Bylaw Vote',
  'Social', 'BHSS McMaster', '2026-03-28T00:00:00Z', 1,
  'BHSS Socials is proposing a shift to a biannual formal model, meaning formals would typically take place every other year.',
  'BHSS Socials is proposing a shift to a biannual formal model, meaning formals would typically take place every other year (e.g., 2026, 2028, 2030), with flexibility to host events in off-years if desired. This proposal comes in response to declining attendance over the past three years, along with increasing financial pressure to run the event annually. Please read the full proposal before voting. Voting closes March 31, 2026. https://forms.gle/yu29fZcVi7ccuG2f9. If you have any questions or additional comments, feel free to reach out to us at bhsssoc@mcmaster.ca.',
  'assets/images/banners/soc_banner@4x.png', 3, false
),
(
  'catalyst-funding-deadline',
  'Last Call for Catalyst Funding',
  'Finance', 'BHSS McMaster', '2026-03-25T00:00:00Z', 1,
  'The clock is ticking for the final round of Catalyst funding applications of the year. Deadline: March 31st, 2026.',
  'The clock is ticking for the final round of Catalyst funding applications of the year! Don''t miss your last chance to secure the resources your group needs. If you feel that there are spaces, communities, issues etc. that are underrepresented in our HHSP community, click the link in our bio to share your feedback and ideas! This could be something that would enhance an existing space or community, or could be a completely new initiative. With support from the BHSS Community Catalyst Fund you can bring your idea to life! Deadline: March 31st, 2026.',
  'assets/images/banners/fin_banner@4x.png', 8, false
),
(
  'edi-culture-day',
  'BHSS EDI Culture Day',
  'General', 'BHSS McMaster', '2026-03-20T00:00:00Z', 1,
  'BHSS EDI is hosting our first ever culture day! Attendees are encouraged to bring their cultural foods, clothes, or collaborate on a trifold.',
  'BHSS EDI is hosting our first ever culture day! Attendees are encouraged to bring their cultural foods, clothes, or collaborate with other peers on a trifold to represent their cultural background(s). Find more information and RSVP at the link in our bio.',
  'assets/images/banners/com_banner@4x.png', 5, false
),
(
  'spring-elections-voting-open',
  'Spring 2026 Elections Voting Now Open',
  'Elections', 'BHSS McMaster', '2026-03-27T00:00:00Z', 1,
  'Voting is now open for the BHSS Spring 2026 Elections. The voting period runs March 27–31 at 9:00 AM.',
  'Hey HHSP! Voting is now open for the BHSS Spring 2026 Elections. The voting period will run from March 27 at 9:00 AM to March 31 at 9:00 AM. To cast your vote, please refer to the email you will receive from the MSU voting system. If you have any questions, feel free to reach out!',
  'assets/images/banners/log_banner@4x.png', 14, false
),
(
  'hot-breakfast-march',
  'Hot Breakfast Alert — Pancakes & Turkey Bacon!',
  'Finance', 'BHSS McMaster', '2026-03-24T00:00:00Z', 1,
  'Come to the Health Sci Lounge this Wednesday for pancakes and turkey bacon! Wednesday, March 25th | 10am–12pm.',
  'Come to the Health Sci Lounge this Wednesday for pancakes and turkey bacon! Wednesday, March 25th | 10am–12pm | Health Science Lounge. The setup: Take up to 2 items. Weekly staples: fruit, cereal, granola bars, tea, hot chocolate. March specialty: Turkey bacon and pancakes!',
  'assets/images/banners/fin_banner@4x.png', 22, false
),
(
  'nominations-open-spring-election',
  'Nomination Forms Now Open — Spring General Election',
  'Elections', 'BHSS McMaster', '2026-03-10T00:00:00Z', 2,
  'Nomination forms for the 2026-2027 Spring General Election are now open. Submit by March 18th at 5 PM EST.',
  'Nomination forms for the 2026-2027 Spring General Election are now OPEN. If you are interested in this great opportunity to advocate for HHSP and showcase our diverse student body, please complete the nomination form linked in our bio and send a PDF to the Election Coordinators (bhssele@mcmaster.ca) by March 18th at 5 PM. There will be no exceptions. As part of the nomination process, we now require completion of a quiz to ensure candidates are well-informed about the election process.',
  'assets/images/banners/log_banner@4x.png', 19, false
),
(
  'brain-bites-midterm-season',
  'BHSS Brain Bites — Free Snacks Every Thursday',
  'Finance', 'BHSS McMaster', '2026-03-12T00:00:00Z', 1,
  'Free snacks every Thursday 1:30–4:00 PM for midterm season. Goldfish, juice, chocolates, ramen, and more!',
  'Studying nonstop? Don''t forget to pause. We''re hosting BHSS Brain Bites for students during midterm season. Stop by, take a break, and recharge! We''ve got Goldfish, Juice, Brookside Chocolates, Protein Granola Bars, Seaweed, Buldak Ramen, and MORE! 1:30pm–4:00pm every Thursday until the end of the semester!',
  'assets/images/banners/fin_banner@4x.png', 31, false
),
(
  'discount-card-launch',
  'BHSS Discount Card is Here!',
  'Finance', 'BHSS McMaster', '2026-03-05T00:00:00Z', 1,
  'Our BHSS Discount Card gives students access to exclusive savings at participating local businesses.',
  'Our BHSS Discount Card gives students access to exclusive savings at participating local businesses. It''s our way of supporting the community while helping students save on food, game cafes, and more! Cards are available at the BHSS Office and BHSS Breakfast. Make sure to grab your card and start saving!',
  'assets/images/banners/fin_banner@4x.png', 17, false
),
(
  'casino-night',
  'BHSS Finance presents Casino Night!',
  'Finance', 'BHSS McMaster', '2026-03-01T00:00:00Z', 1,
  'Join us for an evening of Poker, Craps, Blackjack, board games, a human slot machine, magic show, and more!',
  'Feeling down after the Anat Midterm and want to have some fun? BHSS Finance presents Casino Night! Join us for a fun evening of Poker, Craps, Blackjack, board games, a human slot machine, magic show, and MORE! Buy chips to play and redeem them at the end of the night for a chance to win BHSS merch (tote bags, water bottles, and hats), gift cards and other prizes!',
  'assets/images/banners/fin_banner@4x.png', 9, false
),
(
  'academics-bootcamp',
  'BHSS Academics Bootcamp — Sign Up Now',
  'Academics', 'BHSS McMaster', '2026-02-28T00:00:00Z', 2,
  'Prepare for exam season with the BHSS Academics Bootcamp. Study sessions, peer tutoring, and resource guides available.',
  'Prepare for exam season with the BHSS Academics Bootcamp. We have organized study sessions, peer tutoring, and comprehensive resource guides to help you succeed. Check out the BHSS Academics Google Drive for all resources. Sign up via the link in our bio. Good luck with your studies!',
  'assets/images/banners/aca_banner@4x.png', 43, false
)
on conflict (id) do nothing;
