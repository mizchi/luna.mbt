///| Tests for Node adapter utilities.

///|
extern "js" fn ffi_clear_exported_sol_app() -> Unit =
  #| () => { delete globalThis.__SOL_APP__; }

///|
extern "js" fn ffi_has_exported_sol_app() -> Bool =
  #| () => typeof globalThis.__SOL_APP__?.fetch === "function"

///|
extern "js" fn ffi_set_port_env(value : String) -> Unit =
  #| (value) => { process.env.PORT = value; }

///|
extern "js" fn ffi_clear_port_env() -> Unit =
  #| () => { delete process.env.PORT; }

///|
test "export_app exposes a fetch app for generated adapter wrappers" {
  ffi_clear_exported_sol_app()
  let app = @mars.Server::new()
  export_app(app)
  assert_true(ffi_has_exported_sol_app())
}

///|
test "node_port_from_env uses env value and falls back to default" {
  ffi_clear_port_env()
  assert_eq(node_port_from_env(default=9090), 9090)

  ffi_set_port_env("4123")
  assert_eq(node_port_from_env(default=9090), 4123)

  ffi_set_port_env("not-a-port")
  assert_eq(node_port_from_env(default=9090), 9090)
  ffi_clear_port_env()
}

///|
test "generate_node_serve_js delegates local serving to hono node server" {
  let js = generate_node_serve_js("./main.js")
  assert_true(js.contains("process.env.SOL_ADAPTER = '1'"))
  assert_true(js.contains("await import(\"./main.js\")"))
  assert_true(js.contains("@hono/node-server"))
  assert_true(js.contains("serve({ fetch: app.fetch, port })"))
}

///|
test "generate_node_serve_js escapes main module as a JS string literal" {
  let js = generate_node_serve_js("./main.js';globalThis.__SOL_PWNED__=true;//")
  assert_true(
    js.contains("await import(\"./main.js';globalThis.__SOL_PWNED__=true;//\")"),
  )
  assert_false(
    js.contains("await import('./main.js';globalThis.__SOL_PWNED__=true;//')"),
  )
}
