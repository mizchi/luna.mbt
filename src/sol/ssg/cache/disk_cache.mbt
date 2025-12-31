// Disk Cache
//
// Generic disk-based cache that uses FileSystem trait.
// Can be used with any FileSystem implementation (Node.js fs, memfs, etc.)

// =============================================================================
// Disk Cache
// =============================================================================

///|
/// Disk-based cache using FileSystem trait
pub(all) struct DiskCache[F] {
  /// Underlying filesystem
  fs : F
  /// Cache directory path
  cache_dir : String
  /// Cache metadata
  meta : CacheMeta
  /// Whether cache is enabled
  enabled : Bool
}

///|
/// Create a new disk cache
pub fn[F : @env.FileSystem] DiskCache::new(
  fs : F,
  cache_dir~ : String,
  config_hash? : String = "",
  enabled? : Bool = true,
) -> DiskCache[F] {
  let meta = if enabled {
    load_cache_meta(fs, cache_dir, config_hash)
  } else {
    CacheMeta::new(config_hash~)
  }
  { fs, cache_dir, meta, enabled }
}

///|
/// Get cached value by key
pub fn[F : @env.FileSystem] DiskCache::get(
  self : DiskCache[F],
  key : String,
) -> CacheStatus {
  if not(self.enabled) {
    return Miss
  }

  // Check if entry exists in metadata
  let entry_meta = match self.meta.entries.get(key) {
    Some(m) => m
    None => return Miss
  }

  // Check TTL if set
  // TODO: Add actual time check when time utilities are available
  let _ = entry_meta.ttl

  // Try to read cached content
  let cache_file = cache_file_path(self.cache_dir, entry_meta.content_hash)
  let content : String = self.fs.read_file_sync(cache_file) catch {
    _ => return Miss
  }
  Hit(content)
}

///|
/// Get cached value with content hash validation
pub fn[F : @env.FileSystem] DiskCache::get_with_hash(
  self : DiskCache[F],
  key : String,
  content_hash : String,
) -> CacheStatus {
  if not(self.enabled) {
    return Miss
  }

  // Check if entry exists in metadata
  let entry_meta = match self.meta.entries.get(key) {
    Some(m) => m
    None => return Miss
  }

  // Check if content hash matches
  if entry_meta.content_hash != content_hash {
    return Miss
  }

  // Try to read cached content
  let cache_file = cache_file_path(self.cache_dir, content_hash)
  let content : String = self.fs.read_file_sync(cache_file) catch {
    _ => return Miss
  }
  Hit(content)
}

///|
/// Set cached value
pub fn[F : @env.FileSystem] DiskCache::set(
  self : DiskCache[F],
  key : String,
  content_hash : String,
  value : String,
  ttl? : Int = 0,
) -> Unit {
  if not(self.enabled) {
    return
  }

  // Ensure cache directory exists
  ensure_cache_dir(self.fs, self.cache_dir)

  // Write cache file
  let cache_file = cache_file_path(self.cache_dir, content_hash)
  self.fs.write_file_sync(cache_file, value) catch {
    _ => return
  }

  // Update metadata
  let now = "" // TODO: get current timestamp
  self.meta.entries[key] = EntryMeta::{ content_hash, cached_at: now, ttl }
}

///|
/// Remove cached entry
pub fn[F : @env.FileSystem] DiskCache::remove(
  self : DiskCache[F],
  key : String,
) -> Unit {
  if not(self.enabled) {
    return
  }

  // Get entry metadata
  let entry_meta = match self.meta.entries.get(key) {
    Some(m) => m
    None => return
  }

  // Remove cache file
  let cache_file = cache_file_path(self.cache_dir, entry_meta.content_hash)
  self.fs.unlink_sync(cache_file) catch {
    _ => ()
  }

  // Remove from metadata
  self.meta.entries.remove(key)
}

///|
/// Clear all cache
pub fn[F : @env.FileSystem] DiskCache::clear(self : DiskCache[F]) -> Unit {
  if not(self.enabled) {
    return
  }

  // Remove cache directory
  self.fs.rmdir_sync(self.cache_dir, true) catch {
    _ => ()
  }

  // Clear metadata
  self.meta.entries.clear()
}

///|
/// Save cache metadata to disk
pub fn[F : @env.FileSystem] DiskCache::save(self : DiskCache[F]) -> Unit {
  if not(self.enabled) {
    return
  }
  ensure_cache_dir(self.fs, self.cache_dir)

  // Build JSON
  let json = serialize_cache_meta(self.meta)
  let meta_path = self.cache_dir + "/meta.json"
  self.fs.write_file_sync(meta_path, json) catch {
    _ => ()
  }
}

///|
/// Get cache statistics
pub fn[F : @env.FileSystem] DiskCache::stats(self : DiskCache[F]) -> (Int, Int) {
  let _ = self.fs // Suppress unused warning
  (self.meta.entries.length(), 0)
}

// =============================================================================
// Helper Functions
// =============================================================================

///|
/// Load cache metadata from disk
fn[F : @env.FileSystem] load_cache_meta(
  fs : F,
  cache_dir : String,
  current_config_hash : String,
) -> CacheMeta {
  let meta_path = cache_dir + "/meta.json"

  // Try to read existing meta
  let content : String = fs.read_file_sync(meta_path) catch {
    _ => return CacheMeta::new(config_hash=current_config_hash)
  }

  // Parse JSON
  let json : Json = @json.parse(content) catch {
    _ => return CacheMeta::new(config_hash=current_config_hash)
  }

  // Extract fields
  let obj = match json {
    Object(o) => o
    _ => return CacheMeta::new(config_hash=current_config_hash)
  }

  // Check version
  let version = match obj.get("version") {
    Some(Number(n, ..)) => n.to_int()
    _ => 0
  }
  if version != cache_format_version {
    return CacheMeta::new(config_hash=current_config_hash)
  }

  // Check config hash
  let stored_config_hash = match obj.get("configHash") {
    Some(String(s)) => s
    _ => ""
  }
  if stored_config_hash != current_config_hash {
    return CacheMeta::new(config_hash=current_config_hash)
  }

  // Parse entries
  let entries : Map[String, EntryMeta] = {}
  match obj.get("entries") {
    Some(Object(entries_obj)) =>
      for key, entry_json in entries_obj {
        match parse_entry_meta(entry_json) {
          Some(entry) => entries[key] = entry
          None => ()
        }
      }
    _ => ()
  }
  CacheMeta::{
    version: cache_format_version,
    config_hash: current_config_hash,
    entries,
  }
}

///|
/// Parse entry metadata from JSON
fn parse_entry_meta(json : Json) -> EntryMeta? {
  let obj = match json {
    Object(o) => o
    _ => return None
  }
  let content_hash = match obj.get("contentHash") {
    Some(String(s)) => s
    _ => return None
  }
  let cached_at = match obj.get("cachedAt") {
    Some(String(s)) => s
    _ => ""
  }
  let ttl = match obj.get("ttl") {
    Some(Number(n, ..)) => n.to_int()
    _ => 0
  }
  Some(EntryMeta::{ content_hash, cached_at, ttl })
}

///|
/// Serialize cache metadata to JSON
fn serialize_cache_meta(meta : CacheMeta) -> String {
  let entries_json = StringBuilder::new()
  entries_json.write_string("{")
  let mut first = true
  for key, entry in meta.entries {
    if not(first) {
      entries_json.write_string(",")
    }
    first = false
    entries_json.write_string("\n    \"")
    entries_json.write_string(escape_json_string(key))
    entries_json.write_string("\": {\"contentHash\": \"")
    entries_json.write_string(entry.content_hash)
    entries_json.write_string("\", \"cachedAt\": \"")
    entries_json.write_string(entry.cached_at)
    entries_json.write_string("\", \"ttl\": ")
    entries_json.write_string(entry.ttl.to_string())
    entries_json.write_string("}")
  }
  entries_json.write_string("\n  }")
  "{\n  \"version\": " +
  meta.version.to_string() +
  ",\n  \"configHash\": \"" +
  meta.config_hash +
  "\",\n  \"entries\": " +
  entries_json.to_string() +
  "\n}\n"
}

///|
/// Escape JSON string
fn escape_json_string(s : String) -> String {
  let buf = StringBuilder::new()
  for c in s {
    if c == '\\' {
      buf.write_string("\\\\")
    } else if c == '"' {
      buf.write_string("\\\"")
    } else if c == '\n' {
      buf.write_string("\\n")
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
/// Get cache file path for a content hash
fn cache_file_path(cache_dir : String, content_hash : String) -> String {
  cache_dir + "/data/" + content_hash
}

///|
/// Ensure cache directory exists
fn[F : @env.FileSystem] ensure_cache_dir(fs : F, cache_dir : String) -> Unit {
  fs.mkdir_sync(cache_dir, true) catch {
    _ => ()
  }
  fs.mkdir_sync(cache_dir + "/data", true) catch {
    _ => ()
  }
}
