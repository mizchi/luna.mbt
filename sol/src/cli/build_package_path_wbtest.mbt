// Regression tests for `build_package_path`.
//
// moon emits build artifacts under `_build/js/{profile}/build/` using the
// package path *relative to the module's `source` root* — the module name
// never appears in the build path. `build_package_path` must therefore return
// the source-relative path so that the generated `.sol` stubs import a file
// that actually exists on disk. Prepending the module name here previously
// broke `sol build`'s bundling step (unresolved import) even though
// `moon check` / `moon test` stayed green.

///|
test "build_package_path strips the source root and omits the module name" {
  // source = "app": app/client -> client
  assert_eq(build_package_path("uuu/deli-cms-sol", "app", "app/client"), "client")
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
