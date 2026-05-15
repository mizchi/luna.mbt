///|
fn dummy_func_export() -> FuncExport {
  {
    name: "counter",
    signature: "(CounterProps) -> DomNode",
    contract: client_component_contract_from_signature(
      "(CounterProps) -> DomNode",
    ),
    package_path: "tester/myapp/client",
    import_alias: "client",
    source_pattern: "app/client",
  }
}

///|
test "generate_island_entry_js_v2: dev mode uses debug build imports" {
  let js = generate_island_entry_js_v2(
    dummy_func_export(),
    true,
    "client",
    "dev",
  )
  assert_true(js.contains("../../../_build/js/debug/build/client/client.js"))
  assert_true(
    js.contains("../../../_build/js/debug/build/__gen__/client/client.js"),
  )
}

///|
test "generate_island_entry_js_v2: prod mode uses release build imports" {
  let js = generate_island_entry_js_v2(
    dummy_func_export(),
    true,
    "client",
    "prod",
  )
  assert_true(js.contains("../../../_build/js/release/build/client/client.js"))
  assert_true(
    js.contains("../../../_build/js/release/build/__gen__/client/client.js"),
  )
}
