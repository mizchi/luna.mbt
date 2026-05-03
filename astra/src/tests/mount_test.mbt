///|
/// Smoke test: mounting the public astra middleware on a Mars server
/// returns a real HTTP response. Phase B replaces the Phase A 501
/// placeholder with `@middleware.create(...).handler()` so this test now
/// exercises the actual document-tree dispatch path end-to-end.
async test "astra middleware responds to requests" {
  let cfg = @astra.SsgConfig::default()
  let mw = @middleware.create(cfg, cwd=".")
  let app = @mars.Server::new()
  app.all("/anything", mw.handler())
  let res = @testing.invoke(app, path="/anything")
  // No `docs/` directory in the test cwd, so `/anything` does not match
  // any scanned page — the middleware returns 404 with the body below.
  inspect(res.status, content="404")
  inspect(res.body == "Not Found", content="true")
}
