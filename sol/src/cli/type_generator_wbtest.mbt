///| Whitebox tests for generated frontend/server type contracts

///|
fn sample_counter_props() -> StructExport {
  {
    name: "CounterProps",
    raw_definition: "pub(all) struct CounterProps {\n  initial : Int\n}",
    package_path: "app/client",
    import_alias: "client",
  }
}

///|
fn sample_action_form_props() -> StructExport {
  {
    name: "ContactFormProps",
    raw_definition: "pub(all) struct ContactFormProps {\n  initial_name : String\n  initial_email : String\n}",
    package_path: "app/client",
    import_alias: "client",
  }
}

///|
test "generate_types_mbt: auto bundle keeps default and url-injected factories" {
  let content = generate_types_mbt([sample_counter_props()])
  assert_true(content.contains("pub fn counter_at("))
  assert_true(content.contains("  url : String,"))
  assert_true(content.contains("pub fn counter("))
  assert_true(
    content.contains("counter_at(\"/static/counter.js\", props, trigger~)"),
  )
}

///|
test "generate_types_mbt: external bundle requires explicit component URL" {
  let content = generate_types_mbt(
    [sample_counter_props()],
    external_client_bundle=true,
  )
  assert_true(content.contains("pub fn counter_at("))
  assert_true(content.contains("  url : String,"))
  assert_true(content.contains(") -> @luna.ComponentRef[CounterProps]"))
  assert_false(content.contains("counter_at(\"/static/counter.js\""))
  assert_false(content.contains("pub fn counter(\n  props : CounterProps"))
}

///|
test "generate_types_pkg: external bundle exports url-injected factory only" {
  let content = generate_types_pkg(
    [sample_counter_props()],
    external_client_bundle=true,
  )
  assert_true(content.contains("\"CounterProps\""))
  assert_true(content.contains("\"counter_at\""))
  assert_false(content.contains("\"counter\","))
}

///|
test "generate_types_pkg: imports router when route param accessors exist" {
  let content = generate_types_pkg([], has_route_params=true)
  assert_true(content.contains("\"mizchi/sol/router\" @router"))
}

///|
test "generate_types_pkg: imports action when generated actions exist" {
  let content = generate_types_pkg(
    [sample_action_form_props()],
    has_actions=true,
  )
  assert_true(content.contains("\"mizchi/sol/action\" @action"))
}

///|
test "default_json_value: unknown custom types fall back to object" {
  assert_eq(default_json_value("@app.CustomType"), "{}")
}
