// Shared Mars response helpers
//
// Keep JSON response behavior (status + headers) in one place.

///|
/// Send `@js.Any` as JSON response.
pub fn send_json_any(
  ctx : @mars.Context,
  data : @js.Any,
  status? : Int = 200,
) -> Unit {
  send_json_text(ctx, ffi_json_stringify(data), status)
}

///|
/// Send `{ error: message }` as JSON response.
pub fn send_json_error(
  ctx : @mars.Context,
  message : String,
  status? : Int = 500,
) -> Unit {
  send_json_text(ctx, ffi_json_stringify_error(message), status)
}

///|
/// Send 500 JSON error response.
pub fn send_internal_error(
  ctx : @mars.Context,
  message? : String = "Internal Server Error",
) -> Unit {
  send_json_error(ctx, message, status=500)
}

///|
fn send_json_text(
  ctx : @mars.Context,
  body : String,
  status : Int,
) -> Unit {
  ctx.set_header("Content-Type", "application/json")
  ctx.set_header("X-Content-Type-Options", "nosniff")
  ctx.text(body, status~)
}

///|
extern "js" fn ffi_json_stringify(data : @js.Any) -> String =
  #| (data) => JSON.stringify(data)

///|
extern "js" fn ffi_json_stringify_error(message : String) -> String =
  #| (message) => JSON.stringify({ error: message })
