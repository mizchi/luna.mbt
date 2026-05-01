///|
/// Tests for CacheManager using MemFSAdapter

///|
test "CacheManager::with_fs - basic get/set" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let cache = CacheManager::with_fs(fs, "/cache", "config-hash-123")

  // Initially empty
  let status = cache.get_with_hash("/page/", "hash-1")
  assert_false(status.is_hit())

  // Set a value
  cache.set("/page/", "hash-1", "<html>test</html>")

  // Now should hit
  let status2 = cache.get_with_hash("/page/", "hash-1")
  assert_true(status2.is_hit())
  match status2 {
    Hit(content) => assert_eq(content, "<html>test</html>")
    _ => fail("expected hit")
  }
}

///|
test "CacheManager::with_fs - hash mismatch returns miss" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let cache = CacheManager::with_fs(fs, "/cache", "config-hash-123")

  // Set with one hash
  cache.set("/page/", "hash-1", "<html>v1</html>")

  // Get with different hash should miss
  let status = cache.get_with_hash("/page/", "hash-2")
  assert_false(status.is_hit())
}

///|
test "CacheManager::with_fs - save and reload" {
  let fs = @fs_adapter.MemFSAdapter::new()

  // Create and populate cache
  let cache1 = CacheManager::with_fs(fs, "/cache", "config-hash-123")
  cache1.set("/page1/", "hash-a", "<html>page1</html>")
  cache1.set("/page2/", "hash-b", "<html>page2</html>")
  cache1.save()

  // Create new cache instance (simulating restart)
  let cache2 = CacheManager::with_fs(fs, "/cache", "config-hash-123")

  // Should still find cached entries
  let status1 = cache2.get_with_hash("/page1/", "hash-a")
  assert_true(status1.is_hit())
  let status2 = cache2.get_with_hash("/page2/", "hash-b")
  assert_true(status2.is_hit())
}

///|
test "CacheManager::with_fs - config hash change invalidates cache" {
  let fs = @fs_adapter.MemFSAdapter::new()

  // Create and populate cache with one config
  let cache1 = CacheManager::with_fs(fs, "/cache", "config-v1")
  cache1.set("/page/", "hash-1", "<html>old</html>")
  cache1.save()

  // Create new cache with different config hash
  let cache2 = CacheManager::with_fs(fs, "/cache", "config-v2")

  // Should not find old cached entry (config changed)
  let status = cache2.get_with_hash("/page/", "hash-1")
  assert_false(status.is_hit())
}

///|
test "CacheManager::with_fs - clear removes all" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let cache = CacheManager::with_fs(fs, "/cache", "config-hash")
  cache.set("/page1/", "hash-1", "content1")
  cache.set("/page2/", "hash-2", "content2")

  // Verify entries exist
  assert_true(cache.get_with_hash("/page1/", "hash-1").is_hit())

  // Clear
  cache.clear()

  // Should be empty
  assert_false(cache.get_with_hash("/page1/", "hash-1").is_hit())
  assert_false(cache.get_with_hash("/page2/", "hash-2").is_hit())
}

///|
test "fnv1a - consistent hashing" {
  let hash1 = fnv1a("test content")
  let hash2 = fnv1a("test content")
  assert_eq(hash1, hash2)

  // Different content produces different hash
  let hash3 = fnv1a("different content")
  assert_true(hash1 != hash3)
}

///|
test "compute_page_hash - combines multiple inputs" {
  let hash1 = compute_page_hash("source", "frontmatter", "config")
  let hash2 = compute_page_hash("source", "frontmatter", "config")
  assert_eq(hash1, hash2)

  // Changing any part changes the hash
  let hash3 = compute_page_hash("different", "frontmatter", "config")
  assert_true(hash1 != hash3)
}
