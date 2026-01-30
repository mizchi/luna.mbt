// Server Action Router
//
// Registers action endpoints with Mars router.
// Automatically applies CSRF protection.

///|
/// Mars App type alias
pub type App = @mars.Server

///|
/// Mars Context type alias
pub type Ctx = @mars.Context

// ============================================================================
// Action Registration
// ============================================================================

///|
/// Register all actions from registry to Mars app
pub fn register_actions(app : App, registry : ActionRegistry) -> Unit {
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
    app.post(
      path,
      @mars.handler(async fn(c) {
        // Run middleware chain
        let halted = run_action_middlewares(c, middlewares)
        if halted {
          return
        }

        // Get request body (async)
        let body = c.body()

        // Create action context
        let action_ctx = ActionContext::from_ctx(c, body)

        // Execute action handler
        let result : ActionResult = (handler.0)(action_ctx) catch {
          e => ActionResult::server_error(message=e.to_string())
        }

        // Convert result to response
        action_result_to_response(c, result)
      }),
    )
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

///|
/// Run middleware chain for actions
/// Returns true if response was sent (halted), false if should continue
async fn run_action_middlewares(
  c : Ctx,
  middlewares : Array[@middleware.Middleware],
) -> Bool {
  if middlewares.is_empty() {
    return false
  }
  for mw in middlewares {
    if c.is_response_sent() {
      return true
    }
    let @middleware.Middleware(@mars.Handler(h)) = mw
    h(c) catch {
      e => {
        c.text("Internal Server Error: \{e}", status=500)
        return true
      }
    }
  }
  c.is_response_sent()
}

///|
/// Convert action result to HTTP response
fn action_result_to_response(c : Ctx, result : ActionResult) -> Unit {
  // Always set security header for action responses
  c.set_header("X-Content-Type-Options", "nosniff")
  match result {
    Success(data) => {
      // Use FFI to send @js.Any as JSON response
      c.set_header("Content-Type", "application/json")
      ffi_send_json_response(c, data)
    }
    Redirect(url) => {
      // Return JSON with redirect instruction (for JavaScript clients)
      let obj : Map[String, Json] = {}
      obj["redirect"] = Json::string(url)
      c.json(Json::object(obj))
    }
    HttpRedirect(url) =>
      // Return actual HTTP redirect (302 with Location header)
      // For non-JavaScript form submissions (progressive enhancement)
      c.redirect(url)
    ClientError(status, message) => {
      c.set_header("Content-Type", "application/json")
      c.set_status(status)
      let obj : Map[String, Json] = {}
      obj["error"] = Json::string(message)
      c.json(Json::object(obj))
    }
    ServerError(message) => {
      // Log the actual error (implementation depends on logging setup)
      let _ = message
      // Don't expose internal error details in production
      c.set_header("Content-Type", "application/json")
      c.set_status(500)
      let obj : Map[String, Json] = {}
      obj["error"] = Json::string("Internal Server Error")
      c.json(Json::object(obj))
    }
  }
}

///|
/// Send @js.Any as JSON response via FFI
extern "js" fn ffi_send_json_response(c : Ctx, data : @js.Any) -> Unit =
  #| (c, data) => {
  #|   const body = JSON.stringify(data);
  #|   c.platform.response_resolve(new Response(body, {
  #|     status: 200,
  #|     headers: { 'Content-Type': 'application/json', 'X-Content-Type-Options': 'nosniff' }
  #|   }));
  #| }
