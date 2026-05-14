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
    let middleware_chain = @middleware.pipeline(middlewares)
    let handler = action.handler
    app.post(
      path,
      @mars.handler(async fn(c) {
        // Run middleware chain
        let halted = @middleware.run_or_500(middleware_chain, c)
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

///|
/// Convert action result to HTTP response
fn action_result_to_response(c : Ctx, result : ActionResult) -> Unit {
  // Always set security header for action responses
  c.set_header("X-Content-Type-Options", "nosniff")
  match result.kind {
    JsonSuccess(data) => @mars_response.send_json_any(c, data)
    ClientRedirect(url) => {
      // Return JSON with redirect instruction (for JavaScript clients)
      let obj : Map[String, Json] = {}
      obj["redirect"] = Json::string(url)
      c.json(Json::object(obj))
    }
    HttpRedirectResult(url) =>
      // Return actual HTTP redirect (302 with Location header)
      // For non-JavaScript form submissions (progressive enhancement)
      c.redirect(url)
    ClientFailure(status, message) =>
      @mars_response.send_json_error(c, message, status~)
    ServerFailure(message) => {
      // Log the actual error (implementation depends on logging setup)
      let _ = message
      // Don't expose internal error details in production
      @mars_response.send_internal_error(c)
    }
  }
}
