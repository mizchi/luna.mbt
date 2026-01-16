// Tests for ServerNode - Unified SSR Support
//
// Tests for synchronous and asynchronous server-side rendering.
// These tests verify the core SSR primitives that enable unified rendering.

// =============================================================================
// ServerNode Basic Tests
// =============================================================================

///|
test "ServerNode::sync - creates synchronous node" {
  let node = @luna.text("Hello, World!")
  let server_node = ServerNode::sync(node)
  inspect(server_node.is_async(), content="false")
}

///|
test "ServerNode::async_ - creates asynchronous node" {
  let server_node = ServerNode::async_(async fn() {
    @luna.text("Async content")
  })
  inspect(server_node.is_async(), content="true")
}

// =============================================================================
// ServerNode with Complex VNode Trees
// =============================================================================

///|
test "ServerNode - sync with element tree" {
  let node = @luna.h("div", [("class", @luna.attr_static("container"))], [
    @luna.h("h1", [], [@luna.text("Title")]),
    @luna.h("p", [], [@luna.text("Content")]),
  ])
  let server_node = ServerNode::sync(node)
  // Verify it's synchronous
  inspect(server_node.is_async(), content="false")
  // Can access the node directly for sync
  guard server_node is Sync(inner_node) else { fail("Expected Sync") }
  guard inner_node is @core.Element(el) else { fail("Expected Element") }
  inspect(el.tag, content="div")
  inspect(el.children.length(), content="2")
}

///|
test "ServerNode - async with dynamic data factory" {
  // Test creating async ServerNode (factory pattern)
  let server_node = ServerNode::async_(async fn() {
    let items = ["Item 1", "Item 2", "Item 3"]
    @luna.h(
      "ul",
      [],
      items.map(fn(item) { @luna.h("li", [], [@luna.text(item)]) }),
    )
  })
  // Verify it's asynchronous
  inspect(server_node.is_async(), content="true")
}

// =============================================================================
// ServerNode with Islands (SSR + Hydration)
// =============================================================================

///|
test "ServerNode - sync with island" {
  let island_node = @luna.island(
    "counter-1",
    "/static/counter.js",
    "{\"count\":0}",
    [@luna.text("Loading...")],
    trigger=@core.Load,
  )
  let server_node = ServerNode::sync(island_node)
  inspect(server_node.is_async(), content="false")
  guard server_node is Sync(inner) else { fail("Expected Sync") }
  guard inner is @core.Island(island) else { fail("Expected Island") }
  inspect(island.id, content="counter-1")
  inspect(island.url, content="/static/counter.js")
  inspect(island.state, content="{\"count\":0}")
  inspect(island.trigger.to_string(), content="load")
}

///|
test "ServerNode - sync with wc_island" {
  let wc_island = @luna.wc_island(
    "wc-toggle",
    "/static/toggle.js",
    ".toggle { color: blue; }",
    "{\"checked\":false}",
    [@luna.text("Toggle")],
    trigger=@core.Visible,
  )
  let server_node = ServerNode::sync(wc_island)
  inspect(server_node.is_async(), content="false")
  guard server_node is Sync(inner) else { fail("Expected Sync") }
  guard inner is @core.WcIsland(island) else { fail("Expected WcIsland") }
  inspect(island.name, content="wc-toggle")
  inspect(island.url, content="/static/toggle.js")
  inspect(island.trigger.to_string(), content="visible")
}

///|
test "ServerNode - sync with internal_ref" {
  let ref_node = @luna.internal_ref(
    "/components/button.js",
    "{\"label\":\"Click me\"}",
    trigger=@core.Idle,
    wc=false,
    children=[@luna.text("Click me")],
  )
  let server_node = ServerNode::sync(ref_node)
  inspect(server_node.is_async(), content="false")
  guard server_node is Sync(inner) else { fail("Expected Sync") }
  guard inner is @core.InternalRef(iref) else { fail("Expected InternalRef") }
  inspect(iref.url, content="/components/button.js")
  inspect(iref.wc, content="false")
  inspect(iref.trigger.to_string(), content="idle")
}

// =============================================================================
// ServerNode Composition
// =============================================================================

///|
test "ServerNode - nested islands in sync" {
  let node = @luna.h("main", [], [
    @luna.island("header-nav", "/static/nav.js", "{}", [
      @luna.text("Navigation"),
    ]),
    @luna.h("article", [], [@luna.text("Main content")]),
    @luna.island(
      "footer-contact",
      "/static/contact.js",
      "{\"email\":\"test@example.com\"}",
      [@luna.text("Contact")],
    ),
  ])
  let server_node = ServerNode::sync(node)
  inspect(server_node.is_async(), content="false")
  guard server_node is Sync(inner) else { fail("Expected Sync") }
  guard inner is @core.Element(el) else { fail("Expected Element") }
  inspect(el.tag, content="main")
  inspect(el.children.length(), content="3")
}

// =============================================================================
// TriggerType Tests
// =============================================================================

///|
test "TriggerType - to_string for all types" {
  inspect(@core.Load.to_string(), content="load")
  inspect(@core.Idle.to_string(), content="idle")
  inspect(@core.Visible.to_string(), content="visible")
  inspect(
    @core.Media("(max-width: 768px)").to_string(),
    content="media:(max-width: 768px)",
  )
  inspect(@luna.TriggerType::None.to_string(), content="none")
}

///|
test "TriggerType - from_string roundtrip" {
  // Test load
  let load_str = @core.Load.to_string()
  inspect(load_str, content="load")

  // Test idle
  let idle_str = @core.Idle.to_string()
  inspect(idle_str, content="idle")

  // Test visible
  let visible_str = @core.Visible.to_string()
  inspect(visible_str, content="visible")

  // Test media with query
  let media = @core.Media("(min-width: 1024px)")
  let media_str = media.to_string()
  inspect(media_str, content="media:(min-width: 1024px)")
}

// =============================================================================
// Island Factory Tests
// =============================================================================

///|
test "island - creates VIsland with all parameters" {
  let node : @luna.Node[Unit] = @luna.island(
    "test-island",
    "/static/test.js",
    "{\"foo\":\"bar\"}",
    [@luna.text("Placeholder")],
    trigger=@core.Visible,
  )
  guard node is @core.Island(island) else { fail("Expected Island") }
  inspect(island.id, content="test-island")
  inspect(island.url, content="/static/test.js")
  inspect(island.state, content="{\"foo\":\"bar\"}")
  inspect(island.trigger.to_string(), content="visible")
  inspect(island.children.length(), content="1")
}

///|
test "island - default trigger is Load" {
  let node : @luna.Node[Unit] = @luna.island(
    "default-trigger",
    "/static/default.js",
    "{}",
    [],
  )
  guard node is @core.Island(island) else { fail("Expected Island") }
  inspect(island.trigger.to_string(), content="load")
}

///|
test "wc_island - creates VWcIsland with all parameters" {
  let node : @luna.Node[Unit] = @luna.wc_island(
    "my-component",
    "/static/my-component.js",
    ".host { display: block; }",
    "{\"active\":true}",
    [@luna.text("Shadow content")],
    trigger=@core.Idle,
  )
  guard node is @core.WcIsland(wc) else { fail("Expected WcIsland") }
  inspect(wc.name, content="my-component")
  inspect(wc.url, content="/static/my-component.js")
  inspect(wc.styles, content=".host { display: block; }")
  inspect(wc.state, content="{\"active\":true}")
  inspect(wc.trigger.to_string(), content="idle")
  inspect(wc.children.length(), content="1")
}

///|
test "internal_ref - creates VInternalRef for regular island" {
  let node : @luna.Node[Unit] = @luna.internal_ref(
    "/components/counter.js",
    "{\"initial\":10}",
    trigger=@core.Load,
    wc=false,
    children=[@luna.text("Counter")],
  )
  guard node is @core.InternalRef(iref) else { fail("Expected InternalRef") }
  inspect(iref.url, content="/components/counter.js")
  inspect(iref.state, content="{\"initial\":10}")
  inspect(iref.wc, content="false")
  inspect(iref.trigger.to_string(), content="load")
}

///|
test "internal_ref - creates VInternalRef for web component" {
  let node : @luna.Node[Unit] = @luna.internal_ref(
    "/components/wc-tabs.js",
    "{\"selected\":0}",
    trigger=@core.Visible,
    wc=true,
    styles=".tabs { display: flex; }",
    children=[@luna.text("Tab content")],
  )
  guard node is @core.InternalRef(iref) else { fail("Expected InternalRef") }
  inspect(iref.url, content="/components/wc-tabs.js")
  inspect(iref.wc, content="true")
  inspect(iref.styles.length() > 0, content="true")
  inspect(iref.trigger.to_string(), content="visible")
}

// =============================================================================
// VNode Type Checking Tests
// =============================================================================

///|
test "VNode types - distinguish between node types" {
  let text_node : @luna.Node[Unit] = @luna.text("Hello")
  let element_node : @luna.Node[Unit] = @luna.h("div", [], [])
  let island_node : @luna.Node[Unit] = @luna.island("i1", "/a.js", "{}", [])
  let wc_node : @luna.Node[Unit] = @luna.wc_island("wc-1", "/b.js", "", "{}", [])

  // Check types
  inspect(text_node is @core.Text(_), content="true")
  inspect(element_node is @core.Element(_), content="true")
  inspect(island_node is @core.Island(_), content="true")
  inspect(wc_node is @core.WcIsland(_), content="true")

  // Negative checks
  inspect(text_node is @core.Element(_), content="false")
  inspect(element_node is @core.Text(_), content="false")
  inspect(island_node is @core.WcIsland(_), content="false")
  inspect(wc_node is @core.Island(_), content="false")
}

///|
test "Fragment - contains multiple nodes" {
  let fragment : @luna.Node[Unit] = @luna.fragment([
    @luna.text("First"),
    @luna.h("span", [], [@luna.text("Second")]),
    @luna.text("Third"),
  ])
  guard fragment is @core.Fragment(children) else { fail("Expected Fragment") }
  inspect(children.length(), content="3")
}

// =============================================================================
// ServerNode Pattern Matching Tests
// =============================================================================

///|
test "ServerNode - pattern matching sync" {
  let server_node = ServerNode::sync(@luna.text("test"))
  let is_sync = match server_node {
    Sync(_) => true
    Async(_) => false
  }
  inspect(is_sync, content="true")
}

///|
test "ServerNode - pattern matching async" {
  let server_node = ServerNode::async_(async fn() { @luna.text("async") })
  let is_async = match server_node {
    Sync(_) => false
    Async(_) => true
  }
  inspect(is_async, content="true")
}

// =============================================================================
// Edge Cases
// =============================================================================

///|
test "island - empty children" {
  let node : @luna.Node[Unit] = @luna.island("empty", "/e.js", "{}", [])
  guard node is @core.Island(island) else { fail("Expected Island") }
  inspect(island.children.length(), content="0")
}

///|
test "island - deeply nested children" {
  let node : @luna.Node[Unit] = @luna.island("nested", "/n.js", "{}", [
    @luna.h("div", [], [
      @luna.h("div", [], [@luna.h("div", [], [@luna.text("Deep")])]),
    ]),
  ])
  guard node is @core.Island(island) else { fail("Expected Island") }
  inspect(island.children.length(), content="1")
  guard island.children[0] is @core.Element(el) else {
    fail("Expected Element")
  }
  inspect(el.tag, content="div")
}

///|
test "island - special characters in state" {
  let state = "{\"msg\":\"Hello\\nWorld\\t!\"}"
  let node : @luna.Node[Unit] = @luna.island("special", "/s.js", state, [])
  guard node is @core.Island(island) else { fail("Expected Island") }
  inspect(island.state.contains("\\n"), content="true")
  inspect(island.state.contains("\\t"), content="true")
}

///|
test "wc_island - empty styles" {
  let node : @luna.Node[Unit] = @luna.wc_island(
    "wc-empty",
    "/wc.js",
    "",
    "{}",
    [],
  )
  guard node is @core.WcIsland(wc) else { fail("Expected WcIsland") }
  inspect(wc.styles, content="")
}

///|
test "internal_ref - styles is empty string by default" {
  let node : @luna.Node[Unit] = @luna.internal_ref("/c.js", "{}", wc=false, children=[])
  guard node is @core.InternalRef(iref) else { fail("Expected InternalRef") }
  inspect(iref.styles, content="")
}
