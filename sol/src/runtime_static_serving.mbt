// Runtime static serving helpers

// Static File Serving
// ============================================================================

///|
async fn read_file_text(path : String) -> String? {
  ffi_read_file_text(path).wait()
}

///|
extern "js" fn ffi_read_file_text(path : String) -> @js.Promise[String?] =
  #| async (path) => {
  #|   try {
  #|     const importer = globalThis.__SOL_DYNAMIC_IMPORT__ ||
  #|       ((specifier) => import(specifier));
  #|     const fs = await importer('node:fs/promises');
  #|     return await fs.readFile(path, 'utf-8');
  #|   } catch (_) {
  #|     return undefined;
  #|   }
  #| }

///|
fn content_type_for_file(filename : String) -> String {
  if filename.has_suffix(".js") {
    "application/javascript"
  } else if filename.has_suffix(".css") {
    "text/css"
  } else if filename.has_suffix(".svg") {
    "image/svg+xml"
  } else if filename.has_suffix(".html") {
    "text/html"
  } else {
    "text/plain"
  }
}

///|
fn apply_static_headers(
  c : Ctx,
  content_type : String,
  cache_control : String,
) -> Unit {
  c.set_header("Content-Type", content_type)
  c.set_header("Cache-Control", cache_control)
  c.set_header("X-Content-Type-Options", "nosniff")
}

///|
fn send_static_text(
  c : Ctx,
  body : String,
  content_type : String,
  cache_control : String,
) -> Unit {
  apply_static_headers(c, content_type, cache_control)
  c.text(body)
}

///|
fn default_favicon_svg() -> String {
  (
    #|<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><rect width="64" height="64" rx="12" fill="#111827"/><text x="32" y="42" text-anchor="middle" font-family="system-ui, sans-serif" font-size="34" font-weight="700" fill="#fff">S</text></svg>
  )
}

///|
pub fn serve_default_favicon(app : App) -> Unit {
  app.get(
    "/favicon.ico",
    @mars.handler(async fn(c) {
      send_static_text(
        c,
        default_favicon_svg(),
        "image/svg+xml",
        "public, max-age=86400",
      )
    }),
  )
}

///|
/// Static file configuration
pub struct StaticFileConfig {
  /// URL path prefix (e.g., "/static")
  path_prefix : String
  /// Local directory path (e.g., "static")
  local_dir : String
  /// File mappings: (url_filename, local_path)
  mappings : Array[(String, String)]
  /// Cache-Control header value (default: "max-age=3600", use "no-cache, no-store" for dev)
  cache_control : String
}

///|
/// Create default static file config for Luna apps
pub fn StaticFileConfig::default() -> StaticFileConfig {
  {
    path_prefix: "/static",
    local_dir: "static",
    mappings: [],
    cache_control: "max-age=3600",
  }
}

///|
/// Create static file config for development (no caching)
pub fn StaticFileConfig::dev() -> StaticFileConfig {
  {
    path_prefix: "/static",
    local_dir: "static",
    mappings: [],
    cache_control: "no-cache, no-store, must-revalidate",
  }
}

///|
/// Builder: add file mapping
pub fn StaticFileConfig::with_mapping(
  self : StaticFileConfig,
  url_filename : String,
  local_path : String,
) -> StaticFileConfig {
  let new_mappings = self.mappings.copy()
  new_mappings.push((url_filename, local_path))
  { ..self, mappings: new_mappings }
}

///|
/// Configuration for serving a static directory (SSG output)
pub(all) struct StaticDirServeConfig {
  /// URL path prefix (e.g., "/docs")
  path_prefix : String
  /// Local directory path (relative to cwd)
  local_dir : String
}

///|
/// Create default StaticDirServeConfig
pub fn StaticDirServeConfig::new(
  path_prefix : String,
  _source_dir : String,
) -> StaticDirServeConfig {
  // Map to .sol/prod/static/{path_prefix}
  let local_dir = ".sol/prod/static" +
    path_prefix.trim_end(chars="/").to_string()
  { path_prefix, local_dir }
}

///|
/// Register a static directory for serving SSG output
/// This serves HTML files from .sol/prod/static/{path_prefix}
pub fn serve_static_dir(app : App, config : StaticDirServeConfig) -> Unit {
  let prefix = config.path_prefix.trim_end(chars="/").to_string()
  let local_dir = config.local_dir

  // Serve index.html for directory roots
  app.get(
    prefix,
    @mars.handler(async fn(c) {
      serve_static_html_async(c, local_dir, "index.html")
    }),
  )

  // Serve all paths under the prefix
  app.get(
    prefix + "/*",
    @mars.handler(async fn(c) {
      let path = c.path()
      let start_idx = prefix.length() + 1
      let rest = path[start_idx:].to_string().trim_end(chars="/").to_string()

      // Try exact path first, then as directory index
      if rest.is_empty() {
        serve_static_html_async(c, local_dir, "index.html")
      } else if rest.has_suffix(".html") {
        serve_static_html_async(c, local_dir, rest)
      } else if rest.has_suffix(".css") {
        serve_static_text_file(
          c,
          local_dir,
          rest,
          "text/css",
          "/* Not found: " + rest + " */",
        )
      } else if rest.has_suffix(".js") {
        serve_static_text_file(
          c,
          local_dir,
          rest,
          "application/javascript",
          "// Not found: " + rest,
        )
      } else {
        // Try as directory with index.html
        serve_static_html_async(c, local_dir, rest + "/index.html")
      }
    }),
  )
}

///|
async fn serve_static_html_async(
  c : Ctx,
  local_dir : String,
  filename : String,
) -> Unit {
  let path = local_dir + "/" + filename
  match read_file_text(path) {
    Some(content) => c.html(content)
    None => c.text("Not found: " + filename)
  }
}

///|
async fn serve_static_text_file(
  c : Ctx,
  local_dir : String,
  filename : String,
  content_type : String,
  not_found_body : String,
) -> Unit {
  let path = local_dir + "/" + filename
  c.set_header("Content-Type", content_type)
  match read_file_text(path) {
    Some(content) => c.text(content)
    None => c.text(not_found_body)
  }
}

///|
/// Resolve a built-in runtime asset from disk by trying multiple candidate paths.
/// Used in dev mode for live reload (reads from source each time).
async fn resolve_builtin_asset_from_disk(filename : String) -> String? {
  // Map loader.js -> loader.iife.js for luna dist
  let luna_name = if filename == "loader.js" {
    "loader.iife.js"
  } else if filename == "wc-loader.js" {
    "wc-loader.iife.js"
  } else {
    filename
  }
  let candidates = [
    ".mooncakes/mizchi/luna/js/loader/dist/" + luna_name,
    ".mooncakes/mizchi/astra/src/assets/scripts/" + filename,
  ]
  for path in candidates {
    match read_file_text(path) {
      Some(content) => return Some(content)
      None => continue
    }
  }
  None
}

///|
/// Built-in asset filenames to preload in prod mode
let sol_builtin_assets : Array[String] = [
  "loader.js", "wc-loader.js", "sol-nav.js", "lib.js",
]

///|
/// In-memory cache for prod mode assets (loaded once on first request)
let asset_cache : Map[String, String] = {}

///|
let assets_preloaded : Ref[Bool] = Ref::new(false)

///|
/// Load all built-in assets into memory cache.
/// Called lazily on first request in prod mode.
async fn ensure_assets_preloaded() -> Unit {
  if assets_preloaded.val {
    return
  }
  assets_preloaded.val = true
  for filename in sol_builtin_assets {
    // Try pre-built .sol/prod/__sol__/ first, then fallback to disk resolution
    let content = match read_file_text(".sol/prod/__sol__/" + filename) {
      Some(c) => Some(c)
      None => resolve_builtin_asset_from_disk(filename)
    }
    match content {
      Some(c) => asset_cache[filename] = c
      None => ()
    }
  }
}

///|
/// Register /__sol__/* route for serving built-in framework assets.
/// In prod mode, lazily preloads assets into memory on first request.
/// In dev mode, resolves from source paths on each request.
pub fn serve_sol_assets(app : App) -> Unit {
  let is_dev = @hot_reload.is_dev_mode()
  let cache_ctl = if is_dev {
    "no-cache, no-store, must-revalidate"
  } else {
    "public, max-age=86400"
  }
  app.get(
    "/__sol__/*",
    @mars.handler(async fn(c) {
      let path = c.path()
      // "/__sol__/".length() == 9
      let filename = path[9:].to_string()
      let content_type = content_type_for_file(filename)
      // In prod: serve from memory cache; in dev: resolve from disk
      let content = if is_dev {
        resolve_builtin_asset_from_disk(filename)
      } else {
        ensure_assets_preloaded()
        asset_cache.get(filename)
      }
      match content {
        Some(body) => send_static_text(c, body, content_type, cache_ctl)
        None =>
          send_static_text(
            c,
            "// Not found: " + filename,
            content_type,
            cache_ctl,
          )
      }
    }),
  )
}

///|
/// Register static file serving middleware
pub fn serve_static(app : App, config? : StaticFileConfig) -> Unit {
  let cfg = config.unwrap_or(StaticFileConfig::default())
  let prefix = cfg.path_prefix
  let mappings = cfg.mappings
  // In dev mode, disable caching to avoid stale JS/CSS issues
  let cache_ctl = if @hot_reload.is_dev_mode() {
    "no-cache, no-store, must-revalidate"
  } else {
    cfg.cache_control
  }
  app.get(
    prefix + "/*",
    @mars.handler(async fn(c) {
      let path = c.path()
      let start_idx = prefix.length() + 1
      let filename = path[start_idx:].to_string() // Remove prefix + "/"

      // Check mappings
      for mapping in mappings {
        let (url_file, local_path) = mapping
        if filename == url_file {
          let content_type = content_type_for_file(url_file)
          match read_file_text(local_path) {
            Some(content) => {
              send_static_text(c, content, content_type, cache_ctl)
              return
            }
            None => {
              send_static_text(
                c,
                "// " + url_file + " not found",
                content_type,
                cache_ctl,
              )
              return
            }
          }
        }
      }

      // Fallback: try to read from local_dir/filename, then .sol/{dev,prod}/static/filename
      // Dev is checked first as it's more commonly used during development
      let local_path = cfg.local_dir + "/" + filename
      let sol_dev_path = ".sol/dev/static/" + filename
      let sol_prod_path = ".sol/prod/static/" + filename
      let content = match read_file_text(local_path) {
        Some(c) => Some(c)
        None =>
          match read_file_text(sol_dev_path) {
            Some(c) => Some(c)
            None => read_file_text(sol_prod_path)
          }
      }
      match content {
        Some(content) => {
          let content_type = content_type_for_file(filename)
          send_static_text(c, content, content_type, cache_ctl)
        }
        None =>
          send_static_text(c, "Not found: " + filename, "text/plain", cache_ctl)
      }
    }),
  )
}
