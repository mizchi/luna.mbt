// Astra testing helpers: drive a Mars server through its real handler
// pipeline and capture the resulting HTTP response. Phase A only needs
// status + body; headers will be added when assets land in Phase B.

///|
/// Captured HTTP response from a single `invoke()` call.
///
/// `headers_json` carries the response headers as a JSON object string so
/// MoonBit code can decode them without requiring a working JS-Map FFI
/// (the mars JsHeaders side is a `fetch` `Headers` instance, not a
/// MoonBit Map).
pub(all) struct InvokeResult {
  status : Int
  body : String
  headers_json : String
}

///|
/// Lookup a single response header by name (case-insensitive).
pub fn InvokeResult::header(self : InvokeResult, name : String) -> String? {
  ffi_header_lookup(self.headers_json, name)
}

///|
/// JS FFI: case-insensitive header lookup against the captured headers
/// object. Returns `undefined` (mapped to `None`) when the header is absent.
extern "js" fn ffi_header_lookup(
  headers_json : String,
  name : String,
) -> String? =
  #| (headers_json, name) => {
  #|   const obj = JSON.parse(headers_json);
  #|   const target = String(name).toLowerCase();
  #|   for (const key of Object.keys(obj)) {
  #|     if (String(key).toLowerCase() === target) return obj[key];
  #|   }
  #|   return undefined;
  #| }

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
/// and return the response status + text body + headers in one async hop.
extern "js" fn ffi_invoke(
  handler : @mars.AppHandler,
  meth : String,
  url : String,
) -> @js_async.Promise[InvokeResult] =
  #| async (handler, meth, url) => {
  #|   const req = new Request(url, { method: meth });
  #|   const res = await handler(req);
  #|   const body = await res.text();
  #|   const headers = {};
  #|   res.headers.forEach((value, key) => { headers[key] = value; });
  #|   return { status: res.status, body, headers_json: JSON.stringify(headers) };
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
