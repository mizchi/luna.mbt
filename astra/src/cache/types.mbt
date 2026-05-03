// Disk Cache Types
//
// Generic types for disk-based caching.
// Can be used with any FileSystem implementation.

// =============================================================================
// Cache Entry
// =============================================================================

///|
/// Single cache entry
pub(all) struct CacheEntry {
  /// Hash of the source content
  key : String
  /// Cached content
  value : String
  /// When the entry was cached (ISO 8601)
  cached_at : String
  /// Optional TTL in seconds (0 = no expiration)
  ttl : Int
}

///|
/// Create a new cache entry
pub fn CacheEntry::new(
  key~ : String,
  value~ : String,
  cached_at? : String = "",
  ttl? : Int = 0,
) -> CacheEntry {
  { key, value, cached_at, ttl }
}

// =============================================================================
// Cache Metadata
// =============================================================================

///|
/// Cache metadata stored on disk
pub(all) struct CacheMeta {
  /// Cache format version
  version : Int
  /// Hash of configuration (invalidates cache if changed)
  config_hash : String
  /// Entry metadata (key -> entry info)
  entries : Map[String, EntryMeta]
}

///|
/// Metadata for a single entry
pub(all) struct EntryMeta {
  /// Hash of the content
  content_hash : String
  /// When cached
  cached_at : String
  /// TTL in seconds
  ttl : Int
}

///|
/// Current cache format version
pub let cache_format_version : Int = 1

///|
/// Create empty cache metadata
pub fn CacheMeta::new(config_hash? : String = "") -> CacheMeta {
  { version: cache_format_version, config_hash, entries: {} }
}

// =============================================================================
// Cache Status
// =============================================================================

///|
/// Cache lookup result
pub(all) enum CacheStatus {
  /// Cache hit with valid content
  Hit(String)
  /// Cache miss (not found)
  Miss
  /// Cache stale (found but expired)
  Stale(String)
  /// Cache invalid (config changed)
  Invalid
}

///|
/// Check if status is a hit
pub fn CacheStatus::is_hit(self : CacheStatus) -> Bool {
  match self {
    Hit(_) => true
    _ => false
  }
}

///|
/// Get value if hit or stale
pub fn CacheStatus::value(self : CacheStatus) -> String? {
  match self {
    Hit(v) => Some(v)
    Stale(v) => Some(v)
    _ => None
  }
}
