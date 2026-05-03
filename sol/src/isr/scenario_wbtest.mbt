// ISR Scenario Tests
//
// Tests ISR behavior under realistic scenarios like:
// - Large number of pages (50,000 blog posts)
// - Hot vs cold page access patterns
// - Stale-while-revalidate effectiveness

// =============================================================================
// Scenario: 50,000 Blog Posts with Hot/Cold Access Pattern
// =============================================================================

///|
/// Simulate a blog with many pages, some hot (frequently accessed),
/// most cold (rarely accessed)
test "Large blog scenario: hot pages stay fresh, cold pages go stale" {
  let cache = MemoryCache::new()

  // Simulate manifest with 1000 pages (scaled down from 50k for test speed)
  let pages : Map[String, ISRPageMeta] = {}
  let num_pages = 1000
  for i = 0; i < num_pages; i = i + 1 {
    let path = "/blog/post-" + i.to_string() + "/"
    // Vary TTL: popular posts get longer TTL
    let ttl = if i < 10 { 300 } else { 60 } // Top 10 get 5min, rest get 1min
    pages[path] = ISRPageMeta::{
      revalidate: ttl,
      renderer: "markdown",
      source: "",
    }
  }
  let manifest = ISRManifest::{ version: 1, pages }
  let _handler = ISRHandler::{ cache, manifest, dist_dir: "/tmp/dist" }

  // Base time for simulation
  let base_time = 1000000000L // ~Jan 1970 + 11 days

  // Populate cache for all pages at base_time
  for i = 0; i < num_pages; i = i + 1 {
    let path = "/blog/post-" + i.to_string() + "/"
    let key = cache_key(path, [])
    let ttl = if i < 10 { 300 } else { 60 }
    let entry = CacheEntry::new(
      "<html>Post " + i.to_string() + "</html>",
      base_time,
      ttl,
    )
    ISRCache::put(cache, key, entry)
  }

  // Simulate time passing: 90 seconds later
  let check_time = base_time + 90000L // 90 seconds

  // Hot pages (top 10) should still be Fresh (TTL=300s, only 90s passed)
  for i = 0; i < 10; i = i + 1 {
    let path = "/blog/post-" + i.to_string() + "/"
    let key = cache_key(path, [])
    let entry = ISRCache::get(cache, key)
    let status = check_status(entry, check_time)
    match status {
      Fresh => ()
      _ => fail("Hot page " + i.to_string() + " should be Fresh at 90s")
    }
  }

  // Cold pages (rest) should be Stale (TTL=60s, 90s passed)
  for i = 10; i < 20; i = i + 1 { // Check a sample
    let path = "/blog/post-" + i.to_string() + "/"
    let key = cache_key(path, [])
    let entry = ISRCache::get(cache, key)
    let status = check_status(entry, check_time)
    match status {
      Stale => ()
      _ => fail("Cold page " + i.to_string() + " should be Stale at 90s")
    }
  }
}

///|
/// Test that accessing a stale page returns content while signaling revalidation
test "Stale page serves content while signaling revalidation need" {
  let cache = MemoryCache::new()
  let pages : Map[String, ISRPageMeta] = {}
  pages["/blog/old-post/"] = ISRPageMeta::{
    revalidate: 60,
    renderer: "markdown",
    source: "",
  }
  let manifest = ISRManifest::{ version: 1, pages }
  let _handler = ISRHandler::{ cache, manifest, dist_dir: "/tmp/dist" }

  // Cache an entry that's definitely stale (generated long ago)
  let very_old_time = 1000L // Very old
  let entry = CacheEntry::new("<html>Old content</html>", very_old_time, 60)
  ISRCache::put(cache, "isr:/blog/old-post/", entry)

  // Access at a time much later (simulated via check_status)
  let now = 1000000000L // Much later
  let cached_entry = ISRCache::get(cache, "isr:/blog/old-post/")
  let status = check_status(cached_entry, now)

  // Should be Stale
  match status {
    Stale => ()
    _ => fail("Expected Stale status")
  }

  // Stale means: serve old content, but trigger background revalidation
  match cached_entry {
    Some(e) => assert_eq(e.html, "<html>Old content</html>")
    None => fail("Expected cached content")
  }
}

///|
/// Test cache memory efficiency with many entries
test "Cache handles many entries efficiently" {
  let cache = MemoryCache::new()

  // Add 10,000 entries
  let num_entries = 10000
  for i = 0; i < num_entries; i = i + 1 {
    let key = "isr:/page/" + i.to_string() + "/"
    let entry = CacheEntry::new(
      "<html>" + i.to_string() + "</html>",
      1000000L,
      60,
    )
    ISRCache::put(cache, key, entry)
  }

  // Verify random access works
  match ISRCache::get(cache, "isr:/page/5000/") {
    Some(e) => assert_eq(e.html, "<html>5000</html>")
    None => fail("Entry 5000 not found")
  }
  match ISRCache::get(cache, "isr:/page/9999/") {
    Some(e) => assert_eq(e.html, "<html>9999</html>")
    None => fail("Entry 9999 not found")
  }

  // Non-existent entry returns None
  assert_true(ISRCache::get(cache, "isr:/page/99999/") is None)
}

///|
/// Test revalidation updates cache correctly
test "Revalidation updates stale entry to fresh" {
  let cache = MemoryCache::new()
  let pages : Map[String, ISRPageMeta] = {}
  pages["/blog/updated/"] = ISRPageMeta::{
    revalidate: 60,
    renderer: "markdown",
    source: "",
  }
  let manifest = ISRManifest::{ version: 1, pages }
  let handler = ISRHandler::{ cache, manifest, dist_dir: "/tmp/dist" }

  // Initial stale entry
  let old_time = 1000000L
  ISRCache::put(
    cache,
    "isr:/blog/updated/",
    CacheEntry::new("<html>v1</html>", old_time, 60),
  )

  // Verify it's stale at current time
  let now = old_time + 120000L // 2 minutes later
  let status1 = check_status(ISRCache::get(cache, "isr:/blog/updated/"), now)
  match status1 {
    Stale => ()
    _ => fail("Should be Stale before update")
  }

  // Simulate revalidation: update cache with fresh content
  handler.update_cache("/blog/updated/", "<html>v2</html>")

  // Verify content was updated
  match ISRCache::get(cache, "isr:/blog/updated/") {
    Some(e) => {
      assert_eq(e.html, "<html>v2</html>")
      assert_eq(e.revalidate, 60)
    }
    None => fail("Expected updated entry")
  }
}

///|
/// Test hot page access pattern: frequently accessed pages stay fresh
test "Hot page access pattern keeps cache fresh" {
  let cache = MemoryCache::new()
  let pages : Map[String, ISRPageMeta] = {}
  pages["/blog/popular/"] = ISRPageMeta::{
    revalidate: 60,
    renderer: "markdown",
    source: "",
  }
  let manifest = ISRManifest::{ version: 1, pages }
  let _handler = ISRHandler::{ cache, manifest, dist_dir: "/tmp/dist" }
  let base_time = 1000000000L

  // Initial cache population
  ISRCache::put(
    cache,
    "isr:/blog/popular/",
    CacheEntry::new("<html>v1</html>", base_time, 60),
  )

  // Simulate 5 accesses, each 30 seconds apart, with revalidation
  for access = 0; access < 5; access = access + 1 {
    let access_time = base_time + access.to_int64() * 30000L // Every 30 seconds
    let entry = ISRCache::get(cache, "isr:/blog/popular/")
    let status = check_status(entry, access_time)

    // Since we're accessing every 30s and TTL is 60s, should always be Fresh
    // (assuming we revalidate at the 50s mark which we simulate here)
    if access_time - base_time < 60000L {
      match status {
        Fresh => ()
        _ => fail("Should be Fresh at access " + access.to_string())
      }
    }

    // Simulate revalidation refreshing the cache
    if access == 2 {
      // At 60s mark, simulate background revalidation
      let new_entry = CacheEntry::new("<html>v2</html>", access_time, 60)
      ISRCache::put(cache, "isr:/blog/popular/", new_entry)
    }
  }
}

///|
/// Test cold page: accessed once, becomes stale, accessed again
test "Cold page lifecycle: fresh -> stale -> revalidated" {
  let cache = MemoryCache::new()
  let base_time = 1000000000L
  let key = "isr:/blog/cold-post/"

  // First access: cache miss, populate cache
  let entry1 = CacheEntry::new("<html>initial</html>", base_time, 60)
  ISRCache::put(cache, key, entry1)

  // Verify Fresh immediately
  let status1 = check_status(ISRCache::get(cache, key), base_time + 1000L)
  match status1 {
    Fresh => ()
    _ => fail("Should be Fresh after initial caching")
  }

  // Time passes: 2 hours later, page is accessed again
  let later_time = base_time + 7200000L // 2 hours later
  let status2 = check_status(ISRCache::get(cache, key), later_time)
  match status2 {
    Stale => ()
    _ => fail("Should be Stale after 2 hours")
  }

  // Content is still available despite being stale
  match ISRCache::get(cache, key) {
    Some(e) => assert_eq(e.html, "<html>initial</html>")
    None => fail("Stale content should still be available")
  }

  // Revalidation happens, cache is refreshed
  let entry2 = CacheEntry::new("<html>refreshed</html>", later_time, 60)
  ISRCache::put(cache, key, entry2)

  // Now Fresh again
  let status3 = check_status(ISRCache::get(cache, key), later_time + 1000L)
  match status3 {
    Fresh => ()
    _ => fail("Should be Fresh after revalidation")
  }
}

///|
/// Test mixed workload: simulate realistic access pattern
test "Mixed workload: 80/20 rule simulation" {
  let cache = MemoryCache::new()
  let base_time = 1000000000L

  // Create 100 pages
  let num_pages = 100
  for i = 0; i < num_pages; i = i + 1 {
    let key = "isr:/page/" + i.to_string() + "/"
    let entry = CacheEntry::new(
      "<html>" + i.to_string() + "</html>",
      base_time,
      60,
    )
    ISRCache::put(cache, key, entry)
  }

  // Simulate time: 90 seconds later (past 60s TTL)
  let check_time = base_time + 90000L

  // Count Fresh vs Stale
  let mut fresh_count = 0
  let mut stale_count = 0
  for i = 0; i < num_pages; i = i + 1 {
    let key = "isr:/page/" + i.to_string() + "/"
    let entry = ISRCache::get(cache, key)
    let status = check_status(entry, check_time)
    match status {
      Fresh => fresh_count = fresh_count + 1
      Stale => stale_count = stale_count + 1
      Miss => ()
    }
  }

  // All should be Stale (since all have same TTL and time passed)
  assert_eq(fresh_count, 0)
  assert_eq(stale_count, 100)

  // Simulate: top 20 pages get accessed and revalidated (80/20 rule)
  for i = 0; i < 20; i = i + 1 {
    let key = "isr:/page/" + i.to_string() + "/"
    let new_entry = CacheEntry::new(
      "<html>refreshed-" + i.to_string() + "</html>",
      check_time,
      60,
    )
    ISRCache::put(cache, key, new_entry)
  }

  // Re-count after partial revalidation
  fresh_count = 0
  stale_count = 0
  let recheck_time = check_time + 1000L // 1 second after revalidation
  for i = 0; i < num_pages; i = i + 1 {
    let key = "isr:/page/" + i.to_string() + "/"
    let entry = ISRCache::get(cache, key)
    let status = check_status(entry, recheck_time)
    match status {
      Fresh => fresh_count = fresh_count + 1
      Stale => stale_count = stale_count + 1
      Miss => ()
    }
  }

  // 20 should be Fresh (revalidated), 80 should still be Stale
  assert_eq(fresh_count, 20)
  assert_eq(stale_count, 80)
}
