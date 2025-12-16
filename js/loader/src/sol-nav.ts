/*! sol-nav v1 - CSR Navigation for Sol Framework */

interface SolWindow extends Window {
  __LN_UNLOAD_ALL__?: (target: Element) => void;
  __LN_SCAN__?: () => void;
  __WC_SCAN__?: () => void;
  __SOL_NAVIGATE__: (url: string, replace?: boolean) => Promise<void>;
  __SOL_PREFETCH__: (url: string) => void;
  __SOL_CACHE__: Map<string, string>;
}

interface HTMLElementWithSetHTMLUnsafe extends HTMLElement {
  setHTMLUnsafe?: (html: string) => void;
}

((d: Document, w: SolWindow) => {
  let isNavigating = false;
  const cache = new Map<string, string>();

  // Set HTML with Declarative Shadow DOM support
  const setHTML = (target: HTMLElementWithSetHTMLUnsafe, html: string): void => {
    if (target.setHTMLUnsafe) {
      // Modern browsers - setHTMLUnsafe processes Declarative Shadow DOM
      target.setHTMLUnsafe(html);
    } else {
      // Fallback for older browsers
      target.innerHTML = html;
    }
  };

  // Navigate to URL with CSR
  const navigate = async (url: string, replace = false): Promise<void> => {
    if (isNavigating) return;
    isNavigating = true;

    try {
      // Check cache first
      let html = cache.get(url);
      if (!html) {
        const res = await fetch(url, {
          headers: { 'X-Sol-Fragment': 'true' }
        });
        html = await res.text();

        // Only cache if fragment response
        if (res.headers.get('X-Sol-Fragment-Response')) {
          cache.set(url, html);
          // Clear cache after 5 minutes
          setTimeout(() => cache.delete(url), 5 * 60 * 1000);
        }
      }

      // Parse response
      const parser = new DOMParser();
      const doc = parser.parseFromString(html, 'text/html');

      // Check if this is a fragment response (has template elements)
      const templates = doc.querySelectorAll<HTMLTemplateElement>('template[data-sol-outlet]');

      if (templates.length > 0) {
        // Fragment response - update outlets
        templates.forEach(tpl => {
          const name = tpl.dataset.solOutlet;
          const target = d.querySelector<HTMLElementWithSetHTMLUnsafe>(`[data-sol-outlet="${name}"]`);
          if (target) {
            // Unload existing islands before updating DOM
            w.__LN_UNLOAD_ALL__?.(target);
            setHTML(target, tpl.innerHTML);
          }
        });

        // Update title
        const titleTpl = doc.querySelector<HTMLTemplateElement>('template[data-sol-title]');
        if (titleTpl) {
          d.title = titleTpl.textContent ?? '';
        }
      } else {
        // Full page response - extract #app content
        const app = doc.querySelector('#app');
        const target = d.querySelector<HTMLElementWithSetHTMLUnsafe>('#app');
        if (app && target) {
          // Unload existing islands before updating DOM
          w.__LN_UNLOAD_ALL__?.(target);
          setHTML(target, app.innerHTML);
        }

        // Update title from full page
        const title = doc.querySelector('title');
        if (title) {
          d.title = title.textContent ?? '';
        }
      }

      // Update history
      if (replace) {
        w.history.replaceState({ sol: true }, '', url);
      } else {
        w.history.pushState({ sol: true }, '', url);
      }

      // Scroll to top
      w.scrollTo(0, 0);

      // Re-scan for islands (if loader is available)
      w.__LN_SCAN__?.();
      // Re-scan for Web Components (if wc-loader is available)
      w.__WC_SCAN__?.();
    } catch (e) {
      console.error('Sol navigation failed:', e);
      // Fallback to full page load
      w.location.href = url;
    } finally {
      isNavigating = false;
    }
  };

  // Prefetch URL
  const prefetch = (url: string): void => {
    if (cache.has(url)) return;
    fetch(url, {
      headers: { 'X-Sol-Fragment': 'true' }
    })
      .then(res => res.text())
      .then(html => {
        cache.set(url, html);
        setTimeout(() => cache.delete(url), 5 * 60 * 1000);
      })
      .catch(() => { /* ignore */ });
  };

  // Click handler for sol-link elements
  d.addEventListener('click', (e: MouseEvent) => {
    const target = e.target as Element | null;
    const link = target?.closest<HTMLAnchorElement>('[data-sol-link]');
    if (!link) return;

    const href = link.getAttribute('href');
    if (!href) return;

    // Skip external links
    if (href.startsWith('http') || href.startsWith('//')) return;

    // Skip if modifier key pressed (allow new tab)
    if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;

    e.preventDefault();
    const replace = link.hasAttribute('data-sol-replace');
    navigate(href, replace);
  });

  // Hover prefetch
  d.addEventListener('mouseenter', (e: MouseEvent) => {
    const target = e.target as Element | null;
    if (!target?.closest) return;
    const link = target.closest<HTMLAnchorElement>('[data-sol-link][data-sol-prefetch]');
    if (link) {
      const href = link.getAttribute('href');
      if (href && !href.startsWith('http') && !href.startsWith('//')) {
        prefetch(href);
      }
    }
  }, { capture: true });

  // Handle browser back/forward
  w.addEventListener('popstate', (e: PopStateEvent) => {
    // Only handle our own history entries or if no state
    if ((e.state as { sol?: boolean } | null)?.sol || !e.state) {
      navigate(w.location.href, true);
    }
  });

  // Global API
  w.__SOL_NAVIGATE__ = navigate;
  w.__SOL_PREFETCH__ = prefetch;
  w.__SOL_CACHE__ = cache;
})(document, window as unknown as SolWindow);
