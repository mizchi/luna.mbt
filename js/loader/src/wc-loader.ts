/*! wc-loader v3 - Web Components Hydration Loader */
import { setupTrigger, onReady, observeAdditions } from "./runtime/triggers";
import { createIslandLifecycle, type MountResult } from "./runtime/islands";

type HydrateFn = (el: Element, state: unknown, id: string) => MountResult;

const d = document;
const S: Record<string, unknown> = {};
const lifecycle = createIslandLifecycle((el) => {
  delete (el as Element & { __lw?: 1 }).__lw;
});

const parseState = (el: Element): unknown => {
  const s = el.getAttribute("luna:wc-state");
  try {
    return JSON.parse(
      s?.[0] === "#" ? (d.getElementById(s.slice(1))?.textContent ?? "{}") : s || "{}",
    );
  } catch {
    return {};
  }
};

const hydrate = async (el: Element): Promise<void> => {
  await lifecycle
    .mount(el, async (isCurrent) => {
      const name = el.tagName.toLowerCase();
      const state = parseState(el);
      const url = el.getAttribute("luna:wc-url");
      if (!url) throw new TypeError("Missing WC island URL");
      // Native import caches by URL, including concurrent requests. Component names
      // may repeat with different URLs during HMR or across independently built islands.
      const mod = (await import(url)) as { hydrate?: HydrateFn; default?: HydrateFn };
      if (!isCurrent()) return;
      const fn = mod.hydrate ?? mod.default;
      if (typeof fn !== "function") throw new TypeError("Missing WC island hydrate export");
      S[name] = state;
      return fn(el, state, name);
    })
    .catch((error) => console.warn("[luna] WC hydration failed:", error));
};

const setup = (el: Element): void => {
  const marker = el as Element & { __lw?: 1 };
  if (marker.__lw) return;
  marker.__lw = 1;
  const t = el.getAttribute("luna:wc-trigger") ?? el.getAttribute("luna:trigger") ?? "load";
  setupTrigger(el, t, () => hydrate(el));
};

const scan = (): void => d.querySelectorAll("[luna\\:wc-url]").forEach(setup);

onReady(scan);
observeAdditions((el) => el.hasAttribute("luna:wc-url"), setup);

const w = window as any;
w.__LUNA_WC_STATE__ = S;
w.__LUNA_WC_SCAN__ = scan;
w.__LUNA_WC_HYDRATE__ = hydrate;
w.__LUNA_WC_UNLOAD__ = (name: string) =>
  lifecycle.unmountWhere((el) => el.tagName.toLowerCase() === name);
w.__LUNA_WC_CLEAR_LOADED__ = () => lifecycle.unmountAll();
const unloadAll = w.__LUNA_UNLOAD_ALL__;
w.__LUNA_UNLOAD_ALL__ = (root: Element) => {
  lifecycle.unmountAll(root);
  unloadAll?.(root);
};
