// Whitebox tests for user-managed server entry point feature

///|
test "is_user_managed_server: true when main.mbt exists" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let mem = fs.memfs()
  mem.mkdirSync("/project/app/server", recursive=true)
  mem.writeFileSync("/project/app/server/main.mbt", "fn main {}")
  mem.writeFileSync("/project/app/server/routes.mbt", "pub fn routes() {}")
  let config : SolConfig = {
    islands: [],
    routes: "app/server",
    output: "app/__gen__",
    runtime: RuntimeNode,
    adapter: RuntimeNode,
    client_auto_exports: true,
    server_entry: ServerEntryAuto,
    client_bundle: ClientBundleAuto,
    contract_manifest: None,
    contract_ts: [],
    static_dirs: [],
    wasm_entrypoints: [],
    experimental: [],
  }
  assert_true(is_user_managed_server(fs, "/project", config))
}

///|
test "is_user_managed_server: false when main.mbt missing" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let mem = fs.memfs()
  mem.mkdirSync("/project/app/server", recursive=true)
  mem.writeFileSync("/project/app/server/routes.mbt", "pub fn routes() {}")
  let config : SolConfig = {
    islands: [],
    routes: "app/server",
    output: "app/__gen__",
    runtime: RuntimeNode,
    adapter: RuntimeNode,
    client_auto_exports: true,
    server_entry: ServerEntryAuto,
    client_bundle: ClientBundleAuto,
    contract_manifest: None,
    contract_ts: [],
    static_dirs: [],
    wasm_entrypoints: [],
    experimental: [],
  }
  assert_true(!is_user_managed_server(fs, "/project", config))
}

///|
test "should_use_user_managed_server: explicit user mode does not require main.mbt" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let mem = fs.memfs()
  mem.mkdirSync("/project/app/server", recursive=true)
  mem.writeFileSync("/project/app/server/routes.mbt", "pub fn routes() {}")
  let config : SolConfig = {
    islands: [],
    routes: "app/server",
    output: "app/__gen__",
    runtime: RuntimeNode,
    adapter: RuntimeNode,
    client_auto_exports: true,
    server_entry: ServerEntryUserManaged,
    client_bundle: ClientBundleAuto,
    contract_manifest: None,
    contract_ts: [],
    static_dirs: [],
    wasm_entrypoints: [],
    experimental: [],
  }
  assert_true(should_use_user_managed_server(fs, "/project", config))
}

///|
test "should_use_user_managed_server: generated mode ignores main.mbt" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let mem = fs.memfs()
  mem.mkdirSync("/project/app/server", recursive=true)
  mem.writeFileSync("/project/app/server/main.mbt", "fn main {}")
  mem.writeFileSync("/project/app/server/routes.mbt", "pub fn routes() {}")
  let config : SolConfig = {
    islands: [],
    routes: "app/server",
    output: "app/__gen__",
    runtime: RuntimeNode,
    adapter: RuntimeNode,
    client_auto_exports: true,
    server_entry: ServerEntryGenerated,
    client_bundle: ClientBundleAuto,
    contract_manifest: None,
    contract_ts: [],
    static_dirs: [],
    wasm_entrypoints: [],
    experimental: [],
  }
  assert_false(should_use_user_managed_server(fs, "/project", config))
}

///|
test "detect_app_mode_with_fs: MoonBitFull when routes.mbt exists" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let mem = fs.memfs()
  mem.mkdirSync("/project/app/server", recursive=true)
  mem.writeFileSync("/project/app/server/routes.mbt", "pub fn routes() {}")
  let config : SolConfig = {
    islands: [],
    routes: "app/server",
    output: "app/__gen__",
    runtime: RuntimeNode,
    adapter: RuntimeNode,
    client_auto_exports: true,
    server_entry: ServerEntryAuto,
    client_bundle: ClientBundleAuto,
    contract_manifest: None,
    contract_ts: [],
    static_dirs: [],
    wasm_entrypoints: [],
    experimental: [],
  }
  assert_eq(detect_app_mode_with_fs(fs, "/project", config), MoonBitFull)
}

///|
test "detect_app_mode_with_fs: hybrid when routes.ts exists" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let mem = fs.memfs()
  mem.mkdirSync("/project/app/server", recursive=true)
  mem.writeFileSync("/project/app/server/routes.ts", "export const routes = []")
  let config : SolConfig = {
    islands: [],
    routes: "app/server",
    output: "app/__gen__",
    runtime: RuntimeNode,
    adapter: RuntimeNode,
    client_auto_exports: true,
    server_entry: ServerEntryAuto,
    client_bundle: ClientBundleAuto,
    contract_manifest: None,
    contract_ts: [],
    static_dirs: [],
    wasm_entrypoints: [],
    experimental: [],
  }
  assert_eq(
    detect_app_mode_with_fs(fs, "/project", config),
    MoonBitClientTsServer,
  )
}

///|
test "generate_server_pkg: includes moonbitlang/async import" {
  let content = generate_server_pkg("tester/myapp/server")
  assert_true(content.contains("\"moonbitlang/async\""))
}

///|
test "generate_server_main_mbt: uses async fn main" {
  let content = generate_server_main_mbt(
    "tester/myapp/server",
    {
      _page_components: [],
      _api_handlers: [],
      route_paths: [],
      route_queries: [],
      action_ids: [],
      action_contracts: [],
      api_contracts: [],
      contract_shapes: [],
    },
    [],
  )
  assert_true(content.contains("async fn main {"))
  assert_true(content.contains("@sol_node.run_app(configure_app)"))
  assert_true(content.contains("@sol.serve_default_favicon(app)"))
}

///|
test "generate_server_main_mbt: cloudflare runtime uses cloudflare adapter" {
  let content = generate_server_main_mbt(
    "tester/myapp/server",
    {
      _page_components: [],
      _api_handlers: [],
      route_paths: [],
      route_queries: [],
      action_ids: [],
      action_contracts: [],
      api_contracts: [],
      contract_shapes: [],
    },
    [],
    runtime=RuntimeCloudflare,
  )
  assert_true(content.contains("@sol_cloudflare.run_app(configure_app)"))
  assert_false(content.contains("@sol.run_app(configure_app)"))
  assert_false(content.contains("@sol_node.run_app"))
}
