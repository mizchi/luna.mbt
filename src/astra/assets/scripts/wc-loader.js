(function(){
  function setupTrigger(el, t, cb) {
    if (t === 'load') document.readyState === 'loading' ? document.addEventListener('DOMContentLoaded', cb, {once:true}) : cb();
    else if (t === 'idle') requestIdleCallback(cb);
    else if (t[0] === 'v') new IntersectionObserver((e,o) => { if(e.some(x=>x.isIntersecting)){o.disconnect();cb();}}, {rootMargin:'50px'}).observe(el);
    else if (t[0] === 'm') { var mq = matchMedia(t.slice(6)); var h = () => { if(mq.matches){mq.removeEventListener('change',h);cb();}}; mq.matches ? cb() : mq.addEventListener('change',h);}
  }
  var fns = new Map();
  var pending = new Map();
  async function loadFn(name, url) {
    if (fns.has(name)) return fns.get(name);
    if (pending.has(name)) return pending.get(name);
    var p = import(url).then(mod => {
      var fn = mod.hydrate || mod.default;
      if (typeof fn === 'function') { fns.set(name, fn); return fn; }
      else console.warn('[wc-loader] No hydrate function found in ' + url);
    }).catch(err => console.error('[wc-loader] Failed to load ' + name + ':', err)).finally(() => pending.delete(name));
    pending.set(name, p);
    return p;
  }
  async function hydrate(el) {
    var name = el.tagName.toLowerCase();
    var url = el.getAttribute('luna:wc-url');
    if (!url) return;
    var fn = await loadFn(name, url);
    if (fn) fn(el, {}, name);
  }
  function setup(el) { setupTrigger(el, el.getAttribute('luna:wc-trigger') || 'load', () => hydrate(el)); }
  function scan() { document.querySelectorAll('[luna\\:wc-url]').forEach(setup); }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', scan, {once:true});
  else scan();
  new MutationObserver(m => m.forEach(x => x.addedNodes.forEach(n => { if(n.nodeType === 1 && n.hasAttribute('luna:wc-url')) setup(n); }))).observe(document.body || document.documentElement, {childList:true,subtree:true});
  window.__LUNA_WC_SCAN__ = scan;
  window.__LUNA_WC_CLEAR_LOADED__ = () => fns.clear();
})();
