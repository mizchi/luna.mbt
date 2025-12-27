// Build Manifest for Incremental Build Skip
//
// Stores metadata about the last successful build to enable
// skipping unchanged builds.
//
// NOTE: This file provides backward compatibility.
// New code should use provider.mbt and core/cache/provider.mbt

///|
/// Build manifest stored in .astra-cache/build-manifest.json
pub(all) struct BuildManifest {
  /// Astra version that generated this build
  astra_version : String
  /// Hash of the configuration
  config_hash : String
  /// Hash of all content files
  content_hash : String
  /// ISO 8601 timestamp of the build
  built_at : String
}

///|
/// Create a new build manifest
pub fn BuildManifest::new(
  config_hash~ : String,
  content_hash~ : String,
  built_at~ : String,
) -> BuildManifest {
  { astra_version, config_hash, content_hash, built_at }
}

// Re-export astra_version from provider.mbt for backward compatibility

///|
pub fn get_astra_version() -> String {
  astra_version
}

///|
/// Check if manifest matches current state
pub fn BuildManifest::matches(
  self : BuildManifest,
  current_config_hash : String,
  current_content_hash : String,
) -> Bool {
  self.astra_version == astra_version &&
  self.config_hash == current_config_hash &&
  self.content_hash == current_content_hash
}

///|
/// Serialize manifest to JSON
pub fn BuildManifest::to_json(self : BuildManifest) -> String {
  let buf = StringBuilder::new()
  buf.write_string("{\n")
  buf.write_string("  \"astra_version\": \"")
  buf.write_string(escape_json_string(self.astra_version))
  buf.write_string("\",\n")
  buf.write_string("  \"config_hash\": \"")
  buf.write_string(escape_json_string(self.config_hash))
  buf.write_string("\",\n")
  buf.write_string("  \"content_hash\": \"")
  buf.write_string(escape_json_string(self.content_hash))
  buf.write_string("\",\n")
  buf.write_string("  \"built_at\": \"")
  buf.write_string(escape_json_string(self.built_at))
  buf.write_string("\"\n")
  buf.write_string("}")
  buf.to_string()
}

///|
/// Parse manifest from JSON
pub fn BuildManifest::from_json(json : String) -> BuildManifest? {
  // Simple JSON parsing for our known structure
  let version = extract_json_string(json, "astra_version")
  let config = extract_json_string(json, "config_hash")
  let content = extract_json_string(json, "content_hash")
  let built = extract_json_string(json, "built_at")
  match (version, config, content, built) {
    (Some(v), Some(c), Some(ct), Some(b)) =>
      Some({ astra_version: v, config_hash: c, content_hash: ct, built_at: b })
    _ => None
  }
}

///|
/// Extract string value from JSON by key
fn extract_json_string(json : String, key : String) -> String? {
  let pattern = "\"" + key + "\": \""
  let start_idx = find_substring(json, pattern)
  guard start_idx >= 0 else { return None }
  let value_start = start_idx + pattern.length()
  let remaining = json[value_start:].to_string() catch { _ => return None }
  let end_idx = find_substring(remaining, "\"")
  guard end_idx >= 0 else { return None }
  Some(remaining[:end_idx].to_string() catch { _ => return None })
}

///|
/// Find substring index (returns -1 if not found)
fn find_substring(haystack : String, needle : String) -> Int {
  let haystack_len = haystack.length()
  let needle_len = needle.length()
  if needle_len == 0 {
    return 0
  }
  if needle_len > haystack_len {
    return -1
  }
  for i = 0; i <= haystack_len - needle_len; i = i + 1 {
    let mut found = true
    for j = 0; j < needle_len; j = j + 1 {
      if haystack[i + j] != needle[j] {
        found = false
        break
      }
    }
    if found {
      return i
    }
  }
  -1
}

///|
/// Escape string for JSON
fn escape_json_string(s : String) -> String {
  let buf = StringBuilder::new()
  for c in s {
    match c {
      '"' => buf.write_string("\\\"")
      '\\' => buf.write_string("\\\\")
      '\n' => buf.write_string("\\n")
      '\r' => buf.write_string("\\r")
      '\t' => buf.write_string("\\t")
      _ => buf.write_char(c)
    }
  }
  buf.to_string()
}

// =============================================================================
// Build Manifest File Operations
// =============================================================================

///|
/// Manifest filename
let manifest_filename : String = "build-manifest.json"

///|
/// Load build manifest from cache directory
pub fn load_build_manifest(cache_dir : String) -> BuildManifest? {
  let path = @path.join2(cache_dir, manifest_filename)
  guard @fs.existsSync(path) else { return None }
  let content : String = @fs.readFileSync(path).to_string() catch {
    _ => return None
  }
  BuildManifest::from_json(content)
}

///|
/// Save build manifest to cache directory
pub fn save_build_manifest(
  cache_dir : String,
  manifest : BuildManifest,
) -> Unit {
  // Ensure cache directory exists
  @fs.mkdirSync(cache_dir, recursive=true) catch {
    _ => ()
  }
  let path = @path.join2(cache_dir, manifest_filename)
  @fs.writeFileSync(path, @js.any(manifest.to_json())) catch {
    _ => ()
  }
}
