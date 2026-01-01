///|
/// Cache Manager for Disk-based Build Cache
///
/// Manages cached rendered HTML to skip unchanged pages.
/// Uses disk_cache.mbt for the underlying storage.

///|
/// Default cache directory name
let default_cache_dir : String = ".sol-cache"

///|
/// Cache manager wrapping core DiskCache
pub(all) struct CacheManager {
  cache : DiskCache[@fs_adapter.NodeFsAdapter]
  enabled : Bool
}

///|
/// Create a new cache manager
pub fn CacheManager::new(
  cwd : String,
  config : @ssg.SsgConfig,
  enabled? : Bool = true,
) -> CacheManager {
  let cache_dir = @path.join2(cwd, default_cache_dir)
  let config_hash = compute_config_hash(config)
  let fs = @fs_adapter.NodeFsAdapter::new()
  let cache = DiskCache::new(fs, cache_dir~, config_hash~, enabled~)
  CacheManager::{ cache, enabled }
}

///|
/// Create cache manager with custom FileSystem (for testing)
pub fn[F : @env.FileSystem] CacheManager::with_fs(
  fs : F,
  cache_dir : String,
  config_hash : String,
  enabled? : Bool = true,
) -> DiskCache[F] {
  DiskCache::new(fs, cache_dir~, config_hash~, enabled~)
}

///|
/// Get cached HTML if available and valid
pub fn CacheManager::get(
  self : CacheManager,
  url_path : String,
  source_hash : String,
) -> String? {
  if not(self.enabled) {
    return None
  }
  match self.cache.get_with_hash(url_path, source_hash) {
    Hit(content) => Some(content)
    _ => None
  }
}

///|
/// Store rendered HTML in cache
pub fn CacheManager::set(
  self : CacheManager,
  url_path : String,
  source_hash : String,
  html : String,
) -> Unit {
  if not(self.enabled) {
    return
  }
  self.cache.set(url_path, source_hash, html)
}

///|
/// Save cache metadata to disk
pub fn CacheManager::save(self : CacheManager) -> Unit {
  if not(self.enabled) {
    return
  }
  self.cache.save()
}

///|
/// Clear all cache
pub fn CacheManager::clear(self : CacheManager) -> Unit {
  self.cache.clear()
}

///|
/// Get cache statistics
pub fn CacheManager::stats(self : CacheManager) -> (Int, Int) {
  self.cache.stats()
}
