// Sol ISR Handler
//
// Handles ISR (Incremental Static Regeneration) for Sol server.
// Loads ISR manifest and applies cache logic for marked pages.
//
// The ISRManifest / ISRPageMeta types live in `mizchi/astra/isr` so the
// build side (astra/render) and the runtime side (sol/router) share one
// definition. They are re-exported here for back-compat with sol consumers.

///|
pub using @astra_isr {type ISRPageMeta}

///|
pub using @astra_isr {type ISRManifest}

// =============================================================================
// ISR Handler
// =============================================================================

///|
/// ISR handler that wraps cache and manifest
pub struct ISRHandler[Cache] {
  cache : Cache
  manifest : ISRManifest
  dist_dir : String
}

///|
/// Create new ISR handler
pub fn[Cache] ISRHandler::new(
  cache : Cache,
  manifest : ISRManifest,
  dist_dir : String,
) -> ISRHandler[Cache] {
  { cache, manifest, dist_dir }
}

///|
/// Handle ISR request
/// Returns (html, needs_revalidation)
pub async fn[Cache : ISRCache] ISRHandler::handle(
  self : ISRHandler[Cache],
  path : String,
) -> (String?, Bool) {
  // Check if this is an ISR page
  let page_meta = match self.manifest.get_page(path) {
    Some(meta) => meta
    None => return (None, false) // Not an ISR page
  }

  // Generate cache key
  let key = cache_key(path, [])

  // Check cache status
  let entry = self.cache.get(key)
  let now = now_ms()
  let status = check_status(entry, now)
  match status {
    Fresh =>
      // Serve from cache
      match entry {
        Some(e) => (Some(e.html), false)
        None => (None, false)
      }
    Stale =>
      // Serve stale content, schedule revalidation
      match entry {
        Some(e) => (Some(e.html), true)
        None => (None, true)
      }
    Miss => {
      // Try to read from static file
      let html = read_static_page(self.dist_dir, path)
      match html {
        Some(content) => {
          // Cache it
          let new_entry = CacheEntry::new(content, now, page_meta.revalidate)
          self.cache.put(key, new_entry)
          (Some(content), false)
        }
        None => (None, true) // Need to generate
      }
    }
  }
}

///|
/// Update cache after revalidation
pub fn[Cache : ISRCache] ISRHandler::update_cache(
  self : ISRHandler[Cache],
  path : String,
  html : String,
) -> Unit {
  let page_meta = match self.manifest.get_page(path) {
    Some(meta) => meta
    None => return
  }
  let key = cache_key(path, [])
  let entry = CacheEntry::new(html, now_ms(), page_meta.revalidate)
  self.cache.put(key, entry)
}

// =============================================================================
// File Reading (for initial cache population)
// =============================================================================

///|
/// Read static HTML file from dist directory
async fn read_static_page(dist_dir : String, path : String) -> String? {
  // Convert URL path to file path
  let file_path = if path.has_suffix("/") {
    dist_dir + path + "index.html"
  } else {
    dist_dir + path + "/index.html"
  }
  let data : &@io.Data = @x_fs.read_file(file_path) catch { _ => return None }
  let content = data.text() catch { _ => return None }
  Some(content)
}

// =============================================================================
// Manifest Loading
// =============================================================================

///|
/// Load ISR manifest from _luna/isr.json
pub async fn load_manifest(dist_dir : String) -> ISRManifest {
  let manifest_path = dist_dir + "/_luna/isr.json"
  let data : &@io.Data = @x_fs.read_file(manifest_path) catch {
    _ => return ISRManifest::empty()
  }
  let content = data.text() catch { _ => return ISRManifest::empty() }
  parse_manifest(content)
}

///|
/// Parse ISR manifest from JSON string
fn parse_manifest(content : String) -> ISRManifest {
  let json : Json = @json.parse(content) catch {
    _ => return ISRManifest::empty()
  }
  let obj = match json {
    Object(o) => o
    _ => return ISRManifest::empty()
  }
  let version = match obj.get("version") {
    Some(Number(n, ..)) => n.to_int()
    _ => 1
  }
  let pages : Map[String, ISRPageMeta] = {}
  match obj.get("pages") {
    Some(Object(pages_obj)) =>
      for path, page_json in pages_obj {
        match parse_page_meta(page_json) {
          Some(meta) => pages[path] = meta
          None => ()
        }
      }
    _ => ()
  }
  { version, pages }
}

///|
fn parse_page_meta(json : Json) -> ISRPageMeta? {
  let obj = match json {
    Object(o) => o
    _ => return None
  }
  let revalidate = match obj.get("revalidate") {
    Some(Number(n, ..)) => n.to_int()
    _ => return None
  }
  let renderer = match obj.get("renderer") {
    Some(String(s)) => s
    _ => "markdown"
  }
  let source = match obj.get("source") {
    Some(String(s)) => s
    _ => ""
  }
  Some({ revalidate, renderer, source })
}
