///| Whitebox tests for `sol doctor`.

///|
fn write_minimal_project(
  fs : @fs_adapter.MemFSAdapter,
  cwd : String,
  runtime : String,
  deps : String,
) -> Unit {
  let mem = fs.memfs()
  mem.mkdirSync(cwd + "/app/server", recursive=true)
  mem.writeFileSync(
    cwd + "/sol.config.json",
    "{ \"routes\": \"app/server\", \"output\": \"app/__gen__\", \"runtime\": \"" +
    runtime +
    "\" }",
  )
  mem.writeFileSync(cwd + "/app/server/routes.mbt", "pub fn routes() { [] }")
  mem.writeFileSync(
    cwd + "/moon.mod",
    "name = \"tester/app\"\n\nimport {\n" + deps + "\n}\n\nsource = \"app\"\n",
  )
}

///|
fn sol_dep() -> String {
  "  \"mizchi/sol@\{@version.VERSION}\""
}

///|
fn sol_node_deps() -> String {
  sol_dep() + ",\n  \"mizchi/sol_adapter_node@\{@version.VERSION}\""
}

///|
fn mooncake_mod_json(name : String, version : String) -> String {
  "{ \"name\": \"\{name}\", \"version\": \"\{version}\" }"
}

///|
test "diagnose_project reports ok for a generated node project" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let mem = fs.memfs()
  write_minimal_project(fs, "/project", "node", sol_node_deps())
  mem.mkdirSync("/project/app/__gen__", recursive=true)
  mem.mkdirSync("/project/.sol/prod/server", recursive=true)
  mem.writeFileSync("/project/.sol/prod/server/serve.js", "// serve wrapper")

  let report = diagnose_project_with_fs(fs, "/project")
  assert_false(report.has_errors())
  assert_true(report.summary().contains("0 error"))
  assert_true(report.render().contains("runtime: node"))
}

///|
test "diagnose_project flags missing node adapter dependency" {
  let fs = @fs_adapter.MemFSAdapter::new()
  write_minimal_project(fs, "/project", "node", sol_dep())

  let report = diagnose_project_with_fs(fs, "/project")
  assert_true(report.has_errors())
  assert_true(report.render().contains("mizchi/sol_adapter_node"))
  assert_true(report.render().contains("moon.mod"))
}

///|
test "diagnose_project flags cloudflare projects that still depend on node adapter" {
  let fs = @fs_adapter.MemFSAdapter::new()
  write_minimal_project(fs, "/project", "cloudflare", sol_node_deps())

  let report = diagnose_project_with_fs(fs, "/project")
  assert_true(report.has_errors())
  assert_true(report.render().contains("mizchi/sol_adapter_cloudflare"))
  assert_true(report.render().contains("Remove mizchi/sol_adapter_node"))
}

///|
test "diagnose_project warns when generated outputs are missing" {
  let fs = @fs_adapter.MemFSAdapter::new()
  write_minimal_project(fs, "/project", "node", sol_node_deps())

  let report = diagnose_project_with_fs(fs, "/project")
  assert_false(report.has_errors())
  assert_true(report.has_warnings())
  assert_true(report.render().contains("sol generate"))
  assert_true(report.render().contains("sol build"))
}

///|
test "diagnose_project surfaces mooncake versions when .mooncakes is populated" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let mem = fs.memfs()
  write_minimal_project(fs, "/project", "node", sol_node_deps())
  mem.mkdirSync("/project/.mooncakes/mizchi/sol", recursive=true)
  mem.writeFileSync(
    "/project/.mooncakes/mizchi/sol/moon.mod.json",
    mooncake_mod_json("mizchi/sol", @version.VERSION),
  )
  mem.mkdirSync("/project/.mooncakes/mizchi/luna", recursive=true)
  mem.writeFileSync(
    "/project/.mooncakes/mizchi/luna/moon.mod.json",
    mooncake_mod_json("mizchi/luna", @version.VERSION),
  )
  let report = diagnose_project_with_fs(fs, "/project")
  let rendered = report.render()
  assert_true(rendered.contains("Mooncake versions:"))
  assert_true(rendered.contains("mizchi/sol @ \{@version.VERSION}"))
  assert_true(rendered.contains("mizchi/luna @ \{@version.VERSION}"))
  // No skew warning when JS CLI version matches the resolved sol mooncake.
  assert_false(rendered.contains("Sol JS CLI / .mooncakes version diverge"))
}

///|
test "diagnose_project warns when .mooncakes sol version differs from bundled JS CLI" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let mem = fs.memfs()
  write_minimal_project(fs, "/project", "node", sol_node_deps())
  mem.mkdirSync("/project/.mooncakes/mizchi/sol", recursive=true)
  mem.writeFileSync(
    "/project/.mooncakes/mizchi/sol/moon.mod.json",
    mooncake_mod_json("mizchi/sol", "0.22.1"),
  )
  let report = diagnose_project_with_fs(fs, "/project")
  let rendered = report.render()
  assert_true(report.has_warnings())
  assert_true(rendered.contains("Sol JS CLI / .mooncakes version diverge"))
  assert_true(rendered.contains("moon update"))
}

///|
test "diagnose_project warns when launcher and mooncake versions diverge" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let mem = fs.memfs()
  write_minimal_project(fs, "/project", "node", sol_node_deps())
  mem.mkdirSync("/project/.mooncakes/mizchi/sol", recursive=true)
  mem.writeFileSync(
    "/project/.mooncakes/mizchi/sol/moon.mod.json",
    mooncake_mod_json("mizchi/sol", @version.VERSION),
  )
  let report = diagnose_project_with_fs(
    fs,
    "/project",
    launcher_version=Some("0.22.0"),
  )
  let rendered = report.render()
  assert_true(report.has_warnings())
  assert_true(
    rendered.contains("Launcher and delegated JS CLI versions diverge"),
  )
  assert_true(rendered.contains("0.22.0"))
}
