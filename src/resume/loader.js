/*! ui.mbt resumable loader - MIT License */
((d, w) => {
  const S = {}; // State store: { id: [...values], ... }

  // Extract all inline states
  d.querySelectorAll('script[data-resumable-state]').forEach(s => {
    const id = s.getAttribute('data-resumable-state') || '_';
    S[id] = JSON.parse(s.textContent);
  });

  // Load state from endpoint
  const load = async (id, src) => {
    if (S[id]) return S[id];
    const res = await fetch(src);
    S[id] = await res.json();
    return S[id];
  };

  // Find state for element (walks up to find data-state-id)
  const find = (el) => {
    while (el && el !== d) {
      const id = el.getAttribute('data-state-id');
      if (id) return { id, el };
      el = el.parentElement;
    }
    return { id: '_', el: d.body };
  };

  // Event handler
  const h = async (e) => {
    let t = e.target, n = 'on:' + e.type;
    while (t && t !== d) {
      const a = t.getAttribute(n);
      if (a) {
        // Find state context
        const ctx = find(t);
        const src = ctx.el.getAttribute('data-state-src');

        // Load state if needed
        let state = S[ctx.id];
        if (!state && src) {
          state = await load(ctx.id, src);
        }

        // Import and call handler
        const [m, f] = a.split('#');
        const mod = await import(m);
        const fn = mod[f] || mod.default;
        if (fn) fn(e, t, state || [], ctx.id);
        break;
      }
      t = t.parentElement;
    }
  };

  // Register events
  ['click', 'input', 'change', 'submit', 'keydown', 'keyup', 'focus', 'blur']
    .forEach(e => d.addEventListener(e, h, { capture: true }));

  // Public API
  w.__STATE__ = S;
  w.__RESUME__ = (n, t) => h({ type: n, target: t });
  w.__LOAD__ = load;
})(document, window);
