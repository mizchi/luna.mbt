// Portable API response types and helpers.
// No JS dependencies — works on all targets.

///|
/// Type-safe API response enum
pub(all) enum ApiResponse {
  Json(Json)
  Redirect(String, Int)
  NotFound(String)
  Error(String, Int)
}

///|
pub fn ApiResponse::to_json(self : ApiResponse) -> Json {
  match self {
    Json(data) => data
    Redirect(url, status) =>
      { "redirect": url.to_json(), "status": status.to_json() }
    NotFound(msg) =>
      { "error": msg.to_json(), "status": (404 : Int).to_json() }
    Error(msg, status) =>
      { "error": msg.to_json(), "status": status.to_json() }
  }
}

///|
pub fn ok(pairs : Array[(String, Json)]) -> ApiResponse {
  let obj : Map[String, Json] = {}
  for pair in pairs {
    obj[pair.0] = pair.1
  }
  ApiResponse::Json(obj.to_json())
}

///|
pub fn redirect_to(url : String, status? : Int = 302) -> ApiResponse {
  ApiResponse::Redirect(url, status)
}

///|
pub fn redirect_permanent_to(url : String) -> ApiResponse {
  ApiResponse::Redirect(url, 301)
}

///|
pub fn not_found_response(message? : String = "Not found") -> ApiResponse {
  ApiResponse::NotFound(message)
}

///|
pub fn error_response(message : String, status? : Int = 500) -> ApiResponse {
  ApiResponse::Error(message, status)
}

///|
pub fn bad_request(message : String) -> ApiResponse {
  ApiResponse::Error(message, 400)
}

///|
pub fn unauthorized(message? : String = "Unauthorized") -> ApiResponse {
  ApiResponse::Error(message, 401)
}

///|
pub fn forbidden(message? : String = "Forbidden") -> ApiResponse {
  ApiResponse::Error(message, 403)
}

// =============================================================================
// Parameter Extraction Helpers
// =============================================================================

///|
pub fn require(
  props : RequestProps,
  name : String,
) -> Result[String, ApiResponse] {
  match props.get_param(name) {
    Some(v) => Ok(v)
    None => Err(bad_request("Missing required parameter: " + name))
  }
}

///|
pub fn require_int(
  props : RequestProps,
  name : String,
) -> Result[Int, ApiResponse] {
  match props.get_param(name) {
    Some(v) =>
      try {
        Ok(@strconv.parse_int(v))
      } catch {
        _ => Err(bad_request("Invalid integer parameter: " + name))
      }
    None => Err(bad_request("Missing required parameter: " + name))
  }
}

///|
pub fn require_query(
  props : RequestProps,
  name : String,
) -> Result[String, ApiResponse] {
  match props.get_query(name) {
    Some(v) => Ok(v)
    None => Err(bad_request("Missing required query parameter: " + name))
  }
}

///|
pub fn optional(
  props : RequestProps,
  name : String,
  default : String,
) -> String {
  props.get_param(name).unwrap_or(default)
}

///|
pub fn optional_query(
  props : RequestProps,
  name : String,
  default : String,
) -> String {
  props.get_query(name).unwrap_or(default)
}
