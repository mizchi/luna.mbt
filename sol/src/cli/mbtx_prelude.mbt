// MBTX Prelude - Helper code injected before .mbtx user code
//
// Provides ergonomic API for .mbtx endpoint handlers:
//   param(key), query(key), method(), path()
//   html(status, body), json(status, body), text(status, body)
//
// Experimental: not documented, API may change.

///|
/// MoonBit source code prepended to each .mbtx file before compilation.
/// Provides the runtime bridge between Sol router and .mbtx handlers.
pub fn mbtx_prelude() -> String {
  let buf = StringBuilder::new()
  buf.write_string("// [sol:mbtx-prelude] Auto-injected helpers\n")
  // env bridge
  buf.write_string(
    (
      #|extern "js" fn _mbtx_get_env(key : String) -> String =
      #|  #| (key) => (globalThis.__MBTX_ENV__ && globalThis.__MBTX_ENV__[key]) || ""
      #|
    ),
  )
  // response bridge
  buf.write_string(
    (
      #|extern "js" fn _mbtx_set_response(status : Int, content_type : String, body : String) -> Unit =
      #|  #| (status, contentType, body) => {
      #|  #|   globalThis.__MBTX_RESPONSE__ = { status, contentType, body };
      #|  #| }
      #|
    ),
  )
  // query string parser
  buf.write_string(
    (
      #|extern "js" fn _mbtx_parse_query(qs : String, key : String) -> String =
      #|  #| (qs, key) => new URLSearchParams(qs).get(key) || ""
      #|
    ),
  )
  buf.write_string("\n")
  // --- User-facing API ---
  buf.write_string(
    (
      #|fn param(key : String) -> String { _mbtx_get_env("PARAM_" + key) }
      #|fn query(key : String) -> String { _mbtx_parse_query(_mbtx_get_env("QUERY_STRING"), key) }
      #|fn request_method() -> String { _mbtx_get_env("REQUEST_METHOD") }
      #|fn request_path() -> String { _mbtx_get_env("PATH_INFO") }
      #|fn query_string() -> String { _mbtx_get_env("QUERY_STRING") }
      #|
    ),
  )
  buf.write_string(
    (
      #|fn html(status : Int, body : String) -> Unit { _mbtx_set_response(status, "text/html; charset=utf-8", body) }
      #|fn json_response(status : Int, body : String) -> Unit { _mbtx_set_response(status, "application/json", body) }
      #|fn text(status : Int, body : String) -> Unit { _mbtx_set_response(status, "text/plain; charset=utf-8", body) }
      #|
    ),
  )
  buf.write_string("// [sol:mbtx-prelude-end]\n\n")
  buf.to_string()
}

///|
/// Prepend prelude to .mbtx source code.
pub fn inject_mbtx_prelude(user_code : String) -> String {
  mbtx_prelude() + user_code
}
