/* ═══════════════════════════════════════════════════════════════
   mobile-nav.js — Universal mobile navigation drawer
   Injects the nav overlay + drawer HTML into the page and wires
   up open/close behaviour. Works for both root-level pages and
   pages inside committeepages/.

   To update nav links for every page at once, edit this file only.
═══════════════════════════════════════════════════════════════ */
(function () {
  // Detect subfolder depth so links resolve correctly
  const root = location.pathname.includes('/committeepages/') ? '../' : '';

  // ── INJECT HTML ──
  const overlay = document.createElement('div');
  overlay.className = 'nav-overlay';
  overlay.id = 'navOverlay';

  const nav = document.createElement('nav');
  nav.className = 'mobile-nav';
  nav.id = 'mobileNav';
  nav.setAttribute('aria-label', 'Mobile navigation');
  nav.innerHTML = `
    <div class="mobile-nav-header">
      <span>Menu</span>
      <button id="mobileNavClose" aria-label="Close menu">&#10005;</button>
    </div>
    <a href="${root}index.html">Home</a>
    <div class="mob-section">Announcements</div>
    <div class="mob-sub">
      <a href="${root}announcements.html">All Announcements</a>
      <a href="${root}announcements.html?filter=Academics">Academics</a>
      <a href="${root}announcements.html?filter=External">External</a>
      <a href="${root}announcements.html?filter=General">General</a>
      <a href="${root}announcements.html?filter=Finance">Finance</a>
      <a href="${root}announcements.html?filter=Internal">Internal</a>
      <a href="${root}announcements.html?filter=Social">Social</a>
      <a href="${root}announcements.html?filter=Elections">Elections</a>
    </div>
    <a href="${root}committees.html">Committees</a>
    <a href="${root}resources.html">Resources</a>
    <a href="${root}shop.html">Store</a>
    <a href="${root}bags.html">BAGs</a>
    <a href="${root}about.html">About Us</a>
    <div class="mob-cta"><a href="${root}resources.html">Academic Resources</a></div>
  `;

  document.body.appendChild(overlay);
  document.body.appendChild(nav);

  // ── WIRE UP EVENTS ──
  const ham = document.querySelector('.hamburger');
  if (!ham) return;

  const open  = () => { nav.classList.add('open'); overlay.classList.add('open'); document.body.style.overflow = 'hidden'; };
  const close = () => { nav.classList.remove('open'); overlay.classList.remove('open'); document.body.style.overflow = ''; };

  ham.addEventListener('click', open);
  document.getElementById('mobileNavClose').addEventListener('click', close);
  overlay.addEventListener('click', close);
  document.addEventListener('keydown', e => { if (e.key === 'Escape') close(); });
})();
