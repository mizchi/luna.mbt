/*! luna loader v1 */
((d, w) => {
  const S = {}, loaded = new Set(), Q = s => d.querySelectorAll(s);

  const parseState = async el => {
    const a = el.getAttribute('ln:state');
    if (!a) return;
    if (a[0] === '#') return JSON.parse(d.getElementById(a.slice(1))?.textContent);
    if (a[0] === 'u') return (await fetch(a.slice(4))).json();
    try { return JSON.parse(a); } catch {}
  };

  const hydrate = async el => {
    const id = el.getAttribute('ln:id');
    if (!id || loaded.has(id)) return;
    loaded.add(id);
    const url = el.getAttribute('ln:url');
    if (!url) return;
    S[id] = await parseState(el);
    const mod = await import(url), ex = el.getAttribute('ln:export');
    (ex ? mod[ex] : mod.hydrate ?? mod.default)?.(el, S[id], id);
  };

  const setup = el => {
    const t = el.getAttribute('ln:trigger') ?? 'load';
    t === 'load' ? (d.readyState === 'loading' ? d.addEventListener('DOMContentLoaded', () => hydrate(el), { once: 1 }) : hydrate(el))
    : t === 'idle' ? requestIdleCallback(() => hydrate(el))
    : t[0] === 'v' ? new IntersectionObserver((e, o) => e.some(x => x.isIntersecting && (o.disconnect(), hydrate(el))), { rootMargin: '50px' }).observe(el)
    : t[0] === 'm' && ((m = w.matchMedia(t.slice(6)), c = () => m.matches && (m.removeEventListener('change', c), hydrate(el))) => m.matches ? hydrate(el) : m.addEventListener('change', c))();
  };

  const scan = () => Q('[ln\\:id]').forEach(setup);

  // Preload state from ln/json scripts
  Q('script[type="ln/json"]').forEach(s => s.id && (S[s.id] = JSON.parse(s.textContent)));

  d.readyState === 'loading' ? d.addEventListener('DOMContentLoaded', scan, { once: 1 }) : scan();

  // Watch for dynamically added islands
  new MutationObserver(m => m.flatMap(x => [...x.addedNodes]).forEach(n => n.nodeType === 1 && n.hasAttribute('ln:id') && setup(n)))
    .observe(d.body ?? d.documentElement, { childList: 1, subtree: 1 });

  w.__LN_STATE__ = S;
  w.__LN_HYDRATE__ = hydrate;
  w.__LN_SCAN__ = scan;
})(document, window);
