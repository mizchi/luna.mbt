// Sol ISR Handler Unit Tests
//
// Tests for ISR handler, cache state transitions, and revalidation timing.

// =============================================================================
// Helper Functions for Tests
// =============================================================================

///|
fn create_manifest(pages : Map[String, ISRPageMeta]) -> ISRManifest {
  ISRManifest::{ version: 1, pages }
}

///|
fn create_page_meta(
  revalidate : Int,
  renderer? : String = "markdown",
  source? : String = "",
) -> ISRPageMeta {
  ISRPageMeta::{ revalidate, renderer, source }
}

///|
fn create_handler(
  cache : MemoryCache,
  manifest : ISRManifest,
  dist_dir : String,
) -> ISRHandler[MemoryCache] {
  ISRHandler::{ cache, manifest, dist_dir }
}

// =============================================================================
// ISR Manifest Tests
// =============================================================================

///|
test "ISRManifest::empty creates empty manifest" {
  let manifest = ISRManifest::empty()
  assert_eq(manifest.version, 1)
  assert_true(manifest.pages.is_empty())
}

///|
test "ISRManifest::is_isr_page returns false for empty manifest" {
  let manifest = ISRManifest::empty()
  assert_false(manifest.is_isr_page("/"))
  assert_false(manifest.is_isr_page("/blog/"))
}

///|
test "ISRManifest::is_isr_page returns true for registered page" {
  let pages : Map[String, ISRPageMeta] = {}
  pages["/blog/post-1/"] = create_page_meta(60, source="blog/post-1.md")
  let manifest = create_manifest(pages)
  assert_true(manifest.is_isr_page("/blog/post-1/"))
  assert_false(manifest.is_isr_page("/blog/post-2/"))
}

///|
test "ISRManifest::get_page returns page meta" {
  let pages : Map[String, ISRPageMeta] = {}
  pages["/api/data/"] = create_page_meta(
    10,
    renderer="dynamic",
    source="api/data.ts",
  )
  let manifest = create_manifest(pages)
  match manifest.get_page("/api/data/") {
    Some(meta) => {
      assert_eq(meta.revalidate, 10)
      assert_eq(meta.renderer, "dynamic")
      assert_eq(meta.source, "api/data.ts")
    }
    None => fail("Expected Some(meta)")
  }
}

///|
test "ISRManifest::get_page returns None for non-ISR page" {
  let manifest = ISRManifest::empty()
  assert_true(manifest.get_page("/static-page/") is None)
}

// =============================================================================
// ISR Handler Cache State Tests
// =============================================================================

///|
async test "ISRHandler::handle returns (None, false) for non-ISR page" {
  let cache = MemoryCache::new()
  let manifest = ISRManifest::empty()
  let handler = create_handler(cache, manifest, "/tmp/dist")
  let (html, needs_revalidation) = handler.handle("/static-page/")
  assert_true(html is None)
  assert_false(needs_revalidation)
}

///|
test "MemoryCache Ref sharing works" {
  let cache = MemoryCache::new()
  let cache_copy = cache // Create a copy (should share the Ref)

  // Put via original cache
  let entry = CacheEntry::new("test", 1000000L, 60)
  ISRCache::put(cache, "key", entry)

  // Get via copy - should see the entry if Ref is shared
  match ISRCache::get(cache_copy, "key") {
    Some(e) => assert_eq(e.html, "test")
    None => fail("Ref sharing not working - cache_copy didn't see the entry")
  }
}

///|
test "ISRHandler cache sharing via Ref" {
  let cache = MemoryCache::new()
  let pages : Map[String, ISRPageMeta] = {}
  pages["/blog/"] = create_page_meta(60, source="blog/index.md")
  let manifest = create_manifest(pages)
  let handler = create_handler(cache, manifest, "/tmp/dist")

  // Put entry via original cache
  let entry = CacheEntry::new("<html>test</html>", 1000000L, 60)
  ISRCache::put(cache, "isr:/blog/", entry)

  // Verify handler.cache can see it
  match ISRCache::get(handler.cache, "isr:/blog/") {
    Some(e) => assert_eq(e.html, "<html>test</html>")
    None => fail("Handler cache didn't see the entry from original cache")
  }

  // Verify cache key matches what handler uses
  let key = cache_key("/blog/", [])
  assert_eq(key, "isr:/blog/")

  // Verify handler.cache.get works with handler's key
  match ISRCache::get(handler.cache, key) {
    Some(e) => assert_eq(e.html, "<html>test</html>")
    None => fail("Handler cache didn't find entry using cache_key")
  }
}

///|
test "ISRHandler handle flow debug" {
  let cache = MemoryCache::new()
  let pages : Map[String, ISRPageMeta] = {}
  pages["/blog/"] = create_page_meta(60, source="blog/index.md")
  let manifest = create_manifest(pages)
  let handler = create_handler(cache, manifest, "/tmp/dist")

  // Pre-populate cache with fresh entry
  let base_time = 1000000L
  let entry = CacheEntry::new("<html>cached</html>", base_time, 60)
  ISRCache::put(cache, "isr:/blog/", entry)

  // Step 1: Check manifest lookup
  match handler.manifest.get_page("/blog/") {
    Some(meta) => assert_eq(meta.revalidate, 60)
    None => fail("Manifest lookup failed")
  }

  // Step 2: Check cache key
  let key = cache_key("/blog/", [])
  assert_eq(key, "isr:/blog/")

  // Step 3: Check cache get via handler (explicit trait call)
  match ISRCache::get(handler.cache, key) {
    Some(e) => assert_eq(e.html, "<html>cached</html>")
    None => fail("Cache get via handler.cache failed")
  }

  // Step 4: Check cache get using dot notation (how handler does it)
  match handler.cache.get(key) {
    Some(e) => assert_eq(e.html, "<html>cached</html>")
    None =>
      fail(
        "Cache get via handler.cache.get() failed - this is how handler does it!",
      )
  }

  // Step 5: Check status - use fixed time for predictable result
  let check_time = base_time + 1000L // 1 second after cache entry was created
  let entry_opt = handler.cache.get(key)
  let status = check_status(entry_opt, check_time)
  match status {
    Fresh => ()
    Stale => fail("Expected Fresh but got Stale")
    Miss => fail("Expected Fresh but got Miss")
  }
}

///|
async test "ISRHandler with fresh cache returns cached content" {
  let cache = MemoryCache::new()
  let pages : Map[String, ISRPageMeta] = {}
  pages["/blog/"] = create_page_meta(60, source="blog/index.md")
  let manifest = create_manifest(pages)
  let handler = create_handler(cache, manifest, "/tmp/dist")

  // Pre-populate cache with far-future timestamp to ensure Fresh
  let far_future = now_ms() + 100000000L // Very far in future
  let entry = CacheEntry::new("<html>cached</html>", far_future, 60)
  ISRCache::put(cache, "isr:/blog/", entry)

  // Debug: verify cache content is accessible before calling handle
  let key = cache_key("/blog/", [])
  match ISRCache::get(cache, key) {
    Some(e) => assert_eq(e.html, "<html>cached</html>")
    None => fail("Cache was not populated correctly")
  }

  // Now call handle
  let (html, needs_revalidation) = handler.handle("/blog/")

  // Debug: Print what we got
  match (html, needs_revalidation) {
    (Some(_), false) => () // Expected for Fresh
    (Some(_), true) => fail("Got Stale (Some, true) - cache is stale?")
    (None, false) => fail("Got (None, false) - not an ISR page?")
    (None, true) =>
      fail(
        "Got Miss (None, true) - cache entry not found or static file missing",
      )
  }
}

///|
// Note: Testing handler with stale cache is challenging because handler.handle()
// uses now_ms() internally, and test environment timing may vary.
// The stale detection logic is tested via check_status in isr_wbtest.mbt.
// Here we test that Fresh cache works (via far-future timestamp) and
// rely on the check_status unit tests for stale behavior verification.
test "check_status correctly identifies stale entries" {
  // This tests the underlying stale detection logic
  let old_time = 1000000L // Some old timestamp
  let entry = CacheEntry::new("<html>stale</html>", old_time, 60)

  // Check at a time well past the TTL
  let check_time = old_time + 120000L // 120 seconds later, TTL is 60s
  let status = check_status(Some(entry), check_time)
  match status {
    Stale => ()
    Fresh => fail("Expected Stale but got Fresh")
    Miss => fail("Expected Stale but got Miss")
  }
}

// =============================================================================
// Cache State Transition Tests
// =============================================================================

///|
test "Cache Miss -> Fresh after first request" {
  let cache = MemoryCache::new()
  let key = "isr:/test/"

  // Initially: Miss
  assert_true(ISRCache::get(cache, key) is None)
  let status1 = check_status(ISRCache::get(cache, key), now_ms())
  match status1 {
    Miss => ()
    _ => fail("Expected Miss")
  }

  // After caching: Fresh
  let base_time = 1000000L
  let entry = CacheEntry::new("<html>content</html>", base_time, 60)
  ISRCache::put(cache, key, entry)
  let status2 = check_status(ISRCache::get(cache, key), base_time + 1000L)
  match status2 {
    Fresh => ()
    _ => fail("Expected Fresh after caching")
  }
}

///|
test "Fresh -> Stale after TTL expires" {
  let cache = MemoryCache::new()
  let key = "isr:/expiring/"

  // Cache with 60 second TTL
  let created_at = 1000000L
  let entry = CacheEntry::new("<html>will expire</html>", created_at, 60)
  ISRCache::put(cache, key, entry)

  // At creation time: Fresh
  let status1 = check_status(ISRCache::get(cache, key), created_at + 30000L) // 30s later
  match status1 {
    Fresh => ()
    _ => fail("Expected Fresh at 30s")
  }

  // After TTL: Stale
  let status2 = check_status(ISRCache::get(cache, key), created_at + 61000L) // 61s later
  match status2 {
    Stale => ()
    _ => fail("Expected Stale after TTL")
  }
}

///|
test "Stale -> Fresh after revalidation" {
  let cache = MemoryCache::new()
  let key = "isr:/revalidated/"

  // Start with stale entry
  let old_time = 1000000L
  let entry = CacheEntry::new("<html>old</html>", old_time, 60)
  ISRCache::put(cache, key, entry)

  // Verify stale at current time
  let now = old_time + 120000L // 2 minutes later
  let status1 = check_status(ISRCache::get(cache, key), now)
  match status1 {
    Stale => ()
    _ => fail("Expected Stale before revalidation")
  }

  // Revalidate: update cache with new entry
  let new_entry = CacheEntry::new("<html>fresh</html>", now, 60)
  ISRCache::put(cache, key, new_entry)

  // After revalidation: Fresh again
  let status2 = check_status(ISRCache::get(cache, key), now + 1000L) // 1s after revalidation
  match status2 {
    Fresh => ()
    _ => fail("Expected Fresh after revalidation")
  }

  // Verify content was updated
  match ISRCache::get(cache, key) {
    Some(e) => assert_eq(e.html, "<html>fresh</html>")
    None => fail("Expected entry")
  }
}

// =============================================================================
// Revalidation Timing Tests
// =============================================================================

///|
test "Different TTLs have different expiry times" {
  let cache = MemoryCache::new()
  let base_time = 1000000L

  // 10 second TTL
  let short_entry = CacheEntry::new("short", base_time, 10)
  ISRCache::put(cache, "isr:/short/", short_entry)

  // 300 second TTL (5 minutes)
  let long_entry = CacheEntry::new("long", base_time, 300)
  ISRCache::put(cache, "isr:/long/", long_entry)

  // At 15 seconds: short is stale, long is fresh
  let check_time = base_time + 15000L
  let short_status = check_status(
    ISRCache::get(cache, "isr:/short/"),
    check_time,
  )
  let long_status = check_status(ISRCache::get(cache, "isr:/long/"), check_time)
  match short_status {
    Stale => ()
    _ => fail("Short TTL should be stale at 15s")
  }
  match long_status {
    Fresh => ()
    _ => fail("Long TTL should still be fresh at 15s")
  }
}

///|
test "Zero TTL means always stale after creation" {
  let cache = MemoryCache::new()
  let created_at = 1000000L

  // Zero second TTL
  let entry = CacheEntry::new("instant-expire", created_at, 0)
  ISRCache::put(cache, "isr:/instant/", entry)

  // Immediately stale (even 1ms later)
  let status = check_status(
    ISRCache::get(cache, "isr:/instant/"),
    created_at + 1L,
  )
  match status {
    Stale => ()
    _ => fail("Zero TTL should be stale immediately")
  }
}

///|
test "Boundary: exactly at TTL expiry is Stale" {
  let cache = MemoryCache::new()
  let created_at = 0L
  let entry = CacheEntry::new("boundary", created_at, 60)
  ISRCache::put(cache, "isr:/boundary/", entry)

  // Exactly at 60 seconds (60000ms)
  let status = check_status(ISRCache::get(cache, "isr:/boundary/"), 60000L)
  match status {
    Stale => ()
    _ => fail("Exactly at TTL boundary should be Stale")
  }
}

///|
test "Boundary: 1ms before TTL expiry is Fresh" {
  let cache = MemoryCache::new()
  let created_at = 0L
  let entry = CacheEntry::new("boundary", created_at, 60)
  ISRCache::put(cache, "isr:/boundary/", entry)

  // 1ms before 60 seconds
  let status = check_status(ISRCache::get(cache, "isr:/boundary/"), 59999L)
  match status {
    Fresh => ()
    _ => fail("1ms before TTL should be Fresh")
  }
}

// =============================================================================
// ISRHandler::update_cache Tests
// =============================================================================

///|
test "update_cache refreshes entry with new timestamp" {
  let cache = MemoryCache::new()
  let pages : Map[String, ISRPageMeta] = {}
  pages["/page/"] = create_page_meta(60, source="page.md")
  let manifest = create_manifest(pages)
  let handler = create_handler(cache, manifest, "/tmp/dist")

  // Get current time before update
  let before_update = now_ms()

  // Initial old entry (shared via Ref)
  let old_time = before_update - 1000000L // 1000 seconds before now
  ISRCache::put(
    cache,
    "isr:/page/",
    CacheEntry::new("<html>old</html>", old_time, 60),
  )

  // Update cache - this should set a new timestamp using now_ms()
  handler.update_cache("/page/", "<html>new</html>")

  // Verify new entry (shared via Ref)
  match ISRCache::get(cache, "isr:/page/") {
    Some(e) => {
      assert_eq(e.html, "<html>new</html>")
      // New timestamp should be >= before_update (close to now)
      assert_true(e.generated_at >= before_update)
      assert_eq(e.revalidate, 60) // Same TTL from manifest
    }
    None => fail("Expected updated entry")
  }
}

///|
test "update_cache does nothing for non-ISR page" {
  let cache = MemoryCache::new()
  let manifest = ISRManifest::empty()
  let handler = create_handler(cache, manifest, "/tmp/dist")

  // Try to update non-ISR page
  handler.update_cache("/non-isr/", "<html>ignored</html>")

  // Should not be cached (shared via Ref)
  assert_true(ISRCache::get(cache, "isr:/non-isr/") is None)
}

// =============================================================================
// Manifest Parsing Tests
// =============================================================================

///|
test "parse_manifest handles valid JSON" {
  let json =
    #|{
    #|  "version": 1,
    #|  "pages": {
    #|    "/blog/": {"revalidate": 60, "renderer": "markdown", "source": "blog/index.md"}
    #|  }
    #|}
  let manifest = parse_manifest(json)
  assert_eq(manifest.version, 1)
  assert_true(manifest.is_isr_page("/blog/"))
  match manifest.get_page("/blog/") {
    Some(meta) => {
      assert_eq(meta.revalidate, 60)
      assert_eq(meta.renderer, "markdown")
    }
    None => fail("Expected page meta")
  }
}

///|
test "parse_manifest handles empty pages" {
  let json =
    #|{"version": 1, "pages": {}}
  let manifest = parse_manifest(json)
  assert_eq(manifest.version, 1)
  assert_true(manifest.pages.is_empty())
}

///|
test "parse_manifest handles invalid JSON" {
  let manifest = parse_manifest("not valid json")
  assert_eq(manifest.version, 1)
  assert_true(manifest.pages.is_empty())
}

///|
test "parse_manifest handles missing fields" {
  let json =
    #|{"pages": {"/test/": {"revalidate": 30}}}
  let manifest = parse_manifest(json)
  assert_eq(manifest.version, 1) // Default version
  match manifest.get_page("/test/") {
    Some(meta) => {
      assert_eq(meta.revalidate, 30)
      assert_eq(meta.renderer, "markdown") // Default renderer
      assert_eq(meta.source, "") // Default source
    }
    None => fail("Expected page meta")
  }
}
