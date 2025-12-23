// Server Action Types
//
// Server Actions are secure server-side functions that can be called from the client.
// They automatically include CSRF protection and type-safe serialization.

// ============================================================================
// Action Handler Types
// ============================================================================

///|
/// Action handler context - provides request info and utilities
pub struct ActionContext {
  /// Raw request body (JSON string)
  body : String
  /// Request headers
  headers : Array[(String, String)]
  /// Query parameters
  query : Array[(String, String)]
  /// Middleware state
  state : Map[String, @js.Any]
}

///|
/// Create ActionContext from middleware context
pub fn ActionContext::from_mw_ctx(
  mw_ctx : @middleware.MwContext,
  body : String,
) -> ActionContext {
  {
    body,
    headers: mw_ctx.request.headers,
    query: mw_ctx.request.query,
    state: mw_ctx.state,
  }
}

///|
/// Get header value (case-insensitive)
pub fn ActionContext::get_header(
  self : ActionContext,
  name : String,
) -> String? {
  let lower_name = name.to_lower()
  for pair in self.headers {
    if pair.0.to_lower() == lower_name {
      return Some(pair.1)
    }
  }
  None
}

///|
/// Get query parameter
pub fn ActionContext::get_query(self : ActionContext, name : String) -> String? {
  for pair in self.query {
    if pair.0 == name {
      return Some(pair.1)
    }
  }
  None
}

///|
/// Get state value
pub fn ActionContext::get_state(self : ActionContext, key : String) -> @js.Any? {
  self.state.get(key)
}

// ============================================================================
// Action Result Types
// ============================================================================

///|
/// Action result - either success with data or error
pub enum ActionResult {
  /// Success with JSON data
  Success(@js.Any)
  /// Success with redirect
  Redirect(String)
  /// Client error (4xx)
  ClientError(Int, String)
  /// Server error (5xx)
  ServerError(String)
}

///|
/// Create success result
pub fn ActionResult::ok(data : @js.Any) -> ActionResult {
  Success(data)
}

///|
/// Create redirect result
pub fn ActionResult::redirect(url : String) -> ActionResult {
  Redirect(url)
}

///|
/// Create bad request error
pub fn ActionResult::bad_request(message : String) -> ActionResult {
  ClientError(400, message)
}

///|
/// Create unauthorized error
pub fn ActionResult::unauthorized(message? : String) -> ActionResult {
  ClientError(401, message.unwrap_or("Unauthorized"))
}

///|
/// Create forbidden error
pub fn ActionResult::forbidden(message? : String) -> ActionResult {
  ClientError(403, message.unwrap_or("Forbidden"))
}

///|
/// Create not found error
pub fn ActionResult::not_found(message? : String) -> ActionResult {
  ClientError(404, message.unwrap_or("Not Found"))
}

///|
/// Create server error
pub fn ActionResult::server_error(message? : String) -> ActionResult {
  ServerError(message.unwrap_or("Internal Server Error"))
}

// ============================================================================
// Action Handler
// ============================================================================

///|
/// Action handler type - async function that receives ActionContext and returns ActionResult
pub(all) struct ActionHandler(async (ActionContext) -> ActionResult raise Error)

// ============================================================================
// Action Definition
// ============================================================================

///|
/// Server Action definition
pub struct ActionDef {
  /// Action identifier (should be cryptographically secure in production)
  id : String
  /// Action handler
  handler : ActionHandler
  /// Additional middlewares for this action
  middlewares : Array[@middleware.Middleware]
  /// Whether to require JSON Content-Type
  require_json : Bool
}

///|
/// Create action definition with default settings
pub fn ActionDef::new(id : String, handler : ActionHandler) -> ActionDef {
  { id, handler, middlewares: [], require_json: true }
}

///|
/// Add middleware to action
pub fn ActionDef::with_middleware(
  self : ActionDef,
  mw : @middleware.Middleware,
) -> ActionDef {
  let middlewares = self.middlewares.copy()
  middlewares.push(mw)
  { ..self, middlewares, }
}

///|
/// Add multiple middlewares to action
pub fn ActionDef::with_middlewares(
  self : ActionDef,
  mws : Array[@middleware.Middleware],
) -> ActionDef {
  let middlewares = self.middlewares.copy()
  for mw in mws {
    middlewares.push(mw)
  }
  { ..self, middlewares, }
}

///|
/// Set JSON requirement
pub fn ActionDef::with_require_json(
  self : ActionDef,
  require : Bool,
) -> ActionDef {
  { ..self, require_json: require }
}

// ============================================================================
// Action Registry
// ============================================================================

///|
/// Registry for server actions
pub struct ActionRegistry {
  /// Action definitions by ID
  actions : Map[String, ActionDef]
  /// Base path for action endpoints (default: "/_action")
  base_path : String
  /// Allowed origins for CSRF protection
  allowed_origins : Array[String]
}

///|
/// Create new action registry
pub fn ActionRegistry::new(allowed_origins? : Array[String]) -> ActionRegistry {
  {
    actions: {},
    base_path: "/_action",
    allowed_origins: allowed_origins.unwrap_or([]),
  }
}

///|
/// Set base path for action endpoints
pub fn ActionRegistry::with_base_path(
  self : ActionRegistry,
  base_path : String,
) -> ActionRegistry {
  { ..self, base_path, }
}

///|
/// Register an action
pub fn ActionRegistry::register(
  self : ActionRegistry,
  action : ActionDef,
) -> ActionRegistry {
  let actions = self.actions
  actions[action.id] = action
  { ..self, actions, }
}

///|
/// Register multiple actions
pub fn ActionRegistry::register_all(
  self : ActionRegistry,
  defs : Array[ActionDef],
) -> ActionRegistry {
  let actions = self.actions
  for def in defs {
    actions[def.id] = def
  }
  { ..self, actions, }
}

///|
/// Get action by ID
pub fn ActionRegistry::get(self : ActionRegistry, id : String) -> ActionDef? {
  self.actions.get(id)
}

///|
/// Get all action IDs
pub fn ActionRegistry::action_ids(self : ActionRegistry) -> Array[String] {
  self.actions.keys().collect()
}

///|
/// Get action endpoint URL
pub fn ActionRegistry::action_url(self : ActionRegistry, id : String) -> String {
  self.base_path + "/" + id
}
