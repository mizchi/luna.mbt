// Server Action Router
//
// Registers action endpoints with Hono router.
// Automatically applies CSRF protection.

///|
/// Hono App type alias
pub type App = @hono.Hono[Unit, Unit]

///|
/// Hono Context type alias
pub type Ctx = @hono.Context[Unit, Unit]

// ============================================================================
// Action Registration
// ============================================================================

///|
/// Register all actions from registry to Hono app
pub fn register_actions(app : App, registry : ActionRegistry) -> App {
  let mut result = app
  for id in registry.action_ids() {
    let action = match registry.get(id) {
      Some(a) => a
      None => continue
    }
    let path = registry.action_url(id)
    let allowed_origins = registry.allowed_origins

    // Create CSRF middleware for this action
    let csrf_config = @middleware.CsrfConfig::for_origins(allowed_origins).with_fetch_metadata(
      true,
    )
    // Only require JSON content-type if action.require_json is true
    let csrf_mw = if action.require_json {
      @middleware.csrf_with_config(
        csrf_config.with_content_type("application/json"),
      )
    } else {
      // Allow any content-type (for progressive enhancement with form submissions)
      @middleware.csrf_with_config(csrf_config)
    }

    // Combine CSRF with action-specific middlewares
    let middlewares : Array[@middleware.Middleware] = [csrf_mw]
    for mw in action.middlewares {
      middlewares.push(mw)
    }
    let handler = action.handler
    result = result.post(path, async fn(c) {
      // Run middleware chain
      let mw_result = run_action_middlewares(c, middlewares)
      let mw_ctx = match mw_result {
        @middleware.Flow::Halt(resp) => return send_action_mw_response(c, resp)
        @middleware.Flow::Continue(ctx) => ctx
      }

      // Get request body (async)
      let body = ffi_get_body_async(c.as_any()).wait()

      // Create action context
      let action_ctx = ActionContext::from_mw_ctx(mw_ctx, body)

      // Execute action handler
      let result : ActionResult = (handler.0)(action_ctx) catch {
        e => ActionResult::server_error(message=e.to_string())
      }

      // Convert result to response
      action_result_to_response(c, result)
    })
  }
  result
}

// ============================================================================
// Helper Functions
// ============================================================================

///|
/// Run middleware chain for actions
async fn run_action_middlewares(
  c : Ctx,
  middlewares : Array[@middleware.Middleware],
) -> @middleware.Flow[@middleware.MwContext] {
  if middlewares.is_empty() {
    return @middleware.Flow::Continue(@middleware.MwContext::from_ctx(c))
  }
  let mw_ctx = @middleware.MwContext::from_ctx(c)
  let pipeline = @middleware.pipeline(middlewares)
  @middleware.run(pipeline, mw_ctx) catch {
    e =>
      @middleware.Flow::Halt(
        @middleware.MwResponse::text(e.to_string(), status=500),
      )
  }
}

///|
/// Send middleware response
fn send_action_mw_response(
  c : Ctx,
  resp : @middleware.MwResponse,
) -> @http.Response {
  // Set security header
  ffi_set_header(c.as_any(), "X-Content-Type-Options", "nosniff")
  // Set headers
  for header in resp.headers {
    ffi_set_header(c.as_any(), header.0, header.1)
  }
  // Set content type
  ffi_set_header(c.as_any(), "Content-Type", resp.content_type)
  // Return response
  ffi_create_response(c.as_any(), resp.body, resp.status)
}

///|
/// Convert action result to HTTP response
fn action_result_to_response(c : Ctx, result : ActionResult) -> @http.Response {
  // Always set security header for action responses
  ffi_set_header(c.as_any(), "X-Content-Type-Options", "nosniff")
  match result {
    Success(data) => c.json(data)
    Redirect(url) =>
      // Return JSON with redirect instruction (for JavaScript clients)
      c.json(ffi_json_obj1("redirect", url))
    HttpRedirect(url) =>
      // Return actual HTTP redirect (302 with Location header)
      // For non-JavaScript form submissions (progressive enhancement)
      c.redirect(url)
    ClientError(status, message) => {
      ffi_set_header(c.as_any(), "Content-Type", "application/json")
      ffi_create_response(
        c.as_any(),
        ffi_stringify(ffi_json_obj1("error", message)),
        status,
      )
    }
    ServerError(message) => {
      // Log the actual error (implementation depends on logging setup)
      let _ = message
      // Don't expose internal error details in production
      ffi_set_header(c.as_any(), "Content-Type", "application/json")
      ffi_create_response(
        c.as_any(),
        ffi_stringify(ffi_json_obj1("error", "Internal Server Error")),
        500,
      )
    }
  }
}

// ============================================================================
// FFI
// ============================================================================

///|
extern "js" fn ffi_set_header(
  c : @js.Any,
  name : String,
  value : String,
) -> Unit =
  #| (c, name, value) => c.header(name, value)

///|
extern "js" fn ffi_create_response(
  c : @js.Any,
  body : String,
  status : Int,
) -> @http.Response =
  #| (c, body, status) => c.body(body, status)

///|
/// Get request body asynchronously using Hono's c.req.text()
extern "js" fn ffi_get_body_async(c : @js.Any) -> @js.Promise[String] =
  #| async (c) => {
  #|   try {
  #|     return await c.req.text();
  #|   } catch (e) {
  #|     return "";
  #|   }
  #| }

///|
extern "js" fn ffi_stringify(value : @js.Any) -> String =
  #| (v) => JSON.stringify(v)

///|
/// Create a simple JSON object with one key-value pair
extern "js" fn ffi_json_obj1(key : String, value : String) -> @js.Any =
  #| (key, value) => ({ [key]: value })
