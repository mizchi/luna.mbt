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
  unload: (id: string) => boolean;
  clear: () => void;
} {
  const loaded = new Set<string>();
  return {
    loaded,
    unload: (id: string) => loaded.delete(id),
    clear: () => loaded.clear(),
  };
}
