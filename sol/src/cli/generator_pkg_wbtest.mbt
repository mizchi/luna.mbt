///|
test "generate_server_pkg: uses modern import alias syntax" {
  let content = generate_server_pkg("tester/myapp/server")
  assert_true(content.contains("\"tester/myapp/server\" @app_server"))
  assert_true(!(content.contains(" as @")))
  assert_true(!(content.contains("\"mizchi/js/core\"")))
}

///|
test "generate_client_gen_pkg: uses modern import alias syntax" {
  let content = generate_client_gen_pkg("tester/myapp/client", "client", [
    "__sol_internal__client_counter",
  ])
  assert_true(content.contains("\"tester/myapp/client\" @client"))
  assert_true(content.contains("\"mizchi/js/browser/dom\" @js_dom"))
  assert_true(content.contains("\"mizchi/luna/dom/client\" @wc"))
  assert_true(!(content.contains(" as @")))
}

///|
test "generate_types_pkg: imports core/json for derive support" {
  let structs : Array[StructExport] = []
  let content = generate_types_pkg(structs)
  assert_true(content.contains("\"moonbitlang/core/json\""))
  assert_true(content.contains("\"mizchi/luna\" @luna"))
}
