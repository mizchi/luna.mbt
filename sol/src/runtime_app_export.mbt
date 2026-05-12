// Runtime app export and server launch helpers

///|
/// Global app reference for non-Node runtimes (Cloudflare, Deno, Bun)
/// This is set by run() and exported as __SOL_APP__
let sol_app_ref : Ref[App?] = { val: None }

///|
extern "js" fn ffi_export_sol_app(fetch_handler : MarsFetchHandler) -> Unit =
  #| (fetchHandler) => { globalThis.__SOL_APP__ = { fetch: fetchHandler }; }

///|
/// Type alias for Mars fetch handler with js_async Promise
priv struct MarsFetchHandler((@mars.JsRequest) -> @js.Promise[@mars.JsResponse])

///|
/// Convert Mars Promise type to @js.Promise for FFI compatibility
/// Mars uses moonbitlang/async/js_async.Promise, Sol uses mizchi/js/core.Promise
/// They are the same JS Promise object at runtime
extern "js" fn ffi_convert_fetch_handler(handler : @js.Any) -> MarsFetchHandler =
  #| (handler) => handler

///|
/// Check if running in Node.js environment
extern "js" fn ffi_is_node() -> Bool =
  #| () => globalThis.__SOL_RUNTIME__ !== "cloudflare" &&
  #|   typeof process !== 'undefined' &&
  #|   process.versions?.node != null

///|
fn runtime_is_node() -> Bool {
  ffi_is_node()
}

///|
fn export_runtime_app(app : App) -> Unit {
  sol_app_ref.val = Some(app)
  let fetch_handler = app.to_fetch_handler()
  ffi_export_sol_app(ffi_convert_fetch_handler(@js.any(fetch_handler)))
}

///|
fn should_start_server() -> Bool {
  runtime_is_node() && !is_adapter_mode()
}

///|
fn maybe_start_server(app : App, port : Int) -> Unit {
  if should_start_server() {
    println("Server running at http://localhost:" + port.to_string())
    serve_runtime(app, port)
  }
}

///|
fn serve_runtime(app : App, port : Int) -> Unit {
  let fetch_handler = app.to_fetch_handler()
  ffi_serve(ffi_convert_fetch_handler(@js.any(fetch_handler)), port)
}

///|
extern "js" fn ffi_serve(fetch_handler : MarsFetchHandler, port : Int) -> Unit =
  #|(fetchHandler, port) => {
  #|  const importer = globalThis.__SOL_DYNAMIC_IMPORT__ ||
  #|    ((specifier) => new Function('specifier', 'return import(specifier)')(specifier));
  #|  importer('@hono/node-server').then(({ serve }) => {
  #|    serve({ fetch: fetchHandler, port });
  #|  });
  #|}
