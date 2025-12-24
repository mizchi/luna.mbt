(function(){
  var theme = localStorage.getItem('theme');
  var prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
  var isDark = theme === 'dark' || (theme !== 'light' && prefersDark);
  if (isDark) {
    document.documentElement.classList.add('dark');
  }
  window.toggleTheme = function() {
    var html = document.documentElement;
    var wasDark = html.classList.contains('dark');
    if (wasDark) {
      html.classList.remove('dark');
      localStorage.setItem('theme', 'light');
    } else {
      html.classList.add('dark');
      localStorage.setItem('theme', 'dark');
    }
  };
})();
