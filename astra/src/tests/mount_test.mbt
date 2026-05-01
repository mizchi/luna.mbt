///|
/// Smoke test: mounting astra's placeholder middleware on a Mars server returns
/// the expected 501 response. Phase A only checks that astra is wireable.
async test "placeholder middleware returns 501" {
  let app = @mars.Server::new()
  app.all("/anything", @astra.placeholder())
  let res = @testing.invoke(app, path="/anything")
  inspect(res.status, content="501")
  inspect(res.body == "astra: not implemented yet", content="true")
}
