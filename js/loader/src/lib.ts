export { setupTrigger, onReady, observeAdditions } from "./runtime/triggers";

/**
 * Create a loaded tracker with unload utilities
 */
export function createLoadedTracker(): {
  loaded: Set<string>;
  isLoaded: (el: Element) => boolean;
  markLoaded: (el: Element) => void;
  unload: (id: string) => boolean;
  clear: () => void;
} {
  const loaded = new Set<string>();
  const loadedEpoch = new WeakMap<Element, number>();
  let currentEpoch = 0;

  const escapeSelector = (id: string): string => {
    const css = globalThis.CSS;
    if (css && typeof css.escape === 'function') return css.escape(id);
    return id.replace(/[\\"]/g, '\\$&');
  };

  return {
    loaded,
    isLoaded: (el: Element) => loadedEpoch.get(el) === currentEpoch,
    markLoaded: (el: Element) => {
      loadedEpoch.set(el, currentEpoch);
      const id = el.getAttribute('luna:id') ?? el.tagName.toLowerCase();
      loaded.add(id);
    },
    unload: (id: string) => {
      document
        .querySelectorAll(`[luna\\:id="${escapeSelector(id)}"]`)
        .forEach(el => loadedEpoch.delete(el));
      return loaded.delete(id);
    },
    clear: () => {
      currentEpoch += 1;
      loaded.clear();
    },
  };
}
