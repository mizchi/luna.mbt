// Sol ISR Unit Tests

// ============================================================================
// Cache Key Tests
// ============================================================================

///|
test "cache_key with path only" {
  let key = cache_key("/", [])
  assert_eq(key, "isr:/")
}

///|
test "cache_key with simple path" {
  let key = cache_key("/about", [])
  assert_eq(key, "isr:/about")
}

///|
test "cache_key with query params" {
  let key = cache_key("/search", [("q", "hello")])
  assert_eq(key, "isr:/search?q=hello")
}

///|
test "basic sort_by test" {
  let arr = ["z", "a", "b"]
  arr.sort_by(fn(a, b) { a.compare(b) })
  assert_eq(arr[0], "a")
  assert_eq(arr[1], "b")
  assert_eq(arr[2], "z")
}

///|
test "cache_key sorts query params" {
  let key = cache_key("/api", [("z", "last"), ("a", "first")])
  assert_eq(key, "isr:/api?a=first&z=last")
}

///|
test "lexicographic_compare basic" {
  // Same length
  assert_eq(lexicographic_compare("a", "z"), -1)
  assert_eq(lexicographic_compare("z", "a"), 1)
  assert_eq(lexicographic_compare("a", "a"), 0)
  // Different lengths - alphabetical order wins
  assert_eq(lexicographic_compare("category", "sort"), -1)  // c < s
  assert_eq(lexicographic_compare("sort", "category"), 1)   // s > c
  assert_eq(lexicographic_compare("cat", "category"), -1)   // shorter prefix
}

///|
test "cache_key with multiple query params" {
  let key = cache_key("/products", [("category", "books"), ("sort", "price")])
  assert_eq(key, "isr:/products?category=books&sort=price")
}

// ============================================================================
// Cache Status Tests
// ============================================================================

///|
test "check_status returns Miss for None" {
  let status = check_status(None, 1000L)
  match status {
    Miss => ()
    _ => fail("Expected Miss")
  }
}

///|
test "check_status returns Fresh when not expired" {
  let entry = CacheEntry::new("html", 1000L, 60) // generated at 1000ms, valid for 60s
  let status = check_status(Some(entry), 30000L) // check at 30000ms (30s later)
  match status {
    Fresh => ()
    _ => fail("Expected Fresh")
  }
}

///|
test "check_status returns Stale when expired" {
  let entry = CacheEntry::new("html", 1000L, 60) // generated at 1000ms, valid for 60s
  let status = check_status(Some(entry), 70000L) // check at 70000ms (70s later)
  match status {
    Stale => ()
    _ => fail("Expected Stale")
  }
}

///|
test "check_status Fresh at boundary" {
  let entry = CacheEntry::new("html", 0L, 60) // generated at 0, valid for 60s
  let status = check_status(Some(entry), 59999L) // 1ms before expiry
  match status {
    Fresh => ()
    _ => fail("Expected Fresh at boundary")
  }
}

///|
test "check_status Stale at boundary" {
  let entry = CacheEntry::new("html", 0L, 60) // generated at 0, valid for 60s
  let status = check_status(Some(entry), 60000L) // exactly at expiry
  match status {
    Stale => ()
    _ => fail("Expected Stale at boundary")
  }
}

// ============================================================================
// MemoryCache Tests
// ============================================================================

///|
test "MemoryCache get returns None for missing key" {
  let cache = MemoryCache::new()
  let result = ISRCache::get(cache, "missing")
  assert_true(result is None)
}

///|
test "MemoryCache put and get" {
  let cache = MemoryCache::new()
  let entry = CacheEntry::new("<html>test</html>", 1234567890L, 60)
  ISRCache::put(cache, "test-key", entry)
  let result = ISRCache::get(cache, "test-key")
  match result {
    Some(e) => {
      assert_eq(e.html, "<html>test</html>")
      assert_eq(e.generated_at, 1234567890L)
      assert_eq(e.revalidate, 60)
    }
    None => fail("Expected Some(entry)")
  }
}

///|
test "MemoryCache delete" {
  let cache = MemoryCache::new()
  let entry = CacheEntry::new("html", 1000L, 60)
  ISRCache::put(cache, "key", entry)
  assert_true(ISRCache::get(cache, "key") is Some(_))
  ISRCache::delete(cache, "key")
  assert_true(ISRCache::get(cache, "key") is None)
}

///|
test "MemoryCache multiple entries" {
  let cache = MemoryCache::new()
  ISRCache::put(cache, "a", CacheEntry::new("html-a", 1000L, 60))
  ISRCache::put(cache, "b", CacheEntry::new("html-b", 2000L, 120))
  match ISRCache::get(cache, "a") {
    Some(e) => assert_eq(e.html, "html-a")
    None => fail("Expected entry a")
  }
  match ISRCache::get(cache, "b") {
    Some(e) => assert_eq(e.html, "html-b")
    None => fail("Expected entry b")
  }
}
