(function(){
  var observer = null;
  var tocLinks = [];
  var headings = [];
  function initTocSpy() {
    if (observer) observer.disconnect();
    tocLinks = Array.from(document.querySelectorAll('.toc-item a'));
    headings = tocLinks.map(function(link) {
      var id = link.getAttribute('href')?.slice(1);
      return id ? document.getElementById(id) : null;
    }).filter(Boolean);
    if (!headings.length) return;
    var current = null;
    observer = new IntersectionObserver(function(entries) {
      entries.forEach(function(entry) {
        if (entry.isIntersecting) current = entry.target;
      });
      if (!current) {
        var scrollY = window.scrollY + 100;
        for (var i = headings.length - 1; i >= 0; i--) {
          if (headings[i].offsetTop <= scrollY) { current = headings[i]; break; }
        }
      }
      tocLinks.forEach(function(link) {
        var id = link.getAttribute('href')?.slice(1);
        if (current && id === current.id) {
          link.classList.add('active');
        } else {
          link.classList.remove('active');
        }
      });
    }, { rootMargin: '-60px 0px -70% 0px', threshold: 0 });
    headings.forEach(function(h) { observer.observe(h); });
  }
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initTocSpy);
  } else {
    initTocSpy();
  }
  window.__ASTRA_INIT_TOC_SPY__ = initTocSpy;
})();
