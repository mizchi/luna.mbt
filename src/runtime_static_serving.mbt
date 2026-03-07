// Runtime static serving helpers

// Static File Serving
// ============================================================================

///|
extern "js" fn ffi_read_file_sync(path : String) -> String? =
  #| (path) => {
  #|   try {
  #|     if (!globalThis.__SOL_FS__) {
  #|       throw new Error('fs module not initialized. Call __SOL_INIT_FS__ first.');
  #|     }
  #|     return globalThis.__SOL_FS__.readFileSync(path, 'utf-8');
  #|   } catch (e) {
  #|     return undefined;
  #|   }
  #| }

///|
fn read_file_text(path : String) -> String? {
  ffi_read_file_sync(path)
}

///|
fn content_type_for_file(filename : String) -> String {
  if filename.has_suffix(".js") {
    "application/javascript"
  } else if filename.has_suffix(".css") {
    "text/css"
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
fn serve_static_html_async(
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
fn serve_static_text_file(
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
/// Resolve a built-in runtime asset by trying multiple candidate paths.
/// In dev mode, tries source paths for live reload.
/// In prod mode, tries pre-built .sol/prod/__sol__/ first.
fn resolve_builtin_asset(filename : String) -> String? {
  // In prod mode, try pre-built assets first (written by sol generate)
  if not(@hot_reload.is_dev_mode()) {
    match read_file_text(".sol/prod/__sol__/" + filename) {
      Some(content) => return Some(content)
      None => ()
    }
  }
  // Map loader.js -> loader.iife.js for luna dist
  let luna_name = if filename == "loader.js" {
    "loader.iife.js"
  } else if filename == "wc-loader.js" {
    "wc-loader.iife.js"
  } else {
    filename
  }
  let candidates = [
    // mooncakes (luna): loader dist from luna package
    ".mooncakes/mizchi/luna/js/loader/dist/" + luna_name,
    // mooncakes (sol): canonical assets from sol package
    ".mooncakes/mizchi/sol/src/ssg/assets/scripts/" + filename,
    // Development: sol.mbt repo root (monorepo examples)
    "../../src/ssg/assets/scripts/" + filename,
    // Development: direct child of sol.mbt
    "../src/ssg/assets/scripts/" + filename,
    // Same repo root
    "src/ssg/assets/scripts/" + filename,
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
/// Register /__sol__/* route for serving built-in framework assets.
/// In prod mode, serves pre-built assets from .sol/prod/__sol__/.
/// In dev mode, resolves from mooncakes or source paths.
pub fn serve_sol_assets(app : App) -> Unit {
  let cache_ctl = if @hot_reload.is_dev_mode() {
    "no-cache, no-store, must-revalidate"
  } else {
    "public, max-age=86400"
  }
  app.get(
    "/__sol__/*",
    @mars.handler(async fn(c) {
      let path = c.path()
      // "/__sol__/".length() == 8
      let filename = path[8:].to_string()
      let content_type = content_type_for_file(filename)
      match resolve_builtin_asset(filename) {
        Some(content) => send_static_text(c, content, content_type, cache_ctl)
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
