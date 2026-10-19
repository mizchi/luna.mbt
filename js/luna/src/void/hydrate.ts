import { hydrate, type VNode } from "../ssr";
import type { Dispose } from "./contracts";

/** Hydrate an SSR JSX component without importing the DOM-only renderer. */
export function defineLunaIsland<P extends object>(
  component: (props: P) => VNode,
): {
  mount(element: Element, props: P): Dispose;
} {
  return {
    mount(element, props) {
      return hydrate(element, () => component(props));
    },
  };
}
