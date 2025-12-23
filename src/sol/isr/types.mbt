// Sol ISR (Incremental Static Regeneration) Types
//
// Provides trait-based cache abstraction for ISR implementation.
// Supports multiple backends: MemoryCache (dev), KVCache (production).

// ============================================================================
// Cache Entry
// ============================================================================

///|
/// ISR cache entry containing rendered HTML and metadata
pub struct CacheEntry {
  /// Rendered HTML content
  html : String
  /// Generation timestamp (Unix timestamp in milliseconds)
  generated_at : Int64
  /// Revalidation interval in seconds
  revalidate : Int
}

///|
/// Create a new cache entry
pub fn CacheEntry::new(
  html : String,
  generated_at : Int64,
  revalidate : Int,
) -> CacheEntry {
  { html, generated_at, revalidate }
}

// ============================================================================
// Cache Status
// ============================================================================

///|
/// Cache status for SWR (Stale-While-Revalidate) pattern
pub enum CacheStatus {
  /// Cache is fresh, serve directly
  Fresh
  /// Cache is stale, serve and revalidate in background
  Stale
  /// Cache miss, generate and cache
  Miss
}

// ============================================================================
// ISRCache Trait
// ============================================================================

///|
/// ISR cache storage abstraction
/// Implement this trait for different backends (Memory, KV, Redis, etc.)
pub(open) trait ISRCache {
  /// Get cache entry by key
  get(Self, String) -> CacheEntry?

  /// Put cache entry
  put(Self, String, CacheEntry) -> Unit

  /// Delete cache entry
  delete(Self, String) -> Unit

  /// Schedule background task for SWR revalidation
  /// In memory: executes immediately
  /// In Workers: uses waitUntil for background execution
  schedule_revalidation(Self, async () -> Unit) -> Unit
}

// ============================================================================
// ISR Config
// ============================================================================

///|
/// ISR configuration
pub struct ISRConfig {
  /// Enable ISR
  enabled : Bool
  /// Default revalidation interval in seconds
  default_revalidate : Int
}

///|
/// Default ISR configuration
pub fn ISRConfig::default() -> ISRConfig {
  { enabled: true, default_revalidate: 60 }
}
