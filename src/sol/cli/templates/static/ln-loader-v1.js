/*! luna loader v1 - MIT License */
((d, w) => {
  const S = {}; // State store: { id: state, ... }
  const loaded = new Set(); // Track loaded components

  // Parse ln:state attribute value
  const parseState = async (el) => {
    const attr = el.getAttribute('ln:state');
    if (!attr) return null;

    // #id - reference to script element
    if (attr.startsWith('#')) {
      const script = d.getElementById(attr.slice(1));
      return script ? JSON.parse(script.textContent) : null;
    }

    // url:... - fetch from URL
    if (attr.startsWith('url:')) {
      const res = await fetch(attr.slice(4));
      return res.json();
    }

    // Inline JSON
    try {
      return JSON.parse(attr);
    } catch {
      return null;
    }
  };

  // Hydrate a component
  const hydrate = async (el) => {
    const id = el.getAttribute('ln:id');
    if (!id || loaded.has(id)) return;
    loaded.add(id);

    const url = el.getAttribute('ln:url');
    if (!url) return;

    // Parse state
    const state = await parseState(el);
    S[id] = state;

    // Import module and call hydrate function
    // Supports ln:export attribute to specify which function to call
    try {
      const mod = await import(url);
      const exportName = el.getAttribute('ln:export');
      const fn = exportName ? mod[exportName] : (mod.hydrate || mod.default);
      if (fn) fn(el, state, id);
    } catch (e) {
      console.error(`[ln-loader] Failed to hydrate ${id}:`, e);
    }
  };

  // Setup trigger for an element
  const setupTrigger = (el) => {
    const trigger = el.getAttribute('ln:trigger') || 'load';

    if (trigger === 'load') {
      // Hydrate immediately on DOMContentLoaded (or now if already loaded)
      if (d.readyState === 'loading') {
        d.addEventListener('DOMContentLoaded', () => hydrate(el), { once: true });
      } else {
        hydrate(el);
      }
    } else if (trigger === 'idle') {
      // Hydrate when browser is idle
      if ('requestIdleCallback' in w) {
        requestIdleCallback(() => hydrate(el));
      } else {
        setTimeout(() => hydrate(el), 200);
      }
    } else if (trigger === 'visible') {
      // Hydrate when element enters viewport
      const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            observer.disconnect();
            hydrate(el);
          }
        });
      }, { rootMargin: '50px' });
      observer.observe(el);
    } else if (trigger.startsWith('media:')) {
      // Hydrate when media query matches
      const query = trigger.slice(6);
      const mql = w.matchMedia(query);
      const check = () => {
        if (mql.matches) {
          mql.removeEventListener('change', check);
          hydrate(el);
        }
      };
      if (mql.matches) {
        hydrate(el);
      } else {
        mql.addEventListener('change', check);
      }
    } else if (trigger === 'none') {
      // Manual only - do nothing
    }
  };

  // Scan for ln:id elements and setup triggers
  const scan = () => {
    d.querySelectorAll('[ln\\:id]').forEach(setupTrigger);
  };

  // Also extract legacy data-resumable-state for backwards compatibility
  d.querySelectorAll('script[data-resumable-state]').forEach(s => {
    const id = s.getAttribute('data-resumable-state') || '_';
    S[id] = JSON.parse(s.textContent);
  });

  // Extract ln/json scripts
  d.querySelectorAll('script[type="ln/json"]').forEach(s => {
    const id = s.id;
    if (id) {
      S[id] = JSON.parse(s.textContent);
    }
  });

  // Initialize
  if (d.readyState === 'loading') {
    d.addEventListener('DOMContentLoaded', scan, { once: true });
  } else {
    scan();
  }

  // Watch for dynamically added elements
  const mo = new MutationObserver((mutations) => {
    mutations.forEach(m => {
      m.addedNodes.forEach(node => {
        if (node.nodeType === 1 && node.hasAttribute('ln:id')) {
          setupTrigger(node);
        }
      });
    });
  });
  mo.observe(d.body || d.documentElement, { childList: true, subtree: true });

  // Public API
  w.__LN_STATE__ = S;
  w.__LN_HYDRATE__ = hydrate;
  w.__LN_SCAN__ = scan;
})(document, window);
