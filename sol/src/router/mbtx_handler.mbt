// MBTX Route Handler
//
// Executes pre-built .mbtx JS artifacts in-process via dynamic import().
// Build step transforms the IIFE output into an ESM module with render() export.
// The render function reads __MBTX_ENV__ and returns __MBTX_RESPONSE__.

///|
/// Configuration for a .mbtx route
pub(all) struct MbtxRoute {
  /// URL pattern (e.g., "/hello", "/api/:id")
  path : String
  /// Path to the built ESM JS artifact (.mjs)
  js_path : String
}

///|
/// Register .mbtx routes to the app.
/// Each route calls the pre-loaded render() function from the ESM module.
pub fn register_mbtx_routes(app : App, routes : Array[MbtxRoute]) -> Unit {
  for route in routes {
    let js_path = route.js_path
    app.get(
      route.path,
      @mars.handler(async fn(c) {
        let req_path = c.param("path").unwrap_or(route.path)
        let query = ffi_get_query_string(c)
        let result = ffi_exec_mbtx_esm(js_path, "GET", req_path, query)
        if result.status == 0 {
          ffi_console_error(
            "[sol] mbtx handler failed (\{js_path}): execution error",
          )
          c.text("Internal Server Error", status=500)
          return
        }
        c.set_header("Content-Type", result.content_type)
        c.text(result.body, status=result.status)
      }),
    )
  }
}

///|
/// Result from mbtx execution
priv struct MbtxResponse {
  status : Int
  content_type : String
  body : String
}

///|
/// Execute a built .mbtx ESM module via dynamic import() with hot-reload.
/// Modules are cached and invalidated when file mtime changes.
/// Uses import() for V8 JIT optimization (~0.4µs/call vs ~150µs with vm).
extern "js" fn ffi_exec_mbtx_esm(
  js_path : String,
  req_method : String,
  path_info : String,
  query_string : String,
) -> MbtxResponse =
  #| (() => {
  #|   const fs = require('node:fs');
  #|   const path = require('node:path');
  #|   const cache = new Map();
  #|   return (jsPath, method, pathInfo, queryString) => {
  #|     try {
  #|       const abs = path.resolve(jsPath);
  #|       const mtime = fs.statSync(abs).mtimeMs;
  #|       let entry = cache.get(abs);
  #|       if (!entry || entry.mtime !== mtime) {
  #|         const url = 'file://' + abs + '?t=' + mtime;
  #|         entry = { mtime, mod: null, loading: import(url).then(m => { entry.mod = m; }) };
  #|         cache.set(abs, entry);
  #|       }
  #|       if (!entry.mod) {
  #|         return { status: 0, content_type: '', body: '' };
  #|       }
  #|       const env = { REQUEST_METHOD: method, PATH_INFO: pathInfo, QUERY_STRING: queryString };
  #|       const resp = entry.mod.default(env);
  #|       if (!resp) return { status: 0, content_type: '', body: '' };
  #|       return {
  #|         status: resp.status || 200,
  #|         content_type: resp.contentType || 'text/html',
  #|         body: resp.body || '',
  #|       };
  #|     } catch (e) {
  #|       console.error('[sol] mbtx execution error:', e);
  #|       return { status: 0, content_type: '', body: '' };
  #|     }
  #|   };
  #| })()

///|
extern "js" fn ffi_get_query_string(c : Ctx) -> String =
  #| (c) => {
  #|   try {
  #|     const url = new URL(c.req.url, 'http://localhost');
  #|     return url.search ? url.search.slice(1) : '';
  #|   } catch (_) { return ''; }
  #| }

// =============================================================================
// Build Utilities
// =============================================================================

///|
/// Transform a built .mbtx JS (IIFE) into an ESM module with render() export.
/// Input: standard moonc output with (() => { ... })() at the end
/// Output: same code but IIFE replaced with `export default function render(env) { ... }`
pub fn transform_mbtx_to_esm(code : String) -> String {
  // Find the IIFE: (() => {
  let iife_start = match code.find("(() => {") {
    Some(i) => i
    None => return code // not a standard IIFE, return as-is
  }
  let buf = StringBuilder::new()
  // Copy helper definitions before IIFE
  buf.write_string(code[:iife_start].to_owned())
  // Replace IIFE with export default function
  buf.write_string(
    "export default function render(env) { globalThis.__MBTX_ENV__ = env; globalThis.__MBTX_RESPONSE__ = undefined;",
  )
  // Find the closing })();
  let iife_body_start = iife_start + 8 // skip "(() => {"
  // Find matching })();
  let close_pattern = "})();"
  let close_idx = match code.find(close_pattern) {
    Some(i) => i
    None =>
      // Try without semicolon
      match code.find("})()") {
        Some(i) => i
        None => return code
      }
  }
  // Copy IIFE body
  buf.write_string(code[iife_body_start:close_idx].to_owned())
  buf.write_string(" return globalThis.__MBTX_RESPONSE__; }\n")
  buf.to_string()
}
