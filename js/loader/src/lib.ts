/**
 * Shared utilities for Luna loaders
 */

/**
 * Setup hydration trigger for an element
 */
export function setupTrigger(
  el: Element,
  trigger: string,
  hydrate: () => void | Promise<void>
): void {
  if (trigger === 'load') {
    document.readyState === 'loading'
      ? document.addEventListener('DOMContentLoaded', () => hydrate(), { once: true })
      : hydrate();
  } else if (trigger === 'idle') {
    requestIdleCallback(() => hydrate());
  } else if (trigger[0] === 'v') {
    // visible
    new IntersectionObserver((entries, obs) => {
      if (entries.some(e => e.isIntersecting)) {
        obs.disconnect();
        hydrate();
      }
    }, { rootMargin: '50px' }).observe(el);
  } else if (trigger[0] === 'm') {
    // media:query
    const mq = matchMedia(trigger.slice(6));
    const handler = () => {
      if (mq.matches) {
        mq.removeEventListener('change', handler);
        hydrate();
      }
    };
    mq.matches ? hydrate() : mq.addEventListener('change', handler);
  }
}

/**
 * Run function when DOM is ready
 */
export function onReady(fn: () => void): void {
  document.readyState === 'loading'
    ? document.addEventListener('DOMContentLoaded', fn, { once: true })
    : fn();
}

/**
 * Watch for dynamically added elements matching a predicate
 */
export function observeAdditions(
  match: (el: Element) => boolean,
  setup: (el: Element) => void
): void {
  new MutationObserver(mutations =>
    mutations.forEach(m =>
      m.addedNodes.forEach(n => {
        if (n.nodeType === 1 && match(n as Element)) {
          setup(n as Element);
        }
      })
    )
  ).observe(document.body ?? document.documentElement, { childList: true, subtree: true });
}

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
