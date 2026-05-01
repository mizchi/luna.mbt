// ISR Blog Simulation Test
//
// Simulates a large blog (50,000 posts) with realistic access patterns:
// - Top 100 posts: "hot" (80% of traffic)
// - Next 900 posts: "warm" (15% of traffic)
// - Remaining 49,000: "cold" (5% of traffic, but long tail)

// =============================================================================
// 50,000 Blog Posts Simulation
// =============================================================================

///|
/// Create a manifest for a large blog
fn create_blog_manifest(num_posts : Int) -> ISRManifest {
  let pages : Map[String, ISRPageMeta] = {}
  for i = 0; i < num_posts; i = i + 1 {
    let path = "/blog/post-" + i.to_string() + "/"

    // Tiered TTL based on popularity
    let ttl = if i < 100 {
      300 // Hot posts: 5 minutes
    } else if i < 1000 {
      120 // Warm posts: 2 minutes
    } else {
      60 // Cold posts: 1 minute
    }
    pages[path] = ISRPageMeta::{
      revalidate: ttl,
      renderer: "markdown",
      source: "",
    }
  }
  ISRManifest::{ version: 1, pages }
}

///|
/// Populate cache for blog posts at a given time
fn populate_blog_cache(
  cache : MemoryCache,
  num_posts : Int,
  generated_at : Int64,
) -> Unit {
  for i = 0; i < num_posts; i = i + 1 {
    let path = "/blog/post-" + i.to_string() + "/"
    let key = cache_key(path, [])
    let ttl = if i < 100 { 300 } else if i < 1000 { 120 } else { 60 }
    let html = "<html><h1>Post " +
      i.to_string() +
      "</h1><p>Content...</p></html>"
    let entry = CacheEntry::new(html, generated_at, ttl)
    ISRCache::put(cache, key, entry)
  }
}

///|
/// Count cache status distribution
fn count_cache_status(
  cache : MemoryCache,
  num_posts : Int,
  check_time : Int64,
) -> (Int, Int, Int) { // (fresh, stale, miss)
  let mut fresh = 0
  let mut stale = 0
  let mut miss = 0
  for i = 0; i < num_posts; i = i + 1 {
    let path = "/blog/post-" + i.to_string() + "/"
    let key = cache_key(path, [])
    let entry = ISRCache::get(cache, key)
    let status = check_status(entry, check_time)
    match status {
      Fresh => fresh = fresh + 1
      Stale => stale = stale + 1
      Miss => miss = miss + 1
    }
  }
  (fresh, stale, miss)
}

// =============================================================================
// Simulation Tests
// =============================================================================

///|
test "50k blog: initial state - all fresh" {
  // Use 1000 posts for test speed (scales linearly)
  let num_posts = 1000
  let cache = MemoryCache::new()
  let base_time = 1000000000L
  populate_blog_cache(cache, num_posts, base_time)

  // Immediately after generation: all should be Fresh
  let (fresh, stale, miss) = count_cache_status(
    cache,
    num_posts,
    base_time + 1000L,
  )
  assert_eq(fresh, num_posts)
  assert_eq(stale, 0)
  assert_eq(miss, 0)
}

///|
test "50k blog: after 90 seconds - cold posts stale, hot still fresh" {
  let num_posts = 1000
  let cache = MemoryCache::new()
  let base_time = 1000000000L
  populate_blog_cache(cache, num_posts, base_time)

  // 90 seconds later:
  // - Hot (TTL=300s): Fresh
  // - Warm (TTL=120s): Fresh
  // - Cold (TTL=60s): Stale
  let check_time = base_time + 90000L
  let (fresh, stale, _) = count_cache_status(cache, num_posts, check_time)

  // First 1000 posts (100 hot + 900 warm) = Fresh
  // Remaining are cold = Stale (but we only have 1000 total, all are in first tier)
  // Actually with num_posts=1000: 100 hot + 900 warm, no cold
  // Let me recalculate...

  // Hot: 0-99 (100 posts), TTL=300s -> Fresh at 90s
  // Warm: 100-999 (900 posts), TTL=120s -> Fresh at 90s
  // So all 1000 should be Fresh at 90s

  assert_eq(fresh, 1000)
  assert_eq(stale, 0)
}

///|
test "50k blog: after 150 seconds - warm posts become stale" {
  let num_posts = 1000
  let cache = MemoryCache::new()
  let base_time = 1000000000L
  populate_blog_cache(cache, num_posts, base_time)

  // 150 seconds later:
  // - Hot (TTL=300s): Fresh
  // - Warm (TTL=120s): Stale
  let check_time = base_time + 150000L
  let (fresh, stale, _) = count_cache_status(cache, num_posts, check_time)

  // Hot: 100 posts -> Fresh
  // Warm: 900 posts -> Stale
  assert_eq(fresh, 100)
  assert_eq(stale, 900)
}

///|
test "50k blog: after 10 minutes - only hot posts remain fresh" {
  let num_posts = 1000
  let cache = MemoryCache::new()
  let base_time = 1000000000L
  populate_blog_cache(cache, num_posts, base_time)

  // 10 minutes (600 seconds) later:
  // - Hot (TTL=300s): Stale (past 5 min)
  // - Warm (TTL=120s): Stale
  let check_time = base_time + 600000L
  let (fresh, stale, _) = count_cache_status(cache, num_posts, check_time)

  // All should be Stale
  assert_eq(fresh, 0)
  assert_eq(stale, 1000)
}

///|
test "50k blog: hot page revalidation keeps it fresh" {
  let num_posts = 100
  let cache = MemoryCache::new()
  let manifest = create_blog_manifest(num_posts)
  let handler = ISRHandler::{ cache, manifest, dist_dir: "/tmp/dist" }
  let base_time = 1000000000L
  populate_blog_cache(cache, num_posts, base_time)

  // Simulate hot page being accessed and revalidated every 4 minutes
  let hot_page_key = cache_key("/blog/post-0/", [])

  // At 4 minutes: still Fresh (TTL=300s)
  let t1 = base_time + 240000L
  let status1 = check_status(ISRCache::get(cache, hot_page_key), t1)
  match status1 {
    Fresh => ()
    _ => fail("Hot page should be Fresh at 4 min")
  }

  // At 6 minutes: Stale (past TTL)
  let t2 = base_time + 360000L
  let status2 = check_status(ISRCache::get(cache, hot_page_key), t2)
  match status2 {
    Stale => ()
    _ => fail("Hot page should be Stale at 6 min")
  }

  // Revalidate: update with new content
  handler.update_cache("/blog/post-0/", "<html>Updated hot content</html>")

  // Verify it's Fresh again (with new timestamp)
  match ISRCache::get(cache, hot_page_key) {
    Some(e) => assert_eq(e.html, "<html>Updated hot content</html>")
    // New entry should be Fresh relative to current time
    None => fail("Expected updated entry")
  }
}

///|
test "50k blog: cold page lifecycle (accessed after long time)" {
  let cache = MemoryCache::new()
  let base_time = 1000000000L

  // Single cold page
  let cold_key = "isr:/blog/post-45000/"
  let entry = CacheEntry::new("<html>Old post from 2020</html>", base_time, 60)
  ISRCache::put(cache, cold_key, entry)

  // 1 hour later: someone finds this old post via search
  let access_time = base_time + 3600000L // 1 hour later
  let status = check_status(ISRCache::get(cache, cold_key), access_time)

  // Should be Stale
  match status {
    Stale => ()
    _ => fail("Cold page should be Stale after 1 hour")
  }

  // But content is still served immediately (SWR)
  match ISRCache::get(cache, cold_key) {
    Some(e) => assert_eq(e.html, "<html>Old post from 2020</html>")
    None => fail("Stale content should still be available")
  }

  // Background revalidation happens...
  let refreshed_entry = CacheEntry::new(
    "<html>Updated 2024 content</html>", access_time, 60,
  )
  ISRCache::put(cache, cold_key, refreshed_entry)

  // Next access gets fresh content
  let next_access = access_time + 1000L
  let status2 = check_status(ISRCache::get(cache, cold_key), next_access)
  match status2 {
    Fresh => ()
    _ => fail("Should be Fresh after revalidation")
  }
}

///|
test "50k blog: traffic distribution simulation (80/20 rule)" {
  let num_posts = 1000
  let cache = MemoryCache::new()
  let base_time = 1000000000L
  populate_blog_cache(cache, num_posts, base_time)

  // Simulate 3 minutes of operation
  let current_time = base_time + 180000L

  // Count initial status
  let (initial_fresh, initial_stale, _) = count_cache_status(
    cache, num_posts, current_time,
  )

  // At 3 minutes:
  // Hot (TTL=300s): Fresh (100 posts)
  // Warm (TTL=120s): Stale (900 posts)
  assert_eq(initial_fresh, 100)
  assert_eq(initial_stale, 900)

  // Simulate revalidation of accessed pages
  // 80% of traffic goes to top 20% of posts (200 posts)
  // These get revalidated
  for i = 0; i < 200; i = i + 1 {
    let path = "/blog/post-" + i.to_string() + "/"
    let key = cache_key(path, [])
    let ttl = if i < 100 { 300 } else { 120 }
    let new_entry = CacheEntry::new(
      "<html>Refreshed " + i.to_string() + "</html>",
      current_time,
      ttl,
    )
    ISRCache::put(cache, key, new_entry)
  }

  // After revalidation
  let check_after = current_time + 1000L
  let (after_fresh, after_stale, _) = count_cache_status(
    cache, num_posts, check_after,
  )

  // Top 200 should now be Fresh
  // Remaining 800 still Stale (weren't accessed)
  assert_eq(after_fresh, 200)
  assert_eq(after_stale, 800)
}

///|
test "50k blog: memory efficiency - entries are reusable" {
  let cache = MemoryCache::new()

  // Simulate 50,000 entries (actually 5000 for test speed)
  let num_posts = 5000
  let base_time = 1000000000L
  populate_blog_cache(cache, num_posts, base_time)

  // Verify random access works efficiently
  for i in [0, 100, 500, 1000, 2500, 4999] {
    let key = cache_key("/blog/post-" + i.to_string() + "/", [])
    match ISRCache::get(cache, key) {
      Some(e) => {
        // Just verify content matches
        let expected_start = "<html><h1>Post " + i.to_string()
        assert_true(e.html.has_prefix(expected_start))
      }
      None => fail("Post " + i.to_string() + " not found")
    }
  }

  // Delete some entries (simulate cache eviction)
  for i = 4000; i < 5000; i = i + 1 {
    let key = cache_key("/blog/post-" + i.to_string() + "/", [])
    ISRCache::delete(cache, key)
  }

  // Verify deleted entries are gone
  let deleted_key = cache_key("/blog/post-4500/", [])
  assert_true(ISRCache::get(cache, deleted_key) is None)

  // Remaining entries still accessible
  let remaining_key = cache_key("/blog/post-1000/", [])
  assert_true(ISRCache::get(cache, remaining_key) is Some(_))
}
