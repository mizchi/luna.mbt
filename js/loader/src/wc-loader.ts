/*! wc-loader v3 - Web Components Hydration Loader */
import { setupTrigger, onReady, observeAdditions } from "./lib";
import { createIslandLifecycle, type MountResult } from "../../shared/runtime/islands";

type HydrateFn = (el: Element, state: unknown, id: string) => MountResult;

const d = document;
const S: Record<string, unknown> = {};
const hydrateFns = new Map<string, HydrateFn>();
const pending = new Map<string, Promise<HydrateFn | undefined>>();
const lifecycle = createIslandLifecycle((el) => {
  delete (el as Element & { __lw?: 1 }).__lw;
});

const parseState = async (el: Element): Promise<unknown> => {
  const s = el.getAttribute("luna:wc-state");
  if (!s) return {};
  if (s[0] === "#") {
    try {
      return JSON.parse(d.getElementById(s.slice(1))?.textContent ?? "{}");
    } catch {
      return {};
    }
  }
  try {
    return JSON.parse(
      s
        .replace(/\\u003c/g, "<")
        .replace(/\\u003e/g, ">")
        .replace(/\\u0026/g, "&"),
    );
  } catch {
    return {};
  }
};

const loadHydrateFn = async (name: string, url: string): Promise<HydrateFn | undefined> => {
  if (hydrateFns.has(name)) return hydrateFns.get(name);
  if (pending.has(name)) return pending.get(name);

  const promise = import(url)
    .then((mod) => {
      const fn = mod.hydrate ?? mod.default;
      if (typeof fn === "function") {
        hydrateFns.set(name, fn);
        return fn;
      }
      return undefined;
    })
    .catch(() => {
      return undefined;
    })
    .finally(() => pending.delete(name));

  pending.set(name, promise);
  return promise;
};

const hydrate = async (el: Element): Promise<void> => {
  await lifecycle
    .mount(el, async (isCurrent) => {
      const name = el.tagName.toLowerCase();
      const state = await parseState(el);
      const url = el.getAttribute("luna:wc-url");
      if (!url) throw new TypeError("Missing WC island URL");
      const fn = await loadHydrateFn(name, url);
      if (!isCurrent()) return;
      if (!fn) throw new TypeError("Missing WC island hydrate export");
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
w.__LUNA_WC_UNLOAD__ = (name: string) => {
  const unloaded = lifecycle.unmountWhere((el) => el.tagName.toLowerCase() === name);
  return hydrateFns.delete(name) || unloaded;
};
w.__LUNA_WC_CLEAR_LOADED__ = () => {
  lifecycle.unmountAll();
  hydrateFns.clear();
};
const unloadAll = w.__LUNA_UNLOAD_ALL__;
w.__LUNA_UNLOAD_ALL__ = (root: Element) => {
  lifecycle.unmountAll(root);
  unloadAll?.(root);
};
