/*! wc-loader v1 - Web Components Hydration Loader for Luna */
import { setupTrigger, onReady, observeAdditions } from './lib';

// Luna hydrate function signature
type HydrateFn = (el: Element, state: unknown, id: string) => void;

interface WCModule {
  hydrate?: HydrateFn;
  default?: HydrateFn;
  [key: string]: unknown;
}

interface WCWindow extends Window {
  __LUNA_WC_STATE__: Record<string, unknown>;
  __LUNA_WC_SCAN__: () => void;
  __LUNA_WC_HYDRATE__: (el: Element) => Promise<void>;
  __LUNA_WC_UNLOAD__: (name: string) => boolean;
  __LUNA_WC_CLEAR_LOADED__: () => void;
}

const d = document;
const w = window as unknown as WCWindow;
const S: Record<string, unknown> = {};

// Cache loaded hydrate functions by component name
const hydrateFns = new Map<string, HydrateFn>();
// Track pending imports to avoid duplicate loads
const pending = new Map<string, Promise<HydrateFn | undefined>>();

const parseState = async (el: Element): Promise<unknown> => {
  const s = el.getAttribute('luna:wc-state');
  if (!s) return {};
  // Handle script ref (starts with #)
  if (s.startsWith('#')) {
    const scriptEl = d.getElementById(s.slice(1));
    if (scriptEl?.textContent) {
      try { return JSON.parse(scriptEl.textContent); } catch { return {}; }
    }
    return {};
  }
  try {
    // Unescape JSON
    const unescaped = s
      .replace(/\\u003c/g, '<')
      .replace(/\\u003e/g, '>')
      .replace(/\\u0026/g, '&');
    return JSON.parse(unescaped);
  } catch {
    return {};
  }
};

// Load hydrate function for a component (cached, deduped)
const loadHydrateFn = async (name: string, url: string): Promise<HydrateFn | undefined> => {
  // Return cached function
  if (hydrateFns.has(name)) return hydrateFns.get(name);

  // Return pending promise if already loading
  if (pending.has(name)) return pending.get(name);

  // Start loading
  const promise = import(url).then((mod: WCModule) => {
    const fn = mod.hydrate ?? mod.default;
    if (typeof fn === 'function') {
      hydrateFns.set(name, fn);
      return fn;
    }
    console.warn(`[wc-loader] No hydrate function found in ${url}`);
    return undefined;
  }).catch(err => {
    console.error(`[wc-loader] Failed to load ${name}:`, err);
    return undefined;
  }).finally(() => {
    pending.delete(name);
  });

  pending.set(name, promise);
  return promise;
};

const hydrate = async (el: Element): Promise<void> => {
  const name = el.tagName.toLowerCase();
  const url = el.getAttribute('luna:wc-url');
  if (!url) return;

  // Parse state for this element
  const state = await parseState(el);
  S[name] = state;

  // Load and call hydrate function
  const fn = await loadHydrateFn(name, url);
  if (fn) {
    fn(el, state, name);
  }
};

const setup = (el: Element): void => {
  const t = el.getAttribute('luna:wc-trigger') ?? 'load';
  setupTrigger(el, t, () => hydrate(el));
};

const scan = (): void => {
  d.querySelectorAll('[luna\\:wc-url]').forEach(setup);
};

onReady(scan);

// Watch for dynamically added Web Components
observeAdditions(
  el => el.hasAttribute('luna:wc-url'),
  setup
);

// Utility functions for HMR/dev mode
const unload = (name: string): boolean => hydrateFns.delete(name);
const clear = (): void => hydrateFns.clear();

w.__LUNA_WC_STATE__ = S;
w.__LUNA_WC_SCAN__ = scan;
w.__LUNA_WC_HYDRATE__ = hydrate;
w.__LUNA_WC_UNLOAD__ = unload;
w.__LUNA_WC_CLEAR_LOADED__ = clear;
