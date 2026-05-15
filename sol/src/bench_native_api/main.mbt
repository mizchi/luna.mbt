///| Minimal native API server for benchmarking

///|
/// Comparable to examples/sol_api but using mars native directly
async fn main {
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

  println("Native server on http://localhost:7800")
  app.serve(port=7800)
}
