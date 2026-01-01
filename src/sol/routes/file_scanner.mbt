// File-based Router Scanner
//
// Provides generic file scanning infrastructure for route generation.
// sol/ssg uses this for SSG file-based routing.

// =============================================================================
// Scan Options
// =============================================================================

///|
/// Options for directory scanning
pub(all) struct ScanOptions {
  /// Directories/patterns to exclude
  exclude : Array[String]
  /// Add trailing slash to URL paths
  trailing_slash : Bool
}

///|
/// Default scan options
pub fn ScanOptions::default() -> ScanOptions {
  { exclude: [], trailing_slash: true }
}

// =============================================================================
// File Entry
// =============================================================================

///|
/// Raw file entry from scanning (before content processing)
pub(all) struct FileEntry {
  /// Relative path from docs root
  relative_path : String
  /// Full absolute path
  absolute_path : String
  /// File extension (md, html, mdx, tsx, etc.)
  extension : String
  /// Whether this is a directory
  is_directory : Bool
}

// =============================================================================
// Exclusion Logic
// =============================================================================

///|
/// Check if directory should be excluded
/// Matches against directory name or relative path
pub fn is_excluded(
  name : String,
  relative_path : String,
  exclude : Array[String],
) -> Bool {
  // Always exclude "public" directory (reserved for static assets)
  if name == "public" || relative_path.has_prefix("public/") {
    return true
  }
  for pattern in exclude {
    // Match by directory name (e.g., "internal" matches "docs/internal")
    if name == pattern {
      return true
    }
    // Match by relative path (e.g., "internal/drafts" matches exactly)
    if relative_path == pattern {
      return true
    }
    // Match by path prefix (e.g., "internal" matches "internal/foo")
    if relative_path.has_prefix(pattern + "/") {
      return true
    }
  }
  false
}

// =============================================================================
// Path Utilities
// =============================================================================

///|
/// Simple path join (without using @path which requires Node.js)
pub fn join_path(base : String, name : String) -> String {
  if base.is_empty() {
    name
  } else if base.has_suffix("/") {
    base + name
  } else {
    base + "/" + name
  }
}

///|
/// Get the basename (last segment) of a path
pub fn get_basename(path : String) -> String {
  let chars = path.to_array()
  let mut last_slash = -1
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == '/' {
      last_slash = i
    }
  }
  if last_slash >= 0 && last_slash < chars.length() - 1 {
    let result : Array[Char] = []
    for i = last_slash + 1; i < chars.length(); i = i + 1 {
      result.push(chars[i])
    }
    String::from_array(result)
  } else {
    path
  }
}

///|
/// Get parent directory path
pub fn get_parent_dir(path : String) -> String {
  let chars = path.to_array()
  let mut last_slash = -1
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == '/' {
      last_slash = i
    }
  }
  if last_slash > 0 {
    String::from_array(chars[0:last_slash])
  } else {
    ""
  }
}

///|
/// Get file extension from filename (includes the dot, e.g., ".mbt")
pub fn get_extension(filename : String) -> String {
  match filename.rev_find(".") {
    Some(idx) => {
      let chars = filename.to_array()
      String::from_array(chars[idx:]) // Include the dot
    }
    None => ""
  }
}

///|
/// Check if file is a content file (md, mdx, html)
pub fn is_content_file(filename : String) -> Bool {
  filename.has_suffix(".md") ||
  filename.has_suffix(".mdx") ||
  filename.has_suffix(".html")
}

///|
/// Check if file is a component indicator (moon.pkg.json)
pub fn is_moonbit_component(filename : String) -> Bool {
  filename == "moon.pkg.json"
}

///|
/// Check if file is a TSX component
pub fn is_tsx_file(filename : String) -> Bool {
  filename.has_suffix(".tsx")
}

// Dynamic route detection is provided by scanner.mbt in this package:
// - ParamInfo
// - extract_param_name
// - extract_param_from_filename

// =============================================================================
// Generic Directory Scanner
// =============================================================================

///|
/// Scan a directory and collect file entries
/// This is a low-level scanner - content processing is done by the caller
pub fn[FS : @env.FileSystem] scan_directory(
  filesystem : FS,
  root_path : String,
  options : ScanOptions,
) -> Array[FileEntry] {
  let entries : Array[FileEntry] = []
  scan_directory_recursive(filesystem, root_path, "", options, entries)
  entries
}

///|
fn[FS : @env.FileSystem] scan_directory_recursive(
  filesystem : FS,
  current_path : String,
  relative_path : String,
  options : ScanOptions,
  entries : Array[FileEntry],
) -> Unit {
  let dir_entries : Array[String] = @env.FileSystem::readdir_sync(
    filesystem, current_path,
  ) catch {
    _ => return
  }
  for entry_name in dir_entries {
    let entry_path = join_path(current_path, entry_name)
    let entry_relative = if relative_path.is_empty() {
      entry_name
    } else {
      relative_path + "/" + entry_name
    }
    let is_dir : Bool = @env.FileSystem::is_directory_sync(
      filesystem, entry_path,
    ) catch {
      _ => false
    }
    if is_dir {
      // Skip excluded directories
      if is_excluded(entry_name, entry_relative, options.exclude) {
        continue
      }
      // Add directory entry
      entries.push(FileEntry::{
        relative_path: entry_relative,
        absolute_path: entry_path,
        extension: "",
        is_directory: true,
      })
      // Recurse into subdirectory
      scan_directory_recursive(
        filesystem, entry_path, entry_relative, options, entries,
      )
    } else {
      // Add file entry
      let ext = get_extension(entry_name)
      entries.push(FileEntry::{
        relative_path: entry_relative,
        absolute_path: entry_path,
        extension: ext,
        is_directory: false,
      })
    }
  }
}
