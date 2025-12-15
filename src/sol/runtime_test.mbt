///|
/// Unit tests for sol/runtime pure functions

// =============================================================================
// StaticFileConfig Tests
// =============================================================================

test "StaticFileConfig::default: creates default config" {
  let config = StaticFileConfig::default()
  assert_eq(config.path_prefix, "/static")
  assert_eq(config.local_dir, "static")
  assert_eq(config.mappings.length(), 1)
  assert_eq(config.mappings[0].0, "loader.min.js")
  assert_eq(config.mappings[0].1, "static/loader.min.js")
}

///|
test "StaticFileConfig::with_mapping: adds mapping" {
  let config = StaticFileConfig::default().with_mapping("app.js", "dist/app.js")
  assert_eq(config.mappings.length(), 2)
  assert_eq(config.mappings[1].0, "app.js")
  assert_eq(config.mappings[1].1, "dist/app.js")
}

///|
test "StaticFileConfig::with_mapping: multiple mappings" {
  let config = StaticFileConfig::default()
    .with_mapping("a.js", "dist/a.js")
    .with_mapping("b.css", "dist/b.css")
  assert_eq(config.mappings.length(), 3)
  assert_eq(config.mappings[2].0, "b.css")
}

// =============================================================================
// IslandConfig Tests
// =============================================================================

///|
test "IslandConfig::new: creates config with defaults" {
  let config : IslandConfig[Unit] = IslandConfig::new("my-island", "/island.js")
  assert_eq(config.id, "my-island")
  assert_eq(config.script_url, "/island.js")
}

///|
test "IslandConfig::with_trigger: sets trigger" {
  let config : IslandConfig[Unit] = IslandConfig::new("test", "/test.js").with_trigger(
    @mercurius.TriggerType::Idle,
  )
  assert_true(config.trigger is @mercurius.TriggerType::Idle)
}

///|
test "IslandConfig::with_state: sets inline state" {
  let config : IslandConfig[Unit] = IslandConfig::new("test", "/test.js").with_state(
    "{\"count\":0}",
  )
  assert_true(config.state is @mercurius.StateConfig::Inline(_))
}

///|
test "IslandConfig::with_state_ref: sets script ref state" {
  let config : IslandConfig[Unit] = IslandConfig::new("test", "/test.js").with_state_ref(
    "state-script-id",
  )
  assert_true(config.state is @mercurius.StateConfig::ScriptRef(_))
}

///|
test "IslandConfig::with_state_url: sets url state" {
  let config : IslandConfig[Unit] = IslandConfig::new("test", "/test.js").with_state_url(
    "/api/state",
  )
  assert_true(config.state is @mercurius.StateConfig::Url(_))
}

///|
test "IslandConfig::with_ssr_html: sets ssr html" {
  let config : IslandConfig[Unit] = IslandConfig::new("test", "/test.js").with_ssr_html(
    "<div>Hello</div>",
  )
  assert_true(config.ssr_html is Some(_))
}

///|
test "IslandConfig: builder chain" {
  let config : IslandConfig[Unit] = IslandConfig::new("counter", "/counter.js")
    .with_trigger(@mercurius.TriggerType::Visible)
    .with_state("{\"value\":42}")
    .with_ssr_html("<span>42</span>")
  assert_eq(config.id, "counter")
  assert_eq(config.script_url, "/counter.js")
  assert_true(config.trigger is @mercurius.TriggerType::Visible)
  assert_true(config.state is @mercurius.StateConfig::Inline(_))
  assert_true(config.ssr_html is Some(_))
}

// =============================================================================
// render_island_page Tests
// =============================================================================

///|
test "render_island_page: basic page" {
  let html = render_island_page([])
  assert_true(html.contains("<!DOCTYPE html>"))
  assert_true(html.contains("<title>App</title>"))
  assert_true(html.contains("loader.min.js"))
}

///|
test "render_island_page: with title" {
  let html = render_island_page([], title="My App")
  assert_true(html.contains("<title>My App</title>"))
}

///|
test "render_island_page: with head" {
  let html = render_island_page(
    [],
    head="<link rel=\"stylesheet\" href=\"/style.css\">",
  )
  assert_true(html.contains("stylesheet"))
}

///|
test "render_island_page: with custom loader" {
  let html = render_island_page([], loader_url="/custom/loader.js")
  assert_true(html.contains("/custom/loader.js"))
}

///|
test "render_island_page: with islands" {
  let islands = [
    "<div id=\"island1\">Content 1</div>", "<div id=\"island2\">Content 2</div>",
  ]
  let html = render_island_page(islands)
  assert_true(html.contains("island1"))
  assert_true(html.contains("Content 1"))
  assert_true(html.contains("island2"))
  assert_true(html.contains("Content 2"))
}

// =============================================================================
// render_island Tests (with ssr_html)
// =============================================================================

///|
test "render_island: with ssr_html" {
  let config : IslandConfig[Unit] = IslandConfig::new("test-island", "/test.js").with_ssr_html(
    "<div>SSR Content</div>",
  )
  let html = render_island(config)
  assert_true(html.contains("ln:id=\"test-island\""))
  assert_true(html.contains("ln:url=\"/test.js\""))
  assert_true(html.contains("SSR Content"))
}

///|
test "render_island: with state" {
  let config : IslandConfig[Unit] = IslandConfig::new("counter", "/counter.js")
    .with_state("{\"count\":0}")
    .with_ssr_html("<span>0</span>")
  let html = render_island(config)
  assert_true(html.contains("ln:state"))
  assert_true(html.contains("count"))
}

///|
test "render_island: with trigger" {
  let config : IslandConfig[Unit] = IslandConfig::new("lazy", "/lazy.js")
    .with_trigger(@mercurius.TriggerType::Visible)
    .with_ssr_html("<div>Lazy</div>")
  let html = render_island(config)
  assert_true(html.contains("ln:trigger=\"visible\""))
}

// =============================================================================
// Utility re-exports Tests
// =============================================================================

///|
test "escape_json_for_attr: basic" {
  let escaped = escape_json_for_attr("{\"key\":\"value\"}")
  // Should escape quotes for HTML attribute
  assert_true(escaped.contains("key"))
}

///|
test "escape_json_for_html: basic" {
  let escaped = escape_json_for_html("{\"key\":\"value\"}")
  assert_true(escaped.contains("key"))
}
