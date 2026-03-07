// ISR Performance Benchmark Tests
//
// Measures actual request handling efficiency:
// - Cache lookup time
// - Status check time
// - Throughput with many entries

// =============================================================================
// Performance Helpers
// =============================================================================

///|
/// Get current time in milliseconds for benchmarking
fn bench_now() -> Int64 {
  now_ms()
}

///|
/// Calculate operations per second
fn ops_per_sec(ops : Int, elapsed_ms : Int64) -> Double {
  if elapsed_ms == 0L {
    return 0.0
  }
  ops.to_double() / (elapsed_ms.to_double() / 1000.0)
}

// =============================================================================
// Cache Lookup Performance
// =============================================================================

///|
test "bench: 10000 cache lookups" {
  let cache = MemoryCache::new()
  let num_entries = 10000

  // Populate cache
  for i = 0; i < num_entries; i = i + 1 {
    let key = "isr:/page/" + i.to_string() + "/"
    let entry = CacheEntry::new(
      "<html>" + i.to_string() + "</html>",
      1000000000L,
      60,
    )
    ISRCache::put(cache, key, entry)
  }

  // Benchmark: lookup all entries
  let start = bench_now()
  let mut found = 0
  for i = 0; i < num_entries; i = i + 1 {
    let key = "isr:/page/" + i.to_string() + "/"
    match ISRCache::get(cache, key) {
      Some(_) => found = found + 1
      None => ()
    }
  }
  let elapsed = bench_now() - start

  // All should be found
  assert_eq(found, num_entries)

  // Should complete quickly (< 100ms for 10k lookups)
  // In practice, Map lookup is O(1) so this is very fast
  println(
    "10000 lookups: \{elapsed}ms (\{ops_per_sec(num_entries, elapsed).to_int()} ops/sec)",
  )
}

///|
test "bench: 10000 status checks" {
  let cache = MemoryCache::new()
  let num_entries = 10000
  let base_time = 1000000000L

  // Populate cache with varied TTLs
  for i = 0; i < num_entries; i = i + 1 {
    let key = "isr:/page/" + i.to_string() + "/"
    let ttl = 60 + i % 300 // TTL varies 60-359 seconds
    let entry = CacheEntry::new(
      "<html>" + i.to_string() + "</html>",
      base_time,
      ttl,
    )
    ISRCache::put(cache, key, entry)
  }

  // Benchmark: check status for all entries
  let check_time = base_time + 120000L // 2 minutes later
  let start = bench_now()
  let mut fresh = 0
  let mut stale = 0
  for i = 0; i < num_entries; i = i + 1 {
    let key = "isr:/page/" + i.to_string() + "/"
    let entry = ISRCache::get(cache, key)
    match check_status(entry, check_time) {
      Fresh => fresh = fresh + 1
      Stale => stale = stale + 1
      Miss => ()
    }
  }
  let elapsed = bench_now() - start

  // Verify distribution (TTL <= 120 should be Stale, > 120 should be Fresh)
  // TTL 60-120: 61 values per 300 cycle (i % 300 = 0-60)
  // 10000 = 33*300 + 100, so 33 full cycles + partial
  // Stale: 33*61 + 61 = 2074 (partial cycle has 100 entries, 61 are stale)
  // Fresh: 10000 - 2074 = 7926
  assert_eq(stale, 2074)
  assert_eq(fresh, 7926)
  println(
    "10000 status checks: \{elapsed}ms (\{ops_per_sec(num_entries, elapsed).to_int()} ops/sec)",
  )
}

///|
test "bench: 50000 entries populate and random access" {
  let cache = MemoryCache::new()
  let num_entries = 50000

  // Benchmark: populate cache
  let start_populate = bench_now()
  for i = 0; i < num_entries; i = i + 1 {
    let key = "isr:/blog/post-" + i.to_string() + "/"
    let entry = CacheEntry::new(
      "<html>Post " + i.to_string() + "</html>",
      1000000000L,
      60,
    )
    ISRCache::put(cache, key, entry)
  }
  let elapsed_populate = bench_now() - start_populate

  // Benchmark: random access pattern (simulate real traffic)
  let access_pattern = [
    0, 1, 2, 0, 3, 1, 4, 0, 5, 2, 100, 500, 1000, 0, 1, 49999, 25000,
  ]
  let num_accesses = 10000
  let start_access = bench_now()
  let mut hits = 0
  for j = 0; j < num_accesses; j = j + 1 {
    let idx = access_pattern[j % access_pattern.length()]
    let key = "isr:/blog/post-" + idx.to_string() + "/"
    match ISRCache::get(cache, key) {
      Some(_) => hits = hits + 1
      None => ()
    }
  }
  let elapsed_access = bench_now() - start_access
  assert_eq(hits, num_accesses)
  println("50000 entries populate: \{elapsed_populate}ms")
  println(
    "10000 random accesses: \{elapsed_access}ms (\{ops_per_sec(num_accesses, elapsed_access).to_int()} ops/sec)",
  )
}

///|
async test "bench: handler.handle() full path" {
  let cache = MemoryCache::new()
  let pages : Map[String, ISRPageMeta] = {}

  // Create 1000 ISR pages
  let num_pages = 1000
  for i = 0; i < num_pages; i = i + 1 {
    let path = "/page/" + i.to_string() + "/"
    pages[path] = ISRPageMeta::{
      revalidate: 60,
      renderer: "markdown",
      source: "",
    }
  }
  let manifest = ISRManifest::{ version: 1, pages }
  let handler = ISRHandler::{ cache, manifest, dist_dir: "/tmp/dist" }

  // Pre-populate cache
  let base_time = now_ms() + 100000000L // Far future to ensure Fresh
  for i = 0; i < num_pages; i = i + 1 {
    let path = "/page/" + i.to_string() + "/"
    let key = cache_key(path, [])
    let entry = CacheEntry::new(
      "<html>Page " + i.to_string() + "</html>",
      base_time,
      60,
    )
    ISRCache::put(cache, key, entry)
  }

  // Benchmark: full handle() path
  let num_requests = 5000
  let start = bench_now()
  let mut served = 0
  for j = 0; j < num_requests; j = j + 1 {
    let idx = j % num_pages
    let path = "/page/" + idx.to_string() + "/"
    let (html, _needs_revalidation) = handler.handle(path)
    match html {
      Some(_) => served = served + 1
      None => ()
    }
  }
  let elapsed = bench_now() - start
  assert_eq(served, num_requests)
  let throughput = ops_per_sec(num_requests, elapsed)
  println(
    "5000 handler.handle(): \{elapsed}ms (\{throughput.to_int()} req/sec)",
  )

  // If elapsed is 0ms, operations are faster than timer resolution
  // which means extremely fast (> 5M ops/sec at 1ms resolution)
  // Otherwise check reasonable throughput
  if elapsed > 0L {
    assert_true(throughput > 1000.0)
  }
  // Test passes if elapsed == 0 (too fast to measure)
}

///|
test "bench: cache update (revalidation) throughput" {
  let cache = MemoryCache::new()
  let pages : Map[String, ISRPageMeta] = {}

  // Create 100 ISR pages
  let num_pages = 100
  for i = 0; i < num_pages; i = i + 1 {
    let path = "/hot/" + i.to_string() + "/"
    pages[path] = ISRPageMeta::{
      revalidate: 60,
      renderer: "markdown",
      source: "",
    }
  }
  let manifest = ISRManifest::{ version: 1, pages }
  let handler = ISRHandler::{ cache, manifest, dist_dir: "/tmp/dist" }

  // Pre-populate
  for i = 0; i < num_pages; i = i + 1 {
    let path = "/hot/" + i.to_string() + "/"
    let key = cache_key(path, [])
    let entry = CacheEntry::new("<html>v1</html>", 1000000000L, 60)
    ISRCache::put(cache, key, entry)
  }

  // Benchmark: update cache (simulates revalidation)
  let num_updates = 1000
  let start = bench_now()
  for j = 0; j < num_updates; j = j + 1 {
    let idx = j % num_pages
    let path = "/hot/" + idx.to_string() + "/"
    handler.update_cache(path, "<html>v" + j.to_string() + "</html>")
  }
  let elapsed = bench_now() - start
  println(
    "1000 cache updates: \{elapsed}ms (\{ops_per_sec(num_updates, elapsed).to_int()} ops/sec)",
  )
}

///|
async test "bench: mixed workload (80% read, 20% write)" {
  let cache = MemoryCache::new()
  let pages : Map[String, ISRPageMeta] = {}
  let num_pages = 500
  for i = 0; i < num_pages; i = i + 1 {
    let path = "/mixed/" + i.to_string() + "/"
    pages[path] = ISRPageMeta::{
      revalidate: 60,
      renderer: "markdown",
      source: "",
    }
  }
  let manifest = ISRManifest::{ version: 1, pages }
  let handler = ISRHandler::{ cache, manifest, dist_dir: "/tmp/dist" }

  // Pre-populate
  let base_time = now_ms() + 100000000L
  for i = 0; i < num_pages; i = i + 1 {
    let path = "/mixed/" + i.to_string() + "/"
    let key = cache_key(path, [])
    let entry = CacheEntry::new("<html>Page</html>", base_time, 60)
    ISRCache::put(cache, key, entry)
  }

  // Mixed workload: 80% reads, 20% writes
  let total_ops = 5000
  let start = bench_now()
  let mut reads = 0
  let mut writes = 0
  for j = 0; j < total_ops; j = j + 1 {
    let idx = j % num_pages
    let path = "/mixed/" + idx.to_string() + "/"
    if j % 5 == 0 {
      // 20% writes
      handler.update_cache(path, "<html>Updated</html>")
      writes = writes + 1
    } else {
      // 80% reads
      let _ = handler.handle(path)
      reads = reads + 1
    }
  }
  let elapsed = bench_now() - start
  assert_eq(reads + writes, total_ops)
  println("Mixed workload (5000 ops, 80/20): \{elapsed}ms")
  println("  Reads: \{reads}, Writes: \{writes}")
  println("  Throughput: \{ops_per_sec(total_ops, elapsed).to_int()} ops/sec")
}
