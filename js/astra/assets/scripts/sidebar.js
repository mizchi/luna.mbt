(function(){
  var STORAGE_KEY = 'astra-sidebar-state';
  function loadState() {
    try { return JSON.parse(localStorage.getItem(STORAGE_KEY)) || {}; } catch { return {}; }
  }
  function saveState(state) {
    try { localStorage.setItem(STORAGE_KEY, JSON.stringify(state)); } catch {}
  }
  function initSidebar() {
    var state = loadState();
    document.querySelectorAll('[data-sidebar-group]').forEach(function(el) {
      var key = el.dataset.sidebarGroup;
      if (key && state[key] !== undefined) {
        el.open = state[key];
      }
      el.addEventListener('toggle', function() {
        var s = loadState();
        s[key] = el.open;
        saveState(s);
      });
    });
  }
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initSidebar);
  } else {
    initSidebar();
  }
  window.__ASTRA_INIT_SIDEBAR__ = initSidebar;
})();
