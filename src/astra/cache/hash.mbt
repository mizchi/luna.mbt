///|
/// FNV-1a Hash Implementation for Cache Keys
///
/// NOTE: Hash utilities moved to core/cache/hash.mbt for sharing with Sol.
/// This file re-exports for backward compatibility.

///|
/// FNV-1a 32-bit hash
pub fn fnv1a(data : String) -> String {
  @core_cache.fnv1a(data)
}

///|
/// Compute hash for a page's cache key
pub fn compute_page_hash(
  source_content : String,
  frontmatter_json : String,
  config_hash : String,
) -> String {
  @core_cache.hash_strings([source_content, frontmatter_json, config_hash])
}

///|
/// Compute hash for config (used to invalidate all caches on config change)
pub fn compute_config_hash(config : @astra.SsgConfig) -> String {
  // Hash key config fields that affect rendering
  let parts = [
    config.title,
    config.base_url,
    if config.trailing_slash {
      "true"
    } else {
      "false"
    },
    config.theme.primary_color.unwrap_or(""),
  ]
  fnv1a(parts.join("\u0000"))
}
