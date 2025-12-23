/// FileCache tests using MemFSAdapter

///|
test "FileCache::new creates empty cache" {
  let cache = FileCache::new()
  inspect(cache.len(), content="0")
}

///|
test "FileCache reads file and caches" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let cache = FileCache::new()
  fs.write_file_sync("/test.txt", "content")
  let content = cache.read_file(fs, "/test.txt")
  inspect(content, content="content")
  inspect(cache.len(), content="1")

  // Second read should come from cache
  let cached = cache.read_file(fs, "/test.txt")
  inspect(cached, content="content")
}

///|
test "FileCache detects stale file after invalidation" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let cache = FileCache::new()
  fs.write_file_sync("/test.txt", "content")
  let _ = cache.read_file(fs, "/test.txt")

  // Not stale before invalidation
  inspect(cache.is_stale(fs, "/test.txt"), content="false")

  // Invalidate the cache entry
  cache.invalidate("/test.txt")

  // Should be stale after invalidation
  inspect(cache.is_stale(fs, "/test.txt"), content="true")

  // Reading again should cache it
  let _ = cache.read_file(fs, "/test.txt")
  inspect(cache.is_stale(fs, "/test.txt"), content="false")
}

///|
test "FileCache::clear removes all entries" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let cache = FileCache::new()
  fs.write_file_sync("/a.txt", "a")
  fs.write_file_sync("/b.txt", "b")
  let _ = cache.read_file(fs, "/a.txt")
  let _ = cache.read_file(fs, "/b.txt")
  inspect(cache.len(), content="2")
  cache.clear()
  inspect(cache.len(), content="0")
}

///|
test "FileCache::invalidate removes specific entry" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let cache = FileCache::new()
  fs.write_file_sync("/a.txt", "a")
  fs.write_file_sync("/b.txt", "b")
  let _ = cache.read_file(fs, "/a.txt")
  let _ = cache.read_file(fs, "/b.txt")
  inspect(cache.len(), content="2")
  cache.invalidate("/a.txt")
  inspect(cache.len(), content="1")

  // /b.txt should still be cached
  inspect(cache.is_stale(fs, "/b.txt"), content="false")
  // /a.txt should be stale (not in cache)
  inspect(cache.is_stale(fs, "/a.txt"), content="true")
}

///|
test "FileCache persist and restore" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let cache1 = FileCache::new()
  fs.write_file_sync("/test.txt", "content")
  let _ = cache1.read_file(fs, "/test.txt")
  cache1.persist(fs, "/.cache/manifest.json")

  // New cache should restore from disk
  let cache2 = FileCache::new()
  cache2.restore(fs, "/.cache/manifest.json")

  // Should not be stale since mtime matches
  inspect(cache2.is_stale(fs, "/test.txt"), content="false")
  inspect(cache2.len(), content="1")
}

///|
test "FileCache restore handles missing cache file" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let cache = FileCache::new()

  // Should not error when cache file doesn't exist
  cache.restore(fs, "/.cache/nonexistent.json")
  inspect(cache.len(), content="0")
}

///|
test "FileCache is_stale returns true for uncached files" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let cache = FileCache::new()
  fs.write_file_sync("/test.txt", "content")

  // File exists but not cached
  inspect(cache.is_stale(fs, "/test.txt"), content="true")
}

///|
test "FileCache is_stale returns true for deleted files" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let cache = FileCache::new()
  fs.write_file_sync("/test.txt", "content")
  let _ = cache.read_file(fs, "/test.txt")

  // Delete the file
  fs.unlink_sync("/test.txt")

  // Should be stale since file no longer exists
  inspect(cache.is_stale(fs, "/test.txt"), content="true")
}
