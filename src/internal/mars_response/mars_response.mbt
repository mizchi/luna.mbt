// Shared Mars response helpers
//
// Keep JS-specific response_resolve usage in one place.

///|
/// Send `@js.Any` as JSON response.
pub fn send_json_any(
  ctx : @mars.Context,
  data : @js.Any,
  status? : Int = 200,
) -> Unit {
  ffi_send_json_any(ctx, data, status)
}

///|
/// Send `{ error: message }` as JSON response.
pub fn send_json_error(
  ctx : @mars.Context,
  message : String,
  status? : Int = 500,
) -> Unit {
  ffi_send_json_error(ctx, message, status)
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
extern "js" fn ffi_send_json_any(
  ctx : @mars.Context,
  data : @js.Any,
  status : Int,
) -> Unit =
  #| (ctx, data, status) => {
  #|   const body = JSON.stringify(data);
  #|   ctx.platform.response_resolve(new Response(body, {
  #|     status,
  #|     headers: {
  #|       'Content-Type': 'application/json',
  #|       'X-Content-Type-Options': 'nosniff'
  #|     }
  #|   }));
  #| }

///|
extern "js" fn ffi_send_json_error(
  ctx : @mars.Context,
  message : String,
  status : Int,
) -> Unit =
  #| (ctx, message, status) => {
  #|   const body = JSON.stringify({ error: message });
  #|   ctx.platform.response_resolve(new Response(body, {
  #|     status,
  #|     headers: {
  #|       'Content-Type': 'application/json',
  #|       'X-Content-Type-Options': 'nosniff'
  #|     }
  #|   }));
  #| }
