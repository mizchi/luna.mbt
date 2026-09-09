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
  /// Mars Context
  ctx : @mars.Context
  /// Raw request body (JSON string)
  body : String
}

///|
/// Create ActionContext from Mars context
pub fn ActionContext::from_ctx(
  ctx : @mars.Context,
  body : String,
) -> ActionContext {
  { ctx, body }
}

///|
/// Decode an action request body as typed JSON.
pub fn[T : FromJson] decode_action_body(body : String) -> T? {
  let json : Json = @json.parse(body.view()) catch { _ => return None }
  let value : T = @json.from_json(json) catch { _ => return None }
  Some(value)
}

///|
/// Decode an `application/x-www-form-urlencoded` action body as a typed payload.
/// Field values are normalized to JSON strings and decoded through `FromJson`,
/// which keeps the server action contract identical to JSON submissions.
pub fn[T : FromJson] decode_action_form_urlencoded(body : String) -> T? {
  let obj : Map[String, Json] = Map([])
  for pair_view in body.split("&") {
    let pair = pair_view.to_owned()
    if pair.is_empty() {
      continue
    }
    let (raw_key, raw_value) = match pair.split_once("=") {
      Some((key, value)) => (key.to_owned(), value.to_owned())
      None => (pair, "")
    }
    let key = decode_form_component(raw_key)
    if key.is_empty() {
      continue
    }
    obj[key] = Json::string(decode_form_component(raw_value))
  }
  let value : T = @json.from_json(Json::object(obj)) catch { _ => return None }
  Some(value)
}

///|
/// Decode this action request body as typed JSON.
pub fn[T : FromJson] ActionContext::decode_json(self : ActionContext) -> T? {
  decode_action_body(self.body)
}

///|
/// Decode this action request body as `application/x-www-form-urlencoded`.
pub fn[T : FromJson] ActionContext::decode_form_urlencoded(
  self : ActionContext,
) -> T? {
  decode_action_form_urlencoded(self.body)
}

///|
fn decode_form_component(s : String) -> String {
  let chars = s.to_array()
  let len = chars.length()
  let sb = StringBuilder(size_hint=len)
  let mut i = 0
  while i < len {
    let c = chars[i]
    let has_percent_triplet = c == '%' &&
      i + 2 < len &&
      is_hex_digit(chars[i + 1]) &&
      is_hex_digit(chars[i + 2])
    if c == '+' {
      sb.write_char(' ')
      i += 1
    } else if has_percent_triplet {
      let (decoded, next_i) = decode_percent_encoded_bytes(chars, i, len)
      sb.write_string(decoded)
      i = next_i
    } else {
      sb.write_char(c)
      i += 1
    }
  }
  sb.to_string()
}

///|
fn decode_percent_encoded_bytes(
  chars : Array[Char],
  start : Int,
  len : Int,
) -> (String, Int) {
  let bytes : Array[Byte] = []
  let mut i = start
  while i + 2 < len && chars[i] == '%' {
    let hi = chars[i + 1]
    let lo = chars[i + 2]
    if !(is_hex_digit(hi) && is_hex_digit(lo)) {
      break
    }
    let byte = hex_digit_to_int(hi) * 16 + hex_digit_to_int(lo)
    bytes.push(byte.to_byte())
    i += 3
  }
  (decode_percent_bytes(bytes), i)
}

///|
fn decode_percent_bytes(bytes : Array[Byte]) -> String {
  let raw = Bytes::from_array(bytes)
  @utf8.decode(raw) catch {
    _ => {
      let fallback : Array[Char] = []
      for b in bytes {
        fallback.push(b.to_int().unsafe_to_char())
      }
      String::from_array(fallback)
    }
  }
}

///|
fn is_hex_digit(c : Char) -> Bool {
  (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')
}

///|
fn hex_digit_to_int(c : Char) -> Int {
  if c >= '0' && c <= '9' {
    c.to_int() - '0'.to_int()
  } else if c >= 'a' && c <= 'f' {
    c.to_int() - 'a'.to_int() + 10
  } else {
    c.to_int() - 'A'.to_int() + 10
  }
}

///|
/// Get header value (case-insensitive)
pub fn ActionContext::get_header(
  self : ActionContext,
  name : String,
) -> String? {
  self.ctx.header(name)
}

///|
/// Get query parameter
pub fn ActionContext::get_query(self : ActionContext, name : String) -> String? {
  self.ctx.query(name)
}

///|
/// Get state value
pub fn ActionContext::get_state(self : ActionContext, key : String) -> String? {
  self.ctx.get(key)
}

///|
/// Set state value
pub fn ActionContext::set_state(
  self : ActionContext,
  key : String,
  value : String,
) -> Unit {
  self.ctx.set(key, value)
}

// ============================================================================
// Action Result Types
// ============================================================================

///|
/// Internal action result representation.
priv enum ActionResultKind {
  JsonSuccess(Json)
  ClientRedirect(String)
  HttpRedirectResult(String)
  ClientFailure(Int, String)
  ServerFailure(String)
}

///|
/// Action result returned by server action handlers.
pub struct ActionResult {
  priv kind : ActionResultKind
}

///|
/// Create success result from a typed JSON-serializable payload.
pub fn[T : ToJson] ActionResult::json(data : T) -> ActionResult {
  { kind: JsonSuccess(data.to_json()) }
}

///|
/// Create redirect result (returns JSON for JavaScript clients)
pub fn ActionResult::redirect(url : String) -> ActionResult {
  { kind: ClientRedirect(url) }
}

///|
/// Create HTTP redirect result (returns 302 with Location header)
/// Use this for non-JavaScript form submissions (progressive enhancement)
pub fn ActionResult::http_redirect(url : String) -> ActionResult {
  { kind: HttpRedirectResult(url) }
}

///|
/// Create bad request error
pub fn ActionResult::bad_request(message : String) -> ActionResult {
  { kind: ClientFailure(400, message) }
}

///|
/// Create validation error
pub fn ActionResult::validation_error(message : String) -> ActionResult {
  { kind: ClientFailure(422, message) }
}

///|
/// Create unauthorized error
pub fn ActionResult::unauthorized(message? : String) -> ActionResult {
  { kind: ClientFailure(401, message.unwrap_or("Unauthorized")) }
}

///|
/// Create forbidden error
pub fn ActionResult::forbidden(message? : String) -> ActionResult {
  { kind: ClientFailure(403, message.unwrap_or("Forbidden")) }
}

///|
/// Create not found error
pub fn ActionResult::not_found(message? : String) -> ActionResult {
  { kind: ClientFailure(404, message.unwrap_or("Not Found")) }
}

///|
/// Create server error
pub fn ActionResult::server_error(message? : String) -> ActionResult {
  { kind: ServerFailure(message.unwrap_or("Internal Server Error")) }
}

// ============================================================================
// Action Handler
// ============================================================================

///|
/// Action handler type - async function that receives ActionContext and returns ActionResult
pub(all) struct ActionHandler(async (ActionContext) -> ActionResult raise Error)

// ============================================================================
// ActionKey (generated typed action identifiers)
// ============================================================================

///|
/// Action key implemented by generated marker types.
pub(open) trait ActionKey {
  /// Stable action identifier used in the HTTP endpoint.
  fn id(Self) -> String

  /// Base path for action endpoints.
  fn base_path(Self) -> String
}

///|
/// Phantom-typed action key for generated request/response contracts.
pub struct TypedActionKey[Req, Res] {
  id : String
  base_path : String
  _request : Req?
  _response : Res?
}

///|
fn[Req, Res] TypedActionKey::new(
  id : String,
  base_path? : String = "/_action",
) -> TypedActionKey[Req, Res] {
  { id, base_path, _request: None, _response: None }
}

///|
pub fn[Req, Res, K : ActionKey] TypedActionKey::from_key(
  key : K,
) -> TypedActionKey[Req, Res] {
  TypedActionKey::new(key.id(), base_path=key.base_path())
}

///|
pub fn[Req, Res] TypedActionKey::id(self : TypedActionKey[Req, Res]) -> String {
  self.id
}

///|
pub fn[Req, Res] TypedActionKey::base_path(
  self : TypedActionKey[Req, Res],
) -> String {
  self.base_path
}

///|
pub impl[Req, Res] ActionKey for TypedActionKey[Req, Res] with fn id(self) {
  self.id
}

///|
pub impl[Req, Res] ActionKey for TypedActionKey[Req, Res] with fn base_path(
  self,
) {
  self.base_path
}

///|
pub fn[Req, Res] typed_action_url(key : TypedActionKey[Req, Res]) -> String {
  key.base_path() + "/" + key.id()
}

///|
/// Get the stable action identifier from a generated action key.
pub fn[K : ActionKey] action_id(key : K) -> String {
  key.id()
}

///|
/// Get the full endpoint URL from a generated action key.
pub fn[K : ActionKey] action_url(key : K) -> String {
  key.base_path() + "/" + key.id()
}

// ============================================================================
// Action Definition
// ============================================================================

///|
/// Server Action definition
pub struct ActionDef {
  /// Action identifier (should be cryptographically secure in production)
  priv id : String
  /// Action handler
  priv handler : ActionHandler
  /// Additional middlewares for this action
  priv middlewares : Array[@middleware.Middleware]
  /// Whether to require JSON Content-Type
  priv require_json : Bool
}

///|
/// Create action definition from a generated action key.
pub fn[K : ActionKey] ActionDef::from_key(
  key : K,
  handler : ActionHandler,
) -> ActionDef {
  { id: key.id(), handler, middlewares: [], require_json: true }
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
  priv actions : Map[String, ActionDef]
  /// Base path for action endpoints (default: "/_action")
  priv base_path : String
  /// Allowed origins for CSRF protection
  priv allowed_origins : Array[String]
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
/// Register an action from a generated action key and handler
pub fn[K : ActionKey] ActionRegistry::register_key(
  self : ActionRegistry,
  key : K,
  handler : ActionHandler,
) -> ActionRegistry {
  self.register(ActionDef::from_key(key, handler))
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
fn ActionRegistry::get(self : ActionRegistry, id : String) -> ActionDef? {
  self.actions.get(id)
}

///|
/// Get all action IDs
pub fn ActionRegistry::action_ids(self : ActionRegistry) -> Array[String] {
  self.actions.keys().collect()
}

///|
/// Get action endpoint URL
fn ActionRegistry::action_url(self : ActionRegistry, id : String) -> String {
  self.base_path + "/" + id
}
