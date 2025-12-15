///|
/// Unit tests for generate.mbt pure functions

// =============================================================================
// Config Parser Tests
// =============================================================================

test "parse_sol_config: valid config" {
  let json =
    #|{
    #|  "islands": ["app/client/*"],
    #|  "routes": "app/routes",
    #|  "output": "app/__gen__"
    #|}
  let config = parse_sol_config(json)
  assert_true(config.is_some())
  let c = config.unwrap()
  assert_eq(c.islands.length(), 1)
  assert_eq(c.islands[0], "app/client/*")
  assert_eq(c.routes, "app/routes")
  assert_eq(c.output, "app/__gen__")
}

///|
test "parse_sol_config: default output" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/routes"
    #|}
  let config = parse_sol_config(json)
  assert_true(config.is_some())
  assert_eq(config.unwrap().output, "app/__gen__")
}

///|
test "parse_sol_config: invalid json" {
  let json = "not valid json"
  let config = parse_sol_config(json)
  assert_true(config.is_none())
}

// =============================================================================
// MBTI Parser Tests
// =============================================================================

///|
test "parse_mbti_imports: basic imports" {
  let content =
    #|package "myproject/client"
    #|
    #|import(
    #|  "mizchi/luna/core"
    #|  "mizchi/js/node"
    #|)
  let imports = parse_mbti_imports(content)
  assert_eq(imports.get("core"), Some("mizchi/luna/core"))
  assert_eq(imports.get("node"), Some("mizchi/js/node"))
}

///|
test "rewrite_type_refs: luna types" {
  let sig = "(@core.Node[Unit]) -> Unit"
  let result = rewrite_type_refs(sig, {})
  assert_eq(result, "(@luna.Node[Unit]) -> Unit")
}

///|
test "rewrite_type_refs: js types" {
  let sig = "(@core.Any) -> @core.Any"
  let result = rewrite_type_refs(sig, {})
  assert_eq(result, "(@js.Any) -> @js.Any")
}

///|
test "parse_mbti: pub fn extraction" {
  let content =
    #|package "myproject/client"
    #|
    #|pub fn hydrate(element : @core.Any, state : @core.Any, id : String) -> Unit
    #|pub fn render() -> @core.Node[Unit]
  let funcs = parse_mbti(content)
  assert_eq(funcs.length(), 2)
  assert_eq(funcs[0].0, "hydrate")
  assert_true(funcs[0].1.contains("@js.Any"))
  assert_eq(funcs[1].0, "render")
}

///|
test "extract_package_path: valid path" {
  let content =
    #|package "myproject/client/components"
    #|
    #|pub fn render() -> Unit
  let path = extract_package_path(content)
  assert_eq(path, Some("myproject/client/components"))
}

///|
test "extract_package_path: no package" {
  let content = "pub fn render() -> Unit"
  let path = extract_package_path(content)
  assert_true(path.is_none())
}

// =============================================================================
// Name Generation Tests
// =============================================================================

///|
test "extract_island_name: island_client_ prefix" {
  let name = extract_island_name("island_client_hydrate_counter")
  assert_eq(name, "hydrate_counter")
}

///|
test "extract_island_name: island_ prefix" {
  let name = extract_island_name("island_counter")
  assert_eq(name, "counter")
}

///|
test "extract_island_name: no prefix" {
  let name = extract_island_name("my_function")
  assert_eq(name, "my_function")
}

///|
test "generate_import_alias: island" {
  let result = generate_import_alias("myproject/islands/counter", "island")
  assert_eq(result, "island_counter")
}

///|
test "generate_import_alias: page" {
  let result = generate_import_alias("myproject/pages/home", "page")
  assert_eq(result, "page_home")
}

///|
test "generate_import_alias: component" {
  let result = generate_import_alias("myproject/components", "component")
  assert_eq(result, "components")
}

///|
test "generate_export_name: island hydrate" {
  let name = generate_export_name("hydrate", "island_counter", "island")
  assert_eq(name, "island_counter")
}

///|
test "generate_export_name: page page" {
  let name = generate_export_name("page", "page_home", "page")
  assert_eq(name, "page_home")
}

///|
test "generate_export_name: other function" {
  let name = generate_export_name("render", "island_counter", "island")
  assert_eq(name, "island_counter_render")
}

// =============================================================================
// Parameter Parsing Tests
// =============================================================================

///|
test "split_params: simple types" {
  let params = split_params("String, Int, Bool")
  assert_eq(params.length(), 3)
  assert_eq(params[0], "String")
  assert_eq(params[1], "Int")
  assert_eq(params[2], "Bool")
}

///|
test "split_params: nested types" {
  let params = split_params("Array[String], Map[String, Int]")
  assert_eq(params.length(), 2)
  assert_eq(params[0], "Array[String]")
  assert_eq(params[1], "Map[String, Int]")
}

///|
test "split_params: empty" {
  let params = split_params("")
  assert_eq(params.length(), 0)
}

///|
test "find_matching_paren: simple" {
  let s = "(abc)"
  let idx = find_matching_paren(s, 0)
  assert_eq(idx, Some(4))
}

///|
test "find_matching_paren: nested" {
  let s = "((a)(b))"
  let idx = find_matching_paren(s, 0)
  assert_eq(idx, Some(7))
}

///|
test "find_matching_paren: not found" {
  let s = "(abc"
  let idx = find_matching_paren(s, 0)
  assert_true(idx.is_none())
}

///|
test "generate_params_with_names: no params" {
  let (sig, args) = generate_params_with_names("() -> Unit")
  assert_eq(sig, "() -> Unit")
  assert_eq(args, "()")
}

///|
test "generate_params_with_names: single param" {
  let (sig, args) = generate_params_with_names("(String) -> Unit")
  assert_eq(sig, "(p0 : String) -> Unit")
  assert_eq(args, "(p0)")
}

///|
test "generate_params_with_names: multiple params" {
  let (sig, args) = generate_params_with_names("(String, Int) -> Bool")
  assert_eq(sig, "(p0 : String, p1 : Int) -> Bool")
  assert_eq(args, "(p0, p1)")
}

// =============================================================================
// Type Detection Tests
// =============================================================================

///|
test "uses_luna_types: true" {
  assert_true(uses_luna_types("(ctx : @luna.Ctx) -> @luna.Node[Unit]"))
}

///|
test "uses_luna_types: false" {
  assert_true(not(uses_luna_types("(s : String) -> Int")))
}

///|
test "uses_js_types: true" {
  assert_true(uses_js_types("(element : @js.Any) -> Unit"))
}

///|
test "uses_signal_types: true" {
  assert_true(uses_signal_types("(sig : @signal.Signal[Int]) -> Unit"))
}

///|
test "uses_hono_types: true" {
  assert_true(uses_hono_types("(ctx : @hono.Context) -> Unit"))
}
