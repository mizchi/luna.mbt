import { initIslands } from "void/pages-client";
import { createRoot, render, type LunaNode } from "../index";
import type { Dispose, Island, IslandManifest } from "./contracts";

/** Luna's public JS renderer replaces the fallback DOM; it does not hydrate it. */
export function defineLunaIsland<P extends object>(
  component: (props: P) => LunaNode,
): {
  mount(element: Element, props: P): Dispose;
} {
  return {
    mount(element, props) {
      return createRoot((dispose: Dispose) => {
        try {
          render(element, () => component(props));
          return dispose;
        } catch (error) {
          dispose();
          throw error;
        }
      }) as Dispose;
    },
  };
}

/** Schedule mixed-renderer islands with Void, retaining each renderer's cleanup. */
export function initLunaIslands(manifest: IslandManifest): Dispose {
  let stopped = false;
  const mounted = new Map<Element, Dispose>();
  const active = new WeakSet<Element>();
  const observer = new MutationObserver(() => {
    for (const [element, dispose] of mounted) {
      if (!element.isConnected) {
        mounted.delete(element);
        dispose();
      }
    }
  });
  observer.observe(document.documentElement, { childList: true, subtree: true });
  initIslands(Object.assign(Object.create(null), manifest), async (element, module, props) => {
    if (stopped || !element.isConnected || active.has(element)) return;
    active.add(element);
    const island = (module as { default?: Island }).default;
    if (!island || typeof island.mount !== "function") {
      throw new TypeError(
        "Void island modules must default-export an object with mount(element, props)",
      );
    }
    const dispose = await island.mount(element, props);
    if (typeof dispose === "function") {
      if (stopped || !element.isConnected) dispose();
      else mounted.set(element, dispose);
    }
    if (!stopped && element.isConnected) element.setAttribute("data-luna-mounted", "true");
  });
  return () => {
    if (stopped) return;
    stopped = true;
    observer.disconnect();
    for (const dispose of mounted.values()) dispose();
    mounted.clear();
  };
}

export type { Dispose, Island, IslandManifest } from "./contracts";
