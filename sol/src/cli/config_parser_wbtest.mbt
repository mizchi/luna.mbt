// Whitebox tests for config_parser.mbt

// =============================================================================
// parse_runtime tests
// =============================================================================

///|
test "parse_runtime: node is default" {
  assert_eq(parse_runtime("node"), RuntimeNode)
}

///|
test "parse_runtime: unknown string defaults to node" {
  assert_eq(parse_runtime("unknown"), RuntimeNode)
}

///|
test "parse_runtime: empty string defaults to node" {
  assert_eq(parse_runtime(""), RuntimeNode)
}

///|
test "parse_runtime: cloudflare" {
  assert_eq(parse_runtime("cloudflare"), RuntimeCloudflare)
}

///|
test "parse_runtime: cf alias" {
  assert_eq(parse_runtime("cf"), RuntimeCloudflare)
}

///|
test "parse_runtime: workers alias" {
  assert_eq(parse_runtime("workers"), RuntimeCloudflare)
}

///|
test "parse_runtime: deno" {
  assert_eq(parse_runtime("deno"), RuntimeDeno)
}

///|
test "parse_runtime: bun" {
  assert_eq(parse_runtime("bun"), RuntimeBun)
}

///|
test "parse_runtime: case insensitive cloudflare" {
  assert_eq(parse_runtime("Cloudflare"), RuntimeCloudflare)
  assert_eq(parse_runtime("CLOUDFLARE"), RuntimeCloudflare)
}

///|
test "parse_runtime: case insensitive deno" {
  assert_eq(parse_runtime("DENO"), RuntimeDeno)
}

///|
test "parse_runtime: case insensitive bun" {
  assert_eq(parse_runtime("BUN"), RuntimeBun)
}

// =============================================================================
// Ownership mode parser tests
// =============================================================================

///|
test "parse_server_entry_mode: defaults to auto" {
  assert_eq(parse_server_entry_mode(""), ServerEntryAuto)
  assert_eq(parse_server_entry_mode("unknown"), ServerEntryAuto)
}

///|
test "parse_server_entry_mode: accepts explicit user-managed aliases" {
  assert_eq(parse_server_entry_mode("user"), ServerEntryUserManaged)
  assert_eq(parse_server_entry_mode("user-managed"), ServerEntryUserManaged)
  assert_eq(parse_server_entry_mode("manual"), ServerEntryUserManaged)
}

///|
test "parse_server_entry_mode: accepts generated aliases" {
  assert_eq(parse_server_entry_mode("generated"), ServerEntryGenerated)
  assert_eq(parse_server_entry_mode("codegen"), ServerEntryGenerated)
}

///|
test "parse_client_bundle_mode: defaults to auto" {
  assert_eq(parse_client_bundle_mode(""), ClientBundleAuto)
  assert_eq(parse_client_bundle_mode("unknown"), ClientBundleAuto)
}

///|
test "parse_client_bundle_mode: accepts external aliases" {
  assert_eq(parse_client_bundle_mode("external"), ClientBundleExternal)
  assert_eq(parse_client_bundle_mode("manual"), ClientBundleExternal)
  assert_eq(parse_client_bundle_mode("none"), ClientBundleExternal)
}

// =============================================================================
// parse_sol_config tests
// =============================================================================

///|
test "parse_sol_config: minimal valid JSON returns Some" {
  let result = parse_sol_config("{}")
  assert_true(result is Some(_))
}

///|
test "parse_sol_config: invalid JSON returns None" {
  let result = parse_sol_config("not json")
  assert_true(result is None)
}

///|
test "parse_sol_config: empty string returns None" {
  let result = parse_sol_config("")
  assert_true(result is None)
}

///|
test "parse_sol_config: default routes value" {
  let result = parse_sol_config("{}")
  guard result is Some(config) else { return }
  assert_eq(config.routes, "app/server")
}

///|
test "parse_sol_config: default output value" {
  let result = parse_sol_config("{}")
  guard result is Some(config) else { return }
  assert_eq(config.output, "app/__gen__")
}

///|
test "parse_sol_config: default client_auto_exports is true" {
  let result = parse_sol_config("{}")
  guard result is Some(config) else { return }
  assert_true(config.client_auto_exports)
}

///|
test "parse_sol_config: default ownership modes stay automatic" {
  let result = parse_sol_config("{}")
  guard result is Some(config) else { return }
  assert_eq(config.server_entry, ServerEntryAuto)
  assert_eq(config.client_bundle, ClientBundleAuto)
}

///|
test "parse_sol_config: explicit user server entry and external client bundle" {
  let result = parse_sol_config(
    "{\"serverEntry\": \"user\", \"clientBundle\": \"external\"}",
  )
  guard result is Some(config) else { return }
  assert_eq(config.server_entry, ServerEntryUserManaged)
  assert_eq(config.client_bundle, ClientBundleExternal)
}

///|
test "parse_sol_config: default runtime is node" {
  let result = parse_sol_config("{}")
  guard result is Some(config) else { return }
  assert_eq(config.runtime, RuntimeNode)
}

///|
test "parse_sol_config: default adapter matches runtime when not specified" {
  let result = parse_sol_config("{}")
  guard result is Some(config) else { return }
  assert_eq(config.adapter, config.runtime)
}

///|
test "parse_sol_config: default islands is empty" {
  let result = parse_sol_config("{}")
  guard result is Some(config) else { return }
  assert_eq(config.islands.length(), 0)
}

///|
test "parse_sol_config: default static_dirs is empty" {
  let result = parse_sol_config("{}")
  guard result is Some(config) else { return }
  assert_eq(config.static_dirs.length(), 0)
}

///|
test "parse_sol_config: default wasm_entrypoints is empty" {
  let result = parse_sol_config("{}")
  guard result is Some(config) else { return }
  assert_eq(config.wasm_entrypoints.length(), 0)
}

///|
test "parse_sol_config: custom routes" {
  let result = parse_sol_config("{\"routes\": \"src/server\"}")
  guard result is Some(config) else { return }
  assert_eq(config.routes, "src/server")
}

///|
test "parse_sol_config: custom output" {
  let result = parse_sol_config("{\"output\": \"gen\"}")
  guard result is Some(config) else { return }
  assert_eq(config.output, "gen")
}

///|
test "parse_sol_config: client_auto_exports false" {
  let result = parse_sol_config("{\"client_auto_exports\": false}")
  guard result is Some(config) else { return }
  assert_false(config.client_auto_exports)
}

///|
test "parse_sol_config: runtime cloudflare" {
  let result = parse_sol_config("{\"runtime\": \"cloudflare\"}")
  guard result is Some(config) else { return }
  assert_eq(config.runtime, RuntimeCloudflare)
}

///|
test "parse_sol_config: runtime bun" {
  let result = parse_sol_config("{\"runtime\": \"bun\"}")
  guard result is Some(config) else { return }
  assert_eq(config.runtime, RuntimeBun)
}

///|
test "parse_sol_config: runtime deno" {
  let result = parse_sol_config("{\"runtime\": \"deno\"}")
  guard result is Some(config) else { return }
  assert_eq(config.runtime, RuntimeDeno)
}

///|
test "parse_sol_config: adapter overrides runtime for adapter field" {
  let result = parse_sol_config(
    "{\"runtime\": \"cloudflare\", \"adapter\": \"node\"}",
  )
  guard result is Some(config) else { return }
  assert_eq(config.runtime, RuntimeCloudflare)
  assert_eq(config.adapter, RuntimeNode)
}

///|
test "parse_sol_config: adapter defaults to runtime when absent" {
  let result = parse_sol_config("{\"runtime\": \"bun\"}")
  guard result is Some(config) else { return }
  assert_eq(config.runtime, RuntimeBun)
  assert_eq(config.adapter, RuntimeBun)
}

///|
test "parse_sol_config: islands array" {
  let result = parse_sol_config("{\"islands\": [\"app/client\", \"app/ui\"]}")
  guard result is Some(config) else { return }
  assert_eq(config.islands.length(), 2)
  assert_eq(config.islands[0], "app/client")
  assert_eq(config.islands[1], "app/ui")
}

///|
test "parse_sol_config: not an object returns None" {
  let result = parse_sol_config("[1, 2, 3]")
  assert_true(result is None)
}

///|
test "parse_sol_config: null returns None" {
  let result = parse_sol_config("null")
  assert_true(result is None)
}

// =============================================================================
// StaticDirEntry::default tests
// =============================================================================

///|
test "StaticDirEntry::default: path_prefix is set" {
  let entry = StaticDirEntry::default("/docs", "docs", "Docs")
  assert_eq(entry.path_prefix, "/docs")
}

///|
test "StaticDirEntry::default: source_dir is set" {
  let entry = StaticDirEntry::default("/docs", "docs", "Docs")
  assert_eq(entry.source_dir, "docs")
}

///|
test "StaticDirEntry::default: title is set" {
  let entry = StaticDirEntry::default("/docs", "docs", "My Docs")
  assert_eq(entry.title, "My Docs")
}

///|
test "StaticDirEntry::default: nav is empty" {
  let entry = StaticDirEntry::default("/docs", "docs", "Docs")
  assert_eq(entry.nav.length(), 0)
}

///|
test "StaticDirEntry::default: exclude is empty" {
  let entry = StaticDirEntry::default("/docs", "docs", "Docs")
  assert_eq(entry.exclude.length(), 0)
}

///|
test "StaticDirEntry::default: trailing_slash is true" {
  let entry = StaticDirEntry::default("/docs", "docs", "Docs")
  assert_true(entry.trailing_slash)
}

///|
test "StaticDirEntry::default: ogp_text is None" {
  let entry = StaticDirEntry::default("/docs", "docs", "Docs")
  assert_true(entry.ogp_text is None)
}

///|
test "StaticDirEntry::default: head_snippets is empty" {
  let entry = StaticDirEntry::default("/docs", "docs", "Docs")
  assert_eq(entry.head_snippets.length(), 0)
}

///|
test "StaticDirEntry::default: body_snippets is empty" {
  let entry = StaticDirEntry::default("/docs", "docs", "Docs")
  assert_eq(entry.body_snippets.length(), 0)
}

///|
test "StaticDirEntry::default: prod_body_snippets is empty" {
  let entry = StaticDirEntry::default("/docs", "docs", "Docs")
  assert_eq(entry.prod_body_snippets.length(), 0)
}

// =============================================================================
// extract_quoted_values tests
// =============================================================================

///|
test "extract_quoted_values: basic extraction" {
  let result : Array[String] = []
  extract_quoted_values("component=\"MyComponent\"", "component=\"", result)
  assert_eq(result.length(), 1)
  assert_eq(result[0], "MyComponent")
}

///|
test "extract_quoted_values: multiple matches" {
  let result : Array[String] = []
  extract_quoted_values("path=\"/home\" path=\"/about\"", "path=\"", result)
  assert_eq(result.length(), 2)
  assert_eq(result[0], "/home")
  assert_eq(result[1], "/about")
}

///|
test "extract_quoted_values: no matches returns empty" {
  let result : Array[String] = []
  extract_quoted_values("some text without prefix", "component=\"", result)
  assert_eq(result.length(), 0)
}

///|
test "extract_quoted_values: deduplicates identical values" {
  let result : Array[String] = []
  extract_quoted_values(
    "path=\"/home\" path=\"/home\" path=\"/about\"", "path=\"", result,
  )
  assert_eq(result.length(), 2)
  assert_eq(result[0], "/home")
  assert_eq(result[1], "/about")
}

///|
test "extract_quoted_values: empty content" {
  let result : Array[String] = []
  extract_quoted_values("", "path=\"", result)
  assert_eq(result.length(), 0)
}

///|
test "extract_quoted_values: prefix at end with no closing quote" {
  let result : Array[String] = []
  extract_quoted_values("path=\"incomplete", "path=\"", result)
  assert_eq(result.length(), 0)
}

///|
test "extract_action_handler_ids: supports typed handler names" {
  let result : Array[String] = []
  extract_action_handler_ids(
    (
      #|let submit_contact_handler : @action.ActionHandler = @action.ActionHandler(async fn(ctx) {
      #|  @action.ActionResult::ok(@core.any(true))
      #|})
      #|let add_todo_action : @action.ActionHandler = @action.ActionHandler(async fn(ctx) {
      #|  @action.ActionResult::ok(@core.any(true))
      #|})
    ),
    result,
  )
  assert_eq(result.length(), 2)
  assert_eq(result[0], "submit-contact")
  assert_eq(result[1], "add-todo")
}

///|
test "extract_quoted_values: multiple different prefixes accumulate in same array" {
  let result : Array[String] = []
  extract_quoted_values("path=\"/api\" segment=\"main\"", "path=\"", result)
  assert_eq(result.length(), 1)
  assert_eq(result[0], "/api")
}

// =============================================================================
// parse_sol_config staticDirs integration tests
// =============================================================================

///|
test "parse_sol_config: staticDirs with valid entry" {
  let json =
    #|{
    #|  "staticDirs": [
    #|    {
    #|      "path_prefix": "/docs",
    #|      "source_dir": "docs",
    #|      "title": "Documentation"
    #|    }
    #|  ]
    #|}
  let result = parse_sol_config(json)
  guard result is Some(config) else { return }
  assert_eq(config.static_dirs.length(), 1)
  assert_eq(config.static_dirs[0].path_prefix, "/docs")
  assert_eq(config.static_dirs[0].source_dir, "docs")
  assert_eq(config.static_dirs[0].title, "Documentation")
}

///|
test "parse_sol_config: staticDirs entry without path_prefix is skipped" {
  let json =
    #|{
    #|  "staticDirs": [
    #|    {
    #|      "source_dir": "docs",
    #|      "title": "Documentation"
    #|    }
    #|  ]
    #|}
  let result = parse_sol_config(json)
  guard result is Some(config) else { return }
  assert_eq(config.static_dirs.length(), 0)
}

///|
test "parse_sol_config: staticDirs entry without source_dir is skipped" {
  let json =
    #|{
    #|  "staticDirs": [
    #|    {
    #|      "path_prefix": "/docs",
    #|      "title": "Documentation"
    #|    }
    #|  ]
    #|}
  let result = parse_sol_config(json)
  guard result is Some(config) else { return }
  assert_eq(config.static_dirs.length(), 0)
}

///|
test "parse_sol_config: staticDirs default title is Documentation" {
  let json =
    #|{
    #|  "staticDirs": [
    #|    {
    #|      "path_prefix": "/docs",
    #|      "source_dir": "docs"
    #|    }
    #|  ]
    #|}
  let result = parse_sol_config(json)
  guard result is Some(config) else { return }
  assert_eq(config.static_dirs.length(), 1)
  assert_eq(config.static_dirs[0].title, "Documentation")
}

///|
test "parse_sol_config: staticDirs trailing_slash false" {
  let json =
    #|{
    #|  "staticDirs": [
    #|    {
    #|      "path_prefix": "/docs",
    #|      "source_dir": "docs",
    #|      "trailing_slash": false
    #|    }
    #|  ]
    #|}
  let result = parse_sol_config(json)
  guard result is Some(config) else { return }
  assert_eq(config.static_dirs.length(), 1)
  assert_false(config.static_dirs[0].trailing_slash)
}

///|
test "parse_sol_config: staticDirs with ogpText" {
  let json =
    #|{
    #|  "staticDirs": [
    #|    {
    #|      "path_prefix": "/docs",
    #|      "source_dir": "docs",
    #|      "ogpText": "<meta name=\"og:site\" content=\"example\">"
    #|    }
    #|  ]
    #|}
  let result = parse_sol_config(json)
  guard result is Some(config) else { return }
  assert_eq(config.static_dirs.length(), 1)
  assert_true(config.static_dirs[0].ogp_text is Some(_))
}

///|
test "parse_sol_config: staticDirs with exclude array" {
  let json =
    #|{
    #|  "staticDirs": [
    #|    {
    #|      "path_prefix": "/docs",
    #|      "source_dir": "docs",
    #|      "exclude": ["draft", "wip"]
    #|    }
    #|  ]
    #|}
  let result = parse_sol_config(json)
  guard result is Some(config) else { return }
  assert_eq(config.static_dirs.length(), 1)
  assert_eq(config.static_dirs[0].exclude.length(), 2)
  assert_eq(config.static_dirs[0].exclude[0], "draft")
  assert_eq(config.static_dirs[0].exclude[1], "wip")
}
