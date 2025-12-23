///|
/// FileCache - Disk cache layer for build artifacts
///
/// Provides mtime-based caching to avoid re-reading unchanged files.
/// Used by both Sol and Astra build systems.

///|
/// Cache entry metadata
pub(all) struct CacheEntry {
  /// File modification time when cached
  mtime_ms : Double
  /// Timestamp when this entry was cached
  cached_at : Double
} derive(Eq, Show)

///|
/// File cache with mtime-based invalidation
pub struct FileCache {
  /// Path -> CacheEntry mapping
  entries : Map[String, CacheEntry]
  /// Path -> Content mapping (in-memory cache)
  contents : Map[String, String]
}

///|
/// Create a new empty file cache
pub fn FileCache::new() -> FileCache {
  { entries: {}, contents: {} }
}

///|
/// Check if a cached file is stale (mtime changed)
pub fn[FS : @env.FileSystem] FileCache::is_stale(
  self : FileCache,
  fs : FS,
  path : String,
) -> Bool {
  match self.entries.get(path) {
    None => true // Not cached
    Some(entry) =>
      // Check if file still exists and mtime matches
      if not(fs.exists_sync(path)) {
        true
      } else {
        let stat = fs.stat_sync(path) catch { _ => return true }
        stat.mtime_ms.to_double() != entry.mtime_ms
      }
  }
}

///|
/// Read file with caching
/// Returns cached content if file unchanged, otherwise reads and caches
pub fn[FS : @env.FileSystem] FileCache::read_file(
  self : FileCache,
  fs : FS,
  path : String,
) -> String raise Error {
  // Check if we have a valid cache entry
  if not(self.is_stale(fs, path)) {
    match self.contents.get(path) {
      Some(content) => return content
      None => () // Cache entry exists but content not loaded
    }
  }

  // Read file and update cache
  let content = fs.read_file_sync(path)
  let stat = fs.stat_sync(path)
  let now = current_time_ms()
  self.entries[path] = { mtime_ms: stat.mtime_ms.to_double(), cached_at: now }
  self.contents[path] = content
  content
}

///|
/// Clear all cache entries
pub fn FileCache::clear(self : FileCache) -> Unit {
  self.entries.clear()
  self.contents.clear()
}

///|
/// Remove a specific entry from cache
pub fn FileCache::invalidate(self : FileCache, path : String) -> Unit {
  self.entries.remove(path) |> ignore
  self.contents.remove(path) |> ignore
}

///|
/// Get number of cached entries
pub fn FileCache::len(self : FileCache) -> Int {
  self.entries.length()
}

///|
/// Persist cache metadata to disk (JSON format)
/// Only persists entry metadata, not file contents
pub fn[FS : @env.FileSystem] FileCache::persist(
  self : FileCache,
  fs : FS,
  cache_path : String,
) -> Unit raise Error {
  let json = self.to_json()
  let content = json.stringify()

  // Ensure parent directory exists
  let parent = dirname(cache_path)
  if not(parent.is_empty()) && not(fs.exists_sync(parent)) {
    fs.mkdir_sync(parent, true)
  }
  fs.write_file_sync(cache_path, content)
}

///|
/// Restore cache metadata from disk
pub fn[FS : @env.FileSystem] FileCache::restore(
  self : FileCache,
  fs : FS,
  cache_path : String,
) -> Unit raise Error {
  if not(fs.exists_sync(cache_path)) {
    return
  }
  let content = fs.read_file_sync(cache_path)
  let json : Json = @json.parse(content) catch { _ => return }
  self.from_json(json)
}

///|
/// Convert cache to JSON
fn FileCache::to_json(self : FileCache) -> Json {
  let entries_obj : Map[String, Json] = {}
  for entry in self.entries {
    let path = entry.0
    let cache_entry = entry.1
    entries_obj[path] = {
      "mtime_ms": cache_entry.mtime_ms.to_json(),
      "cached_at": cache_entry.cached_at.to_json(),
    }
  }
  { "version": 1, "entries": entries_obj.to_json() }
}

///|
/// Restore cache from JSON
fn FileCache::from_json(self : FileCache, json : Json) -> Unit {
  self.entries.clear()
  self.contents.clear()
  match json {
    { "entries": Object(entries), .. } =>
      for entry in entries {
        let path = entry.0
        let obj = entry.1
        match obj {
          {
            "mtime_ms": Number(mtime, ..),
            "cached_at": Number(cached_at, ..),
            ..
          } => self.entries[path] = { mtime_ms: mtime, cached_at }
          _ => ()
        }
      }
    _ => ()
  }
}

// ============================================================
// Helper functions
// ============================================================

///|
/// Get current time in milliseconds
fn current_time_ms() -> Double {
  ffi_date_now()
}

///|
extern "js" fn ffi_date_now() -> Double =
  #| () => Date.now()

///|
/// Get directory name from path
fn dirname(path : String) -> String {
  let chars = path.to_array()
  let mut last_sep = -1
  for i, c in chars {
    if c == '/' {
      last_sep = i
    }
  }
  if last_sep < 0 {
    ""
  } else if last_sep == 0 {
    "/"
  } else {
    String::from_array(chars[0:last_sep])
  }
}
