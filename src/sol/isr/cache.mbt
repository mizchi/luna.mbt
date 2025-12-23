// Sol ISR Cache Utilities
//
// Provides cache key generation and status checking for ISR.

// ============================================================================
// Cache Key Generation
// ============================================================================

///|
/// Lexicographic string comparison (character by character)
/// MoonBit's String::compare sorts by length first, so we need this for alphabetical order
fn lexicographic_compare(a : String, b : String) -> Int {
  let len_a = a.length()
  let len_b = b.length()
  let min_len = if len_a < len_b { len_a } else { len_b }
  for i = 0; i < min_len; i = i + 1 {
    let char_a = a[i]
    let char_b = b[i]
    if char_a < char_b {
      return -1
    }
    if char_a > char_b {
      return 1
    }
  }
  // All compared characters are equal, shorter string comes first
  if len_a < len_b {
    -1
  } else if len_a > len_b {
    1
  } else {
    0
  }
}

///|
/// Generate cache key from path and query parameters
/// Key format: "isr:{path}?{sorted_query}"
pub fn cache_key(path : String, query : Array[(String, String)]) -> String {
  if query.is_empty() {
    return "isr:" + path
  }
  // Sort query parameters for consistent key generation (ascending alphabetical)
  let sorted = query.copy()
  sorted.sort_by(fn(a, b) { lexicographic_compare(a.0, b.0) })
  let query_str = sorted
    .iter()
    .map(fn(p) { p.0 + "=" + p.1 })
    .collect()
    .join("&")
  "isr:" + path + "?" + query_str
}

// ============================================================================
// Cache Status Checking
// ============================================================================

///|
/// Check cache status based on entry and current time
pub fn check_status(entry : CacheEntry?, now_ms : Int64) -> CacheStatus {
  match entry {
    None => Miss
    Some(e) => {
      let expires_at = e.generated_at + e.revalidate.to_int64() * 1000L
      if now_ms < expires_at {
        Fresh
      } else {
        Stale
      }
    }
  }
}

// ============================================================================
// Time Utilities
// ============================================================================

///|
/// Get current time in milliseconds (Unix timestamp)
pub fn now_ms() -> Int64 {
  ffi_now_ms()
}

///|
extern "js" fn ffi_now_ms() -> Int64 =
  #| () => BigInt(Date.now())
