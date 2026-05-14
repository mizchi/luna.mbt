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
test "generate_types_mbt: external bundle manifest restores typed default factory" {
  let content = generate_types_mbt(
    [sample_counter_props()],
    external_client_bundle=true,
    client_assets=[{ component: "counter", url: "/assets/counter.abc123.js" }],
  )
  assert_true(content.contains("pub fn counter("))
  assert_true(
    content.contains(
      "counter_at(\"/assets/counter.abc123.js\", props, trigger~)",
    ),
  )
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
test "generate_types_pkg: external bundle manifest exports typed default factory" {
  let content = generate_types_pkg(
    [sample_counter_props()],
    external_client_bundle=true,
    client_assets=[{ component: "counter", url: "/assets/counter.abc123.js" }],
  )
  assert_true(content.contains("\"CounterProps\""))
  assert_true(content.contains("\"counter_at\""))
  assert_true(content.contains("\"counter\""))
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
test "generate_types_pkg: route action only avoids component imports" {
  let content = generate_types_pkg([], has_actions=true, has_route_params=true)
  assert_false(content.contains("\"mizchi/luna\" @luna"))
  assert_false(content.contains("\"moonbitlang/core/json\""))
  assert_true(content.contains("\"mizchi/sol/router\" @router"))
  assert_true(content.contains("\"mizchi/sol/action\" @action"))
}

///|
test "generate_typescript_contract_decl: emits TypeScript props interfaces" {
  let content = generate_typescript_contract_decl(
    [
      {
        name: "CounterProps",
        raw_definition: "pub(all) struct CounterProps {\n  initial : Int\n  label : String?\n  tags : Array[String]\n  meta : Map[String, String]\n}",
        package_path: "app/client",
        import_alias: "client",
      },
    ],
    client_assets=[{ component: "counter", url: "/assets/counter.abc123.js" }],
  )
  assert_true(content.contains("export interface CounterProps {"))
  assert_true(content.contains("  initial: number;"))
  assert_true(content.contains("  label?: string | null;"))
  assert_true(content.contains("  tags: string[];"))
  assert_true(content.contains("  meta: Record<string, string>;"))
  assert_true(content.contains("\"counter\": CounterProps;"))
  assert_true(
    content.contains(
      "\"counter\": { props: CounterProps; url: \"/assets/counter.abc123.js\"; wc: false; };",
    ),
  )
  assert_true(content.contains("export type SolComponentName = keyof SolComponentProps;"))
  assert_true(
    content.contains(
      "export type SolComponentPropsOf<C extends SolComponentName> = SolComponentProps[C];",
    ),
  )
  assert_true(
    content.contains(
      "export interface SolComponentRef<C extends SolComponentName = SolComponentName> {",
    ),
  )
}

///|
test "generate_typescript_contract_decl: emits route and action declarations" {
  let content = generate_typescript_contract_decl(
    [],
    route_info=RouteInfo::{
      _page_components: [],
      _api_handlers: [],
      route_paths: ["/", "/blog/:slug", "/docs/[[...path]]"],
      action_ids: ["submit-contact"],
    },
  )
  assert_true(content.contains("export type SolRoutePath = \"/\" | \"/blog/:slug\" | \"/docs/[[...path]]\";"))
  assert_true(content.contains("\"/blog/:slug\": { slug: string; };"))
  assert_true(content.contains("\"/docs/[[...path]]\": { path?: string | null; };"))
  assert_true(content.contains("export type SolRouteParamsOf<P extends SolRoutePath> = SolRouteParams[P];"))
  assert_true(content.contains("export type SolActionId = \"submit-contact\";"))
  assert_true(content.contains("export interface SolActionKey<I extends SolActionId = SolActionId> {"))
}

///|
test "moonbit_type_to_typescript_type: handles nested arrays and optionals" {
  assert_eq(
    moonbit_type_to_typescript_type("Array[String?]"),
    "(string | null)[]",
  )
  assert_eq(moonbit_type_to_typescript_type("Array[Array[Int]]"), "number[][]")
}

///|
test "default_json_value: unknown custom types fall back to object" {
  assert_eq(default_json_value("@app.CustomType"), "{}")
}
