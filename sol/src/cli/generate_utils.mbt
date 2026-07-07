// Generate Utils - Shared utilities for sol generate command

// =============================================================================
// Help
// =============================================================================

///|
fn show_generate_help() -> Unit {
  let help =
    #|Usage: sol generate [options]
    #|
    #|Generate app/__gen__ (MoonBit) and .sol (JS) directories from sol.config.ts or sol.config.json
    #|
    #|Options:
    #|  -c, --config <path>  Config file path (default: auto-detect)
    #|  -h, --help           Show help
  println(help)
}

// =============================================================================
// App Mode Detection (MoonBit vs TypeScript)
// =============================================================================

///|
/// Application mode - determines how server-side code is written
pub enum AppMode {
  MoonBitFull // All MoonBit (current default)
  MoonBitClientTsServer // MoonBit client + TypeScript server
  TypeScriptFull // All TypeScript (future)
} derive(Eq, Show, Debug)

///|
/// Detect app mode based on file extensions
pub fn detect_app_mode(cwd : String, config : SolConfig) -> AppMode {
  let fs = @fs_adapter.NodeFsAdapter::new()
  detect_app_mode_with_fs(fs, cwd, config)
}

///|
fn[FS : @env.FileSystem] detect_app_mode_with_fs(
  fs : FS,
  cwd : String,
  config : SolConfig,
) -> AppMode {
  let server_dir = @path.join2(cwd, config.routes)
  let ts_routes = @path.join2(server_dir, "routes.ts")
  let mbt_routes = @path.join2(server_dir, "routes.mbt")

  // TypeScript routes take priority for hybrid mode
  if fs.exists_sync(ts_routes) {
    MoonBitClientTsServer
  } else if fs.exists_sync(mbt_routes) {
    MoonBitFull
  } else {
    // Default to MoonBit
    MoonBitFull
  }
}

// =============================================================================
// Runtime Asset Resolution (for sol generate)
// =============================================================================

///|
/// Built-in framework asset filenames served from /__sol__/.
/// These are pulled from `mizchi/astra/assets` for the canonical content,
/// with luna's compiled iife dist preferred where available.
let sol_asset_files : Array[String] = [
  "loader.js", "wc-loader.js", "sol-nav.js", "lib.js",
]

///|
/// Mapping from static/ filename to luna dist filename
fn luna_dist_name(filename : String) -> String {
  if filename == "loader.js" {
    "loader.iife.js"
  } else if filename == "wc-loader.js" {
    "wc-loader.iife.js"
  } else {
    filename
  }
}

///|
/// Resolve a runtime asset file. Priority order:
///   1. luna's compiled iife dist (mooncakes) for loader/wc-loader.
///   2. astra's bundled asset accessors (`@astra_assets.get_*_js()`).
///   3. astra-package raw script in mooncakes (for files astra has no
///      named getter for, e.g. `sol-nav.js`, `lib.js`).
fn resolve_runtime_asset(cwd : String, filename : String) -> String? {
  // Step 1: try luna's compiled iife dist when available (loader/wc-loader).
  let luna_name = luna_dist_name(filename)
  if luna_name != filename {
    let luna_dist = @path.join2(
      cwd,
      ".mooncakes/mizchi/luna/js/loader/dist/" + luna_name,
    )
    try {
      return Some(@fs.read_file_as_string(luna_dist))
    } catch {
      _ => ()
    }
  }
  // Step 2: ask astra/assets for files it knows by name. Empty string
  // means astra returned no content, so fall through to the raw lookup.
  let from_astra = if filename == "wc-loader.js" {
    @astra_assets.get_wc_loader_js()
  } else {
    ""
  }
  if from_astra.length() > 0 {
    return Some(from_astra)
  }
  // Step 3: fall back to reading the raw asset file from astra. Try the
  // mooncake location first (downstream consumers), then sibling dirs
  // for monorepo/path-dep development.
  // This covers `sol-nav.js` / `lib.js` which have no dedicated getter.
  let candidates = [
    cwd + "/.mooncakes/mizchi/astra/src/assets/scripts/" + filename,
    // sibling astra/ inside the same monorepo (sol/examples/<x>/ → ../../../astra/...)
    cwd + "/../../../astra/src/assets/scripts/" + filename,
    // sol-relative monorepo layout (running from sol/ → ../astra/...)
    cwd + "/../astra/src/assets/scripts/" + filename,
  ]
  for p in candidates {
    try {
      return Some(@fs.read_file_as_string(p))
    } catch {
      _ => continue
    }
  }
  None
}

// =============================================================================
// User-Managed Server Detection
// =============================================================================

///|
/// Check if user has a main.mbt in the routes directory (user-managed server mode)
pub fn[FS : @env.FileSystem] is_user_managed_server(
  fs : FS,
  cwd : String,
  config : SolConfig,
) -> Bool {
  let main_path = @path.join2(@path.join2(cwd, config.routes), "main.mbt")
  fs.exists_sync(main_path)
}

///|
/// Resolve server entry ownership. Explicit config wins; auto preserves
/// the historical "main.mbt exists" detection.
pub fn[FS : @env.FileSystem] should_use_user_managed_server(
  fs : FS,
  cwd : String,
  config : SolConfig,
) -> Bool {
  match config.server_entry {
    ServerEntryUserManaged => true
    ServerEntryGenerated => false
    ServerEntryAuto => is_user_managed_server(fs, cwd, config)
  }
}

///|
/// True when Sol should not discover, generate, or bundle client islands.
pub fn SolConfig::uses_external_client_bundle(self : SolConfig) -> Bool {
  self.client_bundle == ClientBundleExternal
}

// =============================================================================
// Helper Functions
// =============================================================================

///|
/// Get directory name from path
fn get_dir_name(path : String) -> String {
  let parts = path.split("/").to_array()
  if parts.length() > 0 {
    parts[parts.length() - 1].to_string()
  } else {
    "unknown"
  }
}

///|
/// Convert snake_case to PascalCase
fn snake_to_pascal(s : String) -> String {
  let buf = StringBuilder::new()
  let mut capitalize_next = true
  for c in s {
    if c == '_' {
      capitalize_next = true
    } else if capitalize_next {
      if c >= 'a' && c <= 'z' {
        buf.write_char(Char::from_int(c.to_int() - 32))
      } else {
        buf.write_char(c)
      }
      capitalize_next = false
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
/// Get routes package path from moon.mod / moon.mod.json
fn get_routes_package_path(cwd : String, routes_dir : String) -> String {
  let fs = @fs_adapter.NodeFsAdapter::new()
  get_routes_package_path_with_fs(fs, cwd, routes_dir)
}

///|
fn[FS : @env.FileSystem] get_routes_package_path_with_fs(
  fs : FS,
  cwd : String,
  routes_dir : String,
) -> String {
  let (pkg_name, source_raw) = read_mod_info_from_cwd_with_fs(fs, cwd)
  if pkg_name != "" {
    let source = if source_raw == "" { "src" } else { source_raw }
    // If source is "." or empty, use the full routes_dir path.
    // If source is "app", strip "app/" prefix for backward compatibility.
    let routes_suffix = if source == "." || source == "" {
      routes_dir
    } else if routes_dir.starts_with(source + "/") {
      routes_dir.substring(start=source.length() + 1)
    } else {
      routes_dir
    }
    return "\{pkg_name}/\{routes_suffix}"
  }
  // Fallback
  routes_dir
}
