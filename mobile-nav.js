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
  const cp   = root + 'committeepages/';

  const chevron = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg>`;

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

    <div class="mob-dropdown">
      <div class="mob-dropdown-row">
        <a href="${root}announcements.html">Announcements</a>
        <button class="mob-chevron-btn" aria-expanded="false" aria-label="Toggle Announcements menu">${chevron}</button>
      </div>
      <div class="mob-dropdown-panel">
        <a href="${root}announcements.html?filter=General">General</a>
        <a href="${root}announcements.html?filter=Academics">Academics</a>
        <a href="${root}announcements.html?filter=External">External</a>
        <a href="${root}announcements.html?filter=Finance">Finance</a>
        <a href="${root}announcements.html?filter=Internal">Internal</a>
        <a href="${root}announcements.html?filter=Social">Social</a>
        <a href="${root}announcements.html?filter=Elections">Elections</a>
      </div>
    </div>

    <div class="mob-dropdown">
      <div class="mob-dropdown-row">
        <a href="${root}committees.html">Committees</a>
        <button class="mob-chevron-btn" aria-expanded="false" aria-label="Toggle Committees menu">${chevron}</button>
      </div>
      <div class="mob-dropdown-panel">
        <a href="${cp}chr_committee.html">Chair</a>
        <a href="${cp}aca_committee.html">Academics</a>
        <a href="${cp}com_committee.html">Communications</a>
        <a href="${cp}edi_committee.html">Equity, Diversity &amp; Inclusion</a>
        <a href="${cp}ext_committee.html">External</a>
        <a href="${cp}fin_committee.html">Financial</a>
        <a href="${cp}int_committee.html">Internal</a>
        <a href="${cp}log_committee.html">Logistics &amp; Elections</a>
        <a href="${cp}soc_committee.html">Social</a>
        <a href="${cp}wwc_committee.html">Welcome Week</a>
        <a href="${cp}sra_committee.html">SRA</a>
        <div class="mob-panel-section">Year Councils</div>
        <a href="${cp}fyc_committee.html">First Year Council</a>
        <a href="${cp}syc_committee.html">Second Year Council</a>
        <a href="${cp}tyc_committee.html">Third Year Council</a>
        <a href="${cp}4yc_committee.html">Fourth Year Council</a>
      </div>
    </div>

    <a href="${root}resources.html">Resources</a>
    <a href="${root}shop.html">Store</a>
    <a href="${root}bags.html">BAGs</a>
    <a href="${root}about.html">About Us</a>
    <div class="mob-cta"><a href="${root}resources.html">Academic Resources</a></div>
  `;

  document.body.appendChild(overlay);
  document.body.appendChild(nav);

  // ── WIRE UP OPEN / CLOSE ──
  const ham = document.querySelector('.hamburger');
  if (!ham) return;

  const open  = () => { nav.classList.add('open'); overlay.classList.add('open'); document.body.style.overflow = 'hidden'; };
  const close = () => { nav.classList.remove('open'); overlay.classList.remove('open'); document.body.style.overflow = ''; };

  ham.addEventListener('click', open);
  document.getElementById('mobileNavClose').addEventListener('click', close);
  overlay.addEventListener('click', close);
  document.addEventListener('keydown', e => { if (e.key === 'Escape') close(); });

  // ── DROPDOWN TOGGLES ──
  nav.querySelectorAll('.mob-chevron-btn').forEach(btn => {
    const panel = btn.closest('.mob-dropdown').querySelector('.mob-dropdown-panel');
    btn.addEventListener('click', () => {
      const isOpen = btn.getAttribute('aria-expanded') === 'true';
      btn.setAttribute('aria-expanded', !isOpen);
      panel.style.maxHeight = isOpen ? '0' : panel.scrollHeight + 'px';
    });
  });
})();
