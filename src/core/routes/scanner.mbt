// Directory Scanner for Pages
//
// Scans src/pages/ directory to generate RouteManifest

// =============================================================================
// Main Scanner
// =============================================================================

///|
/// Scan pages directory and generate RouteManifest
pub fn[FS : @env.FileSystem] scan_pages_dir(
  fs : FS,
  pages_dir : String,
  cwd : String,
) -> RouteManifest {
  let full_path = join_path(cwd, pages_dir)

  // Check if directory exists
  if not(fs.exists_sync(full_path)) {
    return RouteManifest::empty()
  }

  // Scan recursively
  let routes : Array[RouteEntry] = []
  let root_config = PageConfig::default()
  scan_recursive(fs, full_path, pages_dir, "", root_config, routes)
  RouteManifest::{ routes, fallback: FallbackConfig::default() }
}

///|
/// Recursively scan directory
fn[FS : @env.FileSystem] scan_recursive(
  fs : FS,
  abs_path : String,
  pages_dir : String,
  rel_path : String,
  parent_config : PageConfig,
  routes : Array[RouteEntry],
) -> Unit {
  // Read directory entries
  let entries : Array[String] = fs.readdir_sync(abs_path) catch { _ => [] }

  // Load page.json if exists
  let page_json_path = join_path(abs_path, "page.json")
  let config = if fs.exists_sync(page_json_path) {
    let content : String = fs.read_file_sync(page_json_path) catch { _ => "" }
    match parse_page_config(content) {
      Some(cfg) => PageConfig::merge(parent_config, cfg)
      None => parent_config
    }
  } else {
    parent_config
  }

  // Process entries
  for entry in entries {
    let entry_path = join_path(abs_path, entry)
    let entry_rel = if rel_path.is_empty() {
      entry
    } else {
      rel_path + "/" + entry
    }
    if is_directory(fs, entry_path) {
      // Check if it's a component directory (has moon.pkg.json)
      let moon_pkg_path = join_path(entry_path, "moon.pkg.json")
      if fs.exists_sync(moon_pkg_path) {
        // Component directory - process as component
        process_component_dir(
          fs, entry_path, pages_dir, entry_rel, config, routes,
        )
      } else {
        // Check if it's a dynamic segment
        match extract_param_name(entry) {
          Some(param_info) =>
            // Dynamic or catch-all route
            scan_dynamic_dir(
              fs, entry_path, pages_dir, entry_rel, param_info, config, routes,
            )
          None =>
            // Regular directory
            scan_recursive(fs, entry_path, pages_dir, entry_rel, config, routes)
        }
      }
    } else {
      // Regular file
      process_page_file(
        fs, entry_path, pages_dir, entry_rel, entry, config, routes,
      )
    }
  }
}

// =============================================================================
// Component Directory Processing
// =============================================================================

///|
/// Process a component directory (moon.pkg.json with optional client/server)
fn[FS : @env.FileSystem] process_component_dir(
  fs : FS,
  abs_path : String,
  _pages_dir : String,
  rel_path : String,
  parent_config : PageConfig,
  routes : Array[RouteEntry],
) -> Unit {
  // Load page.json if exists
  let page_json_path = join_path(abs_path, "page.json")
  let config = if fs.exists_sync(page_json_path) {
    let content : String = fs.read_file_sync(page_json_path) catch { _ => "" }
    match parse_page_config(content) {
      Some(cfg) => PageConfig::merge(parent_config, cfg)
      None => parent_config
    }
  } else {
    parent_config
  }

  // Detect component type by checking for client/ and server/ directories
  let client_path = join_path(abs_path, "client")
  let server_path = join_path(abs_path, "server")
  let has_client = fs.exists_sync(client_path) && is_directory(fs, client_path)
  let has_server = fs.exists_sync(server_path) && is_directory(fs, server_path)
  let component_type = detect_component_type(has_client, has_server)

  // Build URL path from relative path
  let url_path = "/" + rel_path

  // Get component configuration from page.json
  let (props_type, client_export, server_export) = match config.component {
    Some(comp) => (comp.props_type, comp.client_export, comp.server_export)
    None => (None, None, None)
  }

  // Build static paths from staticParams
  let static_paths = build_static_paths(rel_path, config.static_params)

  // Determine render mode
  let mode = config.to_render_mode()

  // Create component route entry
  let entry = RouteEntry::Component(ComponentRouteEntry::{
    path: url_path,
    source: rel_path + "/",
    component_type,
    mode,
    layout: config.layout,
    props_type,
    client_export,
    server_export,
    static_paths,
    islands: config.islands,
  })
  routes.push(entry)
}

///|
/// Detect component type based on client/server directory presence
pub fn detect_component_type(
  has_client : Bool,
  has_server : Bool,
) -> ComponentType {
  match (has_client, has_server) {
    (true, true) => ComponentType::SsrComponent
    (true, false) => ComponentType::ClientOnlyComponent
    (false, true) => ComponentType::ServerOnlyComponent
    // If neither client nor server, treat as server-only (static content)
    (false, false) => ComponentType::ServerOnlyComponent
  }
}

///|
/// Build static path entries from staticParams array
pub fn build_static_paths(
  base_path : String,
  static_params : Array[Map[String, String]],
) -> Array[StaticPathEntry] {
  let result : Array[StaticPathEntry] = []
  for params in static_params {
    // Build output path from params
    // e.g., base="counter", params={"id": "1"} -> "counter/1/index.html"
    let output = build_output_path_from_params(base_path, params)
    result.push(StaticPathEntry::{ params, output })
  }
  result
}

///|
/// Build output path from base path and parameters
fn build_output_path_from_params(
  base_path : String,
  params : Map[String, String],
) -> String {
  // For single param, append the value
  // For multiple params, append them in order (sorted by key for consistency)
  let mut path = base_path
  let keys = params.keys().collect()
  // Sort keys for consistent ordering
  let sorted_keys = sort_strings(keys)
  for key in sorted_keys {
    match params.get(key) {
      Some(value) => path = path + "/" + value
      None => ()
    }
  }
  path + "/index.html"
}

///|
/// Sort strings lexicographically (simple insertion sort)
fn sort_strings(arr : Array[String]) -> Array[String] {
  let result : Array[String] = []
  for s in arr {
    let mut pos = result.length()
    for i = 0; i < result.length(); i = i + 1 {
      if @ssg.compare_strings_lex(s, result[i]) < 0 {
        pos = i
        break
      }
    }
    if pos == result.length() {
      result.push(s)
    } else {
      result.push(result[result.length() - 1])
      for j = result.length() - 2; j > pos; j = j - 1 {
        result[j] = result[j - 1]
      }
      result[pos] = s
    }
  }
  result
}

///|
/// Scan dynamic directory (_name_/ or _...name_/)
fn[FS : @env.FileSystem] scan_dynamic_dir(
  fs : FS,
  abs_path : String,
  _pages_dir : String,
  rel_path : String,
  param_info : ParamInfo,
  config : PageConfig,
  routes : Array[RouteEntry],
) -> Unit {
  let param_name = param_info.name
  let is_catch_all = param_info.catch_all

  // Read directory entries
  let entries : Array[String] = fs.readdir_sync(abs_path) catch { _ => [] }

  // Look for index file
  for entry in entries {
    let file_type = FileType::from_extension(get_extension(entry))
    if file_type.is_page() && is_index_file(entry) {
      // Build dynamic route
      let url_pattern = build_dynamic_url_pattern(
        rel_path, param_name, is_catch_all,
      )
      let regex_pattern = build_regex_pattern(url_pattern)
      let catch_all_info = if is_catch_all {
        Some(CatchAllInfo::{ name: param_name, optional: false })
      } else {
        None
      }
      if config.is_static() && config.generate_params {
        // Static generation with params - will be filled later
        let entry = RouteEntry::Static(StaticRouteEntry::{
          path: url_pattern,
          source: rel_path + "/" + entry,
          output: "", // Filled during generation
          layout: config.layout,
          title: config.title,
          description: config.description,
          islands: config.islands,
          locale: "en",
          generated_params: [], // Filled by getStaticParams
        })
        routes.push(entry)
      } else {
        // Dynamic route
        let entry = RouteEntry::Dynamic(DynamicRouteEntry::{
          path: url_pattern,
          pattern: regex_pattern,
          param_names: [param_name],
          source: rel_path + "/" + entry,
          mode: config.to_render_mode(),
          layout: config.layout,
          catch_all: catch_all_info,
          title: config.title,
          islands: config.islands,
        })
        routes.push(entry)
      }
    }
  }
}

///|
/// Process a regular page file
fn[FS : @env.FileSystem] process_page_file(
  _fs : FS,
  _abs_path : String,
  _pages_dir : String,
  rel_path : String,
  filename : String,
  config : PageConfig,
  routes : Array[RouteEntry],
) -> Unit {
  let file_type = FileType::from_extension(get_extension(filename))
  if not(file_type.is_page()) {
    return
  }

  // Skip non-index files in dynamic directories
  // (they're handled by scan_dynamic_dir)

  // Build URL path
  let url_path = file_to_url_path(rel_path)

  // Build output path
  let output_path = @ssg.url_to_output_path(url_path)

  // Check file-type specific config
  let ext = get_extension(filename)
  let effective_config = match config.handlers.get(ext) {
    Some(handler_config) => {
      // Merge handler config
      let layout = match handler_config.layout {
        Some(l) => Some(l)
        None => config.layout
      }
      let islands = if handler_config.islands.is_empty() {
        config.islands
      } else {
        handler_config.islands
      }
      PageConfig::{ ..config, layout, islands }
    }
    None => config
  }

  // Create route entry
  if effective_config.is_static() {
    let entry = RouteEntry::Static(StaticRouteEntry::{
      path: url_path,
      source: rel_path,
      output: output_path,
      layout: effective_config.layout,
      title: effective_config.title,
      description: effective_config.description,
      islands: effective_config.islands,
      locale: "en",
      generated_params: [],
    })
    routes.push(entry)
  } else {
    let entry = RouteEntry::Dynamic(DynamicRouteEntry::{
      path: url_path,
      pattern: "^" + url_path + "$",
      param_names: [],
      source: rel_path,
      mode: effective_config.to_render_mode(),
      layout: effective_config.layout,
      catch_all: None,
      title: effective_config.title,
      islands: effective_config.islands,
    })
    routes.push(entry)
  }
}

// =============================================================================
// Helper Functions
// =============================================================================

///|
/// Parameter extraction result
pub(all) struct ParamInfo {
  /// Parameter name
  name : String
  /// Whether this is a catch-all pattern
  catch_all : Bool
}

///|
/// Extract parameter name from directory name
/// _slug_ -> Some(ParamInfo { name: "slug", catch_all: false })
/// _...slug_ -> Some(ParamInfo { name: "slug", catch_all: true })
/// regular -> None
fn extract_param_name(dir_name : String) -> ParamInfo? {
  let len = dir_name.length()
  if dir_name.has_prefix("_") && dir_name.has_suffix("_") && len > 2 {
    // Extract content between underscores
    let inner = @ssg.extract_substring(dir_name, 1, len - 1)
    // Check for catch-all pattern _...name_
    if inner.has_prefix("...") && inner.length() > 3 {
      let name = @ssg.extract_substring(inner, 3, inner.length())
      Some(ParamInfo::{ name, catch_all: true })
    } else {
      Some(ParamInfo::{ name: inner, catch_all: false })
    }
  } else {
    None
  }
}

///|
/// Check if a file is an index file
fn is_index_file(filename : String) -> Bool {
  filename.has_prefix("index.")
}

///|
/// Build URL pattern for dynamic route
fn build_dynamic_url_pattern(
  rel_path : String,
  param_name : String,
  is_catch_all : Bool,
) -> String {
  // Convert _slug_/index.mbt to /:slug
  // Convert _catchall_/index.mbt to /*
  let dir_path = get_parent_path(rel_path)
  let base = if dir_path.is_empty() { "/" } else { "/" + dir_path + "/" }
  if is_catch_all {
    base + "*"
  } else {
    base + ":" + param_name
  }
}

///|
/// Build regex pattern from URL pattern
fn build_regex_pattern(url_pattern : String) -> String {
  // Simple conversion - in production would need proper escaping
  let pattern = url_pattern
    .replace_all(old="*", new="(.*)")
    .replace_all(old=":([a-zA-Z0-9_]+)", new="([^/]+)")
  "^" + pattern + "$"
}

///|
/// Convert file path to URL path
fn file_to_url_path(rel_path : String) -> String {
  // Strip numeric prefixes and convert to URL
  let url = @ssg.file_to_url_path(rel_path, trailing_slash=true)
  if url.is_empty() {
    "/"
  } else {
    url
  }
}

///|
/// Get file extension including dot
fn get_extension(filename : String) -> String {
  let dot_idx = find_last_char(filename, '.')
  if dot_idx >= 0 {
    @ssg.extract_substring(filename, dot_idx, filename.length())
  } else {
    ""
  }
}

///|
/// Get parent directory path
fn get_parent_path(path : String) -> String {
  let slash_idx = find_last_char(path, '/')
  if slash_idx >= 0 {
    @ssg.extract_substring(path, 0, slash_idx)
  } else {
    ""
  }
}

///|
/// Find last occurrence of character in string
fn find_last_char(s : String, ch : Char) -> Int {
  let mut idx = 0
  let mut last_idx = -1
  for c in s {
    if c == ch {
      last_idx = idx
    }
    idx = idx + 1
  }
  last_idx
}

///|
/// Join two path segments
fn join_path(a : String, b : String) -> String {
  if a.is_empty() {
    b
  } else if b.is_empty() {
    a
  } else if a.has_suffix("/") {
    a + b
  } else {
    a + "/" + b
  }
}

///|
/// Check if path is a directory
fn[FS : @env.FileSystem] is_directory(fs : FS, path : String) -> Bool {
  fs.is_directory_sync(path) catch {
    _ => false
  }
}
