///|
/// Navigation scripts for Sol SSG
/// SPA navigation, View Transitions, and Keyboard navigation

///|
/// Get the SPA navigation script
pub fn get_spa_script() -> String {
  let script =
    #|let currentAbortController = null;
    #|let lastPathname = location.pathname;
    #|function scrollToHash(hash) {
    #|  if (!hash) return;
    #|  const id = hash.startsWith('#') ? hash.slice(1) : hash;
    #|  const el = document.getElementById(id);
    #|  if (el) el.scrollIntoView({ behavior: 'instant', block: 'start' });
    #|}
    #|function closeAccordion(details) {
    #|  if (!details.open) return Promise.resolve();
    #|  details.classList.add('closing');
    #|  return new Promise(r => {
    #|    const done = () => { details.open = false; details.classList.remove('closing'); r(); };
    #|    details.querySelector('.sidebar-items')?.addEventListener('transitionend', done, { once: true });
    #|    setTimeout(done, 220);
    #|  });
    #|}
    #|async function spaNavigate(url, pushState = true) {
    #|  // Abort any pending navigation
    #|  if (currentAbortController) currentAbortController.abort();
    #|  currentAbortController = new AbortController();
    #|  const urlObj = new URL(url, location.origin);
    #|  const hash = urlObj.hash;
    #|  // Save sidebar scroll position before navigation
    #|  const sidebar = document.querySelector('.sidebar-content');
    #|  const sidebarScrollTop = sidebar ? sidebar.scrollTop : 0;
    #|  // Close non-target accordions with animation before fetching
    #|  const targetPath = urlObj.pathname;
    #|  const openDetails = document.querySelectorAll('.sidebar-collapse[open]');
    #|  const closePromises = [];
    #|  openDetails.forEach(d => {
    #|    const link = d.querySelector('.sidebar-group-link');
    #|    if (link && !targetPath.startsWith(link.getAttribute('href')?.replace(/\/$/, '') || '###')) {
    #|      closePromises.push(closeAccordion(d));
    #|    }
    #|  });
    #|  try {
    #|    // Fetch in parallel with close animation
    #|    const [res] = await Promise.all([fetch(url, { signal: currentAbortController.signal }), ...closePromises]);
    #|    if (!res.ok) { location.href = url; return; }
    #|    const html = await res.text();
    #|    const parser = new DOMParser();
    #|    const doc = parser.parseFromString(html, 'text/html');
    #|    const newApp = doc.getElementById('app');
    #|    const newTitle = doc.querySelector('title')?.textContent;
    #|    const newRobots = doc.querySelector('meta[name="robots"]');
    #|    if (!newApp) { location.href = url; return; }
    #|    // Update DOM
    #|    document.getElementById('app').innerHTML = newApp.innerHTML;
    #|    if (newTitle) document.title = newTitle;
    #|    // Update robots meta tag
    #|    const oldRobots = document.querySelector('meta[name="robots"]');
    #|    if (newRobots) {
    #|      if (oldRobots) { oldRobots.setAttribute('content', newRobots.getAttribute('content')); }
    #|      else { document.head.appendChild(newRobots.cloneNode(true)); }
    #|    } else if (oldRobots) { oldRobots.remove(); }
    #|    if (pushState) history.pushState({}, '', url);
    #|    lastPathname = urlObj.pathname;
    #|    // Restore sidebar scroll position
    #|    const newSidebar = document.querySelector('.sidebar-content');
    #|    if (newSidebar) newSidebar.scrollTop = sidebarScrollTop;
    #|    // Scroll: to hash target or top
    #|    if (hash) { scrollToHash(hash); } else { window.scrollTo({ top: 0, behavior: 'instant' }); }
    #|    // Re-run loader for new islands
    #|    if (window.__LUNA_CLEAR_LOADED__) window.__LUNA_CLEAR_LOADED__();
    #|    if (window.__LUNA_SCAN__) window.__LUNA_SCAN__();
    #|    // Re-run Web Components loader
    #|    if (window.__LUNA_WC_CLEAR_LOADED__) window.__LUNA_WC_CLEAR_LOADED__();
    #|    if (window.__LUNA_WC_SCAN__) window.__LUNA_WC_SCAN__();
    #|    // Re-init TOC scroll spy
    #|    if (window.__ASTRA_INIT_TOC_SPY__) window.__ASTRA_INIT_TOC_SPY__();
    #|  } catch (e) {
    #|    if (e.name !== 'AbortError') location.href = url;
    #|  }
    #|}
    #|function navigateTo(url) {
    #|  // Skip SPA for home page transitions
    #|  if (isHomePage(url) || isHomePage(location.href)) {
    #|    window.scrollTo({ top: 0, behavior: 'instant' });
    #|    location.href = url;
    #|    return;
    #|  }
    #|  spaNavigate(url);
    #|}
    #|// Handle sidebar chevron clicks (toggle only, no navigation)
    #|document.addEventListener('click', (e) => {
    #|  const chevron = e.target.closest('.sidebar-chevron');
    #|  if (!chevron) return;
    #|  e.preventDefault();
    #|  e.stopPropagation();
    #|  const details = chevron.closest('details');
    #|  if (!details) return;
    #|  if (details.open) { closeAccordion(details); } else { details.open = true; }
    #|});
    #|// Intercept link clicks
    #|document.addEventListener('click', (e) => {
    #|  const link = e.target.closest('a');
    #|  if (!link) return;
    #|  const href = link.getAttribute('href');
    #|  if (!href || href.startsWith('javascript:')) return;
    #|  // Handle hash-only links explicitly (TOC links)
    #|  if (href.startsWith('#')) {
    #|    e.preventDefault();
    #|    const hash = href;
    #|    history.pushState({}, '', location.pathname + hash);
    #|    scrollToHash(hash);
    #|    return;
    #|  }
    #|  if (link.target === '_blank' || link.hasAttribute('download')) return;
    #|  const url = new URL(href, location.origin);
    #|  if (url.origin !== location.origin) return;
    #|  // Same page with hash - scroll to hash
    #|  if (url.pathname === location.pathname && url.hash) {
    #|    e.preventDefault();
    #|    history.pushState({}, '', url.pathname + url.hash);
    #|    scrollToHash(url.hash);
    #|    return;
    #|  }
    #|  // Skip if same page without hash (prevent default to avoid scroll jump)
    #|  if (url.pathname === location.pathname) { e.preventDefault(); return; }
    #|  // Skip SPA for home page
    #|  if (isHomePage(url.href) || isHomePage(location.href)) return;
    #|  e.preventDefault();
    #|  spaNavigate(url.href);
    #|});
    #|// Handle back/forward
    #|window.addEventListener('popstate', () => {
    #|  if (isHomePage(location.href)) {
    #|    location.reload();
    #|    return;
    #|  }
    #|  // If only hash changed (same page), just scroll
    #|  if (location.pathname === lastPathname && location.hash) {
    #|    scrollToHash(location.hash);
    #|    return;
    #|  }
    #|  lastPathname = location.pathname;
    #|  spaNavigate(location.href, false);
    #|});
    #|// Hover prefetch for internal links
    #|const prefetched = new Set();
    #|function prefetchUrl(url) {
    #|  if (prefetched.has(url)) return;
    #|  prefetched.add(url);
    #|  const link = document.createElement('link');
    #|  link.rel = 'prefetch';
    #|  link.href = url;
    #|  document.head.appendChild(link);
    #|}
    #|document.addEventListener('mouseover', (e) => {
    #|  const anchor = e.target.closest('a');
    #|  if (!anchor) return;
    #|  const href = anchor.getAttribute('href');
    #|  if (!href || href.startsWith('#') || href.startsWith('javascript:')) return;
    #|  if (anchor.target === '_blank' || anchor.hasAttribute('download')) return;
    #|  try {
    #|    const url = new URL(href, location.origin);
    #|    if (url.origin !== location.origin) return;
    #|    if (url.pathname === location.pathname) return;
    #|    prefetchUrl(url.href);
    #|  } catch {}
    #|}, { passive: true });
  script
}

///|
/// Get the non-SPA navigation script (full page reload)
pub fn get_non_spa_script() -> String {
  let script =
    #|function navigateTo(url) {
    #|  window.scrollTo({ top: 0, behavior: 'instant' });
    #|  location.href = url;
    #|}
  script
}

///|
/// Get the View Transitions API script
pub fn get_view_transitions_script() -> String {
  let script =
    #|window.addEventListener('pagereveal', (e) => {
    #|  if (!e.viewTransition || !navigation.activation) return;
    #|  const nav = navigation.activation;
    #|  const fromIdx = getPageIndex(nav.from?.url);
    #|  const toIdx = getPageIndex(nav.entry?.url);
    #|  if (fromIdx !== -1 && toIdx !== -1) {
    #|    e.viewTransition.types.add(toIdx > fromIdx ? 'forwards' : 'backwards');
    #|  } else {
    #|    e.viewTransition.types.add('forwards');
    #|  }
    #|});
  script
}

///|
/// Get the keyboard navigation script
pub fn get_keyboard_script() -> String {
  let script =
    #|document.addEventListener('keydown', (e) => {
    #|  if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return;
    #|  const idx = getPageIndex(location.href);
    #|  if (idx === -1) return;
    #|  if (e.key === 'ArrowRight' && idx < pageOrder.length - 1) {
    #|    e.preventDefault();
    #|    navigateTo(pageOrder[idx + 1]);
    #|  } else if (e.key === 'ArrowLeft' && idx > 0) {
    #|    const prevPage = pageOrder[idx - 1];
    #|    if (isHomePage(prevPage)) return;
    #|    e.preventDefault();
    #|    navigateTo(prevPage);
    #|  }
    #|});
  script
}

///|
/// Get the page order utilities script
pub fn get_page_order_utils() -> String {
  let script =
    #|];
    #|function getPageIndex(url) {
    #|  if (!url) return -1;
    #|  const path = new URL(url).pathname.replace(/\/$/, '') || '/';
    #|  return pageOrder.findIndex(p => p.replace(/\/$/, '') === path || p === path + '/');
    #|}
    #|function isHomePage(url) {
    #|  const path = new URL(url, location.origin).pathname;
    #|  return path === '/' || path === '/ja/' || path === '/en/';
    #|}
  script
}

///|
/// Build the complete navigation script
pub fn build_navigation_script(
  page_order : Array[String],
  config : @ssg.NavigationConfig,
) -> String {
  // If all navigation features are disabled, return empty
  if not(config.spa) && not(config.view_transitions) && not(config.keyboard) {
    return ""
  }

  // Build JSON array of page URLs
  let urls_json = page_order.map(fn(url) { "\"\{url}\"" }).join(", ")

  // Generate script parts based on config
  let parts : Array[String] = []

  // Common utilities
  parts.push("const pageOrder = [")
  parts.push(urls_json)
  parts.push(get_page_order_utils())

  // SPA navigation
  if config.spa {
    parts.push(get_spa_script())
  } else {
    parts.push(get_non_spa_script())
  }

  // View Transitions API
  if config.view_transitions {
    parts.push(get_view_transitions_script())
  }

  // Keyboard navigation
  if config.keyboard {
    parts.push(get_keyboard_script())
  }
  let script_body = parts.join("\n")
  "<script>\n(function() {\n\{script_body}\n})();\n</script>"
}
