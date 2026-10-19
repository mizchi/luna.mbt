import { createRoot, onCleanup } from "./index";
import * as bridge from "./ssr/bridge";
import { unwrap, type VNode } from "./ssr/node";
import { withServerRendering } from "./render-context";

export type { VNode } from "./ssr/node";

/** Render JSX with the markers required by hydrate(), without using a DOM. */
export function renderToString(component: () => VNode): string {
  return withServerRendering(() =>
    createRoot((dispose) => {
      try {
        return bridge.ssrRender(unwrap(component()));
      } finally {
        dispose();
      }
    }),
  );
}

/** Attach to matching SSR DOM. Mismatches throw instead of replacing the DOM. */
export function hydrate(container: Element, component: VNode | (() => VNode)): () => void {
  return createRoot((dispose) => {
    try {
      const node = typeof component === "function" ? component() : component;
      const result = bridge.ssrHydrate(container, unwrap(node));
      onCleanup(result._1);
      if (result._0) throw new Error(`Luna hydration mismatch: ${result._0}`);
      return dispose;
    } catch (error) {
      dispose();
      throw error;
    }
  });
}
