// ISR Documentation Site Simulation Test
//
// Simulates the Luna docs site (~95 pages) with realistic ISR behavior:
// - Main pages (index, overview): TTL 300s (hot)
// - Tutorial pages: TTL 120s (warm)
// - Internal docs: TTL 60s (cold, rarely accessed)
// - API reference: TTL 180s (moderate traffic)

// =============================================================================
// Documentation Structure Simulation
// =============================================================================

///|
/// Create ISR manifest simulating Luna docs structure
fn create_docs_manifest() -> ISRManifest {
  let pages : Map[String, ISRPageMeta] = {}

  // Main pages - hot (TTL: 300s)
  let main_pages = [
    "/", "/introduction/", "/luna/", "/ssg/", "/stella/", "/sol/",
  ]
  for path in main_pages {
    pages[path] = ISRPageMeta::{
      revalidate: 300,
      renderer: "markdown",
      source: "",
    }
  }

  // Overview and getting started - hot (TTL: 300s)
  let overview_pages = [
    "/introduction/overview/", "/introduction/getting-started/", "/introduction/faq/",
    "/luna/quick-start/", "/luna/why-luna/",
  ]
  for path in overview_pages {
    pages[path] = ISRPageMeta::{
      revalidate: 300,
      renderer: "markdown",
      source: "",
    }
  }

  // Tutorial pages - warm (TTL: 120s)
  let tutorial_topics = [
    "signals", "effects", "memos", "batch", "untrack", "nested", "show", "for", "switch",
    "onmount", "oncleanup", "islands_basics", "islands_state", "islands_triggers",
    "webcomponents",
  ]
  for topic in tutorial_topics {
    // JS tutorials
    pages["/luna/tutorial-js/" + topic + "/"] = ISRPageMeta::{
      revalidate: 120,
      renderer: "markdown",
      source: "",
    }
    // MoonBit tutorials
    pages["/luna/tutorial-moonbit/" + topic + "/"] = ISRPageMeta::{
      revalidate: 120,
      renderer: "markdown",
      source: "",
    }
  }

  // API reference - moderate traffic (TTL: 180s)
  let api_pages = [
    "/luna/api-js/signals/", "/luna/api-js/islands/", "/luna/api-moonbit/signals/",
    "/luna/api-moonbit/islands/", "/luna/api-moonbit/render/",
  ]
  for path in api_pages {
    pages[path] = ISRPageMeta::{
      revalidate: 180,
      renderer: "markdown",
      source: "",
    }
  }

  // Internal docs - cold (TTL: 60s, rarely accessed)
  let internal_pages = [
    "/internal/coding-guidelines/", "/internal/architecture/", "/internal/hydration-problem/",
    "/internal/markdown/", "/internal/render-bench/",
  ]
  for path in internal_pages {
    pages[path] = ISRPageMeta::{
      revalidate: 60,
      renderer: "markdown",
      source: "",
    }
  }

  // i18n pages (Japanese) - moderate (TTL: 180s)
  let ja_pages = ["/ja/", "/ja/introduction/", "/ja/luna/", "/ja/ssg/"]
  for path in ja_pages {
    pages[path] = ISRPageMeta::{
      revalidate: 180,
      renderer: "markdown",
      source: "",
    }
  }
  ISRManifest::{ version: 1, pages }
}

///|
/// Populate cache for docs pages at a given time
fn populate_docs_cache(
  cache : MemoryCache,
  manifest : ISRManifest,
  generated_at : Int64,
) -> Unit {
  for path, meta in manifest.pages {
    let key = cache_key(path, [])
    let html = "<html><h1>Docs: " + path + "</h1></html>"
    let entry = CacheEntry::new(html, generated_at, meta.revalidate)
    ISRCache::put(cache, key, entry)
  }
}

// =============================================================================
// Simulation Tests
// =============================================================================

///|
test "docs: initial state - all pages cached and fresh" {
  let manifest = create_docs_manifest()
  let cache = MemoryCache::new()
  let base_time = 1000000000L
  populate_docs_cache(cache, manifest, base_time)

  // Check all pages are Fresh
  let mut all_fresh = true
  let check_time = base_time + 1000L
  for path, _ in manifest.pages {
    let key = cache_key(path, [])
    let status = check_status(ISRCache::get(cache, key), check_time)
    match status {
      Fresh => ()
      _ => all_fresh = false
    }
  }
  assert_true(all_fresh)
}

///|
test "docs: after 90 seconds - internal pages stale, main pages fresh" {
  let manifest = create_docs_manifest()
  let cache = MemoryCache::new()
  let base_time = 1000000000L
  populate_docs_cache(cache, manifest, base_time)

  // After 90 seconds:
  // - Internal (TTL=60s): Stale
  // - Tutorial (TTL=120s): Fresh
  // - API (TTL=180s): Fresh
  // - Main (TTL=300s): Fresh
  let check_time = base_time + 90000L

  // Check internal page is Stale
  let internal_key = cache_key("/internal/coding-guidelines/", [])
  let internal_status = check_status(
    ISRCache::get(cache, internal_key),
    check_time,
  )
  match internal_status {
    Stale => ()
    _ => fail("Internal page should be Stale at 90s")
  }

  // Check main page is Fresh
  let main_key = cache_key("/", [])
  let main_status = check_status(ISRCache::get(cache, main_key), check_time)
  match main_status {
    Fresh => ()
    _ => fail("Main page should be Fresh at 90s")
  }

  // Check tutorial page is Fresh
  let tutorial_key = cache_key("/luna/tutorial-js/signals/", [])
  let tutorial_status = check_status(
    ISRCache::get(cache, tutorial_key),
    check_time,
  )
  match tutorial_status {
    Fresh => ()
    _ => fail("Tutorial page should be Fresh at 90s")
  }
}

///|
test "docs: after 150 seconds - tutorials stale, main still fresh" {
  let manifest = create_docs_manifest()
  let cache = MemoryCache::new()
  let base_time = 1000000000L
  populate_docs_cache(cache, manifest, base_time)

  // After 150 seconds:
  // - Internal (TTL=60s): Stale
  // - Tutorial (TTL=120s): Stale
  // - API (TTL=180s): Fresh
  // - Main (TTL=300s): Fresh
  let check_time = base_time + 150000L

  // Tutorial should be Stale
  let tutorial_key = cache_key("/luna/tutorial-moonbit/effects/", [])
  let tutorial_status = check_status(
    ISRCache::get(cache, tutorial_key),
    check_time,
  )
  match tutorial_status {
    Stale => ()
    _ => fail("Tutorial should be Stale at 150s")
  }

  // API should still be Fresh
  let api_key = cache_key("/luna/api-js/signals/", [])
  let api_status = check_status(ISRCache::get(cache, api_key), check_time)
  match api_status {
    Fresh => ()
    _ => fail("API page should be Fresh at 150s")
  }

  // Main should still be Fresh
  let main_key = cache_key("/luna/quick-start/", [])
  let main_status = check_status(ISRCache::get(cache, main_key), check_time)
  match main_status {
    Fresh => ()
    _ => fail("Quick start should be Fresh at 150s")
  }
}

///|
test "docs: after 200 seconds - only main pages remain fresh" {
  let manifest = create_docs_manifest()
  let cache = MemoryCache::new()
  let base_time = 1000000000L
  populate_docs_cache(cache, manifest, base_time)

  // After 200 seconds:
  // - Internal (TTL=60s): Stale
  // - Tutorial (TTL=120s): Stale
  // - API (TTL=180s): Stale
  // - Main (TTL=300s): Fresh
  let check_time = base_time + 200000L

  // API should now be Stale
  let api_key = cache_key("/luna/api-moonbit/render/", [])
  let api_status = check_status(ISRCache::get(cache, api_key), check_time)
  match api_status {
    Stale => ()
    _ => fail("API page should be Stale at 200s")
  }

  // Main index should still be Fresh
  let main_key = cache_key("/", [])
  let main_status = check_status(ISRCache::get(cache, main_key), check_time)
  match main_status {
    Fresh => ()
    _ => fail("Main page should be Fresh at 200s")
  }
}

///|
test "docs: after 10 minutes - all pages stale" {
  let manifest = create_docs_manifest()
  let cache = MemoryCache::new()
  let base_time = 1000000000L
  populate_docs_cache(cache, manifest, base_time)

  // After 10 minutes (600 seconds): all should be Stale
  let check_time = base_time + 600000L
  let mut all_stale = true
  for path, _ in manifest.pages {
    let key = cache_key(path, [])
    let status = check_status(ISRCache::get(cache, key), check_time)
    match status {
      Stale => ()
      _ => all_stale = false
    }
  }
  assert_true(all_stale)
}

///|
test "docs: popular pages revalidation simulation" {
  let manifest = create_docs_manifest()
  let cache = MemoryCache::new()
  let handler = ISRHandler::{ cache, manifest, dist_dir: "/tmp/dist" }
  let base_time = 1000000000L
  populate_docs_cache(cache, manifest, base_time)

  // Simulate 5 minutes of operation
  let current_time = base_time + 300000L

  // Popular pages accessed and revalidated:
  let popular_pages = [
    "/", "/luna/", "/luna/quick-start/", "/introduction/getting-started/",
  ]
  for path in popular_pages {
    handler.update_cache(path, "<html>Fresh content for " + path + "</html>")
  }

  // Check popular pages are now fresh with new content
  for path in popular_pages {
    let key = cache_key(path, [])
    match ISRCache::get(cache, key) {
      Some(e) => {
        let expected = "<html>Fresh content for " + path + "</html>"
        assert_eq(e.html, expected)
      }
      None => fail("Expected cached entry for " + path)
    }
  }

  // Non-popular pages remain stale (if their TTL has passed)
  let cold_key = cache_key("/internal/architecture/", [])
  let cold_status = check_status(ISRCache::get(cache, cold_key), current_time)
  match cold_status {
    Stale => ()
    _ => fail("Cold page should remain stale")
  }
}

///|
test "docs: i18n pages follow same pattern" {
  let manifest = create_docs_manifest()
  let cache = MemoryCache::new()
  let base_time = 1000000000L
  populate_docs_cache(cache, manifest, base_time)

  // Japanese pages have TTL=180s
  let check_time = base_time + 200000L // After 200s

  // Japanese page should be Stale (TTL=180s < 200s)
  let ja_key = cache_key("/ja/", [])
  let ja_status = check_status(ISRCache::get(cache, ja_key), check_time)
  match ja_status {
    Stale => ()
    _ => fail("Japanese page should be Stale at 200s")
  }

  // But at 150s, it should still be Fresh
  let early_check = base_time + 150000L
  let ja_status_early = check_status(ISRCache::get(cache, ja_key), early_check)
  match ja_status_early {
    Fresh => ()
    _ => fail("Japanese page should be Fresh at 150s")
  }
}

///|
test "docs: count pages by TTL tier" {
  let manifest = create_docs_manifest()
  let mut hot = 0 // TTL >= 300
  let mut warm = 0 // 120 <= TTL < 300
  let mut cold = 0 // TTL < 120
  for _, meta in manifest.pages {
    if meta.revalidate >= 300 {
      hot = hot + 1
    } else if meta.revalidate >= 120 {
      warm = warm + 1
    } else {
      cold = cold + 1
    }
  }

  // Verify distribution:
  // - Hot (main + overview): 11 pages
  // - Warm (tutorials + API + i18n): 30 tutorials + 5 API + 4 i18n = 39 pages
  // - Cold (internal): 5 pages
  assert_eq(hot, 11)
  assert_eq(warm, 39)
  assert_eq(cold, 5)
}

///|
test "docs: cache eviction simulation" {
  let manifest = create_docs_manifest()
  let cache = MemoryCache::new()
  let base_time = 1000000000L
  populate_docs_cache(cache, manifest, base_time)

  // Simulate evicting cold pages (rarely accessed, save memory)
  let cold_pages = [
    "/internal/coding-guidelines/", "/internal/architecture/", "/internal/hydration-problem/",
    "/internal/markdown/", "/internal/render-bench/",
  ]
  for path in cold_pages {
    let key = cache_key(path, [])
    ISRCache::delete(cache, key)
  }

  // Verify cold pages are evicted
  for path in cold_pages {
    let key = cache_key(path, [])
    assert_true(ISRCache::get(cache, key) is None)
  }

  // Hot pages remain
  let hot_key = cache_key("/", [])
  assert_true(ISRCache::get(cache, hot_key) is Some(_))
}
