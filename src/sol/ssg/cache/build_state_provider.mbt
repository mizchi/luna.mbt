// Build State Provider
//
// Abstraction for determining if a rebuild is needed.
// Implementations can use file hashes, database timestamps, or other sources.

// =============================================================================
// Build State Provider Trait
// =============================================================================

///|
/// Provider for build state information
/// Used to determine if content has changed and rebuild is needed
pub(open) trait BuildStateProvider {
  /// Get the current content state as a string
  /// This could be a hash, timestamp, version number, etc.
  /// The value should change when content changes.
  get_content_state(Self) -> String

  /// Optional: Get a human-readable description of the state
  /// e.g., "2024-12-28T12:00:00Z" or "42 files, hash: abc123"
  describe_state(Self) -> String
}

// =============================================================================
// Build State Result
// =============================================================================

///|
/// Result of checking build state
pub(all) enum BuildStateCheck {
  /// No rebuild needed - content unchanged
  UpToDate(String) // last_built_at timestamp
  /// Rebuild needed - content changed
  NeedsRebuild
  /// No previous build found
  NoPreviousBuild
}

///|
/// Check if state is up to date
pub fn BuildStateCheck::is_up_to_date(self : BuildStateCheck) -> Bool {
  match self {
    UpToDate(_) => true
    _ => false
  }
}

// =============================================================================
// Build State Checker
// =============================================================================

///|
/// Check if rebuild is needed by comparing provider state with manifest
pub fn[P : BuildStateProvider] check_build_state(
  provider : P,
  config_hash : String,
  cache_dir : String,
  load_manifest : (String) -> BuildManifest?,
) -> BuildStateCheck {
  let current_state = provider.get_content_state()
  match load_manifest(cache_dir) {
    Some(manifest) =>
      if manifest.matches(config_hash, current_state) {
        UpToDate(manifest.built_at)
      } else {
        NeedsRebuild
      }
    None => NoPreviousBuild
  }
}

// =============================================================================
// Build Manifest (moved from astra/cache for sharing)
// =============================================================================

///|
/// Build manifest stored in cache directory
pub(all) struct BuildManifest {
  /// Version of the build tool
  tool_version : String
  /// Hash of the configuration
  config_hash : String
  /// State from the provider (hash, timestamp, etc.)
  content_state : String
  /// ISO 8601 timestamp of the build
  built_at : String
}

///|
/// Create a new build manifest
pub fn BuildManifest::new(
  tool_version~ : String,
  config_hash~ : String,
  content_state~ : String,
  built_at~ : String,
) -> BuildManifest {
  { tool_version, config_hash, content_state, built_at }
}

///|
/// Check if manifest matches current state
pub fn BuildManifest::matches(
  self : BuildManifest,
  current_config_hash : String,
  current_content_state : String,
) -> Bool {
  self.config_hash == current_config_hash &&
  self.content_state == current_content_state
}

///|
/// Serialize manifest to JSON
pub fn BuildManifest::to_json(self : BuildManifest) -> String {
  let buf = StringBuilder::new()
  buf.write_string("{\n")
  buf.write_string("  \"tool_version\": \"")
  buf.write_string(escape_json(self.tool_version))
  buf.write_string("\",\n")
  buf.write_string("  \"config_hash\": \"")
  buf.write_string(escape_json(self.config_hash))
  buf.write_string("\",\n")
  buf.write_string("  \"content_state\": \"")
  buf.write_string(escape_json(self.content_state))
  buf.write_string("\",\n")
  buf.write_string("  \"built_at\": \"")
  buf.write_string(escape_json(self.built_at))
  buf.write_string("\"\n")
  buf.write_string("}")
  buf.to_string()
}

///|
/// Parse manifest from JSON
pub fn BuildManifest::from_json(json : String) -> BuildManifest? {
  let tool_version = extract_json_value(json, "tool_version")
  let config_hash = extract_json_value(json, "config_hash")
  let content_state = extract_json_value(json, "content_state")
  let built_at = extract_json_value(json, "built_at")
  match (tool_version, config_hash, content_state, built_at) {
    (Some(v), Some(c), Some(s), Some(b)) =>
      Some({ tool_version: v, config_hash: c, content_state: s, built_at: b })
    _ => None
  }
}

// =============================================================================
// JSON Helpers
// =============================================================================

///|
fn escape_json(s : String) -> String {
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

///|
fn extract_json_value(json : String, key : String) -> String? {
  let pattern = "\"" + key + "\": \""
  let start_idx = find_pattern(json, pattern)
  guard start_idx >= 0 else { return None }
  let value_start = start_idx + pattern.length()
  let remaining = json[value_start:].to_string() catch { _ => return None }
  let end_idx = find_pattern(remaining, "\"")
  guard end_idx >= 0 else { return None }
  Some(remaining[:end_idx].to_string() catch { _ => return None })
}

///|
fn find_pattern(haystack : String, needle : String) -> Int {
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
