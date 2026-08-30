/* ═══════════════════════════════════════════════════════════════
   mobile-nav.js — Universal mobile navigation drawer
   Injects the nav overlay + drawer HTML into the page and wires
   up open/close behaviour. Works for both root-level pages and
   pages inside committees/.

   To update nav links for every page at once, edit this file only.
═══════════════════════════════════════════════════════════════ */
(function () {
  // All links are root-relative + extensionless, so they resolve from any page.
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

    <a href="/">Home</a>

    <div class="mob-dropdown">
      <div class="mob-dropdown-row">
        <a href="/committees">Committees</a>
        <button class="mob-chevron-btn" aria-expanded="false" aria-label="Toggle Committees menu">${chevron}</button>
      </div>
      <div class="mob-dropdown-panel">
        <a href="/committees/chair">Chair</a>
        <a href="/committees/academics">Academics</a>
        <a href="/committees/communications">Communications</a>
        <a href="/committees/edi">Equity, Diversity &amp; Inclusion</a>
        <a href="/committees/external">External</a>
        <a href="/committees/financial">Financial</a>
        <a href="/committees/internal">Internal</a>
        <a href="/committees/logistics">Logistics &amp; Elections</a>
        <a href="/committees/social">Social</a>
        <a href="/committees/welcome-week">Welcome Week</a>
        <a href="/committees/sra">SRA</a>
        <div class="mob-panel-section">Year Councils</div>
        <a href="/committees/first-year-council">First Year Council</a>
        <a href="/committees/second-year-council">Second Year Council</a>
        <a href="/committees/third-year-council">Third Year Council</a>
        <a href="/committees/fourth-year-council">Fourth Year Council</a>
      </div>
    </div>

    <a href="/resources">Resources</a>
    <a href="/shop">Store</a>
    <a href="/bags">BAGs</a>
    <a href="/student-events">Student Events</a>
    <a href="/about">About Us</a>
    <a href="/contact">Contact</a>
    <div class="mob-cta"><a href="https://drive.google.com/drive/folders/1YlpnrLa7I39miOYMrV8sf2DoPRnFAx20">Academic Resources</a></div>
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
