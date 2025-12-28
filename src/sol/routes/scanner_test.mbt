// Tests for Pages Directory Scanner

// =============================================================================
// Component Directory Detection Tests
// =============================================================================

///|
test "scan_pages_dir - detects component directory with moon.pkg.json" {
  let fs = @fs_adapter.MemFSAdapter::new()

  // Create pages directory
  fs.memfs().mkdirSync("/project/src/pages", recursive=true)

  // Create component directory with moon.pkg.json
  fs.memfs().mkdirSync("/project/src/pages/counter", recursive=true)
  fs.memfs().writeFileSync("/project/src/pages/counter/moon.pkg.json", "{}")

  // Create client and server directories
  fs.memfs().mkdirSync("/project/src/pages/counter/client", recursive=true)
  fs.memfs().mkdirSync("/project/src/pages/counter/server", recursive=true)

  // Create page.json
  let page_json =
    #|{
    #|  "mode": "static",
    #|  "component": {
    #|    "propsType": "CounterProps",
    #|    "clientExport": "counter",
    #|    "serverExport": "render_ssr"
    #|  }
    #|}
  fs.memfs().writeFileSync("/project/src/pages/counter/page.json", page_json)
  let manifest = scan_pages_dir(fs, "src/pages", "/project")
  inspect(manifest.routes.length(), content="1")

  // Verify it's a Component route
  guard manifest.routes[0] is Component(entry) else {
    fail("Expected Component route")
  }
  inspect(entry.path, content="/counter")
  inspect(entry.source, content="counter/")
  inspect(entry.component_type, content="SsrComponent")
  inspect(entry.props_type, content="Some(\"CounterProps\")")
  inspect(entry.client_export, content="Some(\"counter\")")
  inspect(entry.server_export, content="Some(\"render_ssr\")")
}

///|
test "scan_pages_dir - client only component" {
  let fs = @fs_adapter.MemFSAdapter::new()

  // Create pages directory
  fs.memfs().mkdirSync("/project/src/pages", recursive=true)

  // Create component directory with only client/
  fs.memfs().mkdirSync("/project/src/pages/widget", recursive=true)
  fs.memfs().writeFileSync("/project/src/pages/widget/moon.pkg.json", "{}")
  fs.memfs().mkdirSync("/project/src/pages/widget/client", recursive=true)
  // No server/ directory

  let manifest = scan_pages_dir(fs, "src/pages", "/project")
  inspect(manifest.routes.length(), content="1")
  guard manifest.routes[0] is Component(entry) else {
    fail("Expected Component route")
  }
  inspect(entry.component_type, content="ClientOnlyComponent")
}

///|
test "scan_pages_dir - server only component" {
  let fs = @fs_adapter.MemFSAdapter::new()

  // Create pages directory
  fs.memfs().mkdirSync("/project/src/pages", recursive=true)

  // Create component directory with only server/
  fs.memfs().mkdirSync("/project/src/pages/static-render", recursive=true)
  fs
  .memfs()
  .writeFileSync("/project/src/pages/static-render/moon.pkg.json", "{}")
  fs
  .memfs()
  .mkdirSync("/project/src/pages/static-render/server", recursive=true)
  // No client/ directory

  let manifest = scan_pages_dir(fs, "src/pages", "/project")
  inspect(manifest.routes.length(), content="1")
  guard manifest.routes[0] is Component(entry) else {
    fail("Expected Component route")
  }
  inspect(entry.component_type, content="ServerOnlyComponent")
}

///|
test "scan_pages_dir - component with staticParams" {
  let fs = @fs_adapter.MemFSAdapter::new()

  // Create pages directory
  fs.memfs().mkdirSync("/project/src/pages", recursive=true)

  // Create component directory
  fs.memfs().mkdirSync("/project/src/pages/product", recursive=true)
  fs.memfs().writeFileSync("/project/src/pages/product/moon.pkg.json", "{}")
  fs.memfs().mkdirSync("/project/src/pages/product/client", recursive=true)
  fs.memfs().mkdirSync("/project/src/pages/product/server", recursive=true)

  // Create page.json with staticParams
  let page_json =
    #|{
    #|  "mode": "static",
    #|  "staticParams": [
    #|    { "id": "1" },
    #|    { "id": "2" },
    #|    { "id": "3" }
    #|  ]
    #|}
  fs.memfs().writeFileSync("/project/src/pages/product/page.json", page_json)
  let manifest = scan_pages_dir(fs, "src/pages", "/project")
  guard manifest.routes[0] is Component(entry) else {
    fail("Expected Component route")
  }
  inspect(entry.static_paths.length(), content="3")
  inspect(entry.static_paths[0].params.get("id"), content="Some(\"1\")")
  inspect(entry.static_paths[0].output, content="product/1/index.html")
  inspect(entry.static_paths[1].output, content="product/2/index.html")
  inspect(entry.static_paths[2].output, content="product/3/index.html")
}

///|
test "scan_pages_dir - mixed regular and component directories" {
  let fs = @fs_adapter.MemFSAdapter::new()

  // Create pages directory
  fs.memfs().mkdirSync("/project/src/pages", recursive=true)

  // Create regular page file
  fs.memfs().writeFileSync("/project/src/pages/index.mbt", "// home page")

  // Create about directory with index.mbt
  fs.memfs().mkdirSync("/project/src/pages/about", recursive=true)
  fs
  .memfs()
  .writeFileSync("/project/src/pages/about/index.mbt", "// about page")

  // Create component directory
  fs.memfs().mkdirSync("/project/src/pages/counter", recursive=true)
  fs.memfs().writeFileSync("/project/src/pages/counter/moon.pkg.json", "{}")
  fs.memfs().mkdirSync("/project/src/pages/counter/client", recursive=true)
  fs.memfs().mkdirSync("/project/src/pages/counter/server", recursive=true)
  let manifest = scan_pages_dir(fs, "src/pages", "/project")

  // Should have 3 routes: index.mbt, about/index.mbt, counter (component)
  inspect(manifest.routes.length(), content="3")

  // Count route types
  let mut static_count = 0
  let mut component_count = 0
  for route in manifest.routes {
    match route {
      Static(_) => static_count = static_count + 1
      Component(_) => component_count = component_count + 1
      _ => ()
    }
  }
  inspect(static_count, content="2")
  inspect(component_count, content="1")
}

// =============================================================================
// Helper Function Tests
// =============================================================================

///|
test "detect_component_type - all combinations" {
  inspect(detect_component_type(true, true), content="SsrComponent")
  inspect(detect_component_type(true, false), content="ClientOnlyComponent")
  inspect(detect_component_type(false, true), content="ServerOnlyComponent")
  inspect(detect_component_type(false, false), content="ServerOnlyComponent")
}

///|
test "build_static_paths - empty params" {
  let params : Array[Map[String, String]] = []
  let result = build_static_paths("counter", params)
  inspect(result.length(), content="0")
}

///|
test "build_static_paths - single param" {
  let params : Array[Map[String, String]] = [{ "id": "1" }, { "id": "2" }]
  let result = build_static_paths("product", params)
  inspect(result.length(), content="2")
  inspect(result[0].output, content="product/1/index.html")
  inspect(result[1].output, content="product/2/index.html")
}

///|
test "build_static_paths - multiple params" {
  let params : Array[Map[String, String]] = [
    { "category": "books", "id": "123" },
  ]
  let result = build_static_paths("shop", params)
  inspect(result.length(), content="1")
  // Keys are sorted alphabetically: category, id
  inspect(result[0].output, content="shop/books/123/index.html")
}

// =============================================================================
// Dynamic File Pattern Tests
// =============================================================================

///|
test "extract_param_name - single underscore pattern" {
  let result = extract_param_name("_id_")
  guard result is Some(info) else { fail("Expected Some") }
  inspect(info.name, content="id")
  inspect(info.catch_all, content="false")
}

///|
test "extract_param_name - triple underscore pattern (catch-all)" {
  let result = extract_param_name("___all___")
  guard result is Some(info) else { fail("Expected Some") }
  inspect(info.name, content="all")
  inspect(info.catch_all, content="true")
}

///|
test "extract_param_name - legacy catch-all pattern" {
  let result = extract_param_name("_...slug_")
  guard result is Some(info) else { fail("Expected Some") }
  inspect(info.name, content="slug")
  inspect(info.catch_all, content="true")
}

///|
test "extract_param_name - regular directory" {
  let result = extract_param_name("posts")
  assert_true(result is None)
}

///|
test "extract_param_from_filename - single param md" {
  let result = extract_param_from_filename("_id_.md")
  guard result is Some(info) else { fail("Expected Some") }
  inspect(info.name, content="id")
  inspect(info.catch_all, content="false")
}

///|
test "extract_param_from_filename - catch-all tsx" {
  let result = extract_param_from_filename("___path___.tsx")
  guard result is Some(info) else { fail("Expected Some") }
  inspect(info.name, content="path")
  inspect(info.catch_all, content="true")
}

///|
test "extract_param_from_filename - regular file" {
  let result = extract_param_from_filename("index.md")
  assert_true(result is None)
}

///|
test "extract_param_from_filename - mbt file" {
  let result = extract_param_from_filename("_slug_.mbt")
  guard result is Some(info) else { fail("Expected Some") }
  inspect(info.name, content="slug")
  inspect(info.catch_all, content="false")
}
