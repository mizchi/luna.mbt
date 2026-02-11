// ISR Micro-benchmark with high-resolution timing
//
// Uses performance.now() for sub-millisecond precision

///|
extern "js" fn perf_now() -> Double =
  #| () => performance.now()

///|
test "micro-bench: cache operations timing" {
  let cache = MemoryCache::new()

  // Warm up
  for i = 0; i < 100; i = i + 1 {
    let key = "warm:" + i.to_string()
    ISRCache::put(cache, key, CacheEntry::new("x", 0L, 60))
  }

  // Benchmark: 10000 puts
  let start_put = perf_now()
  for i = 0; i < 10000; i = i + 1 {
    let key = "isr:/bench/" + i.to_string() + "/"
    let entry = CacheEntry::new(
      "<html>" + i.to_string() + "</html>",
      1000000000L,
      60,
    )
    ISRCache::put(cache, key, entry)
  }
  let elapsed_put = perf_now() - start_put

  // Benchmark: 10000 gets
  let start_get = perf_now()
  for i = 0; i < 10000; i = i + 1 {
    let key = "isr:/bench/" + i.to_string() + "/"
    let _ = ISRCache::get(cache, key)
  }
  let elapsed_get = perf_now() - start_get

  // Benchmark: 10000 status checks
  let check_time = 1000000000L + 30000L
  let start_status = perf_now()
  for i = 0; i < 10000; i = i + 1 {
    let key = "isr:/bench/" + i.to_string() + "/"
    let entry = ISRCache::get(cache, key)
    let _ = check_status(entry, check_time)
  }
  let elapsed_status = perf_now() - start_status
  println("=== Micro-benchmark Results ===")
  println(
    "10000 cache puts:    \{elapsed_put.to_string()}ms (\{(10000.0 / elapsed_put * 1000.0).to_int()} ops/sec)",
  )
  println(
    "10000 cache gets:    \{elapsed_get.to_string()}ms (\{(10000.0 / elapsed_get * 1000.0).to_int()} ops/sec)",
  )
  println(
    "10000 status checks: \{elapsed_status.to_string()}ms (\{(10000.0 / elapsed_status * 1000.0).to_int()} ops/sec)",
  )

  // Calculate per-operation time in microseconds
  let put_us = elapsed_put * 1000.0 / 10000.0
  let get_us = elapsed_get * 1000.0 / 10000.0
  let status_us = elapsed_status * 1000.0 / 10000.0
  println("")
  println("Per-operation latency:")
  println("  put:    \{put_us.to_string()}μs")
  println("  get:    \{get_us.to_string()}μs")
  println("  status: \{status_us.to_string()}μs")
}

///|
test "micro-bench: handler.handle() latency" {
  let cache = MemoryCache::new()
  let pages : Map[String, ISRPageMeta] = {}
  let num_pages = 1000
  for i = 0; i < num_pages; i = i + 1 {
    let path = "/bench/" + i.to_string() + "/"
    pages[path] = ISRPageMeta::{
      revalidate: 60,
      renderer: "markdown",
      source: "",
    }
  }
  let manifest = ISRManifest::{ version: 1, pages }
  let handler = ISRHandler::{ cache, manifest, dist_dir: "/tmp/dist" }

  // Pre-populate cache with far future timestamps
  let far_future = now_ms() + 100000000L
  for i = 0; i < num_pages; i = i + 1 {
    let path = "/bench/" + i.to_string() + "/"
    let key = cache_key(path, [])
    let entry = CacheEntry::new(
      "<html>Page " + i.to_string() + "</html>",
      far_future,
      60,
    )
    ISRCache::put(cache, key, entry)
  }

  // Warm up
  for i = 0; i < 100; i = i + 1 {
    let _ = handler.handle("/bench/" + (i % num_pages).to_string() + "/")
  }

  // Benchmark: 10000 handle() calls
  let num_requests = 10000
  let start = perf_now()
  for j = 0; j < num_requests; j = j + 1 {
    let idx = j % num_pages
    let path = "/bench/" + idx.to_string() + "/"
    let _ = handler.handle(path)
  }
  let elapsed = perf_now() - start
  let ops_per_sec = num_requests.to_double() / elapsed * 1000.0
  let latency_us = elapsed * 1000.0 / num_requests.to_double()
  println("")
  println("=== Handler Performance ===")
  println("10000 handler.handle(): \{elapsed.to_string()}ms")
  println("Throughput: \{ops_per_sec.to_int()} req/sec")
  println("Latency:    \{latency_us.to_string()}μs per request")
}

///|
test "micro-bench: 50k entries scalability" {
  let sizes = [1000, 5000, 10000, 25000, 50000]
  println("")
  println("=== Scalability Test ===")
  println("Entries | Populate(ms) | 1000 Gets(ms) | Get Latency(μs)")
  println("--------|--------------|---------------|----------------")
  for size in sizes {
    // Clear and repopulate
    let fresh_cache = MemoryCache::new()
    let start_pop = perf_now()
    for i = 0; i < size; i = i + 1 {
      let key = "isr:/scale/" + i.to_string() + "/"
      let entry = CacheEntry::new(
        "<html>" + i.to_string() + "</html>",
        1000000000L,
        60,
      )
      ISRCache::put(fresh_cache, key, entry)
    }
    let elapsed_pop = perf_now() - start_pop

    // Random access pattern
    let start_get = perf_now()
    for j = 0; j < 1000; j = j + 1 {
      let idx = j * 7919 % size // Prime number for pseudo-random spread
      let key = "isr:/scale/" + idx.to_string() + "/"
      let _ = ISRCache::get(fresh_cache, key)
    }
    let elapsed_get = perf_now() - start_get
    let get_latency = elapsed_get * 1000.0 / 1000.0
    println(
      "\{size}   | \{elapsed_pop.to_string()} | \{elapsed_get.to_string()} | \{get_latency.to_string()}",
    )
  }
}
