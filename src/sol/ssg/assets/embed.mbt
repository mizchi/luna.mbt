///|
/// Asset embedding helpers for Astra SSG
/// Functions to embed CSS and JavaScript into HTML

///|
/// Get combined CSS with theme customization
pub fn get_default_css(config : @ssg.SsgConfig) -> String {
  // Luna theme: Moon-inspired black and gold colors
  // Primary color from config is used for dark mode (bright gold)
  // Light mode uses a darker amber for better readability on white background
  let primary_dark = config.theme.primary_color.unwrap_or("#fbbf24") // amber-400
  let primary_light = "#b45309" // amber-700
  let base_css = get_main_css()
  // Apply custom primary colors if configured
  if base_css.is_empty() {
    // Fallback to inline CSS if file not found
    get_fallback_css(primary_light, primary_dark)
  } else {
    // Replace default primary colors with configured ones
    base_css
    .replace(
      old="--primary-color: #b45309",
      new="--primary-color: \{primary_light}",
    )
    .replace(
      old="--primary-color: #fbbf24",
      new="--primary-color: \{primary_dark}",
    )
  }
}

///|
/// Get GitHub markdown CSS
pub fn get_github_markdown_css() -> String {
  let css = get_markdown_css()
  if css.is_empty() {
    get_fallback_markdown_css()
  } else {
    css
  }
}

///|
/// Get theme toggle script (early load to prevent flash)
pub fn get_theme_script() -> String {
  let js = get_theme_js()
  if js.is_empty() {
    get_fallback_theme_script()
  } else {
    js
  }
}

///|
/// Get sidebar state persistence script (wrapped in script tags)
pub fn get_sidebar_script() -> String {
  let js = get_sidebar_js()
  if js.is_empty() {
    get_fallback_sidebar_script()
  } else {
    "<script>\n\{js}\n</script>"
  }
}

///|
/// Get TOC scroll spy script (wrapped in script tags)
pub fn get_toc_script() -> String {
  let js = get_toc_js()
  if js.is_empty() {
    get_fallback_toc_script()
  } else {
    "<script>\n\{js}\n</script>"
  }
}

///|
/// Get Web Components loader script (wrapped in script tags)
pub fn get_wc_loader_script() -> String {
  let js = get_wc_loader_js()
  if js.is_empty() {
    get_fallback_wc_loader_script()
  } else {
    "<script>\n\{js}\n</script>"
  }
}

///|
/// Get island loader script
pub fn get_island_loader_js() -> String {
  let js = get_loader_js()
  if js.is_empty() {
    get_fallback_loader_js()
  } else {
    js
  }
}

// Fallback functions for when external files are not available
// These contain the minimal necessary CSS/JS

///|
fn get_fallback_css(primary_light : String, primary_dark : String) -> String {
  "/* Luna SSG Default Theme - Fallback */\n:root { --primary-color: \{primary_light}; --text-color: #1f2937; --bg-color: #fff; }\nhtml.dark { --primary-color: \{primary_dark}; --text-color: #f3f4f6; --bg-color: #0f0f0f; }"
}

///|
fn get_fallback_markdown_css() -> String {
  "/* Markdown fallback */\n.markdown-body { font-family: sans-serif; line-height: 1.5; }"
}

///|
fn get_fallback_theme_script() -> String {
  let script =
    #|(function(){
    #|  var theme = localStorage.getItem('theme');
    #|  if (theme === 'dark' || (!theme && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
    #|    document.documentElement.classList.add('dark');
    #|  }
    #|  window.toggleTheme = function() {
    #|    var html = document.documentElement;
    #|    html.classList.toggle('dark');
    #|    localStorage.setItem('theme', html.classList.contains('dark') ? 'dark' : 'light');
    #|  };
    #|})();
  script
}

///|
fn get_fallback_sidebar_script() -> String {
  "<script>(function(){ window.__ASTRA_INIT_SIDEBAR__ = function(){}; })();</script>"
}

///|
fn get_fallback_toc_script() -> String {
  "<script>(function(){ window.__ASTRA_INIT_TOC_SPY__ = function(){}; })();</script>"
}

///|
fn get_fallback_wc_loader_script() -> String {
  "<script>(function(){ window.__LUNA_WC_SCAN__ = function(){}; window.__LUNA_WC_CLEAR_LOADED__ = function(){}; })();</script>"
}

///|
fn get_fallback_loader_js() -> String {
  "(function(){ window.__LUNA_STATE__ = {}; window.__LUNA_SCAN__ = function(){}; })();"
}
