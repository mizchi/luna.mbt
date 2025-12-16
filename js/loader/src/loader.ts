/*! luna loader v1 */
import { setupTrigger, onReady, observeAdditions, createLoadedTracker } from './lib';

type StateMap = Record<string, unknown>;
type HydrateFn = (el: Element, state: unknown, id: string) => void;

interface LunaWindow extends Window {
  __LN_STATE__: StateMap;
  __LN_HYDRATE__: (el: Element) => Promise<void>;
  __LN_SCAN__: () => void;
  __LN_UNLOAD__: (id: string) => boolean;
  __LN_UNLOAD_ALL__: (root?: Element) => void;
  __LN_CLEAR_LOADED__: () => void;
}

const d = document;
const w = window as unknown as LunaWindow;
const S: StateMap = {};
const { loaded, unload, clear } = createLoadedTracker();

const parseState = async (el: Element): Promise<unknown> => {
  const a = el.getAttribute('ln:state');
  if (!a) return;
  if (a[0] === '#') return JSON.parse(d.getElementById(a.slice(1))?.textContent ?? 'null');
  try { return JSON.parse(a); } catch { /* ignore */ }
};

const hydrate = async (el: Element): Promise<void> => {
  const id = el.getAttribute('ln:id');
  if (!id || loaded.has(id)) return;
  loaded.add(id);
  const url = el.getAttribute('ln:url');
  if (!url) return;
  S[id] = await parseState(el);
  const mod = await import(url) as Record<string, HydrateFn>;
  const ex = el.getAttribute('ln:export');
  (ex ? mod[ex] : mod.hydrate ?? mod.default)?.(el, S[id], id);
};

const setup = (el: Element): void => {
  const t = el.getAttribute('ln:trigger') ?? 'load';
  setupTrigger(el, t, () => hydrate(el));
};

const scan = (): void => {
  d.querySelectorAll('[ln\\:id]').forEach(setup);
};

// Preload state from ln/json scripts
d.querySelectorAll('script[type="ln/json"]').forEach(s => {
  if (s.id) S[s.id] = JSON.parse(s.textContent ?? '{}');
});

onReady(scan);

// Watch for dynamically added islands
observeAdditions(
  el => el.hasAttribute('ln:id'),
  setup
);

// Unload all islands within an element (for CSR navigation)
const unloadAll = (root: Element = d.body): void => {
  root.querySelectorAll('[ln\\:id]').forEach(el => {
    const id = el.getAttribute('ln:id');
    if (id) loaded.delete(id);
  });
};

w.__LN_STATE__ = S;
w.__LN_HYDRATE__ = hydrate;
w.__LN_SCAN__ = scan;
w.__LN_UNLOAD__ = unload;
w.__LN_UNLOAD_ALL__ = unloadAll;
w.__LN_CLEAR_LOADED__ = clear;
