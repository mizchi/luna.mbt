/*! wc-loader v1 - Web Components Hydration Loader */
import { setupTrigger, onReady, observeAdditions, createLoadedTracker } from './lib';

interface WCComponentDef {
  name: string;
  [key: string]: unknown;
}

interface WCSSRGlobal {
  registerComponent: (def: WCComponentDef) => void;
}

interface WCWindow extends Window {
  __WCSSR__?: WCSSRGlobal;
  __WC_SCAN__: () => void;
  __WC_HYDRATE__: (el: Element) => Promise<void>;
  __WC_UNLOAD__: (name: string) => boolean;
  __WC_CLEAR_LOADED__: () => void;
}

interface WCElement extends HTMLElement {
  dataset: DOMStringMap & {
    state?: string;
    wcUrl?: string;
    trigger?: string;
  };
}

const d = document;
const w = window as unknown as WCWindow;
const { loaded, unload, clear } = createLoadedTracker();

const parseState = (el: WCElement): Record<string, unknown> => {
  const s = el.dataset.state;
  if (!s) return {};
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

const hydrate = async (el: WCElement): Promise<void> => {
  const name = el.tagName.toLowerCase();
  if (loaded.has(name)) return;

  const url = el.dataset.wcUrl;
  if (!url) return;
  loaded.add(name);

  try {
    const mod = await import(url) as Record<string, WCComponentDef>;
    const def = mod.default ?? mod[name];

    if (def && typeof def === 'object') {
      if (w.__WCSSR__?.registerComponent) {
        w.__WCSSR__.registerComponent(def);
      } else {
        const { registerComponent } = await import('@mizchi/wcssr/client');
        registerComponent(def);
      }
    }
  } catch (err) {
    console.error(`[wc-loader] Failed to hydrate ${name}:`, err);
  }
};

const setup = (el: WCElement): void => {
  const t = el.dataset.trigger ?? 'load';
  setupTrigger(el, t, () => hydrate(el));
};

const scan = (): void => {
  d.querySelectorAll<WCElement>('[data-wc-url]').forEach(setup);
};

onReady(scan);

// Watch for dynamically added Web Components
observeAdditions(
  el => !!(el as WCElement).dataset?.wcUrl,
  el => setup(el as WCElement)
);

w.__WC_SCAN__ = scan;
w.__WC_HYDRATE__ = hydrate;
w.__WC_UNLOAD__ = unload;
w.__WC_CLEAR_LOADED__ = clear;
