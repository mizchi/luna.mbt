// `run_dev`: bind the in-process middleware to a real `node:http` listener
// and dispatch every incoming request through Mars's `Server::to_handler`.
//
// Mars on the JS target exposes `Server::to_handler() -> (JsRequest) ->
// Promise[JsResponse]`. The handler expects a Web `Request` and returns a
// Web `Response`. node:http hands us `IncomingMessage` / `ServerResponse`
// instead, so the FFI bridge below converts in both directions.
//
// We deliberately keep this on the cli library side (not adapters/) so the
// cli can be reused as a testing harness without dragging mars-adapter
// types out of their package.

///|
/// FFI: ensure the global symbol that mars's `to_handler` references via
/// inline JS exists. Same shim used by `astra/testing` so the moon-test and
/// the production server agree on the symbol shape.
extern "js" fn ffi_dev_ensure_reschedule_symbol() -> Unit =
  #| () => {
  #|   if (typeof globalThis.moonbitlang$async$internal$event_loop$$reschedule !== "function") {
  #|     globalThis.moonbitlang$async$internal$event_loop$$reschedule = () => {};
  #|   }
  #| }

///|
/// FFI: start a `node:http` server on `port` whose request listener
/// forwards every incoming request through the mars `AppHandler`.
///
/// The conversion piece is in JS rather than MoonBit because mizchi/js's
/// `node:http` types don't directly expose the body stream / writeHead
/// signatures we need with the right async shape, and writing the bridge
/// here keeps it close to the Web Request <-> node:http translation.
extern "js" fn ffi_listen(handler : @mars.AppHandler, port : Int) -> Unit =
  #| async (handler, port) => {
  #|   const http = await import("node:http");
  #|   const server = http.createServer(async (req, res) => {
  #|     try {
  #|       // Build a Web Request from the IncomingMessage. Mars only reads
  #|       // method / url / headers in `js_request_to_http_request`, so the
  #|       // bare URL + method + Headers is enough; no body for GET/HEAD.
  #|       const proto = "http";
  #|       const host = req.headers.host || "localhost";
  #|       const url = `${proto}://${host}${req.url || "/"}`;
  #|       const method = req.method || "GET";
  #|       const headers = new Headers();
  #|       for (const [k, v] of Object.entries(req.headers || {})) {
  #|         if (Array.isArray(v)) {
  #|           for (const item of v) headers.append(k, String(item));
  #|         } else if (v != null) {
  #|           headers.set(k, String(v));
  #|         }
  #|       }
  #|       const init = { method, headers };
  #|       // For methods that may have a body, buffer it. Page/asset GETs
  #|       // are the dev-server's only real load today; we still keep the
  #|       // POST/PUT path correct so a future endpoint isn't blocked.
  #|       if (method !== "GET" && method !== "HEAD") {
  #|         const chunks = [];
  #|         for await (const chunk of req) chunks.push(chunk);
  #|         init.body = Buffer.concat(chunks);
  #|       }
  #|       const webReq = new Request(url, init);
  #|       const webRes = await handler(webReq);
  #|       const body = await webRes.text();
  #|       const respHeaders = {};
  #|       webRes.headers.forEach((value, key) => { respHeaders[key] = value; });
  #|       res.writeHead(webRes.status, respHeaders);
  #|       res.end(body);
  #|     } catch (e) {
  #|       // Surface render / handler errors as 500 with the message in
  #|       // the body so the developer sees them in the browser.
  #|       const msg = (e && e.stack) ? e.stack : String(e);
  #|       res.writeHead(500, { "Content-Type": "text/plain; charset=utf-8" });
  #|       res.end(msg);
  #|     }
  #|   });
  #|   server.listen(port, () => {
  #|     console.log(`astra dev: listening on http://localhost:${port}`);
  #|   });
  #| }

///|
/// `astra dev [--port <n>]` - boot the in-process middleware behind a
/// real `node:http` server.
///
/// Lives next to `run_build` rather than in `cli.mbt` so the FFI bridge
/// above stays paired with its only caller; the doc comment on `cli.mbt`'s
/// stub is now stale and gets replaced when this file is in scope.
pub fn run_dev_listen(args : Array[String], cwd : String) -> Unit {
  if has_flag(args, "--help") || has_flag(args, "-h") {
    println("Usage: astra dev [--port <n>]")
    return
  }
  let port : Int = match get_flag_value(args, "--port") {
    Some(p) =>
      try {
        @string.parse_int(p)
      } catch {
        _ => 7777
      }
    None => 7777
  }
  let cfg = load_config(cwd)
  let mw = @middleware.create(cfg, cwd~)
  let urls = mw.list_urls()
  println("astra dev: \{urls.length()} routes registered")
  let app = @mars.Server::new()
  app.all("/*", mw.handler())
  ffi_dev_ensure_reschedule_symbol()
  let handler = app.to_handler()
  ffi_listen(handler, port)
}
