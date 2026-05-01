//

///|
/// Unit tests for sol/compiler pure functions

// =============================================================================
// BundleConfig Tests
// =============================================================================

test "BundleConfig::new: creates config with defaults" {
  let input = [("main", "./src/main.js")]
  let config = BundleConfig::new(input, "dist")
  assert_eq(config.input.length(), 1)
  assert_eq(config.input[0].0, "main")
  assert_eq(config.input[0].1, "./src/main.js")
  assert_eq(config.output_dir, "dist")
  assert_eq(config.format.to_string(), "esm")
  assert_eq(config.entry_file_names, "[name].js")
  assert_eq(config.chunk_file_names, "_shared/[name]-[hash].js")
  assert_eq(config.minify, false)
  assert_eq(config.sourcemap, false)
}

///|
test "BundleConfig::new: multiple entries" {
  let input = [("app", "./app.js"), ("vendor", "./vendor.js")]
  let config = BundleConfig::new(input, "build")
  assert_eq(config.input.length(), 2)
  assert_eq(config.input[0].0, "app")
  assert_eq(config.input[1].0, "vendor")
}

///|
test "BundleConfig::with_minify: enables minification" {
  let config = BundleConfig::new([], "dist").with_minify(true)
  assert_eq(config.minify, true)
}

///|
test "BundleConfig::with_minify: disables minification" {
  let config = BundleConfig::new([], "dist")
    .with_minify(true)
    .with_minify(false)
  assert_eq(config.minify, false)
}

///|
test "BundleConfig::with_sourcemap: enables sourcemap" {
  let config = BundleConfig::new([], "dist").with_sourcemap(true)
  assert_eq(config.sourcemap, true)
}

///|
test "BundleConfig: builder chain" {
  let config = BundleConfig::new([("main", "./main.js")], "output")
    .with_minify(true)
    .with_sourcemap(true)
  assert_eq(config.output_dir, "output")
  assert_eq(config.minify, true)
  assert_eq(config.sourcemap, true)
}

// =============================================================================
// IslandManifest Tests
// =============================================================================

///|
test "parse_island_manifest: valid manifest" {
  let json =
    #|{
    #|  "output_dir": "static/islands",
    #|  "islands": [
    #|    { "name": "counter", "entry_path": "./islands/counter.js" },
    #|    { "name": "todo", "entry_path": "./islands/todo.js" }
    #|  ]
    #|}
  let manifest = parse_island_manifest(json)
  assert_true(manifest is Some(_))
  let m = manifest.unwrap()
  assert_eq(m.output_dir, "static/islands")
  assert_eq(m.islands.length(), 2)
  assert_eq(m.islands[0].name, "counter")
  assert_eq(m.islands[0].entry_path, "./islands/counter.js")
  assert_eq(m.islands[1].name, "todo")
  assert_eq(m.islands[1].entry_path, "./islands/todo.js")
}

///|
test "parse_island_manifest: empty islands" {
  let json =
    #|{
    #|  "output_dir": "dist",
    #|  "islands": []
    #|}
  let manifest = parse_island_manifest(json)
  assert_true(manifest is Some(_))
  let m = manifest.unwrap()
  assert_eq(m.output_dir, "dist")
  assert_eq(m.islands.length(), 0)
}

///|
test "parse_island_manifest: default output_dir" {
  let json =
    #|{
    #|  "islands": []
    #|}
  let manifest = parse_island_manifest(json)
  assert_true(manifest is Some(_))
  assert_eq(manifest.unwrap().output_dir, "static")
}

///|
test "parse_island_manifest: invalid json" {
  let json = "not valid json"
  let manifest = parse_island_manifest(json)
  assert_true(manifest is None)
}

///|
test "parse_island_manifest: not an object" {
  let json = "[1, 2, 3]"
  let manifest = parse_island_manifest(json)
  assert_true(manifest is None)
}

///|
test "parse_island_manifest: missing name in island" {
  let json =
    #|{
    #|  "islands": [
    #|    { "entry_path": "./test.js" }
    #|  ]
    #|}
  let manifest = parse_island_manifest(json)
  assert_true(manifest is Some(_))
  // Island without name should be skipped
  assert_eq(manifest.unwrap().islands.length(), 0)
}

///|
test "parse_island_manifest: missing entry_path in island" {
  let json =
    #|{
    #|  "islands": [
    #|    { "name": "test" }
    #|  ]
    #|}
  let manifest = parse_island_manifest(json)
  assert_true(manifest is Some(_))
  // Island without entry_path should be skipped
  assert_eq(manifest.unwrap().islands.length(), 0)
}

///|
test "generate_island_manifest: single island" {
  let islands = [("counter", "./counter.js")]
  let json = generate_island_manifest(islands, "dist")
  assert_true(json.contains("\"output_dir\": \"dist\""))
  assert_true(json.contains("\"name\": \"counter\""))
  assert_true(json.contains("\"entry_path\": \"./counter.js\""))
}

///|
test "generate_island_manifest: multiple islands" {
  let islands = [("a", "./a.js"), ("b", "./b.js")]
  let json = generate_island_manifest(islands, "output")
  assert_true(json.contains("\"name\": \"a\""))
  assert_true(json.contains("\"name\": \"b\""))
  assert_true(json.contains("\"entry_path\": \"./a.js\""))
  assert_true(json.contains("\"entry_path\": \"./b.js\""))
}

///|
test "generate_island_manifest: empty islands" {
  let islands : Array[(String, String)] = []
  let json = generate_island_manifest(islands, "dist")
  assert_true(json.contains("\"islands\": ["))
  assert_true(json.contains("\"output_dir\": \"dist\""))
}

///|
test "generate_island_manifest: roundtrip" {
  let original_islands = [("counter", "./counter.js"), ("todo", "./todo.js")]
  let json = generate_island_manifest(original_islands, "static")
  let parsed = parse_island_manifest(json)
  assert_true(parsed is Some(_))
  let manifest = parsed.unwrap()
  assert_eq(manifest.output_dir, "static")
  assert_eq(manifest.islands.length(), 2)
  assert_eq(manifest.islands[0].name, "counter")
  assert_eq(manifest.islands[0].entry_path, "./counter.js")
  assert_eq(manifest.islands[1].name, "todo")
  assert_eq(manifest.islands[1].entry_path, "./todo.js")
}
