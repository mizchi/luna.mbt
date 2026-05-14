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
    cwd + "/moon.mod.json",
    "{ \"name\": \"tester/app\", \"deps\": { " + deps + " } }",
  )
}

///|
test "diagnose_project reports ok for a generated node project" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let mem = fs.memfs()
  let deps = "\"mizchi/sol\": \"0.20.2\", \"mizchi/sol_adapter_node\": \"0.20.2\""
  write_minimal_project(
    fs, "/project", "node", deps,
  )
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
  write_minimal_project(fs, "/project", "node", "\"mizchi/sol\": \"0.20.2\"")

  let report = diagnose_project_with_fs(fs, "/project")
  assert_true(report.has_errors())
  assert_true(report.render().contains("mizchi/sol_adapter_node"))
  assert_true(report.render().contains("moon.mod.json"))
}

///|
test "diagnose_project flags cloudflare projects that still depend on node adapter" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let deps = "\"mizchi/sol\": \"0.20.2\", \"mizchi/sol_adapter_node\": \"0.20.2\""
  write_minimal_project(
    fs, "/project", "cloudflare", deps,
  )

  let report = diagnose_project_with_fs(fs, "/project")
  assert_true(report.has_errors())
  assert_true(report.render().contains("mizchi/sol_adapter_cloudflare"))
  assert_true(report.render().contains("Remove mizchi/sol_adapter_node"))
}

///|
test "diagnose_project warns when generated outputs are missing" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let deps = "\"mizchi/sol\": \"0.20.2\", \"mizchi/sol_adapter_node\": \"0.20.2\""
  write_minimal_project(
    fs, "/project", "node", deps,
  )

  let report = diagnose_project_with_fs(fs, "/project")
  assert_false(report.has_errors())
  assert_true(report.has_warnings())
  assert_true(report.render().contains("sol generate"))
  assert_true(report.render().contains("sol build"))
}
