///|
test "default_hmr_port: adds offset to app port" {
  assert_eq(default_hmr_port(3000), 3100)
  assert_eq(default_hmr_port(7777), 7877)
}

///|
test "resolve_app_port: parses valid port" {
  let port = resolve_app_port(app_port=Some("3123"))
  assert_eq(port, 3123)
}

///|
test "resolve_app_port: falls back on invalid port" {
  let port = resolve_app_port(app_port=Some("invalid"), default_port=8787)
  assert_eq(port, 8787)
}

///|
test "resolve_app_port: falls back when missing" {
  let port = resolve_app_port(app_port=None, default_port=8787)
  assert_eq(port, 8787)
}

///|
test "resolve_hmr_port: HMR_PORT takes precedence" {
  let port = resolve_hmr_port(hmr_port=Some("24679"), app_port=Some("3000"))
  assert_eq(port, 24679)
}

///|
test "resolve_hmr_port: falls back to app port + offset" {
  let port = resolve_hmr_port(hmr_port=None, app_port=Some("3000"))
  assert_eq(port, 3100)
}

///|
test "resolve_hmr_port: invalid port falls back to default" {
  let port = resolve_hmr_port(hmr_port=None, app_port=Some("bad-port"))
  assert_eq(port, 7877)
}

///|
test "client_script_hostname: uses location.hostname and handles reload events" {
  let script = client_script_hostname(24679)
  assert_true(script.contains("location.hostname"))
  assert_true(script.contains("m.type==='update'"))
  assert_true(script.contains("m.type==='reload'"))
  assert_true(script.contains("m.type==='full-reload'"))
  assert_true(script.contains("location.reload()"))
  assert_true(script.contains("24679"))
}

///|
test "client_script_hostname: supports island-specific HMR" {
  let script = client_script_hostname(7877)
  // Should check for __LUNA_HYDRATE__ function
  assert_true(script.contains("__LUNA_HYDRATE__"))
  // Should query islands by luna:url attribute
  assert_true(script.contains("luna\\\\:url"))
  // Should fallback to full reload for wildcard
  assert_true(script.contains("islands[0]==='*'"))
}

///|
test "client_script_localhost: uses localhost for ws host" {
  let script = client_script_localhost(24679)
  assert_true(script.contains("'localhost'"))
}

///|
test "with_dev_head_script: keeps head in non-dev mode" {
  let head = "<meta charset=\"utf-8\">"
  let result = with_dev_head_script(head, dev_mode=false)
  assert_eq(result, head)
}

///|
test "with_dev_head_script: appends script in dev mode" {
  let head = "<meta name=\"viewport\">"
  let result = with_dev_head_script(head, dev_mode=true)
  assert_true(result.has_prefix(head))
  assert_true(result.contains("location.hostname"))
  assert_true(result.contains("ws://"))
}

///|
test "inject_script: injects before closing body tag" {
  let html = "<html><body><h1>Hello</h1></body></html>"
  let injected = inject_script(html, "<script>hmr</script>")
  assert_true(injected.contains("<h1>Hello</h1><script>hmr</script></body>"))
}

///|
test "inject_script: appends when body is missing" {
  let html = "<html><head></head></html>"
  let injected = inject_script(html, "<script>hmr</script>")
  assert_true(injected.has_suffix("<script>hmr</script>"))
}
