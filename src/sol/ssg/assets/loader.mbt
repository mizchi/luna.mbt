///|
/// Asset loader for Astra SSG
/// Loads CSS and JavaScript files from external files at build time

///|
/// Get assets directory from globalThis.__sol_assets_dir (set by JS wrapper)
extern "js" fn ffi_get_sol_assets_dir() -> String? =
  #| () => globalThis.__sol_assets_dir

// Cache for loaded assets

///|
let main_css_cache : Ref[String?] = { val: None }

///|
let markdown_css_cache : Ref[String?] = { val: None }

///|
let theme_js_cache : Ref[String?] = { val: None }

///|
let sidebar_js_cache : Ref[String?] = { val: None }

///|
let toc_js_cache : Ref[String?] = { val: None }

///|
let wc_loader_js_cache : Ref[String?] = { val: None }

///|
let loader_js_cache : Ref[String?] = { val: None }

///|
/// Load a file from the assets directory
/// Note: Uses simple string concatenation instead of @path.join to avoid
/// async issues with the MoonBit coroutine scheduler
fn load_asset(relative_path : String) -> String {
  // Build list of paths to try
  let paths : Array[String] = []

  // First priority: globalThis.__sol_assets_dir (set by JS wrapper)
  match ffi_get_sol_assets_dir() {
    Some(dir) => paths.push(dir + "/" + relative_path)
    None => ()
  }

  // Development: running from luna.mbt repo root
  paths.push("src/astra/assets/" + relative_path)
  // npm package: @luna_ui/sol installed via npm (relative to cwd)
  paths.push("node_modules/@luna_ui/sol/assets/" + relative_path)
  // Examples/subprojects: path dependency to parent luna.mbt
  paths.push("../../src/astra/assets/" + relative_path)
  for p in paths {
    try {
      return @fs.read_file_as_string(p)
    } catch {
      _ => continue
    }
  }
  ""
}

///|
/// Load and cache main CSS
pub fn get_main_css() -> String {
  match main_css_cache.val {
    Some(css) => css
    None => {
      let css = load_asset("styles/main.css")
      main_css_cache.val = Some(css)
      css
    }
  }
}

///|
/// Load and cache markdown CSS
pub fn get_markdown_css() -> String {
  match markdown_css_cache.val {
    Some(css) => css
    None => {
      let css = load_asset("styles/markdown.css")
      markdown_css_cache.val = Some(css)
      css
    }
  }
}

///|
/// Load and cache theme script
pub fn get_theme_js() -> String {
  match theme_js_cache.val {
    Some(js) => js
    None => {
      let js = load_asset("scripts/theme.js")
      theme_js_cache.val = Some(js)
      js
    }
  }
}

///|
/// Load and cache sidebar script
pub fn get_sidebar_js() -> String {
  match sidebar_js_cache.val {
    Some(js) => js
    None => {
      let js = load_asset("scripts/sidebar.js")
      sidebar_js_cache.val = Some(js)
      js
    }
  }
}

///|
/// Load and cache TOC script
pub fn get_toc_js() -> String {
  match toc_js_cache.val {
    Some(js) => js
    None => {
      let js = load_asset("scripts/toc.js")
      toc_js_cache.val = Some(js)
      js
    }
  }
}

///|
/// Load and cache Web Components loader script
pub fn get_wc_loader_js() -> String {
  match wc_loader_js_cache.val {
    Some(js) => js
    None => {
      let js = load_asset("scripts/wc-loader.js")
      wc_loader_js_cache.val = Some(js)
      js
    }
  }
}

///|
/// Load and cache island loader script
pub fn get_loader_js() -> String {
  match loader_js_cache.val {
    Some(js) => js
    None => {
      let js = load_asset("scripts/loader.js")
      loader_js_cache.val = Some(js)
      js
    }
  }
}

///|
/// Clear all caches (useful for development/hot reload)
pub fn clear_cache() -> Unit {
  main_css_cache.val = None
  markdown_css_cache.val = None
  theme_js_cache.val = None
  sidebar_js_cache.val = None
  toc_js_cache.val = None
  wc_loader_js_cache.val = None
  loader_js_cache.val = None
}
