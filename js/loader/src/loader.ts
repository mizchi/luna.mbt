/*! luna loader v4 - minimal dispatcher */
import { createLoadedTracker, observeAdditions, onReady, setupTrigger } from './lib';

type HydrateFn = (el: Element, state: unknown, id: string) => void;
type LunaWindow = Window &
  typeof globalThis & {
    __LUNA_ALLOWED_HOSTS__?: string[] | string;
    __LUNA_STATE__?: Record<string, unknown>;
    __LUNA_HYDRATE__?: (el: Element) => Promise<void>;
    __LUNA_SCAN__?: () => void;
    __LUNA_UNLOAD__?: (id: string) => boolean;
    __LUNA_CLEAR_LOADED__?: () => void;
    __LUNA_SET_ALLOWED_HOSTS__?: (hosts: string[] | string) => void;
    __LUNA_SCAN_DEFER__?: () => void;
  };

const d = document;
const S: Record<string, unknown> = {};
const { isLoaded, markLoaded, unload, clear } = createLoadedTracker();

const normalizeAllowedEntries = (raw: unknown): string[] => {
  if (Array.isArray(raw)) {
    return raw.map(v => `${v}`.trim().toLowerCase()).filter(Boolean);
  }
  if (typeof raw === 'string') {
    return raw.split(',').map(v => v.trim().toLowerCase()).filter(Boolean);
  }
  return [];
};

const getAllowedHostEntries = (): string[] =>
  normalizeAllowedEntries((globalThis as LunaWindow).__LUNA_ALLOWED_HOSTS__);

const isAllowedModuleUrl = (rawUrl: string | null): string | undefined => {
  if (!rawUrl) return undefined;

  let parsed: URL;
  try {
    parsed = new URL(rawUrl, d.baseURI || location.href);
  } catch {
    console.warn(`[luna] Blocked invalid module URL: ${rawUrl}`);
    return undefined;
  }

  if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') {
    console.warn(`[luna] Blocked non-http(s) module URL: ${rawUrl}`);
    return undefined;
  }

  if (parsed.origin === location.origin) return parsed.href;

  const allowed = getAllowedHostEntries();
  const origin = parsed.origin.toLowerCase();
  const host = parsed.hostname.toLowerCase();
  const hostPort = parsed.host.toLowerCase();
  if (allowed.includes(origin) || allowed.includes(host) || allowed.includes(hostPort)) {
    return parsed.href;
  }

  console.warn(
    `[luna] Blocked cross-origin module URL: ${parsed.href}. ` +
      'Set window.__LUNA_ALLOWED_HOSTS__ to allow this host.'
  );
  return undefined;
};

const setAllowedHosts = (hosts: string[] | string): void => {
  (globalThis as LunaWindow).__LUNA_ALLOWED_HOSTS__ =
    Array.isArray(hosts) || typeof hosts === 'string' ? hosts : [];
};

const parseState = async (el: Element): Promise<unknown> => {
  const raw = el.getAttribute('luna:state');
  if (!raw) return undefined;
  if (raw[0] === '#') {
    return JSON.parse(d.getElementById(raw.slice(1))?.textContent ?? 'null');
  }
  if (raw.startsWith('url:')) {
    const response = await fetch(raw.slice(4));
    return response.ok ? response.json() : undefined;
  }
  try {
    return JSON.parse(raw);
  } catch {
    return undefined;
  }
};

const hydrate = async (el: Element): Promise<void> => {
  const id = el.getAttribute('luna:id') ?? el.tagName.toLowerCase();
  const url = isAllowedModuleUrl(el.getAttribute('luna:url'));
  if (!url) {
    // A later allowed-host update and scan can schedule this element again.
    delete (el as Element & { __lunaSetup?: 1 }).__lunaSetup;
    return;
  }
  if (isLoaded(el)) return;

  markLoaded(el);
  S[id] = await parseState(el);

  try {
    const mod = (await import(url)) as Record<string, HydrateFn | undefined>;
    const ex = el.getAttribute('luna:export');
    (ex ? mod[ex] : mod.hydrate ?? mod.default)?.(el, S[id], id);
  } catch (e) {
    console.warn(`[luna] Failed to load ${url}:`, e);
  }
};

const setup = (el: Element): void => {
  const marker = el as Element & { __lunaSetup?: 1 };
  if (marker.__lunaSetup) return;
  marker.__lunaSetup = 1;

  const trigger =
    el.getAttribute('luna:client-trigger') ?? el.getAttribute('luna:trigger') ?? 'load';
  setupTrigger(el, trigger, () => hydrate(el));
};

const scan = (): void => {
  d.querySelectorAll('[luna\\:url]').forEach(setup);
};

d.querySelectorAll('script[type="luna/json"]').forEach(s => {
  if (s.id) S[s.id] = JSON.parse(s.textContent ?? '{}');
});

const scanDefer = (): void => {
  d.querySelectorAll('[luna\\:defer]').forEach(el => {
    const url = el.getAttribute('luna:defer');
    if (!url) return;
    el.removeAttribute('luna:defer');
    fetch(url)
      .then(r => (r.ok ? r.text() : ''))
      .then(html => {
        if (html) {
          el.innerHTML = html;
          scan();
        }
      })
      .catch(e => console.warn('[luna] defer fetch failed:', e));
  });
};

onReady(scan);
onReady(scanDefer);
observeAdditions(
  el => el.hasAttribute('luna:url') || el.hasAttribute('luna:defer'),
  el => {
    if (el.hasAttribute('luna:url')) setup(el);
    if (el.hasAttribute('luna:defer')) scanDefer();
  }
);

const w = window as LunaWindow;
w.__LUNA_STATE__ = S;
w.__LUNA_HYDRATE__ = hydrate;
w.__LUNA_SCAN__ = scan;
w.__LUNA_UNLOAD__ = unload;
w.__LUNA_CLEAR_LOADED__ = clear;
w.__LUNA_SET_ALLOWED_HOSTS__ = setAllowedHosts;
w.__LUNA_SCAN_DEFER__ = scanDefer;
