///|
using @test {assert_eq}

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
    #|  "routes": "app/server",
    #|  "output": "app/__gen__"
    #|}
  let config = @cli.parse_sol_config(json)
  assert_true(config is Some(_))
  let c = config.unwrap()
  assert_eq(c.islands.length(), 1)
  assert_eq(c.islands[0], "app/client/*")
  assert_eq(c.routes, "app/server")
  assert_eq(c.output, "app/__gen__")
}

///|
test "parse_sol_config: default output" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/server"
    #|}
  let config = @cli.parse_sol_config(json)
  assert_true(config is Some(_))
  assert_eq(config.unwrap().output, "app/__gen__")
}

///|
test "parse_sol_config: invalid json" {
  let json = "not valid json"
  let config = @cli.parse_sol_config(json)
  assert_true(config is None)
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
    #|  "mizchi/js_node"
    #|)
  let imports = @cli.parse_mbti_imports(content)
  assert_eq(imports.get("core"), Some("mizchi/luna/core"))
  assert_eq(imports.get("js_node"), Some("mizchi/js_node"))
}

///|
test "rewrite_type_refs: luna types" {
  let sig = "(@core.Node[Unit]) -> Unit"
  let result = @cli.rewrite_type_refs(sig, {})
  assert_eq(result, "(@luna.Node[Unit, String]) -> Unit")
}

///|
test "rewrite_type_refs: js types" {
  let sig = "(@core.Any) -> @core.Any"
  let result = @cli.rewrite_type_refs(sig, {})
  assert_eq(result, "(@js.Any) -> @js.Any")
}

///|
test "parse_mbti: pub fn extraction" {
  let content =
    #|package "myproject/client"
    #|
    #|pub fn hydrate(element : @core.Any, state : @core.Any, id : String) -> Unit
    #|pub fn render() -> @core.Node[Unit]
  let funcs = @cli.parse_mbti(content)
  assert_eq(funcs.length(), 2)
  assert_eq(funcs[0].0, "hydrate")
  assert_true(funcs[0].1.contains("@js.Any"))
  assert_eq(funcs[1].0, "render")
}

///|
test "parse_mbti: associated methods are not island entry points" {
  let content =
    #|package "myproject/client"
    #|
    #|pub fn counter(CounterProps) -> @element.DomNode
    #|pub fn CounterProps::to_json(Self) -> Json
    #|pub fn CounterProps::from_json(Json, @json.JsonPath) -> Self raise @json.JsonDecodeError
    #|pub fn CounterProps::new(Int) -> Self
    #|pub fn api_tools(ApiToolsProps) -> @element.DomNode
  let funcs = @cli.parse_mbti(content)
  assert_eq(funcs.length(), 2)
  assert_eq(funcs[0].0, "counter")
  assert_eq(funcs[1].0, "api_tools")
}

///|
test "extract_package_path: valid path" {
  let content =
    #|package "myproject/client/components"
    #|
    #|pub fn render() -> Unit
  let path = @cli.extract_package_path(content)
  assert_eq(path, Some("myproject/client/components"))
}

///|
test "extract_package_path: no package" {
  let content = "pub fn render() -> Unit"
  let path = @cli.extract_package_path(content)
  assert_true(path is None)
}

// =============================================================================
// Name Generation Tests
// =============================================================================

///|
test "extract_island_name: island_client_ prefix" {
  let name = @cli.extract_island_name("island_client_hydrate_counter")
  assert_eq(name, "hydrate_counter")
}

///|
test "extract_island_name: island_ prefix" {
  let name = @cli.extract_island_name("island_counter")
  assert_eq(name, "counter")
}

///|
test "extract_island_name: no prefix" {
  let name = @cli.extract_island_name("my_function")
  assert_eq(name, "my_function")
}

///|
test "generate_import_alias: island" {
  let result = @cli.generate_import_alias("myproject/islands/counter", "island")
  assert_eq(result, "island_counter")
}

///|
test "generate_import_alias: page" {
  let result = @cli.generate_import_alias("myproject/pages/home", "page")
  assert_eq(result, "page_home")
}

///|
test "generate_import_alias: component" {
  let result = @cli.generate_import_alias("myproject/components", "component")
  assert_eq(result, "components")
}

///|
test "generate_export_name: island hydrate" {
  let name = @cli.generate_export_name("hydrate", "island_counter", "island")
  assert_eq(name, "island_counter")
}

///|
test "generate_export_name: page page" {
  let name = @cli.generate_export_name("page", "page_home", "page")
  assert_eq(name, "page_home")
}

///|
test "generate_export_name: other function" {
  let name = @cli.generate_export_name("render", "island_counter", "island")
  assert_eq(name, "island_counter_render")
}

// =============================================================================
// Parameter Parsing Tests
// =============================================================================

///|
test "split_params: simple types" {
  let params = @cli.split_params("String, Int, Bool")
  assert_eq(params.length(), 3)
  assert_eq(params[0], "String")
  assert_eq(params[1], "Int")
  assert_eq(params[2], "Bool")
}

///|
test "split_params: nested types" {
  let params = @cli.split_params("Array[String], Map[String, Int]")
  assert_eq(params.length(), 2)
  assert_eq(params[0], "Array[String]")
  assert_eq(params[1], "Map[String, Int]")
}

///|
test "split_params: empty" {
  let params = @cli.split_params("")
  assert_eq(params.length(), 0)
}

///|
test "find_matching_paren: simple" {
  let s = "(abc)"
  let idx = @cli.find_matching_paren(s, 0)
  assert_eq(idx, Some(4))
}

///|
test "find_matching_paren: nested" {
  let s = "((a)(b))"
  let idx = @cli.find_matching_paren(s, 0)
  assert_eq(idx, Some(7))
}

///|
test "find_matching_paren: not found" {
  let s = "(abc"
  let idx = @cli.find_matching_paren(s, 0)
  assert_true(idx is None)
}

///|
test "generate_params_with_names: no params" {
  let (sig, args) = @cli.generate_params_with_names("() -> Unit")
  assert_eq(sig, "() -> Unit")
  assert_eq(args, "()")
}

///|
test "generate_params_with_names: single param" {
  let (sig, args) = @cli.generate_params_with_names("(String) -> Unit")
  assert_eq(sig, "(p0 : String) -> Unit")
  assert_eq(args, "(p0)")
}

///|
test "generate_params_with_names: multiple params" {
  let (sig, args) = @cli.generate_params_with_names("(String, Int) -> Bool")
  assert_eq(sig, "(p0 : String, p1 : Int) -> Bool")
  assert_eq(args, "(p0, p1)")
}

// =============================================================================
// Type Detection Tests
// =============================================================================

///|
test "uses_luna_types: true" {
  assert_true(
    @cli.uses_luna_types("(ctx : @luna.Ctx) -> @luna.Node[Unit, String]"),
  )
}

///|
test "uses_luna_types: false" {
  assert_true(!@cli.uses_luna_types("(s : String) -> Int"))
}

///|
test "uses_js_types: true" {
  assert_true(@cli.uses_js_types("(element : @js.Any) -> Unit"))
}

///|
test "uses_signal_types: true" {
  assert_true(@cli.uses_signal_types("(sig : @signal.Signal[Int]) -> Unit"))
}

///|
test "uses_hono_types: true" {
  assert_true(@cli.uses_hono_types("(ctx : @hono.Context) -> Unit"))
}

// =============================================================================
// ComponentRef Factory Tests
// =============================================================================

///|
test "extract_component_name_from_props: simple" {
  let name = @cli.extract_component_name_from_props("CounterProps")
  assert_eq(name, "counter")
}

///|
test "extract_component_name_from_props: multi word" {
  let name = @cli.extract_component_name_from_props("MyWidgetProps")
  assert_eq(name, "my_widget")
}

///|
test "extract_component_name_from_props: no props suffix" {
  let name = @cli.extract_component_name_from_props("Counter")
  assert_eq(name, "counter")
}

///|
test "extract_component_name_from_props: single letter" {
  let name = @cli.extract_component_name_from_props("AProps")
  assert_eq(name, "a")
}

///|
test "is_web_component: wc_ prefix" {
  assert_true(@cli.is_web_component("wc_counter"))
}

///|
test "is_web_component: no prefix" {
  assert_true(!@cli.is_web_component("counter"))
}

///|
test "extract_component_name_from_props: WcCounterProps" {
  let name = @cli.extract_component_name_from_props("WcCounterProps")
  assert_eq(name, "wc_counter")
}

///|
test "is_web_component detects WcCounterProps correctly" {
  let component_name = @cli.extract_component_name_from_props("WcCounterProps")
  assert_true(@cli.is_web_component(component_name))
}

// =============================================================================
// Runtime Config Tests
// =============================================================================

///|
test "parse_runtime: node" {
  // Use parse_runtime to get enum values (workaround for enum constructor visibility)
  let node = @cli.parse_runtime("node")
  let node2 = @cli.parse_runtime("node")
  assert_eq(node, node2)
}

///|
test "parse_runtime: cloudflare and aliases" {
  let cf1 = @cli.parse_runtime("cloudflare")
  let cf2 = @cli.parse_runtime("cf")
  let cf3 = @cli.parse_runtime("workers")
  assert_eq(cf1, cf2)
  assert_eq(cf2, cf3)
}

///|
test "parse_runtime: deno" {
  let deno = @cli.parse_runtime("deno")
  let deno2 = @cli.parse_runtime("deno")
  assert_eq(deno, deno2)
}

///|
test "parse_runtime: bun" {
  let bun = @cli.parse_runtime("bun")
  let bun2 = @cli.parse_runtime("bun")
  assert_eq(bun, bun2)
}

///|
test "parse_runtime: unknown defaults to node" {
  let node = @cli.parse_runtime("node")
  assert_eq(@cli.parse_runtime("unknown"), node)
  assert_eq(@cli.parse_runtime(""), node)
}

///|
test "parse_runtime: case insensitive" {
  let cf = @cli.parse_runtime("cloudflare")
  let deno = @cli.parse_runtime("deno")
  let bun = @cli.parse_runtime("bun")
  assert_eq(@cli.parse_runtime("CLOUDFLARE"), cf)
  assert_eq(@cli.parse_runtime("Deno"), deno)
  assert_eq(@cli.parse_runtime("BUN"), bun)
}

///|
test "parse_runtime: all runtimes are distinct" {
  let node = @cli.parse_runtime("node")
  let cf = @cli.parse_runtime("cloudflare")
  let deno = @cli.parse_runtime("deno")
  let bun = @cli.parse_runtime("bun")
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
    #|  "routes": "app/server",
    #|  "runtime": "node"
    #|}
  let config = @cli.parse_sol_config(json)
  assert_true(config is Some(_))
  assert_eq(config.unwrap().runtime, @cli.parse_runtime("node"))
}

///|
test "parse_sol_config: with runtime cloudflare" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/server",
    #|  "runtime": "cloudflare"
    #|}
  let config = @cli.parse_sol_config(json)
  assert_true(config is Some(_))
  assert_eq(config.unwrap().runtime, @cli.parse_runtime("cloudflare"))
}

///|
test "parse_sol_config: with runtime deno" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/server",
    #|  "runtime": "deno"
    #|}
  let config = @cli.parse_sol_config(json)
  assert_true(config is Some(_))
  assert_eq(config.unwrap().runtime, @cli.parse_runtime("deno"))
}

///|
test "parse_sol_config: with runtime bun" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/server",
    #|  "runtime": "bun"
    #|}
  let config = @cli.parse_sol_config(json)
  assert_true(config is Some(_))
  assert_eq(config.unwrap().runtime, @cli.parse_runtime("bun"))
}

///|
test "parse_sol_config: default runtime is node" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/server"
    #|}
  let config = @cli.parse_sol_config(json)
  assert_true(config is Some(_))
  assert_eq(config.unwrap().runtime, @cli.parse_runtime("node"))
}

// =============================================================================
// Entry Point Generation Tests
// =============================================================================

///|
test "generate_sol_server_main_js: node runtime" {
  let js = @cli.generate_sol_server_main_js(
    "myapp/server",
    @cli.parse_runtime("node"),
    "prod",
    "myapp/__gen__/server",
  )
  assert_true(js.contains("Runtime: RuntimeNode"))
  assert_true(js.contains("@hono/node-server"))
  assert_true(js.contains("@sol.run()"))
  assert_true(js.contains("export *"))
  assert_true(
    js.contains(
      "import * as server from '../../../_build/js/release/build/myapp/__gen__/server/server.js'",
    ),
  )
}

///|
test "generate_sol_serve_js: node adapter uses exported global app fallback" {
  let js = @cli.generate_sol_serve_js(@cli.parse_runtime("node"))
  assert_true(js.contains("process.env.SOL_ADAPTER = '1'"))
  assert_true(js.contains("m.default || globalThis.__SOL_APP__"))
  assert_true(js.contains("@hono/node-server"))
}

///|
test "generate_sol_server_main_js: cloudflare runtime" {
  let js = @cli.generate_sol_server_main_js(
    "myapp/server",
    @cli.parse_runtime("cloudflare"),
    "prod",
    "myapp/__gen__/server",
  )
  assert_true(js.contains("Runtime: RuntimeCloudflare"))
  assert_true(
    js.contains(
      "await import('../../../_build/js/release/build/myapp/__gen__/server/server.js')",
    ),
  )
  assert_true(js.contains("globalThis.__SOL_APP__"))
  assert_true(js.contains("export default app"))
  assert_true(js.contains("globalThis.__SOL_RUNTIME__ = 'cloudflare'"))
  assert_true(js.contains("await import("))
  assert_false(js.contains("await new Promise"))
  assert_false(js.contains("setInterval"))
}

///|
test "generate_sol_server_main_js: deno runtime" {
  let js = @cli.generate_sol_server_main_js(
    "myapp/server",
    @cli.parse_runtime("deno"),
    "prod",
    "myapp/__gen__/server",
  )
  assert_true(js.contains("Runtime: RuntimeDeno"))
  assert_true(
    js.contains(
      "import '../../../_build/js/release/build/myapp/__gen__/server/server.js'",
    ),
  )
  assert_true(js.contains("globalThis.__SOL_APP__"))
  assert_true(js.contains("Deno.serve"))
  assert_true(js.contains("Deno.env.get('PORT')"))
  assert_true(js.contains("app.fetch"))
}

///|
test "generate_sol_server_main_js: bun runtime" {
  let js = @cli.generate_sol_server_main_js(
    "myapp/server",
    @cli.parse_runtime("bun"),
    "prod",
    "myapp/__gen__/server",
  )
  assert_true(js.contains("Runtime: RuntimeBun"))
  assert_true(
    js.contains(
      "import '../../../_build/js/release/build/myapp/__gen__/server/server.js'",
    ),
  )
  assert_true(js.contains("globalThis.__SOL_APP__"))
  assert_true(js.contains("export default {"))
  assert_true(js.contains("port,"))
  assert_true(js.contains("fetch: app.fetch"))
}

///|
test "generate_sol_server_main_js: dev mode uses debug build path" {
  let js = @cli.generate_sol_server_main_js(
    "myapp/server",
    @cli.parse_runtime("node"),
    "dev",
    "myapp/__gen__/server",
  )
  assert_true(
    js.contains(
      "import * as server from '../../../_build/js/debug/build/myapp/__gen__/server/server.js'",
    ),
  )
  assert_true(
    js.contains(
      "export * from '../../../_build/js/debug/build/myapp/__gen__/server/server.js'",
    ),
  )
}

// =============================================================================
// Static Dirs Parser Tests
// =============================================================================

///|
test "parse_sol_config: with staticDirs" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/server",
    #|  "staticDirs": [
    #|    {
    #|      "path_prefix": "/docs",
    #|      "source_dir": "docs",
    #|      "title": "Documentation"
    #|    }
    #|  ]
    #|}
  let config = @cli.parse_sol_config(json)
  assert_true(config is Some(_))
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
    #|  "routes": "app/server",
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
  let config = @cli.parse_sol_config(json)
  assert_true(config is Some(_))
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
    #|  "routes": "app/server",
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
  let config = @cli.parse_sol_config(json)
  assert_true(config is Some(_))
  let c = config.unwrap()
  let nav = c.static_dirs[0].navigation
  assert_true(nav.spa)
  assert_true(!nav.view_transitions)
  assert_true(nav.keyboard)
}

///|
test "parse_sol_config: staticDirs with sidebar auto" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/server",
    #|  "staticDirs": [
    #|    {
    #|      "path_prefix": "/docs",
    #|      "source_dir": "docs",
    #|      "sidebar": "auto"
    #|    }
    #|  ]
    #|}
  let config = @cli.parse_sol_config(json)
  assert_true(config is Some(_))
  let c = config.unwrap()
  assert_true(c.static_dirs[0].sidebar is @astra.SidebarConfig::Auto)
}

///|
test "parse_sol_config: staticDirs defaults" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/server",
    #|  "staticDirs": [
    #|    {
    #|      "path_prefix": "/docs",
    #|      "source_dir": "docs"
    #|    }
    #|  ]
    #|}
  let config = @cli.parse_sol_config(json)
  assert_true(config is Some(_))
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
    #|  "routes": "app/server",
    #|  "staticDirs": [
    #|    { "path_prefix": "/docs", "source_dir": "docs", "title": "Docs" },
    #|    { "path_prefix": "/blog", "source_dir": "blog", "title": "Blog" }
    #|  ]
    #|}
  let config = @cli.parse_sol_config(json)
  assert_true(config is Some(_))
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
    #|  "routes": "app/server",
    #|  "staticDirs": [
    #|    { "path_prefix": "/docs" }
    #|  ]
    #|}
  let config = @cli.parse_sol_config(json)
  assert_true(config is Some(_))
  let c = config.unwrap()
  // Entry should be skipped due to missing source_dir
  assert_eq(c.static_dirs.length(), 0)
}

///|
test "parse_sol_config: empty staticDirs" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/server",
    #|  "staticDirs": []
    #|}
  let config = @cli.parse_sol_config(json)
  assert_true(config is Some(_))
  assert_eq(config.unwrap().static_dirs.length(), 0)
}

///|
test "parse_sol_config: no staticDirs field" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/server"
    #|}
  let config = @cli.parse_sol_config(json)
  assert_true(config is Some(_))
  assert_eq(config.unwrap().static_dirs.length(), 0)
}

///|
test "parse_sol_config: staticDirs with exclude" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/server",
    #|  "staticDirs": [
    #|    {
    #|      "path_prefix": "/docs",
    #|      "source_dir": "docs",
    #|      "exclude": ["internal", "drafts"]
    #|    }
    #|  ]
    #|}
  let config = @cli.parse_sol_config(json)
  assert_true(config is Some(_))
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
    #|  "routes": "app/server",
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
  let config = @cli.parse_sol_config(json)
  assert_true(config is Some(_))
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
    #|  "routes": "app/server",
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
  let config = @cli.parse_sol_config(json)
  assert_true(config is Some(_))
  let c = config.unwrap()
  let ogp = c.static_dirs[0].ogp
  assert_eq(ogp.site_url, Some("https://example.com"))
  assert_eq(ogp.image, Some("/og-image.png"))
  assert_eq(ogp.twitter_handle, Some("@example"))
}

// =============================================================================
// Wasm Entrypoints (mbtx + wasip2/wagi) Tests
// =============================================================================

///|
test "parse_sol_config: with wasmEntryPoints" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/server",
    #|  "wasmEntryPoints": [
    #|    {
    #|      "id": "users_show",
    #|      "route": "/users/:id",
    #|      "source": "app/entries/users_show.mbtx",
    #|      "runtime": "wagi",
    #|      "method": ["GET", "POST"]
    #|    }
    #|  ]
    #|}
  let config = @cli.parse_sol_config(json)
  assert_true(config is Some(_))
  let c = config.unwrap()
  assert_eq(c.wasm_entrypoints.length(), 1)
  let ep = c.wasm_entrypoints[0]
  assert_eq(ep.id, "users_show")
  assert_eq(ep.route, "/users/:id")
  assert_eq(ep.source, "app/entries/users_show.mbtx")
  assert_eq(ep.runtime, @cli.parse_wasm_entrypoint_runtime("wagi"))
  assert_eq(ep.methods.length(), 2)
  assert_eq(ep.methods[0], "GET")
  assert_eq(ep.methods[1], "POST")
}

///|
test "parse_sol_config: wasmEntryPoints defaults" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/server",
    #|  "wasmEntryPoints": [
    #|    {
    #|      "id": "health",
    #|      "route": "/health",
    #|      "source": "app/entries/health.mbtx"
    #|    }
    #|  ]
    #|}
  let config = @cli.parse_sol_config(json)
  assert_true(config is Some(_))
  let c = config.unwrap()
  assert_eq(c.wasm_entrypoints.length(), 1)
  let ep = c.wasm_entrypoints[0]
  assert_eq(ep.runtime, @cli.parse_wasm_entrypoint_runtime("wagi"))
  assert_eq(ep.methods.length(), 1)
  assert_eq(ep.methods[0], "GET")
}

///|
test "parse_sol_config: wasmEntryPoints with env and wac source" {
  let json =
    #|{
    #|  "islands": [],
    #|  "routes": "app/server",
    #|  "wasmEntryPoints": [
    #|    {
    #|      "id": "composed_users",
    #|      "route": "/users/composed",
    #|      "source": "app/entries/users_show.wac",
    #|      "runtime": "wagi",
    #|      "method": ["GET"],
    #|      "env": {
    #|        "API_ORIGIN": "https://api.example.com",
    #|        "FEATURE_FLAG": "on"
    #|      }
    #|    }
    #|  ]
    #|}
  let config = @cli.parse_sol_config(json)
  assert_true(config is Some(_))
  let c = config.unwrap()
  assert_eq(c.wasm_entrypoints.length(), 1)
  let ep = c.wasm_entrypoints[0]
  assert_eq(ep.source, "app/entries/users_show.wac")
  assert_true(ep.env.contains("API_ORIGIN"))
  assert_true(ep.env.contains("FEATURE_FLAG"))
  assert_eq(ep.env["API_ORIGIN"], "https://api.example.com")
  assert_eq(ep.env["FEATURE_FLAG"], "on")
}

///|
test "generate_wasm_manifest_json: includes route runtime and wasm path" {
  let entries : Array[@cli.WasmMountEntry] = [
    @cli.WasmMountEntry::new(
      "users_show",
      "/users/:id",
      ["GET"],
      @cli.parse_wasm_entrypoint_runtime("wagi"),
      ".sol/wasm/entries/users_show/module.wasm",
    ),
  ]
  let manifest = @cli.generate_wasm_manifest_json(entries)
  assert_true(manifest.contains("\"id\": \"users_show\""))
  assert_true(manifest.contains("\"route\": \"/users/:id\""))
  assert_true(manifest.contains("\"runtime\": \"wagi\""))
  assert_true(
    manifest.contains("\"wasm\": \".sol/wasm/entries/users_show/module.wasm\""),
  )
}

///|
test "generate_wasm_manifest_json: includes env and build metadata" {
  let env_map : Map[String, String] = {
    "API_ORIGIN": "https://api.example.com",
    "FEATURE_FLAG": "on",
  }
  let entries : Array[@cli.WasmMountEntry] = [
    @cli.WasmMountEntry::new(
      "users_show",
      "/users/:id",
      ["GET"],
      @cli.parse_wasm_entrypoint_runtime("wagi"),
      ".sol/wasm/entries/users_show/module.wasm",
      env=env_map,
    ),
  ]
  let manifest = @cli.generate_wasm_manifest_json(entries)
  assert_true(manifest.contains("\"build\": \"moon-build\""))
  assert_true(manifest.contains("\"env\": {"))
  assert_true(manifest.contains("\"API_ORIGIN\": \"https://api.example.com\""))
  assert_true(manifest.contains("\"FEATURE_FLAG\": \"on\""))
}

///|
test "generate_wasm_env_json: includes runtime and env map" {
  let entries : Array[@cli.WasmMountEntry] = [
    @cli.WasmMountEntry::new(
      "users_show",
      "/users/:id",
      ["GET"],
      @cli.parse_wasm_entrypoint_runtime("wagi"),
      ".sol/wasm/entries/users_show/module.wasm",
      env={ "API_ORIGIN": "https://api.example.com" },
    ),
  ]
  let env_json = @cli.generate_wasm_env_json(entries)
  assert_true(env_json.contains("\"id\": \"users_show\""))
  assert_true(env_json.contains("\"runtime\": \"wagi\""))
  assert_true(env_json.contains("\"API_ORIGIN\": \"https://api.example.com\""))
}

///|
test "generate_spin_toml_fragment: wagi route mount" {
  let entries : Array[@cli.WasmMountEntry] = [
    @cli.WasmMountEntry::new(
      "users_show",
      "/users/:id",
      ["GET", "POST"],
      @cli.parse_wasm_entrypoint_runtime("wagi"),
      ".sol/wasm/entries/users_show/module.wasm",
    ),
  ]
  let fragment = @cli.generate_spin_toml_fragment(entries)
  assert_true(fragment.contains("[[trigger.http]]"))
  assert_true(fragment.contains("route = \"/users/:id\""))
  assert_true(fragment.contains("component = \"users_show\""))
  assert_true(fragment.contains("[component.users_show]"))
  assert_true(fragment.contains("executor = \"wagi\""))
}

///|
test "generate_spin_toml_fragment: includes environment table" {
  let entries : Array[@cli.WasmMountEntry] = [
    @cli.WasmMountEntry::new(
      "users_show",
      "/users/:id",
      ["GET"],
      @cli.parse_wasm_entrypoint_runtime("wagi"),
      ".sol/wasm/entries/users_show/module.wasm",
      env={ "API_ORIGIN": "https://api.example.com", "FEATURE_FLAG": "on" },
    ),
  ]
  let fragment = @cli.generate_spin_toml_fragment(entries)
  assert_true(fragment.contains("[component.users_show.environment]"))
  assert_true(fragment.contains("API_ORIGIN = \"https://api.example.com\""))
  assert_true(fragment.contains("FEATURE_FLAG = \"on\""))
}

///|
test "generate_mars_adapter_hints: includes spin_wagi manifest hints" {
  let entries : Array[@cli.WasmMountEntry] = [
    @cli.WasmMountEntry::new(
      "users_show",
      "/users/:id",
      ["GET"],
      @cli.parse_wasm_entrypoint_runtime("wagi"),
      ".sol/wasm/entries/users_show/module.wasm",
    ),
  ]
  let hints = @cli.generate_mars_adapter_hints(entries)
  assert_true(hints.contains("# spin_wagi: users_show"))
  assert_true(
    hints.contains(
      "[component.users_show] route=\"/users/:id\" executor=\"wagi\"",
    ),
  )
}

///|
test "generate_mars_adapter_hints: includes wasm_component binding hints" {
  let entries : Array[@cli.WasmMountEntry] = [
    @cli.WasmMountEntry::new(
      "users_component",
      "/users/component",
      ["POST"],
      @cli.parse_wasm_entrypoint_runtime("component"),
      ".sol/wasm/entries/users_component/module.wasm",
    ),
  ]
  let hints = @cli.generate_mars_adapter_hints(entries)
  assert_true(hints.contains("# wasm_component: users_component"))
  assert_true(
    hints.contains(
      "component=users_component world=http-component export=handle",
    ),
  )
}

///|
test "WasmEntrypointBuildOptions::default has ergonomic defaults" {
  let opts = @cli.WasmEntrypointBuildOptions::default()
  assert_true(opts.runtime_override is None)
  assert_eq(opts.emit_spin_fragment, false)
  assert_eq(opts.emit_env_json, true)
  assert_eq(opts.write_if_changed, true)
}

///|
test "WasmEntrypointBuildOptions::for_cli maps legacy flags" {
  let opts = @cli.WasmEntrypointBuildOptions::for_cli(
    runtime_override=Some(@cli.parse_wasm_entrypoint_runtime("wagi")),
    emit_spin_fragment=true,
  )
  assert_true(opts.runtime_override is Some(_))
  assert_eq(opts.emit_spin_fragment, true)
  assert_eq(opts.emit_env_json, true)
  assert_eq(opts.write_if_changed, true)
}

// =============================================================================
// User-Managed Server Entry Point Tests
// =============================================================================

///|
test "generate_sol_server_main_js_user_managed: node runtime uses server/server.js path" {
  let js = @cli.generate_sol_server_main_js_user_managed(
    @cli.parse_runtime("node"),
    "prod",
    "myapp/server",
  )
  assert_true(js.contains("user-managed MoonBit mode"))
  assert_true(
    js.contains(
      "import * as server from '../../../_build/js/release/build/myapp/server/server.js'",
    ),
  )
  assert_true(
    js.contains(
      "export * from '../../../_build/js/release/build/myapp/server/server.js'",
    ),
  )
  // Must NOT reference __gen__/server
  assert_true(!js.contains("__gen__"))
}

///|
test "generate_sol_server_main_js_user_managed: dev mode uses debug path" {
  let js = @cli.generate_sol_server_main_js_user_managed(
    @cli.parse_runtime("node"),
    "dev",
    "myapp/server",
  )
  assert_true(
    js.contains(
      "import * as server from '../../../_build/js/debug/build/myapp/server/server.js'",
    ),
  )
  assert_true(!js.contains("__gen__"))
}

///|
test "generate_sol_server_main_js_user_managed: cloudflare runtime" {
  let js = @cli.generate_sol_server_main_js_user_managed(
    @cli.parse_runtime("cloudflare"),
    "prod",
    "myapp/server",
  )
  assert_true(js.contains("RuntimeCloudflare"))
  assert_true(js.contains("globalThis.__SOL_APP__"))
  assert_true(js.contains("export default app"))
  assert_true(
    js.contains(
      "await import('../../../_build/js/release/build/myapp/server/server.js')",
    ),
  )
  assert_true(js.contains("globalThis.__SOL_RUNTIME__ = 'cloudflare'"))
  assert_false(js.contains("await new Promise"))
  assert_false(js.contains("setInterval"))
  assert_true(!js.contains("__gen__"))
}

///|
test "generate_sol_server_main_js_user_managed: deno runtime" {
  let js = @cli.generate_sol_server_main_js_user_managed(
    @cli.parse_runtime("deno"),
    "prod",
    "myapp/server",
  )
  assert_true(js.contains("RuntimeDeno"))
  assert_true(js.contains("Deno.serve"))
  assert_true(js.contains("Deno.env.get('PORT')"))
  assert_true(!js.contains("__gen__"))
}

///|
test "generate_sol_server_main_js_user_managed: bun runtime" {
  let js = @cli.generate_sol_server_main_js_user_managed(
    @cli.parse_runtime("bun"),
    "prod",
    "myapp/server",
  )
  assert_true(js.contains("RuntimeBun"))
  assert_true(js.contains("export default {"))
  assert_true(js.contains("fetch: app.fetch"))
  assert_true(!js.contains("__gen__"))
}

///|
test "template_routes_main_mbt: has async fn main and create_app facade" {
  let content = @cli.template_routes_main_mbt()
  assert_true(content.contains("async fn main {"))
  assert_true(content.contains("@sol.run_app"))
  assert_true(content.contains("@sol.create_app(routes()"))
  // Should NOT reference @mars, @router, @action directly
  assert_true(!content.contains("@mars."))
  assert_true(!content.contains("@router."))
  assert_true(!content.contains("@action."))
}

///|
test "template_routes_moon_pkg: user-managed has is-main, minimal imports" {
  let content = @cli.template_routes_moon_pkg("tester/myapp")
  assert_true(content.contains("\"is-main\": true"))
  assert_true(content.contains("\"mizchi/sol\" @sol"))
  assert_true(content.contains("\"moonbitlang/async\""))
  assert_true(content.contains("\"format\": \"esm\""))
  // Should NOT require @mars, @router, or @action (re-exported via @sol)
  assert_true(!content.contains("\"mizchi/mars\""))
  assert_true(!content.contains("\"mizchi/sol/router\""))
  assert_true(!content.contains("\"mizchi/sol/action\""))
  // Should NOT export configure_app (no longer exists)
  assert_true(!content.contains("configure_app"))
}

///|
test "generate_templates: includes app/server/main.mbt" {
  let templates = @cli.generate_templates("tester/myapp", "myapp", None)
  let main_mbt = find_template_content(templates, "app/server/main.mbt")
  assert_true(main_mbt is Some(_))
  assert_true(main_mbt.unwrap().contains("async fn main"))
}

///|
fn find_template_content(
  templates : Array[@cli.TemplateFile],
  path : String,
) -> String? {
  for file in templates {
    if file.path == path {
      return Some(file.content)
    }
  }
  None
}

///|
test "generate_templates: moon.mod includes sol and mars dependencies" {
  let templates = @cli.generate_templates("tester/myapp", "myapp", None)
  let content = find_template_content(templates, "moon.mod").unwrap_or("")
  assert_true(content.contains("\"mizchi/sol@"))
  assert_true(content.contains("\"mizchi/mars@"))
  assert_true(content.contains("\"mizchi/signals@"))
}

///|
test "template_moon_mod: uses current published moon deps" {
  let templates = @cli.generate_templates("tester/myapp", "myapp", None)
  let content = find_template_content(templates, "moon.mod").unwrap_or("")
  assert_true(content.contains("\"mizchi/sol@\{@version.VERSION}\""))
  assert_true(content.contains("\"mizchi/sol_adapter_node@0.23.4\""))
  assert_true(content.contains("\"mizchi/luna@0.25.2\""))
  assert_true(content.contains("\"mizchi/signals@0.6.6\""))
  assert_true(content.contains("\"mizchi/js@0.13.0\""))
  assert_true(content.contains("\"mizchi/js_core@0.13.0\""))
  assert_true(content.contains("\"mizchi/js_browser@0.13.0\""))
  assert_true(content.contains("\"mizchi/npm_typed@0.1.18\""))
  assert_true(content.contains("\"moonbitlang/async@0.22.5\""))
}

///|
test "generate_templates: dev mode writes moon.work for local luna" {
  let templates = @cli.generate_templates(
    "tester/myapp",
    "myapp",
    Some("../luna"),
  )
  let moon_work = find_template_content(templates, "moon.work").unwrap_or("")
  assert_true(moon_work.contains("members = ["))
  assert_true(moon_work.contains("\".\""))
  assert_true(moon_work.contains("\"../luna\""))
}

///|
test "template_layout_mbt: provides root_layout used by routes template" {
  let content = @cli.template_layout_mbt()
  assert_true(content.contains("pub fn root_layout("))
  assert_true(content.contains("let default_head"))
  assert_true(content.contains("<meta name=\\\"description\\\""))
  assert_true(
    content.contains("<link rel=\\\"icon\\\" href=\\\"/favicon.ico\\\""),
  )
}

///|
test "template_layout_moon_pkg: uses current static dom package path" {
  let content = @cli.template_layout_moon_pkg()
  assert_true(content.contains("\"mizchi/luna/dom/static\" @server_dom"))
  assert_true(!content.contains(" as @"))
}

///|
test "template_gen_types_mbt: includes counter component ref factory" {
  let content = @cli.template_gen_types_mbt()
  assert_true(content.contains("pub fn counter_at("))
  assert_true(content.contains("pub fn counter("))
  assert_true(
    content.contains("counter_at(\"/static/counter.js\", props, trigger~)"),
  )
}

///|
test "template_gen_types_mbt: includes api tools component ref factory" {
  let content = @cli.template_gen_types_mbt()
  assert_true(content.contains("pub(all) struct ApiToolsProps"))
  assert_true(content.contains("pub fn api_tools_at("))
  assert_true(content.contains("pub fn api_tools("))
  assert_true(content.contains("/static/api_tools.js"))
}

///|
test "template_gen_types_moon_pkg: imports luna for ComponentRef types" {
  let content = @cli.template_gen_types_moon_pkg()
  assert_true(content.contains("\"moonbitlang/core/json\""))
  assert_true(content.contains("\"mizchi/luna\" @luna"))
}

///|
test "generate_templates: package.json includes dev/build/serve scripts" {
  let templates = @cli.generate_templates("tester/myapp", "myapp", None)
  let content = find_template_content(templates, "package.json").unwrap_or("")
  assert_true(content.contains("\"scripts\""))
  assert_true(content.contains("\"dev\""))
  assert_true(content.contains("\"build\""))
  assert_true(content.contains("\"serve\""))
}

///|
test "template_package_json: uses current npm deps" {
  let templates = @cli.generate_templates("tester/myapp", "myapp", None)
  let content = find_template_content(templates, "package.json").unwrap_or("")
  assert_true(content.contains("\"hono\": \"^4.13.7\""))
  assert_true(content.contains("\"@hono/node-server\": \"^2.1.1\""))
  assert_true(content.contains("\"rolldown\": \"1.2.8\""))
}

///|
test "generate_templates: package.json avoids unreleased sol npm version" {
  let templates = @cli.generate_templates("tester/myapp", "myapp", None)
  let content = find_template_content(templates, "package.json").unwrap_or("")
  assert_true(!content.contains("\"@luna_ui/sol\""))
  assert_true(!content.contains("^0.8.0"))
}

///|
test "generate_templates: uses flat app/client package layout" {
  let templates = @cli.generate_templates("tester/myapp", "myapp", None)
  let mut has_flat_client_pkg = false
  let mut has_nested_client_pkg = false
  let mut has_flat_client_mbt = false
  for file in templates {
    if file.path == "app/client/moon.pkg" {
      has_flat_client_pkg = true
    }
    if file.path == "app/client/counter.mbt" {
      has_flat_client_mbt = true
    }
    if file.path == "app/client/counter/moon.pkg" {
      has_nested_client_pkg = true
    }
  }
  assert_true(has_flat_client_pkg)
  assert_true(has_flat_client_mbt)
  assert_true(!has_nested_client_pkg)
}

///|
test "template_client_counter_moon_pkg: uses current luna/signals imports" {
  let content = @cli.template_client_counter_moon_pkg()
  assert_true(content.contains("\"moonbitlang/core/json\""))
  assert_true(content.contains("\"mizchi/luna/dom\" @element"))
  assert_true(content.contains("\"mizchi/signals\" @signal"))
  assert_true(content.contains("\"counter\""))
  assert_true(content.contains("\"api_tools\""))
}

///|
test "template_client_api_tools_mbt: scaffolds worker app UX affordances" {
  let content = @cli.template_client_api_tools_mbt()
  assert_true(content.contains("pub(all) struct ApiToolsProps"))
  assert_true(content.contains("copy_to_clipboard"))
  assert_true(content.contains("Copy API URL"))
  assert_true(content.contains("status.update"))
  assert_true(content.contains("Operations Console"))
  assert_true(content.contains("filter_button"))
  assert_true(content.contains("job_row"))
  assert_true(content.contains("Retry Failed"))
  assert_true(content.contains("Pending:"))
  assert_true(content.contains("Last Success:"))
  assert_true(content.contains("Last Error:"))
  assert_true(content.contains("Simulate Error"))
  assert_true(content.contains("Authorization: Bearer dev-token"))
}

///|
test "generate_templates: includes api tools island" {
  let templates = @cli.generate_templates("tester/myapp", "myapp", None)
  assert_true(
    find_template_content(templates, "app/client/api_tools.mbt") is Some(_),
  )
}

///|
test "template_client_counter_mbt: uses modern using syntax" {
  let content = @cli.template_client_counter_mbt()
  assert_true(content.contains("using @element {"))
  assert_true(content.contains("text_of"))
  assert_true(!content.contains("using @element.{"))
}

///|
test "template_routes_moon_pkg: uses current static dom package path" {
  let content = @cli.template_routes_moon_pkg("tester/myapp")
  assert_true(content.contains("\"mizchi/luna/dom/static\" @server_dom"))
  assert_true(!content.contains(" as @"))
}

///|
test "template_routes_moon_pkg: imports sol (action via facade)" {
  let content = @cli.template_routes_moon_pkg("tester/myapp")
  assert_true(content.contains("\"mizchi/sol\" @sol"))
  // @action is no longer needed directly - accessed via @sol.create_app facade
  assert_true(!content.contains("\"mizchi/sol/action\""))
}

///|
test "template_routes_mbt: no action_registry (optional via create_app)" {
  let content = @cli.template_routes_mbt("tester/myapp")
  // action_registry removed from template - actions are optional in create_app
  assert_true(!content.contains("action_registry"))
}

///|
test "template_routes_mbt: starter handlers keep async signature" {
  let content = @cli.template_routes_mbt("tester/myapp")
  assert_true(content.contains("async fn home("))
  assert_true(content.contains("async fn about("))
  assert_true(content.contains("async fn api_health("))
}

///|
test "template_routes_using_mbt: keeps only starter-used tags" {
  let content = @cli.template_routes_using_mbt()
  assert_true(content.contains("div"))
  assert_true(content.contains("button"))
  assert_true(content.contains("h1"))
  assert_true(content.contains("p"))
  assert_true(content.contains("text"))
  assert_true(!content.contains("h2"))
  assert_true(!content.contains("\n  a,\n"))
}

///|
test "template_server_using_mbt: keeps layout-only tags" {
  let content = @cli.template_server_using_mbt()
  assert_true(content.contains("div"))
  assert_true(content.contains("a"))
  assert_true(content.contains("nav"))
  assert_true(content.contains("text"))
  assert_true(content.contains("outlet"))
  assert_true(!content.contains("\n  span,\n"))
  assert_true(!content.contains("\n  button,\n"))
  assert_true(!content.contains("\n  h1,\n"))
  assert_true(!content.contains("\n  p,\n"))
}

///|
test "generate_cloudflare_templates: writes worker composition starter" {
  let templates = @cli.generate_cloudflare_templates(
    "tester/myapp",
    "myapp",
    None,
  )
  let config = find_template_content(templates, "sol.config.json").unwrap_or("")
  let moon_mod = find_template_content(templates, "moon.mod").unwrap_or("")
  let server_pkg = find_template_content(templates, "app/server/moon.pkg").unwrap_or(
    "",
  )
  let server_main = find_template_content(templates, "app/server/main.mbt").unwrap_or(
    "",
  )
  let worker = find_template_content(templates, "worker.entry.mjs").unwrap_or(
    "",
  )
  let worker_dev = find_template_content(templates, "worker.entry.dev.mjs").unwrap_or(
    "",
  )
  let wrangler = find_template_content(templates, "wrangler.toml").unwrap_or("")
  let wrangler_dev = find_template_content(templates, "wrangler.dev.toml").unwrap_or(
    "",
  )
  let playwright = find_template_content(templates, "playwright.config.ts").unwrap_or(
    "",
  )
  let e2e = find_template_content(templates, "tests/e2e/worker-app.spec.ts").unwrap_or(
    "",
  )
  let readme = find_template_content(templates, "README.md").unwrap_or("")
  assert_true(config.contains("\"runtime\": \"cloudflare\""))
  assert_true(moon_mod.contains("\"mizchi/sol_adapter_cloudflare@"))
  assert_false(moon_mod.contains("\"mizchi/sol_adapter_node@"))
  assert_true(
    server_pkg.contains("\"mizchi/sol_adapter_cloudflare\" @sol_cloudflare"),
  )
  assert_true(server_main.contains("@sol_cloudflare.run_app"))
  assert_true(worker.contains("./.sol/prod/server/main.js"))
  assert_true(worker.contains("url.pathname.startsWith(\"/api/\")"))
  assert_true(worker.contains("requireWriteToken"))
  assert_true(worker.contains("/api/jobs"))
  assert_true(worker.contains("/api/jobs/batch"))
  assert_true(worker.contains("BACKEND_SERVICE"))
  assert_true(worker.contains("solApp.fetch(request, env, ctx)"))
  assert_true(!worker.contains("__SOL_APP__"))
  assert_true(!worker.contains("_build/js"))
  assert_true(worker_dev.contains("./.sol/dev/server/main.js"))
  assert_true(worker_dev.contains("url.pathname.startsWith(\"/api/\")"))
  assert_true(worker_dev.contains("solApp.fetch(request, env, ctx)"))
  assert_true(!worker_dev.contains("__SOL_APP__"))
  assert_true(!worker_dev.contains("_build/js"))
  assert_true(wrangler.contains("main = \"worker.entry.mjs\""))
  assert_true(wrangler.contains("compatibility_date = \"2026-05-07\""))
  assert_true(wrangler.contains("[[kv_namespaces]]"))
  assert_true(wrangler.contains("binding = \"APP_KV\""))
  assert_true(wrangler.contains("[[r2_buckets]]"))
  assert_true(wrangler.contains("binding = \"UPLOADS_BUCKET\""))
  assert_true(wrangler_dev.contains("main = \"worker.entry.dev.mjs\""))
  assert_true(wrangler_dev.contains("compatibility_date = \"2026-05-07\""))
  assert_true(playwright.contains("webServer"))
  assert_true(playwright.contains("pnpm dev"))
  assert_true(e2e.contains("Operations Console"))
  assert_true(e2e.contains("/api/jobs/batch"))
  assert_true(e2e.contains("Last Error: validation failed"))
  assert_true(readme.contains("Route ownership"))
  assert_true(readme.contains("Operational UI"))
  assert_true(readme.contains("Dogfood checklist"))
}

///|
test "generate_cloudflare_templates: wrangler scripts do not require no-bundle" {
  let templates = @cli.generate_cloudflare_templates(
    "tester/myapp",
    "myapp",
    None,
  )
  let content = find_template_content(templates, "package.json").unwrap_or("")
  assert_true(
    content.contains(
      "\"dev\": \"sol generate --mode dev && moon build --target js && wrangler dev --config wrangler.dev.toml\"",
    ),
  )
  assert_true(content.contains("\"deploy\": \"sol build && wrangler deploy\""))
  assert_true(content.contains("\"test:e2e\": \"playwright test\""))
  assert_true(content.contains("\"verify\": \"pnpm build && pnpm test:e2e\""))
  assert_true(content.contains("\"@playwright/test\""))
  assert_true(content.contains("\"wrangler\""))
  assert_true(!content.contains("--no-bundle"))
}
