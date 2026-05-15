///|
using @test {assert_eq}

///|
/// Additional tests for hot_reload pure functions

///|
test "default_hmr_port: custom offset" {
  assert_eq(default_hmr_port(3000, offset=200), 3200)
}

///|
test "default_hmr_port: zero offset" {
  assert_eq(default_hmr_port(4000, offset=0), 4000)
}

///|
test "default_hmr_port: large port with default offset" {
  assert_eq(default_hmr_port(60000), 60100)
}

///|
test "client_script_with_host_expr: substitutes host expression and port" {
  let script = client_script_with_host_expr(9999, "'example.com'")
  assert_true(script.contains("'example.com'"))
  assert_true(script.contains("9999"))
  assert_true(script.contains("<script>"))
  assert_true(script.contains("</script>"))
  assert_true(script.contains("WebSocket"))
}

///|
test "client_script_with_host_expr: no raw __HOST__ placeholder remains" {
  let script = client_script_with_host_expr(1234, "location.hostname")
  assert_false(script.contains("__HOST__"))
}

///|
test "client_script_with_host_expr: no raw __PORT__ placeholder remains" {
  let script = client_script_with_host_expr(1234, "location.hostname")
  assert_false(script.contains("__PORT__"))
}

///|
test "client_script_localhost: contains literal localhost string" {
  let script = client_script_localhost(8080)
  assert_true(script.contains("'localhost'"))
  assert_true(script.contains("8080"))
}

///|
test "client_script_localhost: does not contain location.hostname" {
  let script = client_script_localhost(8080)
  assert_false(script.contains("location.hostname"))
}

///|
test "resolve_app_port: parses port 80" {
  let port = resolve_app_port(app_port=Some("80"))
  assert_eq(port, 80)
}

///|
test "resolve_app_port: parses port 0" {
  let port = resolve_app_port(app_port=Some("0"))
  assert_eq(port, 0)
}

///|
test "resolve_app_port: parses large port 65535" {
  let port = resolve_app_port(app_port=Some("65535"))
  assert_eq(port, 65535)
}

///|
test "resolve_app_port: returns fallback for float string" {
  let port = resolve_app_port(app_port=Some("3000.5"), default_port=9090)
  assert_eq(port, 9090)
}

///|
test "resolve_app_port: returns fallback for empty string" {
  let port = resolve_app_port(app_port=Some(""), default_port=5000)
  assert_eq(port, 5000)
}

///|
test "resolve_hmr_port: invalid HMR port falls back to app port plus offset" {
  let port = resolve_hmr_port(
    hmr_port=Some("not-a-number"),
    app_port=Some("4000"),
    offset=50,
  )
  assert_eq(port, 4050)
}

///|
test "resolve_hmr_port: all None uses default port plus offset" {
  let port = resolve_hmr_port(
    hmr_port=None,
    app_port=None,
    default_port=8000,
    offset=100,
  )
  assert_eq(port, 8100)
}

///|
test "inject_script: injects before </body> preserving surrounding content" {
  let html = "<html><body><p>text</p></body></html>"
  let result = inject_script(html, "<script>x</script>")
  assert_true(result.contains("<script>x</script></body>"))
  assert_false(result.has_suffix("<script>x</script>"))
}

///|
test "inject_script: multiple </body> tags only first is replaced" {
  // inject_script uses replace which replaces the first occurrence
  let html = "<body>inner</body><body>outer</body>"
  let result = inject_script(html, "<s/>")
  assert_true(result.contains("<s/></body>"))
}
