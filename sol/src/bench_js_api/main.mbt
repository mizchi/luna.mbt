///| Minimal JS API server for benchmarking

///|
/// Same endpoints as native_api for fair comparison
fn main {
  ffi_init()
  let app = @mars.Server::new()

  // Health endpoint
  app.get(
    "/api/health",
    @mars.handler(async fn(c) {
      let json : Json = { "status": "ok".to_json() }
      c.json(json)
    }),
  )

  // Items endpoint (static JSON for consistent benchmark)
  let items_json : Json = [
    { "id": (1).to_json(), "name": "Item 1".to_json() },
    { "id": (2).to_json(), "name": "Item 2".to_json() },
    { "id": (3).to_json(), "name": "Item 3".to_json() },
  ].to_json()
  app.get(
    "/api/items",
    @mars.handler(async fn(c) {
      let json : Json = { "items": items_json, "total": (3).to_json() }
      c.json(json)
    }),
  )

  // Echo endpoint with param
  app.get(
    "/api/echo/:msg",
    @mars.handler(async fn(c) {
      let msg = c.param("msg").unwrap_or("hello")
      let json : Json = { "echo": msg.to_json() }
      c.json(json)
    }),
  )

  ffi_serve(app.to_handler(), 7801)
}

///|
extern "js" fn ffi_init() -> Unit =
  #| () => {
  #|   if (typeof globalThis.moonbitlang$async$internal$event_loop$$reschedule !== "function") {
  #|     globalThis.moonbitlang$async$internal$event_loop$$reschedule = () => {};
  #|   }
  #| }

///|
extern "js" fn ffi_serve(handler : @mars.AppHandler, port : Int) -> Unit =
  #| async (handler, port) => {
  #|   const { serve } = await import("@hono/node-server");
  #|   serve({ fetch: handler, port });
  #|   console.log(`JS server on http://localhost:${port}`);
  #| }
