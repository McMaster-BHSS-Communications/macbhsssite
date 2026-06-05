/* ═══════════════════════════════════════════════════════════════
   committee.js — Shared logic for all individual committee pages
   Requires: const COMMITTEE_ID = '...'; defined before this script
             window.db (Supabase client) from supabase-client.js
═══════════════════════════════════════════════════════════════ */

function _esc(s) {
  return String(s)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;')
    .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

// ── RENDER RESOURCES ──
async function renderResources() {
  const el = document.getElementById('resourceList');
  if (!el) return;

  try {
    const { data, error } = await window.db
      .from('resources')
      .select('*')
      .eq('committee_id', COMMITTEE_ID)
      .order('created_at', { ascending: true });
    if (error) throw error;

    const items = data || [];
    if (!items.length) {
      el.innerHTML = '<p class="resource-empty">No resources added yet.</p>';
      return;
    }
    el.innerHTML = items.map(r => `
      <div class="resource-item">
        <div class="resource-icon">
          <img src="../assets/images/BHSSshield_100x97.png" alt="" />
        </div>
        <a class="resource-link" href="${_esc(r.url)}" target="_blank" rel="noopener">${_esc(r.title)}</a>
      </div>`).join('');
  } catch (err) {
    console.warn('Could not load resources from Supabase:', err);
    el.innerHTML = '<p class="resource-empty">No resources added yet.</p>';
  }
}

// ── RENDER MEMBERS ──
async function renderMembers() {
  try {
    const { data, error } = await window.db
      .from('members')
      .select('*')
      .eq('committee_id', COMMITTEE_ID)
      .order('is_coordinator', { ascending: false })
      .order('created_at', { ascending: true });
    if (error) throw error;

    const members = data || [];
    const coords = members.filter(m => m.is_coordinator);
    const rest   = members.filter(m => !m.is_coordinator);

    const coordEl = document.getElementById('coordinatorCard');
    if (coordEl) {
      coordEl.innerHTML = coords.length
        ? coords.map(m => _cardHTML(m, true)).join('')
        : '<p class="people-empty">No coordinator set yet.</p>';
    }

    const gridEl = document.getElementById('membersGrid');
    if (gridEl) {
      gridEl.innerHTML = rest.length
        ? rest.map(m => _cardHTML(m, false)).join('')
        : '<p class="people-empty" style="grid-column:1/-1">No members added yet.</p>';
    }
  } catch (err) {
    console.warn('Could not load members from Supabase:', err);
  }
}

function _cardHTML(m, large) {
  const cls   = large ? 'person-card coordinator' : 'person-card';
  const photo = m.photo
    ? `<img class="person-photo" src="${_esc(m.photo)}" alt="" />`
    : `<div class="person-shield-bg"><img src="../assets/images/BHSSshield_100x97.png" alt="" /></div>`;
  return `<div class="${cls}">
    <div class="person-card-top">${photo}<div class="person-firstname">${_esc(m.first_name)}</div></div>
    <div class="person-card-bottom">
      <div class="person-lastname">${_esc(m.last_name)}</div>
      <div class="person-role">${_esc(m.role)}</div>
    </div>
  </div>`;
}

// ── AUTO-HIGHLIGHT ACTIVE SUB-NAV TAB ──
(function () {
  const current = location.pathname.split('/').pop();
  document.querySelectorAll('.comm-tab').forEach(t => {
    if ((t.getAttribute('href') || '') === current) t.classList.add('active');
  });
})();

// ── INIT ──
renderResources();
renderMembers();
