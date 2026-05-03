// ISR Edge Cases Tests
//
// Tests for edge cases, boundary conditions, and error handling

// =============================================================================
// Cache Key Generation Tests
// =============================================================================

///|
test "cache_key: simple path without query" {
  let key = cache_key("/blog/", [])
  assert_eq(key, "isr:/blog/")
}

///|
test "cache_key: path with single query param" {
  let key = cache_key("/api/", [("id", "123")])
  assert_eq(key, "isr:/api/?id=123")
}

///|
test "cache_key: path with multiple query params sorted" {
  // Query params should be sorted alphabetically
  let key = cache_key("/search/", [
    ("z", "last"),
    ("a", "first"),
    ("m", "middle"),
  ])
  assert_eq(key, "isr:/search/?a=first&m=middle&z=last")
}

///|
test "cache_key: empty path" {
  let key = cache_key("", [])
  assert_eq(key, "isr:")
}

///|
test "cache_key: root path" {
  let key = cache_key("/", [])
  assert_eq(key, "isr:/")
}

///|
test "cache_key: path with special characters" {
  let key = cache_key("/blog/post-with-dashes/", [])
  assert_eq(key, "isr:/blog/post-with-dashes/")
}

///|
test "cache_key: duplicate query param keys" {
  // Multiple params with same key - all should be included
  let key = cache_key("/filter/", [("tag", "a"), ("tag", "b")])
  // After sorting, both should appear
  assert_true(key.contains("tag=a"))
  assert_true(key.contains("tag=b"))
}

// =============================================================================
// TTL Boundary Tests
// =============================================================================

///|
test "TTL boundary: exactly at expiry time" {
  let base_time = 1000000000L
  let ttl = 60 // 60 seconds
  let entry = CacheEntry::new("<html>test</html>", base_time, ttl)
  let cache = MemoryCache::new()
  ISRCache::put(cache, "test", entry)

  // Exactly at TTL boundary (60s = 60000ms)
  let at_boundary = base_time + 60000L
  let status = check_status(ISRCache::get(cache, "test"), at_boundary)
  match status {
    Stale => () // At boundary should be Stale (>= check)
    _ => fail("At TTL boundary should be Stale")
  }
}

///|
test "TTL boundary: 1ms before expiry" {
  let base_time = 1000000000L
  let ttl = 60
  let entry = CacheEntry::new("<html>test</html>", base_time, ttl)
  let cache = MemoryCache::new()
  ISRCache::put(cache, "test", entry)

  // 1ms before TTL
  let before_boundary = base_time + 59999L
  let status = check_status(ISRCache::get(cache, "test"), before_boundary)
  match status {
    Fresh => ()
    _ => fail("1ms before TTL should be Fresh")
  }
}

///|
test "TTL boundary: 1ms after expiry" {
  let base_time = 1000000000L
  let ttl = 60
  let entry = CacheEntry::new("<html>test</html>", base_time, ttl)
  let cache = MemoryCache::new()
  ISRCache::put(cache, "test", entry)

  // 1ms after TTL
  let after_boundary = base_time + 60001L
  let status = check_status(ISRCache::get(cache, "test"), after_boundary)
  match status {
    Stale => ()
    _ => fail("1ms after TTL should be Stale")
  }
}

///|
test "TTL boundary: zero TTL is immediately stale" {
  let base_time = 1000000000L
  let entry = CacheEntry::new("<html>test</html>", base_time, 0)
  let cache = MemoryCache::new()
  ISRCache::put(cache, "test", entry)

  // Even 1ms later should be Stale
  let status = check_status(ISRCache::get(cache, "test"), base_time + 1L)
  match status {
    Stale => ()
    _ => fail("Zero TTL should be immediately Stale")
  }
}

///|
test "TTL boundary: very large TTL" {
  let base_time = 1000000000L
  let ttl = 86400 // 24 hours in seconds
  let entry = CacheEntry::new("<html>test</html>", base_time, ttl)
  let cache = MemoryCache::new()
  ISRCache::put(cache, "test", entry)

  // After 23 hours (still within TTL)
  let after_23h = base_time + 82800000L // 23 hours in ms
  let status = check_status(ISRCache::get(cache, "test"), after_23h)
  match status {
    Fresh => ()
    _ => fail("Should be Fresh within 24h TTL")
  }
}

// =============================================================================
// Cache State Transition Tests
// =============================================================================

///|
test "cache state: Miss → Fresh after put" {
  let cache = MemoryCache::new()
  let base_time = 1000000000L

  // Initially Miss
  let status1 = check_status(ISRCache::get(cache, "key"), base_time)
  match status1 {
    Miss => ()
    _ => fail("Should be Miss initially")
  }

  // Add entry
  let entry = CacheEntry::new("<html>new</html>", base_time, 60)
  ISRCache::put(cache, "key", entry)

  // Now Fresh
  let status2 = check_status(ISRCache::get(cache, "key"), base_time + 1000L)
  match status2 {
    Fresh => ()
    _ => fail("Should be Fresh after put")
  }
}

///|
test "cache state: Fresh → Stale over time" {
  let cache = MemoryCache::new()
  let base_time = 1000000000L
  let entry = CacheEntry::new("<html>content</html>", base_time, 60)
  ISRCache::put(cache, "key", entry)

  // Fresh at 30s
  let status1 = check_status(ISRCache::get(cache, "key"), base_time + 30000L)
  match status1 {
    Fresh => ()
    _ => fail("Should be Fresh at 30s")
  }

  // Stale at 90s
  let status2 = check_status(ISRCache::get(cache, "key"), base_time + 90000L)
  match status2 {
    Stale => ()
    _ => fail("Should be Stale at 90s")
  }
}

///|
test "cache state: Stale → Fresh after update" {
  let cache = MemoryCache::new()
  let base_time = 1000000000L
  let entry = CacheEntry::new("<html>old</html>", base_time, 60)
  ISRCache::put(cache, "key", entry)

  // Stale at 90s
  let check_time = base_time + 90000L
  let status1 = check_status(ISRCache::get(cache, "key"), check_time)
  match status1 {
    Stale => ()
    _ => fail("Should be Stale at 90s")
  }

  // Update with new timestamp
  let new_entry = CacheEntry::new("<html>new</html>", check_time, 60)
  ISRCache::put(cache, "key", new_entry)

  // Now Fresh again
  let status2 = check_status(ISRCache::get(cache, "key"), check_time + 1000L)
  match status2 {
    Fresh => ()
    _ => fail("Should be Fresh after update")
  }
}

///|
test "cache state: delete makes entry Miss" {
  let cache = MemoryCache::new()
  let base_time = 1000000000L
  let entry = CacheEntry::new("<html>content</html>", base_time, 60)
  ISRCache::put(cache, "key", entry)

  // Exists
  assert_true(ISRCache::get(cache, "key") is Some(_))

  // Delete
  ISRCache::delete(cache, "key")

  // Now Miss
  let status = check_status(ISRCache::get(cache, "key"), base_time)
  match status {
    Miss => ()
    _ => fail("Should be Miss after delete")
  }
}

// =============================================================================
// Manifest Edge Cases
// =============================================================================

///|
test "manifest: empty pages map" {
  let manifest = ISRManifest::empty()
  assert_false(manifest.is_isr_page("/any/"))
  assert_true(manifest.get_page("/any/") is None)
}

///|
test "manifest: path not found" {
  let pages : Map[String, ISRPageMeta] = {}
  pages["/exists/"] = ISRPageMeta::{
    revalidate: 60,
    renderer: "markdown",
    source: "",
  }
  let manifest = ISRManifest::{ version: 1, pages }
  assert_true(manifest.is_isr_page("/exists/"))
  assert_false(manifest.is_isr_page("/not-exists/"))
}

///|
test "manifest: trailing slash matters" {
  let pages : Map[String, ISRPageMeta] = {}
  pages["/blog/"] = ISRPageMeta::{
    revalidate: 60,
    renderer: "markdown",
    source: "",
  }
  let manifest = ISRManifest::{ version: 1, pages }

  // With trailing slash - found
  assert_true(manifest.is_isr_page("/blog/"))

  // Without trailing slash - NOT found (different key)
  assert_false(manifest.is_isr_page("/blog"))
}

///|
test "manifest: case sensitive paths" {
  let pages : Map[String, ISRPageMeta] = {}
  pages["/Blog/"] = ISRPageMeta::{
    revalidate: 60,
    renderer: "markdown",
    source: "",
  }
  let manifest = ISRManifest::{ version: 1, pages }
  assert_true(manifest.is_isr_page("/Blog/"))
  assert_false(manifest.is_isr_page("/blog/"))
  assert_false(manifest.is_isr_page("/BLOG/"))
}

// =============================================================================
// Handler Edge Cases
// =============================================================================

///|
async test "handler: non-ISR page returns None" {
  let cache = MemoryCache::new()
  let pages : Map[String, ISRPageMeta] = {}
  pages["/isr-page/"] = ISRPageMeta::{
    revalidate: 60,
    renderer: "markdown",
    source: "",
  }
  let manifest = ISRManifest::{ version: 1, pages }
  let handler = ISRHandler::{ cache, manifest, dist_dir: "/nonexistent" }
  let (html, needs_revalidation) = handler.handle("/static-page/")
  assert_true(html is None)
  assert_false(needs_revalidation)
}

///|
test "handler: update_cache preserves TTL from manifest" {
  let cache = MemoryCache::new()
  let pages : Map[String, ISRPageMeta] = {}
  pages["/test/"] = ISRPageMeta::{
    revalidate: 120,
    renderer: "markdown",
    source: "",
  }
  let manifest = ISRManifest::{ version: 1, pages }
  let handler = ISRHandler::{ cache, manifest, dist_dir: "/nonexistent" }

  // Update cache
  handler.update_cache("/test/", "<html>content</html>")

  // Verify TTL matches manifest
  let key = cache_key("/test/", [])
  match ISRCache::get(cache, key) {
    Some(e) => assert_eq(e.revalidate, 120)
    None => fail("Entry should exist")
  }
}

///|
test "handler: update_cache for non-ISR page does nothing" {
  let cache = MemoryCache::new()
  let manifest = ISRManifest::empty()
  let handler = ISRHandler::{ cache, manifest, dist_dir: "/nonexistent" }

  // Try to update non-ISR page
  handler.update_cache("/not-isr/", "<html>content</html>")

  // Should not be in cache
  let key = cache_key("/not-isr/", [])
  assert_true(ISRCache::get(cache, key) is None)
}

// =============================================================================
// Concurrent Access Simulation
// =============================================================================

///|
test "concurrent: multiple reads don't interfere" {
  let cache = MemoryCache::new()
  let base_time = 1000000000L

  // Create 100 entries
  for i = 0; i < 100; i = i + 1 {
    let key = "isr:/page/" + i.to_string() + "/"
    let entry = CacheEntry::new(
      "<html>" + i.to_string() + "</html>",
      base_time,
      60,
    )
    ISRCache::put(cache, key, entry)
  }

  // Read all entries multiple times
  for round = 0; round < 5; round = round + 1 {
    for i = 0; i < 100; i = i + 1 {
      let key = "isr:/page/" + i.to_string() + "/"
      match ISRCache::get(cache, key) {
        Some(e) => assert_eq(e.html, "<html>" + i.to_string() + "</html>")
        None =>
          fail(
            "Entry " + i.to_string() + " missing on round " + round.to_string(),
          )
      }
    }
  }
}

///|
test "concurrent: interleaved reads and writes" {
  let cache = MemoryCache::new()
  let base_time = 1000000000L

  // Simulate interleaved operations
  for i = 0; i < 50; i = i + 1 {
    let key = "isr:/interleaved/"

    // Write
    let entry = CacheEntry::new(
      "<html>v" + i.to_string() + "</html>",
      base_time + i.to_int64() * 1000L,
      60,
    )
    ISRCache::put(cache, key, entry)

    // Read and verify
    match ISRCache::get(cache, key) {
      Some(e) => assert_eq(e.html, "<html>v" + i.to_string() + "</html>")
      None => fail("Entry missing after write " + i.to_string())
    }
  }
}

// =============================================================================
// Memory and Scale Tests
// =============================================================================

///|
test "scale: 1000 entries with varied TTLs" {
  let cache = MemoryCache::new()
  let base_time = 1000000000L

  // Create entries with varied TTLs
  for i = 0; i < 1000; i = i + 1 {
    let key = "isr:/varied/" + i.to_string() + "/"
    let ttl = 60 + i % 240 // TTL 60-299s
    let entry = CacheEntry::new(
      "<html>" + i.to_string() + "</html>",
      base_time,
      ttl,
    )
    ISRCache::put(cache, key, entry)
  }

  // Check at 120s - some should be Fresh, some Stale
  let check_time = base_time + 120000L
  let mut fresh_count = 0
  let mut stale_count = 0
  for i = 0; i < 1000; i = i + 1 {
    let key = "isr:/varied/" + i.to_string() + "/"
    let status = check_status(ISRCache::get(cache, key), check_time)
    match status {
      Fresh => fresh_count = fresh_count + 1
      Stale => stale_count = stale_count + 1
      Miss => fail("Entry " + i.to_string() + " should exist")
    }
  }

  // TTL 60-119 (60 values) → Stale at 120s = 250 entries per 240 cycle, 4.16 cycles = ~250
  // TTL 120-299 (180 values) → Fresh at 120s = 750 entries
  // Actually: 1000 entries / 240 TTL range = 4.16 cycles
  // Per cycle: TTL 60-119 (60 entries stale), TTL 120-299 (180 entries fresh)
  // Total: 4 full cycles = 240 stale, 720 fresh + partial
  assert_true(fresh_count > 700)
  assert_true(stale_count > 200)
  assert_eq(fresh_count + stale_count, 1000)
}

///|
test "scale: rapid updates to same key" {
  let cache = MemoryCache::new()
  let base_time = 1000000000L
  let key = "isr:/rapid/"

  // 1000 rapid updates
  for i = 0; i < 1000; i = i + 1 {
    let entry = CacheEntry::new(
      "<html>v" + i.to_string() + "</html>",
      base_time + i.to_int64(),
      60,
    )
    ISRCache::put(cache, key, entry)
  }

  // Should have last value
  match ISRCache::get(cache, key) {
    Some(e) => assert_eq(e.html, "<html>v999</html>")
    None => fail("Entry should exist")
  }
}
