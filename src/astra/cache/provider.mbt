// Local File System Provider for Astra SSG
//
// Implements BuildStateProvider using local file system hashes.

///|
/// Astra version for cache invalidation
pub let astra_version : String = "0.1.0"

///|
/// Local file system provider for build state
pub(all) struct LocalFileProvider {
  docs_dir : String
  cwd : String
  exclude : Array[String]
  // Cached state (computed lazily)
  mut cached_state : String?
}

///|
/// Create a new local file provider
pub fn LocalFileProvider::new(
  docs_dir : String,
  cwd : String,
  exclude : Array[String],
) -> LocalFileProvider {
  { docs_dir, cwd, exclude, cached_state: None }
}

///|
/// Implement BuildStateProvider for LocalFileProvider
pub impl @core_cache.BuildStateProvider for LocalFileProvider with get_content_state(
  self,
) {
  match self.cached_state {
    Some(state) => state
    None => {
      let state = compute_content_hash(self.docs_dir, self.cwd, self.exclude)
      self.cached_state = Some(state)
      state
    }
  }
}

///|
pub impl @core_cache.BuildStateProvider for LocalFileProvider with describe_state(
  self,
) {
  let state = self.get_content_state()
  "Local files (hash: \{state})"
}

// =============================================================================
// Convenience Functions
// =============================================================================

///|
/// Check build state using local file provider
pub fn check_local_build_state(
  config : @astra.SsgConfig,
  cwd : String,
  cache_dir : String,
) -> @core_cache.BuildStateCheck {
  let provider = LocalFileProvider::new(config.docs_dir, cwd, config.exclude)
  let config_hash = compute_config_hash(config)
  @core_cache.check_build_state(provider, config_hash, cache_dir, load_manifest)
}

///|
/// Load manifest from cache directory (wrapper for core function)
fn load_manifest(cache_dir : String) -> @core_cache.BuildManifest? {
  let path = @path.join2(cache_dir, "build-manifest.json")
  guard @fs.existsSync(path) else { return None }
  let content : String = @fs.readFileSync(path).to_string() catch {
    _ => return None
  }
  @core_cache.BuildManifest::from_json(content)
}

///|
/// Save manifest to cache directory
pub fn save_manifest(
  cache_dir : String,
  config : @astra.SsgConfig,
  cwd : String,
) -> Unit {
  let provider = LocalFileProvider::new(config.docs_dir, cwd, config.exclude)
  let manifest = @core_cache.BuildManifest::new(
    tool_version=astra_version,
    config_hash=compute_config_hash(config),
    content_state=provider.get_content_state(),
    built_at=get_current_timestamp(),
  )
  // Ensure cache directory exists
  @fs.mkdirSync(cache_dir, recursive=true) catch {
    _ => ()
  }
  let path = @path.join2(cache_dir, "build-manifest.json")
  @fs.writeFileSync(path, @js.any(manifest.to_json())) catch {
    _ => ()
  }
}

///|
/// Get current ISO 8601 timestamp
pub fn get_current_timestamp() -> String {
  ffi_get_iso_timestamp()
}

///|
extern "js" fn ffi_get_iso_timestamp() -> String =
  #| () => new Date().toISOString()
