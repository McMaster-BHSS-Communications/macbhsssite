// sync-notion-calendar — copies the public rows of two Notion databases into
// public.calendar_events. Deploy via Supabase Dashboard → Edge Functions
// (turn OFF "Verify JWT"; auth is checked in here), or `supabase functions deploy`.
//
// Secrets (Dashboard → Edge Functions → Secrets):
//   NOTION_TOKEN  — internal integration token (secret_… / ntn_…)
//   CRON_SECRET   — random string; must match the one in the pg_cron job
// SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY / SUPABASE_ANON_KEY are injected automatically.
//
// Callers: pg_cron (x-cron-secret header) or a signed-in admin (Authorization: Bearer <jwt>,
// from admin.html's "Sync now" button).

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const NOTION_VERSION = '2025-09-03';
const TZ = 'America/Toronto';

// Notion data source ids (not database ids)
const EVENTS_DS   = '35ffe270-18d9-8099-b0e7-000bf31cd192';
const ACADEMIC_DS = '35ffe270-18d9-80ec-b566-000bbf7f17e5';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-cron-secret',
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...CORS, 'Content-Type': 'application/json' } });

// ── Notion helpers ──────────────────────────────────────────────────
async function notion(path: string, init: RequestInit = {}) {
  const res = await fetch('https://api.notion.com/v1' + path, {
    ...init,
    headers: {
      Authorization: `Bearer ${Deno.env.get('NOTION_TOKEN')}`,
      'Notion-Version': NOTION_VERSION,
      'Content-Type': 'application/json',
    },
  });
  if (!res.ok) throw new Error(`Notion ${res.status} on ${path}: ${(await res.text()).slice(0, 300)}`);
  return res.json();
}

async function queryPublic(dataSourceId: string) {
  const pages: any[] = [];
  let cursor: string | undefined;
  do {
    const data = await notion(`/data_sources/${dataSourceId}/query`, {
      method: 'POST',
      body: JSON.stringify({
        filter: { property: 'Public?', checkbox: { equals: true } },
        page_size: 100,
        ...(cursor ? { start_cursor: cursor } : {}),
      }),
    });
    pages.push(...data.results);
    cursor = data.has_more ? data.next_cursor : undefined;
  } while (cursor);
  return pages;
}

const plain = (rich: any[] | undefined) => (rich ?? []).map((r) => r.plain_text).join('').trim();

// ── Timezone handling (everything is Eastern, EST/EDT) ──────────────
// Offset string like "-04:00" for a given Toronto wall-clock time.
function torontoOffset(y: number, m: number, d: number, h = 12): string {
  const probe = new Date(Date.UTC(y, m - 1, d, h));
  const part = new Intl.DateTimeFormat('en-US', { timeZone: TZ, timeZoneName: 'longOffset' })
    .formatToParts(probe).find((p) => p.type === 'timeZoneName')!.value; // "GMT-04:00"
  const off = part.replace('GMT', '');
  return off === '' ? '+00:00' : off;
}

// Returns an ISO instant + whether the Notion value was date-only.
function parseNotionDate(s: string): { iso: string; allDay: boolean } {
  if (/^\d{4}-\d{2}-\d{2}$/.test(s)) {
    const [y, m, d] = s.split('-').map(Number);
    return { iso: `${s}T00:00:00${torontoOffset(y, m, d)}`, allDay: true };
  }
  if (/(Z|[+-]\d{2}:\d{2})$/.test(s)) return { iso: new Date(s).toISOString(), allDay: false };
  // Datetime with no offset → treat as Toronto wall-clock time
  const [y, m, d] = s.slice(0, 10).split('-').map(Number);
  const h = Number(s.slice(11, 13)) || 12;
  return { iso: new Date(`${s.slice(0, 19)}${torontoOffset(y, m, d, h)}`).toISOString(), allDay: false };
}

// ── Row mappers ─────────────────────────────────────────────────────
type Row = {
  notion_id: string; source: 'events' | 'academic'; title: string;
  start_at: string; end_at: string | null; all_day: boolean;
  category: string | null; levels: string[]; bag_name: string | null;
};

const committeeCache = new Map<string, string>();
async function committeeName(pageId: string): Promise<string> {
  if (committeeCache.has(pageId)) return committeeCache.get(pageId)!;
  const page = await notion(`/pages/${pageId}`);
  const titleProp: any = Object.values(page.properties).find((p: any) => p.type === 'title');
  const name = plain(titleProp?.title);
  committeeCache.set(pageId, name);
  return name;
}

async function mapEvent(page: any): Promise<Row | null> {
  const p = page.properties;
  const date = p['Date']?.date;
  const title = plain(p['Event Name']?.title);
  if (!date?.start || !title) return null; // can't show an undated/untitled event
  const start = parseNotionDate(date.start);
  const end = date.end ? parseNotionDate(date.end) : null;
  const names = await Promise.all((p['Committee']?.relation ?? []).map((r: any) => committeeName(r.id)));
  const bag = plain(p['BAG Name (if applicable)']?.rich_text) || null;
  return {
    notion_id: page.id, source: 'events', title,
    start_at: start.iso, end_at: end?.iso ?? null, all_day: start.allDay,
    category: names.filter(Boolean).join(', ') || (bag ? 'BAG' : 'General'),
    levels: [], bag_name: bag,
  };
}

function mapAcademic(page: any): Row | null {
  const p = page.properties;
  const date = p['Date']?.date;
  const title = plain(p['Name']?.title);
  if (!date?.start || !title) return null;
  const start = parseNotionDate(date.start);
  const end = date.end ? parseNotionDate(date.end) : null;
  return {
    notion_id: page.id, source: 'academic', title,
    start_at: start.iso, end_at: end?.iso ?? null, all_day: start.allDay,
    category: p['Type']?.select?.name ?? null,
    levels: (p['Level']?.multi_select ?? []).map((o: any) => o.name),
    bag_name: null,
  };
}

// ── Sync one source: upsert current rows, delete the ones that vanished ──
async function syncSource(db: any, source: 'events' | 'academic', rows: Row[]) {
  const { data: existing, error: e1 } = await db.from('calendar_events').select('notion_id').eq('source', source);
  if (e1) throw e1;
  const have = new Set((existing ?? []).map((r: any) => r.notion_id));
  const keep = new Set(rows.map((r) => r.notion_id));

  const added = rows.filter((r) => !have.has(r.notion_id)).length;
  const updated = rows.length - added;

  const now = new Date().toISOString();
  for (let i = 0; i < rows.length; i += 500) {
    const chunk = rows.slice(i, i + 500).map((r) => ({ ...r, synced_at: now }));
    const { error } = await db.from('calendar_events').upsert(chunk, { onConflict: 'notion_id' });
    if (error) throw error;
  }

  const gone = [...have].filter((id) => !keep.has(id));
  for (let i = 0; i < gone.length; i += 200) {
    const { error } = await db.from('calendar_events').delete().in('notion_id', gone.slice(i, i + 200));
    if (error) throw error;
  }
  return { added, updated, removed: gone.length };
}

// ── Handler ─────────────────────────────────────────────────────────
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });

  const url = Deno.env.get('SUPABASE_URL')!;
  const db = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

  // Auth: cron secret OR a signed-in Supabase user (the admin).
  let trigger: 'cron' | 'manual';
  const cronSecret = Deno.env.get('CRON_SECRET');
  if (cronSecret && req.headers.get('x-cron-secret') === cronSecret) {
    trigger = 'cron';
  } else {
    const jwt = (req.headers.get('Authorization') ?? '').replace(/^Bearer\s+/i, '');
    const { data, error } = jwt ? await db.auth.getUser(jwt) : { data: null, error: true };
    if (error || !data?.user) return json({ error: 'Unauthorized' }, 401);
    trigger = 'manual';
  }

  const total = { added: 0, updated: 0, removed: 0 };
  const errors: string[] = [];

  // Each source is independent: if one Notion query fails we leave that source's
  // existing rows untouched (never delete on a failed fetch).
  for (const [source, ds] of [['events', EVENTS_DS], ['academic', ACADEMIC_DS]] as const) {
    try {
      const pages = await queryPublic(ds);
      const mapped = source === 'events'
        ? await Promise.all(pages.map(mapEvent))
        : pages.map(mapAcademic);
      const rows = mapped.filter((r): r is Row => r !== null);
      const r = await syncSource(db, source, rows);
      total.added += r.added; total.updated += r.updated; total.removed += r.removed;
    } catch (e) {
      errors.push(`${source}: ${e instanceof Error ? e.message : JSON.stringify(e)}`);
    }
  }

  await db.from('calendar_sync_status').upsert({
    id: 1,
    last_synced_at: new Date().toISOString(),
    trigger, ...total,
    error: errors.length ? errors.join(' | ') : null,
  });

  return json({ ok: errors.length === 0, trigger, ...total, errors }, errors.length ? 502 : 200);
});
