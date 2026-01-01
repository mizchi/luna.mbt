/*! luna loader v4 - minimal dispatcher */
import { setupTrigger, onReady, observeAdditions, createLoadedTracker } from './lib';

type StateMap = Record<string, unknown>;
type HydrateFn = (el: Element, state: unknown, id: string) => void;

const d = document;
const S: StateMap = {};
const { loaded, unload, clear } = createLoadedTracker();

const parseState = async (el: Element): Promise<unknown> => {
  const a = el.getAttribute('luna:state');
  if (!a) return;
  if (a[0] === '#') return JSON.parse(d.getElementById(a.slice(1))?.textContent ?? 'null');
  try { return JSON.parse(a); } catch { /* ignore */ }
};

const hydrate = async (el: Element): Promise<void> => {
  const id = el.getAttribute('luna:id') ?? el.tagName.toLowerCase();
  if (loaded.has(id)) return;
  loaded.add(id);
  S[id] = await parseState(el);

  // Load module from luna:url
  const url = el.getAttribute('luna:url');
  if (!url) return;

  try {
    const mod = await import(url) as Record<string, HydrateFn>;
    const ex = el.getAttribute('luna:export');
    (ex ? mod[ex] : mod.hydrate ?? mod.default)?.(el, S[id], id);
  } catch (e) {
    console.warn(`[luna] Failed to load ${url}:`, e);
  }
};

const setup = (el: Element): void => {
  const t = el.getAttribute('luna:trigger') ?? 'load';
  setupTrigger(el, t, () => hydrate(el));
};

const scan = (): void => {
  d.querySelectorAll('[luna\\:url]').forEach(setup);
};

// Preload state
d.querySelectorAll('script[type="luna/json"]').forEach(s => {
  if (s.id) S[s.id] = JSON.parse(s.textContent ?? '{}');
});

onReady(scan);
observeAdditions(el => el.hasAttribute('luna:url'), setup);

// Export globals
const w = window as any;
w.__LUNA_STATE__ = S;
w.__LUNA_HYDRATE__ = hydrate;
w.__LUNA_SCAN__ = scan;
w.__LUNA_UNLOAD__ = unload;
w.__LUNA_CLEAR_LOADED__ = clear;
