// Regression tests for `build_package_path`.
//
// moon emits build artifacts under `_build/js/{profile}/build/` using the
// package path *relative to the module's `source` root* — the module name
// never appears in the build path — UNLESS the module is one of several
// source members of a `moon.work` workspace, in which case every member
// (including this one) is disambiguated by its full module name. Standalone
// builds (and a `moon.work` whose only source member is this module) must
// therefore get the source-relative path so the generated `.sol` stubs
// import a file that actually exists on disk; multi-member `moon.work`
// builds (e.g. this monorepo's own e2e tests, which build a scaffold
// alongside local `luna`/`sol` source) need the module-name-prefixed path
// instead. Getting either direction wrong breaks `sol build`'s bundling step
// (unresolved import) even though `moon check` / `moon test` stay green,
// since neither runs the bundler.

///|
test "build_package_path strips the source root and omits the module name by default" {
  // source = "app": app/client -> client
  assert_eq(
    build_package_path("uuu/deli-cms-sol", "app", "app/client"),
    "client",
  )
  // nested generated package: src/__gen__/server -> __gen__/server
  assert_eq(
    build_package_path("tester/myapp", "src", "src/__gen__/server"),
    "__gen__/server",
  )
}

///|
test "build_package_path leaves the path unchanged when there is no source root" {
  // source = "." or "": package path is already module-root relative.
  assert_eq(build_package_path("tester/myapp", ".", "client"), "client")
  assert_eq(build_package_path("tester/myapp", "", "server"), "server")
  // package outside the declared source dir is left untouched.
  assert_eq(build_package_path("tester/myapp", "app", "vendor/x"), "vendor/x")
}

///|
test "build_package_path prepends the module name for a multi-member moon.work workspace" {
  assert_eq(
    build_package_path(
      "testuser/worker-app",
      "app",
      "app/client",
      is_workspace_build=true,
    ),
    "testuser/worker-app/client",
  )
  assert_eq(
    build_package_path("tester/myapp", ".", "client", is_workspace_build=true),
    "tester/myapp/client",
  )
}

///|
test "count_moon_work_members counts quoted entries in the members array" {
  assert_eq(
    count_moon_work_members(
      (
        #|members = [
        #|  "./worker-app",
        #|]
      ),
    ),
    1,
  )
  assert_eq(
    count_moon_work_members(
      (
        #|members = [
        #|  "./worker-app",
        #|  "./luna",
        #|  "./sol",
        #|]
      ),
    ),
    3,
  )
}

///|
test "is_multi_module_workspace_with_fs is false without moon.work" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let mem = fs.memfs()
  mem.mkdirSync("/project", recursive=true)
  assert_false(is_multi_module_workspace_with_fs(fs, "/project"))
}

///|
test "is_multi_module_workspace_with_fs is false for a single-member moon.work" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let mem = fs.memfs()
  mem.mkdirSync("/project", recursive=true)
  mem.writeFileSync(
    "/project/moon.work",
    (
      #|members = [
      #|  ".",
      #|]
    ),
  )
  assert_false(is_multi_module_workspace_with_fs(fs, "/project"))
}

///|
test "is_multi_module_workspace_with_fs is true for a multi-member moon.work" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let mem = fs.memfs()
  mem.mkdirSync("/project", recursive=true)
  mem.writeFileSync(
    "/project/moon.work",
    (
      #|members = [
      #|  "./worker-app",
      #|  "./luna",
      #|]
    ),
  )
  assert_true(is_multi_module_workspace_with_fs(fs, "/project"))
}
