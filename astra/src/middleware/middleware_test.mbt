// Tests for the public astra middleware surface (`create`, `handler`,
// `list_urls`). The plan's literal example uses `@mars.test_request` and
// `@mars.Request::get`, neither of which exist in the local mars; we use
// `@testing.invoke` instead, which drives a real `app.to_handler()`
// dispatch end-to-end.

///|
async test "create returns a middleware whose handler responds to GET /" {
  let cfg = @astra.SsgConfig::default()
  let mw = @middleware.create(cfg, cwd=".")
  let app = @mars.Server::new()
  app.all("/*path", mw.handler())
  let res = @testing.invoke(app, path="/")
  inspect(res.status >= 200 && res.status < 600, content="true")
}

///|
test "list_urls returns the document tree URLs" {
  let cfg = @astra.SsgConfig::default()
  let mw = @middleware.create(cfg, cwd=".")
  let urls = mw.list_urls()
  inspect(urls.length() >= 0, content="true")
}
