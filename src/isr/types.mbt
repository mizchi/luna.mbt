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

// ============================================================================
// Cache Strategy (CDN + App layer)
// ============================================================================

///|
/// CDN cache strategy for ISR pages.
/// Controls how CDN-level caching (e.g., Cloudflare async SWR) interacts
/// with app-level ISR caching.
pub(all) enum CDNCacheStrategy {
  /// CDN handles SWR entirely via Cache-Control headers.
  /// App-level ISR is bypassed. Simplest option.
  /// Sets: `Cache-Control: s-maxage={revalidate}, stale-while-revalidate={grace}`
  CdnSwr(Int) // grace period in seconds
  /// Two-layer cache: CDN with short TTL + app-level ISR with longer TTL.
  /// CDN miss falls through to app ISR which serves from KV/memory.
  /// Sets: `Cache-Control: s-maxage={cdn_ttl}, stale-while-revalidate={cdn_grace}`
  Hybrid(Int, Int) // cdn_ttl, cdn_grace
  /// App-level ISR only. CDN caching disabled (`private, no-store`).
  /// All requests reach the app. Full control over cache invalidation.
  AppIsr
}

///|
/// Generate Cache-Control header value for a given strategy and revalidate interval.
pub fn CDNCacheStrategy::cache_control(
  self : CDNCacheStrategy,
  revalidate : Int,
) -> String {
  match self {
    CdnSwr(grace) =>
      "s-maxage=" + revalidate.to_string() + ", stale-while-revalidate=" + grace.to_string()
    Hybrid(cdn_ttl, cdn_grace) =>
      "s-maxage=" + cdn_ttl.to_string() + ", stale-while-revalidate=" + cdn_grace.to_string()
    AppIsr => "private, no-store"
  }
}

///|
/// Get the X-Sol-CDN-Cache header value describing this strategy.
pub fn CDNCacheStrategy::header_value(self : CDNCacheStrategy) -> String {
  match self {
    CdnSwr(_) => "cdn-swr"
    Hybrid(_, _) => "hybrid"
    AppIsr => "app-isr"
  }
}
