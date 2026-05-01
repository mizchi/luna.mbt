// Astra testing helpers: drive a Mars server through its real handler
// pipeline and capture the resulting HTTP response. Phase A only needs
// status + body; headers will be added when assets land in Phase B.

///|
/// Captured HTTP response from a single `invoke()` call.
pub(all) struct InvokeResult {
  status : Int
  body : String
}

///|
/// JS FFI: ensure the global symbol that mars's `to_handler` expects exists.
///
/// Mars references `moonbitlang$async$internal$event_loop$$reschedule` via an
/// inline JS string. In `moon test` bundles the symbol is mangled differently
/// (`moonbitlang5async8internal11event__loop10reschedule`) so the global is
/// missing. Sol's router test FFI uses the same noop stub.
extern "js" fn ffi_ensure_reschedule_symbol() -> Unit =
  #| () => {
  #|   if (typeof globalThis.moonbitlang$async$internal$event_loop$$reschedule !== "function") {
  #|     globalThis.moonbitlang$async$internal$event_loop$$reschedule = () => {};
  #|   }
  #| }

///|
/// JS FFI: build a `Request`, dispatch it through the Mars `AppHandler`,
/// and return the response status + text body in one async hop.
extern "js" fn ffi_invoke(
  handler : @mars.AppHandler,
  meth : String,
  url : String,
) -> @js_async.Promise[InvokeResult] =
  #| async (handler, meth, url) => {
  #|   const req = new Request(url, { method: meth });
  #|   const res = await handler(req);
  #|   const body = await res.text();
  #|   return { status: res.status, body };
  #| }

///|
/// Invoke a Mars `Server` with a synthetic request and return the response.
///
/// The path may be absolute (`/foo`) or fully qualified (`http://host/foo`);
/// bare paths are prefixed with `http://localhost` so `new Request` accepts
/// them.
pub async fn invoke(
  app : @mars.Server,
  meth~ : String = "GET",
  path~ : String,
) -> InvokeResult {
  ffi_ensure_reschedule_symbol()
  let handler = app.to_handler()
  let url = if path.has_prefix("http") {
    path
  } else {
    "http://localhost" + path
  }
  ffi_invoke(handler, meth, url).wait()
}
