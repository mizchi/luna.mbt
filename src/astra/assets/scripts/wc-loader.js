(function(){
  function setupTrigger(el, t, cb) {
    if (t === 'load') document.readyState === 'loading' ? document.addEventListener('DOMContentLoaded', cb, {once:true}) : cb();
    else if (t === 'idle') requestIdleCallback(cb);
    else if (t[0] === 'v') new IntersectionObserver((e,o) => { if(e.some(x=>x.isIntersecting)){o.disconnect();cb();}}, {rootMargin:'50px'}).observe(el);
    else if (t[0] === 'm') { var mq = matchMedia(t.slice(6)); var h = () => { if(mq.matches){mq.removeEventListener('change',h);cb();}}; mq.matches ? cb() : mq.addEventListener('change',h);}
  }
  var loaded = new Set();
  async function hydrate(el) {
    var name = el.tagName.toLowerCase();
    if (loaded.has(name)) return;
    var url = el.getAttribute('luna:wc-url');
    if (!url) return;
    loaded.add(name);
    try {
      var mod = await import(url);
      var fn = mod.hydrate || mod.default;
      if (typeof fn === 'function') fn(el, {}, name);
    } catch(e) { console.error('[wc] Failed:', name, e); }
  }
  function setup(el) { setupTrigger(el, el.getAttribute('luna:wc-trigger') || 'load', () => hydrate(el)); }
  function scan() { document.querySelectorAll('[luna\\:wc-url]').forEach(setup); }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', scan, {once:true});
  else scan();
  new MutationObserver(m => m.forEach(x => x.addedNodes.forEach(n => { if(n.nodeType === 1 && n.hasAttribute('luna:wc-url')) setup(n); }))).observe(document.body || document.documentElement, {childList:true,subtree:true});
  window.__LUNA_WC_SCAN__ = scan;
  window.__LUNA_WC_CLEAR_LOADED__ = () => loaded.clear();
})();
