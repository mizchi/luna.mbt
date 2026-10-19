import { createRoot, render, type LunaNode } from "../index";
import type { Dispose } from "./contracts";

export { initLunaIslands } from "./scheduler";

/** Render a DOM-only Luna component; SSR JSX uses the void/hydrate entry. */
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

export type { Dispose, Island, IslandManifest } from "./contracts";
