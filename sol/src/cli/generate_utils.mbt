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
} derive(Eq, Show)

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
/// Built-in framework asset filenames served from /__sol__/
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
/// Resolve a runtime asset file by trying multiple candidate paths.
/// Used at build time (sol generate) to find and copy assets.
fn resolve_runtime_asset(cwd : String, filename : String) -> String? {
  let luna_name = luna_dist_name(filename)
  let candidates = [
    // mooncakes (luna): loader dist from luna package
    @path.join2(cwd, ".mooncakes/mizchi/luna/js/loader/dist/" + luna_name),
    // mooncakes (sol): canonical assets from sol package
    @path.join2(cwd, ".mooncakes/mizchi/sol/src/ssg/assets/scripts/" + filename),
    // Development: sol.mbt repo root (monorepo examples)
    @path.join2(cwd, "../../src/ssg/assets/scripts/" + filename),
    // Development: direct child of sol.mbt
    @path.join2(cwd, "../src/ssg/assets/scripts/" + filename),
    // Same repo root
    @path.join2(cwd, "src/ssg/assets/scripts/" + filename),
  ]
  for path in candidates {
    try {
      return Some(@fs.read_file_as_string(path))
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
pub fn is_user_managed_server[FS : @env.FileSystem](
  fs : FS,
  cwd : String,
  config : SolConfig,
) -> Bool {
  let main_path = @path.join2(@path.join2(cwd, config.routes), "main.mbt")
  fs.exists_sync(main_path)
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
/// Get routes package path from moon.mod.json
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
  // Read moon.mod.json to get package name
  let mod_path = @path.join2(cwd, "moon.mod.json")
  if fs.exists_sync(mod_path) {
    try {
      let content = fs.read_file_sync(mod_path)
      let json = @json.parse(content.view())
      guard json is Object(obj) else { return "\{routes_dir}" }
      guard obj.get("name") is Some(String(pkg_name)) else {
        return "\{routes_dir}"
      }
      // Check source field to determine package path
      let source = match obj.get("source") {
        Some(String(s)) => s
        _ => "src"
      }
      // If source is "." or empty, use the full routes_dir path
      // If source is "app", strip "app/" prefix for backward compatibility
      let routes_suffix = if source == "." || source == "" {
        routes_dir
      } else if routes_dir.starts_with(source + "/") {
        routes_dir.substring(start=source.length() + 1)
      } else {
        routes_dir
      }
      return "\{pkg_name}/\{routes_suffix}"
    } catch {
      _ => ()
    }
  }
  // Fallback
  routes_dir
}

///|
/// Read module name and source from moon.mod.json
/// Returns (name, source) tuple
fn read_mod_info(mod_json_path : String) -> (String, String) {
  let fs = @fs_adapter.NodeFsAdapter::new()
  read_mod_info_with_fs(fs, mod_json_path)
}

///|
fn[FS : @env.FileSystem] read_mod_info_with_fs(
  fs : FS,
  mod_json_path : String,
) -> (String, String) {
  let content : String = fs.read_file_sync(mod_json_path) catch {
    _ => return ("", "")
  }
  if content.length() == 0 {
    return ("", "")
  }
  let json = @json.parse(content.view()) catch { _ => return ("", "") }
  match json {
    Object(obj) => {
      let name = match obj.get("name") {
        Some(String(n)) => n
        _ => ""
      }
      let source = match obj.get("source") {
        Some(String(s)) => s
        _ => ""
      }
      (name, source)
    }
    _ => ("", "")
  }
}
