// MBTX File Scanner
//
// Scans directories for .mbtx files and derives route paths from filenames.
// Used by `sol generate` to auto-discover .mbtx page handlers.

///|
/// Discovered .mbtx file entry
pub(all) struct MbtxFileEntry {
  /// Route path (e.g., "/api/hello", "/api/users/:id")
  route : String
  /// Relative source path (e.g., "app/mbtx/hello.mbtx")
  source : String
  /// Derived ID (e.g., "hello", "users_id")
  id : String
}

///|
/// Scan a directory for .mbtx files and derive route entries.
/// Converts file paths to URL patterns:
///   hello.mbtx         → /hello
///   users/_id_.mbtx    → /users/:id
///   docs/___slug___.mbtx → /docs/[...slug]
pub fn[FS : @env.FileSystem] scan_mbtx_dir(
  fs : FS,
  mbtx_dir : String,
  cwd : String,
  base_path? : String = "",
) -> Array[MbtxFileEntry] {
  let full_path = if mbtx_dir.has_prefix("/") {
    mbtx_dir
  } else {
    cwd + "/" + mbtx_dir
  }
  if !(fs.exists_sync(full_path)) {
    return []
  }
  let entries : Array[MbtxFileEntry] = []
  scan_mbtx_recursive(fs, full_path, mbtx_dir, "", base_path, entries)
  entries
}

///|
fn[FS : @env.FileSystem] scan_mbtx_recursive(
  fs : FS,
  abs_path : String,
  mbtx_dir : String,
  rel_path : String,
  base_path : String,
  entries : Array[MbtxFileEntry],
) -> Unit {
  let dir_entries : Array[String] = fs.readdir_sync(abs_path) catch { _ => [] }
  for entry in dir_entries {
    let entry_abs = abs_path + "/" + entry
    let entry_rel = if rel_path.is_empty() { entry } else { rel_path + "/" + entry }
    if (fs.is_directory_sync(entry_abs) catch { _ => false }) {
      scan_mbtx_recursive(fs, entry_abs, mbtx_dir, entry_rel, base_path, entries)
    } else if entry.has_suffix(".mbtx") {
      let source = mbtx_dir + "/" + entry_rel
      let route = mbtx_file_to_route(entry_rel, base_path)
      let id = mbtx_file_to_id(entry_rel)
      entries.push({ route, source, id })
    }
  }
}

///|
/// Convert a .mbtx relative path to a route URL pattern.
/// "hello.mbtx"           → "/hello"
/// "api/hello.mbtx"       → "/api/hello"
/// "users/_id_.mbtx"      → "/users/:id"
/// "index.mbtx"           → "/"
/// "api/index.mbtx"       → "/api"
fn mbtx_file_to_route(rel_path : String, base_path : String) -> String {
  // Remove .mbtx extension
  let without_ext = rel_path.substring(end=rel_path.length() - 5)
  let buf = StringBuilder::new()
  buf.write_string(base_path)
  for segment_view in without_ext.split("/") {
    let segment = segment_view.to_string()
    if segment.is_empty() {
      continue
    }
    if segment == "index" {
      // index.mbtx maps to the directory itself
      continue
    }
    buf.write_string("/")
    // Check for dynamic segment: _name_ → :name
    if segment.has_prefix("___") && segment.has_suffix("___") && segment.length() > 6 {
      // Catch-all: ___slug___ → [...slug]
      let param = segment.substring(start=3, end=segment.length() - 3)
      buf.write_string("[...")
      buf.write_string(param)
      buf.write_string("]")
    } else if segment.has_prefix("_") &&
      segment.has_suffix("_") &&
      segment.length() > 2 {
      // Dynamic param: _id_ → :id
      let param = segment.substring(start=1, end=segment.length() - 1)
      buf.write_string(":")
      buf.write_string(param)
    } else {
      buf.write_string(segment)
    }
  }
  let route = buf.to_string()
  if route.is_empty() {
    "/"
  } else {
    route
  }
}

///|
/// Convert a .mbtx relative path to an identifier.
/// "hello.mbtx"      → "hello"
/// "api/hello.mbtx"  → "api_hello"
/// "users/_id_.mbtx"  → "users_id"
fn mbtx_file_to_id(rel_path : String) -> String {
  let without_ext = rel_path.substring(end=rel_path.length() - 5)
  let buf = StringBuilder::new()
  let mut first = true
  for segment_view in without_ext.split("/") {
    let segment = segment_view.to_string()
    if segment.is_empty() || segment == "index" {
      continue
    }
    if !(first) {
      buf.write_string("_")
    }
    first = false
    // Strip dynamic markers
    if segment.has_prefix("___") && segment.has_suffix("___") && segment.length() > 6 {
      buf.write_string(segment.substring(start=3, end=segment.length() - 3))
    } else if segment.has_prefix("_") &&
      segment.has_suffix("_") &&
      segment.length() > 2 {
      buf.write_string(segment.substring(start=1, end=segment.length() - 1))
    } else {
      for c in segment {
        if c == '-' {
          buf.write_char('_')
        } else {
          buf.write_char(c)
        }
      }
    }
  }
  let id = buf.to_string()
  if id.is_empty() { "index" } else { id }
}
