///| Whitebox tests for MoonBit module manifest helpers.

///|
test "moon_mod_has_dep reads new moon.mod import entries" {
  let content =
    #|name = "tester/app"
    #|
    #|version = "0.1.0"
    #|
    #|import {
    #|  "mizchi/sol@0.23.0",
    #|  "mizchi/sol_adapter_node@0.23.0",
    #|}
    #|
    #|source = "app"
  assert_true(moon_mod_has_dep(content, "mizchi/sol"))
  assert_true(moon_mod_has_dep(content, "mizchi/sol_adapter_node"))
  assert_false(moon_mod_has_dep(content, "mizchi/sol_adapter_cloudflare"))
}

///|
test "moon_mod_version reads new moon.mod assignment" {
  let content =
    #|name = "tester/app"
    #|version = "0.23.0"
  assert_eq(moon_mod_version(content).unwrap_or(""), "0.23.0")
}

///|
test "read_mod_info_from_cwd_with_fs prefers moon.mod over legacy json" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let mem = fs.memfs()
  mem.mkdirSync("/project", recursive=true)
  mem.writeFileSync(
    "/project/moon.mod.json", "{ \"name\": \"tester/legacy\", \"source\": \"src\" }",
  )
  mem.writeFileSync(
    "/project/moon.mod",
    (
      #|name = "tester/app"
      #|source = "app"
    ),
  )
  assert_eq(
    find_moon_mod_path_with_fs(fs, "/project").unwrap_or(""),
    "/project/moon.mod",
  )
  let (name, source) = read_mod_info_from_cwd_with_fs(fs, "/project")
  assert_eq(name, "tester/app")
  assert_eq(source, "app")
}

///|
test "read_mod_info_from_cwd_with_fs keeps legacy moon.mod.json compatibility" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let mem = fs.memfs()
  mem.mkdirSync("/project", recursive=true)
  mem.writeFileSync(
    "/project/moon.mod.json", "{ \"name\": \"tester/legacy\", \"source\": \"app\" }",
  )
  let (name, source) = read_mod_info_from_cwd_with_fs(fs, "/project")
  assert_eq(name, "tester/legacy")
  assert_eq(source, "app")
}
