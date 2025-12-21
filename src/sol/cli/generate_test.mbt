//

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

// =============================================================================
// ComponentRef Factory Tests
// =============================================================================

///|
test "extract_component_name_from_props: simple" {
  let name = extract_component_name_from_props("CounterProps")
  assert_eq(name, "counter")
}

///|
test "extract_component_name_from_props: multi word" {
  let name = extract_component_name_from_props("MyWidgetProps")
  assert_eq(name, "my_widget")
}

///|
test "extract_component_name_from_props: no props suffix" {
  let name = extract_component_name_from_props("Counter")
  assert_eq(name, "counter")
}

///|
test "extract_component_name_from_props: single letter" {
  let name = extract_component_name_from_props("AProps")
  assert_eq(name, "a")
}

///|
test "is_web_component: wc_ prefix" {
  assert_true(is_web_component("wc_counter"))
}

///|
test "is_web_component: no prefix" {
  assert_true(not(is_web_component("counter")))
}

///|
test "extract_component_name_from_props: WcCounterProps" {
  let name = extract_component_name_from_props("WcCounterProps")
  assert_eq(name, "wc_counter")
}

///|
test "is_web_component detects WcCounterProps correctly" {
  let component_name = extract_component_name_from_props("WcCounterProps")
  assert_true(is_web_component(component_name))
}

// =============================================================================
// Runtime Config Tests
// =============================================================================

///|
test "parse_runtime: node" {
  // Use parse_runtime to get enum values (workaround for enum constructor visibility)
  let node = parse_runtime("node")
  let node2 = parse_runtime("node")
  assert_eq(node, node2)
}

///|
test "parse_runtime: cloudflare and aliases" {
  let cf1 = parse_runtime("cloudflare")
  let cf2 = parse_runtime("cf")
  let cf3 = parse_runtime("workers")
  assert_eq(cf1, cf2)
  assert_eq(cf2, cf3)
}

///|
test "parse_runtime: deno" {
  let deno = parse_runtime("deno")
  let deno2 = parse_runtime("deno")
  assert_eq(deno, deno2)
}

///|
test "parse_runtime: bun" {
  let bun = parse_runtime("bun")
  let bun2 = parse_runtime("bun")
  assert_eq(bun, bun2)
}

///|
test "parse_runtime: unknown defaults to node" {
  let node = parse_runtime("node")
  assert_eq(parse_runtime("unknown"), node)
  assert_eq(parse_runtime(""), node)
}

///|
test "parse_runtime: case insensitive" {
  let cf = parse_runtime("cloudflare")
  let deno = parse_runtime("deno")
  let bun = parse_runtime("bun")
  assert_eq(parse_runtime("CLOUDFLARE"), cf)
  assert_eq(parse_runtime("Deno"), deno)
  assert_eq(parse_runtime("BUN"), bun)
}

///|
test "parse_runtime: all runtimes are distinct" {
  let node = parse_runtime("node")
  let cf = parse_runtime("cloudflare")
  let deno = parse_runtime("deno")
  let bun = parse_runtime("bun")
  assert_true(node != cf)
  assert_true(node != deno)
  assert_true(node != bun)
  assert_true(cf != deno)
  assert_true(cf != bun)
  assert_true(deno != bun)
}

///|
test "parse_sol_config: with runtime node" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/routes",
    #|  "runtime": "node"
    #|}
  let config = parse_sol_config(json)
  assert_true(config.is_some())
  assert_eq(config.unwrap().runtime, parse_runtime("node"))
}

///|
test "parse_sol_config: with runtime cloudflare" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/routes",
    #|  "runtime": "cloudflare"
    #|}
  let config = parse_sol_config(json)
  assert_true(config.is_some())
  assert_eq(config.unwrap().runtime, parse_runtime("cloudflare"))
}

///|
test "parse_sol_config: with runtime deno" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/routes",
    #|  "runtime": "deno"
    #|}
  let config = parse_sol_config(json)
  assert_true(config.is_some())
  assert_eq(config.unwrap().runtime, parse_runtime("deno"))
}

///|
test "parse_sol_config: with runtime bun" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/routes",
    #|  "runtime": "bun"
    #|}
  let config = parse_sol_config(json)
  assert_true(config.is_some())
  assert_eq(config.unwrap().runtime, parse_runtime("bun"))
}

///|
test "parse_sol_config: default runtime is node" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/routes"
    #|}
  let config = parse_sol_config(json)
  assert_true(config.is_some())
  assert_eq(config.unwrap().runtime, parse_runtime("node"))
}

// =============================================================================
// Entry Point Generation Tests
// =============================================================================

///|
test "generate_sol_server_main_js: node runtime" {
  let js = generate_sol_server_main_js("myapp/routes", parse_runtime("node"))
  assert_true(js.contains("Runtime: RuntimeNode"))
  assert_true(js.contains("@hono/node-server"))
  assert_true(js.contains("@sol.run()"))
  assert_true(js.contains("export *"))
}

///|
test "generate_sol_server_main_js: cloudflare runtime" {
  let js = generate_sol_server_main_js(
    "myapp/routes",
    parse_runtime("cloudflare"),
  )
  assert_true(js.contains("Runtime: RuntimeCloudflare"))
  assert_true(js.contains("import { Hono } from 'hono'"))
  assert_true(js.contains("import { configure_app }"))
  assert_true(js.contains("const app = configure_app(new Hono())"))
  assert_true(js.contains("export default app"))
}

///|
test "generate_sol_server_main_js: deno runtime" {
  let js = generate_sol_server_main_js("myapp/routes", parse_runtime("deno"))
  assert_true(js.contains("Runtime: RuntimeDeno"))
  assert_true(js.contains("import { Hono } from 'hono'"))
  assert_true(js.contains("import { configure_app }"))
  assert_true(js.contains("Deno.serve"))
  assert_true(js.contains("Deno.env.get('PORT')"))
  assert_true(js.contains("app.fetch"))
}

///|
test "generate_sol_server_main_js: bun runtime" {
  let js = generate_sol_server_main_js("myapp/routes", parse_runtime("bun"))
  assert_true(js.contains("Runtime: RuntimeBun"))
  assert_true(js.contains("import { Hono } from 'hono'"))
  assert_true(js.contains("import { configure_app }"))
  assert_true(js.contains("export default {"))
  assert_true(js.contains("port,"))
  assert_true(js.contains("fetch: app.fetch"))
}

// =============================================================================
// Static Dirs Parser Tests
// =============================================================================

///|
test "parse_sol_config: with staticDirs" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/routes",
    #|  "staticDirs": [
    #|    {
    #|      "path_prefix": "/docs",
    #|      "source_dir": "docs",
    #|      "title": "Documentation"
    #|    }
    #|  ]
    #|}
  let config = parse_sol_config(json)
  assert_true(config.is_some())
  let c = config.unwrap()
  assert_eq(c.static_dirs.length(), 1)
  assert_eq(c.static_dirs[0].path_prefix, "/docs")
  assert_eq(c.static_dirs[0].source_dir, "docs")
  assert_eq(c.static_dirs[0].title, "Documentation")
}

///|
test "parse_sol_config: staticDirs with i18n" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/routes",
    #|  "staticDirs": [
    #|    {
    #|      "path_prefix": "/docs",
    #|      "source_dir": "docs",
    #|      "title": "Docs",
    #|      "i18n": {
    #|        "default_locale": "en",
    #|        "locales": [
    #|          { "code": "en", "label": "English", "path": "" },
    #|          { "code": "ja", "label": "日本語", "path": "ja" }
    #|        ]
    #|      }
    #|    }
    #|  ]
    #|}
  let config = parse_sol_config(json)
  assert_true(config.is_some())
  let c = config.unwrap()
  assert_eq(c.static_dirs.length(), 1)
  let i18n = c.static_dirs[0].i18n
  assert_eq(i18n.default_locale, "en")
  assert_eq(i18n.locales.length(), 2)
  assert_eq(i18n.locales[0].code, "en")
  assert_eq(i18n.locales[1].code, "ja")
  assert_eq(i18n.locales[1].label, "日本語")
  assert_eq(i18n.locales[1].path, "ja")
}

///|
test "parse_sol_config: staticDirs with navigation config" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/routes",
    #|  "staticDirs": [
    #|    {
    #|      "path_prefix": "/docs",
    #|      "source_dir": "docs",
    #|      "navigation": {
    #|        "spa": true,
    #|        "view_transitions": false,
    #|        "keyboard": true
    #|      }
    #|    }
    #|  ]
    #|}
  let config = parse_sol_config(json)
  assert_true(config.is_some())
  let c = config.unwrap()
  let nav = c.static_dirs[0].navigation
  assert_true(nav.spa)
  assert_true(not(nav.view_transitions))
  assert_true(nav.keyboard)
}

///|
test "parse_sol_config: staticDirs with sidebar auto" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/routes",
    #|  "staticDirs": [
    #|    {
    #|      "path_prefix": "/docs",
    #|      "source_dir": "docs",
    #|      "sidebar": "auto"
    #|    }
    #|  ]
    #|}
  let config = parse_sol_config(json)
  assert_true(config.is_some())
  let c = config.unwrap()
  assert_true(c.static_dirs[0].sidebar is @astra.SidebarConfig::Auto)
}

///|
test "parse_sol_config: staticDirs defaults" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/routes",
    #|  "staticDirs": [
    #|    {
    #|      "path_prefix": "/docs",
    #|      "source_dir": "docs"
    #|    }
    #|  ]
    #|}
  let config = parse_sol_config(json)
  assert_true(config.is_some())
  let c = config.unwrap()
  let entry = c.static_dirs[0]
  // Default title
  assert_eq(entry.title, "Documentation")
  // Default trailing_slash
  assert_true(entry.trailing_slash)
  // Default sidebar
  assert_true(entry.sidebar is @astra.SidebarConfig::Auto)
  // Default i18n
  assert_eq(entry.i18n.default_locale, "en")
}

///|
test "parse_sol_config: multiple staticDirs" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/routes",
    #|  "staticDirs": [
    #|    { "path_prefix": "/docs", "source_dir": "docs", "title": "Docs" },
    #|    { "path_prefix": "/blog", "source_dir": "blog", "title": "Blog" }
    #|  ]
    #|}
  let config = parse_sol_config(json)
  assert_true(config.is_some())
  let c = config.unwrap()
  assert_eq(c.static_dirs.length(), 2)
  assert_eq(c.static_dirs[0].path_prefix, "/docs")
  assert_eq(c.static_dirs[1].path_prefix, "/blog")
}

///|
test "parse_sol_config: staticDirs missing required fields" {
  // Missing source_dir
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/routes",
    #|  "staticDirs": [
    #|    { "path_prefix": "/docs" }
    #|  ]
    #|}
  let config = parse_sol_config(json)
  assert_true(config.is_some())
  let c = config.unwrap()
  // Entry should be skipped due to missing source_dir
  assert_eq(c.static_dirs.length(), 0)
}

///|
test "parse_sol_config: empty staticDirs" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/routes",
    #|  "staticDirs": []
    #|}
  let config = parse_sol_config(json)
  assert_true(config.is_some())
  assert_eq(config.unwrap().static_dirs.length(), 0)
}

///|
test "parse_sol_config: no staticDirs field" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/routes"
    #|}
  let config = parse_sol_config(json)
  assert_true(config.is_some())
  assert_eq(config.unwrap().static_dirs.length(), 0)
}

///|
test "parse_sol_config: staticDirs with exclude" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/routes",
    #|  "staticDirs": [
    #|    {
    #|      "path_prefix": "/docs",
    #|      "source_dir": "docs",
    #|      "exclude": ["internal", "drafts"]
    #|    }
    #|  ]
    #|}
  let config = parse_sol_config(json)
  assert_true(config.is_some())
  let c = config.unwrap()
  assert_eq(c.static_dirs[0].exclude.length(), 2)
  assert_eq(c.static_dirs[0].exclude[0], "internal")
  assert_eq(c.static_dirs[0].exclude[1], "drafts")
}

///|
test "parse_sol_config: staticDirs with theme" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/routes",
    #|  "staticDirs": [
    #|    {
    #|      "path_prefix": "/docs",
    #|      "source_dir": "docs",
    #|      "theme": {
    #|        "primary_color": "#ff6600",
    #|        "logo": "/logo.svg"
    #|      }
    #|    }
    #|  ]
    #|}
  let config = parse_sol_config(json)
  assert_true(config.is_some())
  let c = config.unwrap()
  let theme = c.static_dirs[0].theme
  assert_eq(theme.primary_color, Some("#ff6600"))
  assert_eq(theme.logo, Some("/logo.svg"))
}

///|
test "parse_sol_config: staticDirs with ogp" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/routes",
    #|  "staticDirs": [
    #|    {
    #|      "path_prefix": "/docs",
    #|      "source_dir": "docs",
    #|      "ogp": {
    #|        "site_url": "https://example.com",
    #|        "image": "/og-image.png",
    #|        "twitter_handle": "@example"
    #|      }
    #|    }
    #|  ]
    #|}
  let config = parse_sol_config(json)
  assert_true(config.is_some())
  let c = config.unwrap()
  let ogp = c.static_dirs[0].ogp
  assert_eq(ogp.site_url, Some("https://example.com"))
  assert_eq(ogp.image, Some("/og-image.png"))
  assert_eq(ogp.twitter_handle, Some("@example"))
}
