// Whitebox tests for mbtx_scanner.mbt

///|
test "mbtx_file_to_route: simple" {
  assert_eq(mbtx_file_to_route("hello.mbtx", ""), "/hello")
}

///|
test "mbtx_file_to_route: nested" {
  assert_eq(mbtx_file_to_route("api/hello.mbtx", ""), "/api/hello")
}

///|
test "mbtx_file_to_route: index" {
  assert_eq(mbtx_file_to_route("index.mbtx", ""), "/")
}

///|
test "mbtx_file_to_route: nested index" {
  assert_eq(mbtx_file_to_route("api/index.mbtx", ""), "/api")
}

///|
test "mbtx_file_to_route: dynamic param" {
  assert_eq(mbtx_file_to_route("users/_id_.mbtx", ""), "/users/:id")
}

///|
test "mbtx_file_to_route: catch-all" {
  assert_eq(mbtx_file_to_route("docs/___slug___.mbtx", ""), "/docs/[...slug]")
}

///|
test "mbtx_file_to_route: with base path" {
  assert_eq(mbtx_file_to_route("hello.mbtx", "/api"), "/api/hello")
}

///|
test "mbtx_file_to_id: simple" {
  assert_eq(mbtx_file_to_id("hello.mbtx"), "hello")
}

///|
test "mbtx_file_to_id: nested" {
  assert_eq(mbtx_file_to_id("api/hello.mbtx"), "api_hello")
}

///|
test "mbtx_file_to_id: dynamic" {
  assert_eq(mbtx_file_to_id("users/_id_.mbtx"), "users_id")
}

///|
test "mbtx_file_to_id: index" {
  assert_eq(mbtx_file_to_id("index.mbtx"), "index")
}
