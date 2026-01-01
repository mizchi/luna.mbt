// Shared CLI Utilities
//
// Common utilities used by Sol CLI.

///|
/// Log error message to console.error
pub fn console_error(msg : String) -> Unit {
  @console.error(@js.any(msg))
}

///|
/// Keep Node.js event loop alive (for long-running servers)
pub fn keep_alive() -> Unit {
  ffi_keep_alive()
}

///|
extern "js" fn ffi_keep_alive() -> Unit =
  #| () => { setInterval(() => {}, 1000 * 60 * 60) }

///|
/// Get current timestamp in milliseconds
pub fn date_now() -> Double {
  ffi_date_now()
}

///|
extern "js" fn ffi_date_now() -> Double =
  #| () => Date.now()

// =============================================================================
// Config File Discovery
// =============================================================================

///|
/// Find config file from a list of candidates.
/// Returns the first found candidate path, or the default if none found.
pub fn[FS : @env.FileSystem] find_config(
  fs : FS,
  cwd : String,
  candidates : Array[String],
  default : String,
) -> String {
  for candidate in candidates {
    let full_path = @path.join2(cwd, candidate)
    if fs.exists_sync(full_path) {
      return candidate
    }
  }
  default
}

///|
/// SSG config file candidates in search order
pub let ssg_config_candidates : Array[String] = [
  "sol.config.json", "website/sol.config.json", "docs/sol.config.json",
]

///|
/// Sol config file candidates in search order
pub let sol_config_candidates : Array[String] = ["sol.config.json"]

// =============================================================================
// File System Utilities
// =============================================================================

///|
/// Recursively remove a directory (rm -rf equivalent)
pub fn[FS : @env.FileSystem] rm_rf_sync(fs : FS, path : String) -> Unit {
  fs.rmdir_sync(path, true) catch {
    _ => ()
  }
}

// =============================================================================
// MIME Type Detection
// =============================================================================

///|
/// Get content type (MIME type) for a file path based on extension
pub fn get_content_type(file_path : String) -> String {
  if file_path.has_suffix(".html") {
    "text/html; charset=utf-8"
  } else if file_path.has_suffix(".css") {
    "text/css; charset=utf-8"
  } else if file_path.has_suffix(".js") {
    "application/javascript; charset=utf-8"
  } else if file_path.has_suffix(".json") {
    "application/json; charset=utf-8"
  } else if file_path.has_suffix(".svg") {
    "image/svg+xml"
  } else if file_path.has_suffix(".png") {
    "image/png"
  } else if file_path.has_suffix(".jpg") || file_path.has_suffix(".jpeg") {
    "image/jpeg"
  } else if file_path.has_suffix(".gif") {
    "image/gif"
  } else if file_path.has_suffix(".ico") {
    "image/x-icon"
  } else if file_path.has_suffix(".woff") {
    "font/woff"
  } else if file_path.has_suffix(".woff2") {
    "font/woff2"
  } else if file_path.has_suffix(".ttf") {
    "font/ttf"
  } else if file_path.has_suffix(".xml") {
    "application/xml"
  } else if file_path.has_suffix(".txt") {
    "text/plain; charset=utf-8"
  } else if file_path.has_suffix(".wasm") {
    "application/wasm"
  } else if file_path.has_suffix(".pf_meta") ||
    file_path.has_suffix(".pf_index") {
    "application/octet-stream"
  } else {
    "application/octet-stream"
  }
}
