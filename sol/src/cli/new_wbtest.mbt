///|
test "extract_project_basename: nested path" {
  assert_eq(extract_project_basename("apps/demo/myapp"), "myapp")
}

///|
test "extract_project_basename: trailing slash" {
  assert_eq(extract_project_basename("myapp/"), "myapp")
}

///|
test "resolve_project_dir: absolute path is preserved" {
  let cwd = "/repo/root"
  let project_name = "/private/tmp/myapp"
  assert_eq(resolve_project_dir(cwd, project_name), "/private/tmp/myapp")
}

///|
test "resolve_project_dir: relative path is joined with cwd" {
  let cwd = "/repo/root"
  let project_name = "apps/myapp"
  assert_eq(resolve_project_dir(cwd, project_name), "/repo/root/apps/myapp")
}
