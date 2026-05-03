// Sol ISR Middleware
//
// Middleware for handling ISR (Incremental Static Regeneration) in Sol.
// Integrates ISR handler with Sol's middleware pipeline.

// =============================================================================
// ISR Middleware
// =============================================================================

///|
/// ISR middleware configuration
pub struct ISRMiddlewareConfig {
  /// Distribution directory (where static files are)
  dist_dir : String
  /// Whether to enable ISR
  enabled : Bool
}

///|
/// Default ISR middleware configuration
pub fn ISRMiddlewareConfig::default() -> ISRMiddlewareConfig {
  { dist_dir: "dist", enabled: true }
}

// =============================================================================
// Global ISR Handler (singleton for the server)
// =============================================================================

///|
let isr_handler_store : Ref[ISRHandler[MemoryCache]?] = Ref::new(None)

///|
/// Initialize ISR handler (call once at server startup)
pub async fn init_isr(dist_dir : String) -> ISRHandler[MemoryCache] {
  let cache = MemoryCache::new()
  let manifest = load_manifest(dist_dir)
  let handler = ISRHandler::new(cache, manifest, dist_dir)
  isr_handler_store.val = Some(handler)
  handler
}

///|
/// Get the global ISR handler
pub fn get_isr_handler() -> ISRHandler[MemoryCache]? {
  isr_handler_store.val
}

// =============================================================================
// ISR Request Handler
// =============================================================================

///|
/// Handle ISR for a request path
/// Returns Some(html) if ISR handled, None otherwise
pub async fn handle_isr_request(path : String) -> (String?, Bool) {
  match get_isr_handler() {
    Some(handler) => handler.handle(path)
    None => (None, false)
  }
}

///|
/// Schedule background revalidation for a path
pub fn schedule_revalidation(path : String) -> Unit {
  match get_isr_handler() {
    Some(handler) =>
      handler.cache.schedule_revalidation(async fn() {
        // In a real implementation, this would call SSG to regenerate
        // For now, just log
        println("ISR: Revalidating \{path}")
        // Read fresh content from disk (assumes SSG has regenerated)
        let fresh_html = read_static_page(handler.dist_dir, path)
        match fresh_html {
          Some(html) => handler.update_cache(path, html)
          None => ()
        }
      })
    None => ()
  }
}

// =============================================================================
// Hono Integration
// =============================================================================

///|
/// Create ISR handler for Hono
/// Returns a function that can be used as Hono middleware
pub async fn create_isr_middleware(
  dist_dir : String,
) -> (@hono.Context[Unit, Unit]) -> @js.Promise[Unit]? {
  // Initialize ISR handler
  let _ = init_isr(dist_dir)

  // Return middleware function — note: the returned closure is sync
  // because Hono expects sync middleware. ISR handle is called via
  // handle_isr_request_sync which uses the pre-loaded cache.
  fn(ctx : @hono.Context[Unit, Unit]) -> @js.Promise[Unit]? {
    let path = ffi_get_req_path(ctx.as_any())

    // Check ISR from cache (sync path — cache is already populated)
    let handler = match get_isr_handler() {
      Some(h) => h
      None => return None
    }
    let page_meta = match handler.manifest.get_page(path) {
      Some(meta) => meta
      None => return None
    }
    let key = cache_key(path, [])
    let entry = handler.cache.get(key)
    let now = now_ms()
    let status = check_status(entry, now)
    let (html, needs_revalidation) = match status {
      Fresh =>
        match entry {
          Some(e) => (Some(e.html), false)
          None => (None, false)
        }
      Stale =>
        match entry {
          Some(e) => (Some(e.html), true)
          None => (None, true)
        }
      Miss => {
        // On cache miss, we can't do async file read in sync context
        // Return None to fall through to next handler
        ignore(page_meta)
        (None, false)
      }
    }
    match html {
      Some(content) => {
        if needs_revalidation {
          schedule_revalidation(path)
        }
        Some(ffi_return_html(ctx.as_any(), content))
      }
      None => None
    }
  }
}

///|
extern "js" fn ffi_get_req_path(ctx : @js.Any) -> String =
  #| (c) => new URL(c.req.url).pathname

///|
extern "js" fn ffi_return_html(
  ctx : @js.Any,
  html : String,
) -> @js.Promise[Unit] =
  #| (c, html) => c.html(html)
