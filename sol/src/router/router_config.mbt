// Router configuration and chunk manifest

///|
/// Chunk manifest entry (from Rolldown/Vite manifest.json)
/// Maps entry files to their output chunks and dependencies
pub struct ChunkManifestEntry {
  /// Output file path (e.g., "counter.js")
  file : String
  /// Import dependencies (e.g., ["_shared/client-abc123.js"])
  imports : Array[String]
}

///|
/// Create a chunk manifest entry
pub fn ChunkManifestEntry::new(
  file : String,
  imports : Array[String],
) -> ChunkManifestEntry {
  { file, imports }
}

///|
/// Chunk manifest - maps entry names to their output info
/// Used to resolve shared chunk dependencies for preloading
pub struct ChunkManifest {
  /// Map of entry name -> manifest entry
  entries : Map[String, ChunkManifestEntry]
  /// Base URL prefix for chunks (e.g., "/static/")
  base_url : String
}

///|
/// Create empty chunk manifest
pub fn ChunkManifest::empty() -> ChunkManifest {
  { entries: {}, base_url: "/static/" }
}

///|
/// Create chunk manifest with base URL
pub fn ChunkManifest::new(base_url : String) -> ChunkManifest {
  { entries: {}, base_url }
}

///|
/// Add entry to manifest
pub fn ChunkManifest::add(
  self : ChunkManifest,
  name : String,
  entry : ChunkManifestEntry,
) -> Unit {
  self.entries[name] = entry
}

///|
/// Get all chunk URLs for an entry (including dependencies)
pub fn ChunkManifest::get_chunks(
  self : ChunkManifest,
  entry_url : String,
) -> Array[String] {
  // Extract entry name from URL (e.g., "/static/counter.js" -> "counter.js")
  let entry_name = extract_entry_name(entry_url, self.base_url)
  match self.entries.get(entry_name) {
    Some(entry) => {
      let chunks : Array[String] = []
      // Add all import dependencies with base URL prefix
      for imp in entry.imports {
        let chunk_url = self.base_url + imp
        if !(chunks.contains(chunk_url)) {
          chunks.push(chunk_url)
        }
      }
      chunks
    }
    None => []
  }
}

///|
fn extract_entry_name(url : String, base_url : String) -> String {
  if url.has_prefix(base_url) {
    // Remove base_url prefix
    let result = url[base_url.length():].to_string() catch { _ => url }
    result
  } else {
    // Find last slash and get filename
    let mut last_slash = -1
    let chars = url.to_array()
    for i = 0; i < chars.length(); i = i + 1 {
      if chars[i] == '/' {
        last_slash = i
      }
    }
    if last_slash >= 0 && last_slash < url.length() - 1 {
      let result = url[last_slash + 1:].to_string() catch { _ => url }
      result
    } else {
      url
    }
  }
}

///|
/// Parse chunk manifest from JSON string (Rolldown/Vite format)
pub fn ChunkManifest::parse(
  json_str : String,
  base_url : String,
) -> ChunkManifest? {
  let json : Json = @json.parse(json_str) catch { _ => return None }
  let obj = match json {
    Object(o) => o
    _ => return None
  }
  let manifest = ChunkManifest::new(base_url)
  for entry in obj {
    let name = entry.0
    let entry_obj = match entry.1 {
      Object(o) => o
      _ => continue
    }
    // Get "file" field
    let file = match entry_obj.get("file") {
      Some(String(s)) => s
      _ => continue
    }
    // Get "imports" field (optional)
    let imports : Array[String] = match entry_obj.get("imports") {
      Some(Array(arr)) => {
        let result : Array[String] = []
        for item in arr {
          match item {
            String(s) => result.push(s)
            _ => continue
          }
        }
        result
      }
      _ => []
    }
    manifest.add(name, { file, imports })
  }
  Some(manifest)
}

///|
/// Router configuration for customizing routing behavior
pub struct RouterConfig {
  /// Prefix for page titles (e.g., "MyApp - ")
  title_prefix : String
  /// Default title when page has no title
  default_title : String
  /// Default head HTML (styles, meta tags, etc.)
  default_head : String
  /// URL for the island loader script
  loader_url : String
  /// URL for the Web Components loader script
  wc_loader_url : String
  /// Enable modulepreload for island scripts (default: true)
  enable_preload : Bool
  /// Enable streaming SSR for full-page responses (default: false)
  /// Note: fragment responses and ISR(with cache) are always non-streaming.
  /// Note: streaming uses `root_template` when `__LUNA_MAIN__` exists;
  ///       otherwise it falls back to built-in page shell.
  enable_streaming : Bool
  /// Additional library URLs to preload (e.g., ["/static/lib.js"])
  preload_libs : Array[String]
  /// Chunk manifest for resolving shared chunk dependencies
  chunk_manifest : ChunkManifest?
  /// Root HTML template with placeholders:
  /// - __LUNA_TITLE__ : Page title
  /// - __LUNA_PRELOAD__ : Modulepreload tags
  /// - __LUNA_HEAD__ : Custom head HTML
  /// - __LUNA_MAIN__ : Main content
  root_template : String
  /// ISR cache for incremental static regeneration (None = disabled)
  /// Currently uses MemoryCache; can be replaced with KVCache for production
  isr_cache : @isr.MemoryCache?
  /// Cache strategy for ISR pages (CDN SWR, Hybrid, or App-only ISR)
  /// Controls Cache-Control headers and CDN/app layer interaction.
  /// None = use AppIsr (default, backward compatible)
  cache_strategy : @isr.CDNCacheStrategy?
  /// Server island registry for deferred server-side rendering
  /// None = no server islands (default)
  server_islands : ServerIslandRegistry?
}

///|
/// Default root HTML template
fn default_root_template() -> String {
  "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"><title>__LUNA_TITLE__</title>__LUNA_PRELOAD____LUNA_HEAD__</head><body><div id=\"__sol__\">__LUNA_MAIN__</div></body></html>"
}

///|
/// Create default router configuration
pub fn RouterConfig::default() -> RouterConfig {
  {
    title_prefix: "",
    default_title: "App",
    default_head: "",
    loader_url: "/__sol__/loader.js",
    wc_loader_url: "/__sol__/wc-loader.js",
    enable_preload: true,
    enable_streaming: false,
    preload_libs: [],
    chunk_manifest: None,
    root_template: default_root_template(),
    isr_cache: None,
    cache_strategy: None,
    server_islands: None,
  }
}

///|
/// Set ISR cache for incremental static regeneration
pub fn RouterConfig::with_isr_cache(
  self : RouterConfig,
  cache : @isr.MemoryCache,
) -> RouterConfig {
  { ..self, isr_cache: Some(cache) }
}

///|
/// Set chunk manifest for resolving shared chunk dependencies
pub fn RouterConfig::with_chunk_manifest(
  self : RouterConfig,
  manifest : ChunkManifest,
) -> RouterConfig {
  { ..self, chunk_manifest: Some(manifest) }
}

///|
/// Add library URLs to preload
pub fn RouterConfig::with_preload_libs(
  self : RouterConfig,
  libs : Array[String],
) -> RouterConfig {
  { ..self, preload_libs: libs }
}

///|
/// Enable/disable streaming SSR for full-page responses.
pub fn RouterConfig::with_streaming_ssr(
  self : RouterConfig,
  enabled? : Bool = true,
) -> RouterConfig {
  { ..self, enable_streaming: enabled }
}

///|
/// Set default head HTML
pub fn RouterConfig::with_default_head(
  self : RouterConfig,
  head : String,
) -> RouterConfig {
  { ..self, default_head: head }
}

///|
/// Set loader URL
pub fn RouterConfig::with_loader_url(
  self : RouterConfig,
  url : String,
) -> RouterConfig {
  { ..self, loader_url: url }
}

///|
/// Set Web Components loader URL
pub fn RouterConfig::with_wc_loader_url(
  self : RouterConfig,
  url : String,
) -> RouterConfig {
  { ..self, wc_loader_url: url }
}

///|
/// Set title prefix
pub fn RouterConfig::with_title_prefix(
  self : RouterConfig,
  prefix : String,
) -> RouterConfig {
  { ..self, title_prefix: prefix }
}

///|
/// Set default title
pub fn RouterConfig::with_default_title(
  self : RouterConfig,
  title : String,
) -> RouterConfig {
  { ..self, default_title: title }
}

///|
/// Set cache strategy for ISR pages
pub fn RouterConfig::with_cache_strategy(
  self : RouterConfig,
  strategy : @isr.CDNCacheStrategy,
) -> RouterConfig {
  { ..self, cache_strategy: Some(strategy) }
}

///|
/// Set server island registry for deferred rendering
pub fn RouterConfig::with_server_islands(
  self : RouterConfig,
  registry : ServerIslandRegistry,
) -> RouterConfig {
  { ..self, server_islands: Some(registry) }
}

///|
/// Set root HTML template
/// Template placeholders:
/// - __LUNA_TITLE__ : Page title
/// - __LUNA_PRELOAD__ : Modulepreload tags
/// - __LUNA_HEAD__ : Custom head HTML
/// - __LUNA_MAIN__ : Main content
pub fn RouterConfig::with_root_template(
  self : RouterConfig,
  template : String,
) -> RouterConfig {
  { ..self, root_template: template }
}

///|
fn resolve_router_config(
  config : RouterConfig?,
  title_prefix? : String = "",
  default_title? : String = "App",
  default_head? : String = "",
  loader_url? : String = "/__sol__/loader.js",
  wc_loader_url? : String = "/__sol__/wc-loader.js",
) -> RouterConfig {
  match config {
    Some(existing) => existing
    None =>
      RouterConfig::default()
      .with_title_prefix(title_prefix)
      .with_default_title(default_title)
      .with_default_head(default_head)
      .with_loader_url(loader_url)
      .with_wc_loader_url(wc_loader_url)
  }
}
