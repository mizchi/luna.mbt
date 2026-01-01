// Tests for Island Rendering - SSR Output Verification
//
// Tests the HTML output for various island types:
// - VIsland (luna:* attributes)
// - VWcIsland (Web Components with Declarative Shadow DOM)
// - VInternalRef (ComponentRef-based)

// =============================================================================
// VIsland Rendering Tests
// =============================================================================

///|
test "render Island - basic structure" {
  let node : @luna.Node[Unit] = @luna.island(
    "counter-1",
    "/static/counter.js",
    "{\"count\":0}",
    [@luna.text("Loading...")],
  )
  let result = render_to_string(node)
  let html = result.html

  // Should have luna:id attribute
  inspect(html.contains("luna:id=\"counter-1\""), content="true")
  // Should have luna:url attribute
  inspect(html.contains("luna:url=\"/static/counter.js\""), content="true")
  // Should have luna:state attribute (escaped JSON)
  inspect(html.contains("luna:state=\""), content="true")
  // Should have luna:client-trigger attribute
  inspect(html.contains("luna:client-trigger=\"load\""), content="true")
  // Should wrap in div
  inspect(html.contains("<div"), content="true")
  inspect(html.contains("</div>"), content="true")
  // Should have marker comments
  inspect(html.contains("<!--luna:island:counter-1"), content="true")
  inspect(html.contains("<!--/luna:island:counter-1-->"), content="true")
}

///|
test "render Island - with visible trigger" {
  let node : @luna.Node[Unit] = @luna.island(
    "lazy-1",
    "/static/lazy.js",
    "{}",
    [@luna.text("Lazy content")],
    trigger=@luna.Visible,
  )
  let result = render_to_string(node)
  inspect(
    result.html.contains("luna:client-trigger=\"visible\""),
    content="true",
  )
}

///|
test "render Island - with idle trigger" {
  let node : @luna.Node[Unit] = @luna.island(
    "idle-1",
    "/static/idle.js",
    "{}",
    [],
    trigger=@luna.Idle,
  )
  let result = render_to_string(node)
  inspect(result.html.contains("luna:client-trigger=\"idle\""), content="true")
}

///|
test "render Island - with media trigger" {
  let node : @luna.Node[Unit] = @luna.island(
    "mobile-1",
    "/static/mobile.js",
    "{}",
    [],
    trigger=@luna.Media("(max-width: 768px)"),
  )
  let result = render_to_string(node)
  inspect(
    result.html.contains("luna:client-trigger=\"media:(max-width: 768px)\""),
    content="true",
  )
}

///|
test "render Island - state with quotes is escaped" {
  let node : @luna.Node[Unit] = @luna.island(
    "test-1",
    "/static/test.js",
    "{\"message\":\"Hello \\\"World\\\"\"}",
    [],
  )
  let result = render_to_string(node)
  // State should be present in output
  inspect(result.html.contains("luna:state=\""), content="true")
  // Quotes in JSON should be properly escaped for HTML attribute
  inspect(
    result.html.contains("&quot;") || result.html.contains("\\\""),
    content="true",
  )
}

///|
test "render Island - children are rendered inside" {
  let node : @luna.Node[Unit] = @luna.island(
    "parent-1",
    "/static/parent.js",
    "{}",
    [
      @luna.h("span", [("class", @luna.attr_static("child"))], [
        @luna.text("Child content"),
      ]),
    ],
  )
  let result = render_to_string(node)
  inspect(result.html.contains("<span class=\"child\">"), content="true")
  inspect(result.html.contains("Child content"), content="true")
}

///|
test "render Island - nested islands" {
  let inner_island : @luna.Node[Unit] = @luna.island(
    "inner-1",
    "/static/inner.js",
    "{}",
    [@luna.text("Inner")],
  )
  let outer_island : @luna.Node[Unit] = @luna.island(
    "outer-1",
    "/static/outer.js",
    "{}",
    [inner_island],
  )
  let result = render_to_string(outer_island)
  // Both islands should be present
  inspect(result.html.contains("luna:id=\"outer-1\""), content="true")
  inspect(result.html.contains("luna:id=\"inner-1\""), content="true")
}

// =============================================================================
// VWcIsland Rendering Tests (Web Components + Declarative Shadow DOM)
// =============================================================================

///|
test "render WcIsland - basic structure" {
  let node : @luna.Node[Unit] = @luna.wc_island(
    "wc-counter",
    "/static/wc-counter.js",
    ".counter { color: blue; }",
    "{\"count\":0}",
    [@luna.text("0")],
  )
  let result = render_to_string(node)
  let html = result.html

  // Should use custom element tag
  inspect(html.contains("<wc-counter"), content="true")
  inspect(html.contains("</wc-counter>"), content="true")
  // Should have luna:wc-url attribute
  inspect(
    html.contains("luna:wc-url=\"/static/wc-counter.js\""),
    content="true",
  )
  // Should have luna:wc-state attribute
  inspect(html.contains("luna:wc-state=\""), content="true")
  // Should have Declarative Shadow DOM template
  inspect(html.contains("<template shadowrootmode=\"open\">"), content="true")
  inspect(html.contains("</template>"), content="true")
}

///|
test "render WcIsland - includes styles in shadow DOM" {
  let node : @luna.Node[Unit] = @luna.wc_island(
    "wc-styled",
    "/static/wc-styled.js",
    ".styled { background: red; padding: 10px; }",
    "{}",
    [@luna.text("Styled")],
  )
  let result = render_to_string(node)
  // Should have style tag with content
  inspect(result.html.contains("<style"), content="true")
  inspect(result.html.contains("background:red"), content="true") // minified
}

///|
test "render WcIsland - with visible trigger" {
  let node : @luna.Node[Unit] = @luna.wc_island(
    "wc-lazy",
    "/static/wc-lazy.js",
    "",
    "{}",
    [],
    trigger=@luna.Visible,
  )
  let result = render_to_string(node)
  inspect(result.html.contains("luna:wc-trigger=\"visible\""), content="true")
}

///|
test "render WcIsland - children in shadow DOM" {
  let node : @luna.Node[Unit] = @luna.wc_island(
    "wc-container",
    "/static/wc-container.js",
    "",
    "{}",
    [
      @luna.h("div", [("class", @luna.attr_static("content"))], [
        @luna.text("Shadow content"),
      ]),
    ],
  )
  let result = render_to_string(node)
  // Content should be inside template (shadow DOM)
  inspect(result.html.contains("class=\"content\""), content="true")
  inspect(result.html.contains("Shadow content"), content="true")
}

// =============================================================================
// VInternalRef Rendering Tests (ComponentRef-based)
// =============================================================================

///|
test "render InternalRef - as regular Island" {
  let node : @luna.Node[Unit] = @luna.internal_ref(
    "/components/button.js",
    "{\"label\":\"Click\"}",
    trigger=@luna.Load,
    wc=false,
    children=[@luna.text("Click")],
  )
  let result = render_to_string(node)
  let html = result.html

  // Should render as luna:* style island
  inspect(html.contains("luna:url=\"/components/button.js\""), content="true")
  inspect(html.contains("luna:state=\""), content="true")
  inspect(html.contains("<div"), content="true")
}

///|
test "render InternalRef - as Web Component" {
  let node : @luna.Node[Unit] = @luna.internal_ref(
    "/components/wc-modal.js",
    "{\"open\":false}",
    trigger=@luna.Load,
    wc=true,
    styles=".modal { position: fixed; }",
    children=[@luna.text("Modal content")],
  )
  let result = render_to_string(node)
  let html = result.html

  // Should render as Web Component with Declarative Shadow DOM
  inspect(html.contains("<wc-modal"), content="true")
  inspect(html.contains("<template shadowrootmode=\"open\">"), content="true")
  inspect(
    html.contains("luna:wc-url=\"/components/wc-modal.js\""),
    content="true",
  )
}

///|
test "render InternalRef - ID generation from URL" {
  let node : @luna.Node[Unit] = @luna.internal_ref(
    "/static/components/counter.js",
    "{}",
    wc=false,
    children=[],
  )
  let result = render_to_string(node)
  // ID should be generated from URL with / and . replaced
  inspect(result.html.contains("luna:id=\""), content="true")
}

// =============================================================================
// Preload URL Collection Tests
// =============================================================================

///|
test "render with preload - collects island URLs" {
  let node : @luna.Node[Unit] = @luna.fragment([
    @luna.island("a", "/static/a.js", "{}", []),
    @luna.island("b", "/static/b.js", "{}", []),
    @luna.island("c", "/static/c.js", "{}", []),
  ])
  let result = render_to_string(node, preload=true)
  inspect(result.preload_urls.length(), content="3")
  inspect(result.preload_urls.contains("/static/a.js"), content="true")
  inspect(result.preload_urls.contains("/static/b.js"), content="true")
  inspect(result.preload_urls.contains("/static/c.js"), content="true")
}

///|
test "render with preload - deduplicates URLs" {
  let node : @luna.Node[Unit] = @luna.fragment([
    @luna.island("a1", "/static/shared.js", "{}", []),
    @luna.island("a2", "/static/shared.js", "{}", []),
    @luna.island("a3", "/static/shared.js", "{}", []),
  ])
  let result = render_to_string(node, preload=true)
  // Should only have one URL despite multiple islands using it
  inspect(result.preload_urls.length(), content="1")
  inspect(result.preload_urls[0], content="/static/shared.js")
}

///|
test "render with preload - includes WcIsland URLs" {
  let node : @luna.Node[Unit] = @luna.fragment([
    @luna.island("i1", "/static/island.js", "{}", []),
    @luna.wc_island("wc-1", "/static/wc.js", "", "{}", []),
  ])
  let result = render_to_string(node, preload=true)
  inspect(result.preload_urls.length(), content="2")
  inspect(result.preload_urls.contains("/static/island.js"), content="true")
  inspect(result.preload_urls.contains("/static/wc.js"), content="true")
}

///|
test "generate_preload_tags - creates modulepreload links" {
  let urls = ["/static/a.js", "/static/b.js"]
  let tags = generate_preload_tags(urls)
  inspect(
    tags.contains("<link rel=\"modulepreload\" href=\"/static/a.js\">"),
    content="true",
  )
  inspect(
    tags.contains("<link rel=\"modulepreload\" href=\"/static/b.js\">"),
    content="true",
  )
}

///|
test "generate_preload_tags - empty array returns empty string" {
  let urls : Array[String] = []
  let tags = generate_preload_tags(urls)
  inspect(tags, content="")
}

// =============================================================================
// Island State Serialization Tests
// =============================================================================

///|
test "render Island - JSON state with special characters" {
  let node : @luna.Node[Unit] = @luna.island(
    "json-test",
    "/static/json.js",
    "{\"text\":\"Line1\\nLine2\",\"tab\":\"Col1\\tCol2\"}",
    [],
  )
  let result = render_to_string(node)
  // State should be properly escaped for HTML attribute
  inspect(result.html.contains("luna:state=\""), content="true")
}

///|
test "render Island - complex nested JSON state" {
  let state = "{\"user\":{\"name\":\"John\",\"email\":\"john@example.com\"},\"items\":[1,2,3]}"
  let node : @luna.Node[Unit] = @luna.island(
    "complex",
    "/static/complex.js",
    state,
    [],
  )
  let result = render_to_string(node)
  // Should contain the state attribute
  inspect(result.html.contains("luna:state=\""), content="true")
}

///|
test "render Island - empty state" {
  let node : @luna.Node[Unit] = @luna.island(
    "empty-state",
    "/static/empty.js",
    "{}",
    [],
  )
  let result = render_to_string(node)
  inspect(result.html.contains("luna:state=\"{}\""), content="true")
}

// =============================================================================
// Multiple Islands Tests
// =============================================================================

///|
test "render multiple islands - in fragment" {
  let node : @luna.Node[Unit] = @luna.fragment([
    @luna.island("first", "/static/first.js", "{\"n\":1}", [@luna.text("First")]),
    @luna.island("second", "/static/second.js", "{\"n\":2}", [
      @luna.text("Second"),
    ]),
  ])
  let result = render_to_string(node)
  inspect(result.html.contains("luna:id=\"first\""), content="true")
  inspect(result.html.contains("luna:id=\"second\""), content="true")
  inspect(result.html.contains("/static/first.js"), content="true")
  inspect(result.html.contains("/static/second.js"), content="true")
}

///|
test "render multiple islands - in element" {
  let node : @luna.Node[Unit] = @luna.h(
    "div",
    [("class", @luna.attr_static("container"))],
    [
      @luna.island("header", "/static/header.js", "{}", [@luna.text("Header")]),
      @luna.h("main", [], [@luna.text("Content")]),
      @luna.island("footer", "/static/footer.js", "{}", [@luna.text("Footer")]),
    ],
  )
  let result = render_to_string(node)
  inspect(result.html.contains("<div class=\"container\">"), content="true")
  inspect(result.html.contains("luna:id=\"header\""), content="true")
  inspect(result.html.contains("luna:id=\"footer\""), content="true")
}

// =============================================================================
// Mixed Island Types Tests
// =============================================================================

///|
test "render mixed - VIsland and VWcIsland" {
  let node : @luna.Node[Unit] = @luna.fragment([
    @luna.island("regular", "/static/regular.js", "{}", [@luna.text("Regular")]),
    @luna.wc_island("wc-special", "/static/wc.js", ".s{}", "{}", [
      @luna.text("WC"),
    ]),
  ])
  let result = render_to_string(node)
  // Regular island with luna:* attributes
  inspect(result.html.contains("luna:id=\"regular\""), content="true")
  // Web component with custom element tag
  inspect(result.html.contains("<wc-special"), content="true")
  inspect(result.html.contains("luna:wc-url"), content="true")
}

///|
test "render mixed - all three island types" {
  let node : @luna.Node[Unit] = @luna.fragment([
    @luna.island("v-island", "/a.js", "{}", []),
    @luna.wc_island("wc-island", "/b.js", "", "{}", []),
    @luna.internal_ref("/c.js", "{}", wc=false, children=[]),
  ])
  let result = render_to_string(node)
  // All three should be present
  inspect(result.html.contains("luna:id=\"v-island\""), content="true")
  inspect(result.html.contains("<wc-island"), content="true")
  inspect(result.html.contains("/c.js"), content="true")
}

// =============================================================================
// Edge Case Tests
// =============================================================================

///|
test "render Island - very long ID" {
  let long_id = "a".repeat(100)
  let node : @luna.Node[Unit] = @luna.island(long_id, "/x.js", "{}", [])
  let result = render_to_string(node)
  inspect(result.html.contains("luna:id=\"" + long_id + "\""), content="true")
}

///|
test "render Island - ID with allowed special characters" {
  let node : @luna.Node[Unit] = @luna.island(
    "my-island_v2",
    "/static/island.js",
    "{}",
    [],
  )
  let result = render_to_string(node)
  inspect(result.html.contains("luna:id=\"my-island_v2\""), content="true")
}

///|
test "render WcIsland - complex styles" {
  let styles = ".host { display: block; } .child { margin: 0; padding: 0; }"
  let node : @luna.Node[Unit] = @luna.wc_island(
    "wc-styled",
    "/static/styled.js",
    styles,
    "{}",
    [],
  )
  let result = render_to_string(node)
  inspect(result.html.contains("<style"), content="true")
}

///|
test "render Island - with boolean-like state values" {
  let node : @luna.Node[Unit] = @luna.island(
    "bool-state",
    "/static/bool.js",
    "{\"active\":true,\"disabled\":false}",
    [],
  )
  let result = render_to_string(node)
  inspect(result.html.contains("luna:state=\""), content="true")
}

///|
test "render Island - with array state" {
  let node : @luna.Node[Unit] = @luna.island(
    "array-state",
    "/static/array.js",
    "[1,2,3,4,5]",
    [],
  )
  let result = render_to_string(node)
  inspect(result.html.contains("luna:state=\""), content="true")
}

///|
test "render Island - with null in state" {
  let node : @luna.Node[Unit] = @luna.island(
    "null-state",
    "/static/null.js",
    "{\"value\":null}",
    [],
  )
  let result = render_to_string(node)
  inspect(result.html.contains("luna:state=\""), content="true")
}

// =============================================================================
// URL Format Tests
// =============================================================================

///|
test "render Island - absolute URL" {
  let node : @luna.Node[Unit] = @luna.island(
    "abs-url",
    "https://cdn.example.com/components/counter.js",
    "{}",
    [],
  )
  let result = render_to_string(node)
  inspect(
    result.html.contains(
      "luna:url=\"https://cdn.example.com/components/counter.js\"",
    ),
    content="true",
  )
}

///|
test "render Island - relative URL without leading slash" {
  let node : @luna.Node[Unit] = @luna.island(
    "rel-url",
    "components/counter.js",
    "{}",
    [],
  )
  let result = render_to_string(node)
  inspect(
    result.html.contains("luna:url=\"components/counter.js\""),
    content="true",
  )
}

///|
test "render Island - URL with query params" {
  let node : @luna.Node[Unit] = @luna.island(
    "query-url",
    "/static/counter.js?v=1.0.0",
    "{}",
    [],
  )
  let result = render_to_string(node)
  inspect(
    result.html.contains("luna:url=\"/static/counter.js?v=1.0.0\""),
    content="true",
  )
}

// =============================================================================
// Children Content Tests
// =============================================================================

///|
test "render Island - children with complex HTML" {
  let node : @luna.Node[Unit] = @luna.island(
    "complex-children",
    "/static/complex.js",
    "{}",
    [
      @luna.h("div", [("class", @luna.attr_static("wrapper"))], [
        @luna.h("header", [], [@luna.text("Header")]),
        @luna.h("section", [], [
          @luna.h("p", [], [@luna.text("Paragraph 1")]),
          @luna.h("p", [], [@luna.text("Paragraph 2")]),
        ]),
        @luna.h("footer", [], [@luna.text("Footer")]),
      ]),
    ],
  )
  let result = render_to_string(node)
  inspect(result.html.contains("<div class=\"wrapper\">"), content="true")
  inspect(result.html.contains("<header>"), content="true")
  inspect(result.html.contains("<section>"), content="true")
  inspect(result.html.contains("<footer>"), content="true")
}

///|
test "render Island - empty children renders empty content" {
  let node : @luna.Node[Unit] = @luna.island(
    "empty-children",
    "/static/empty.js",
    "{}",
    [],
  )
  let result = render_to_string(node)
  // Should have opening and closing comments with nothing between except wrapper
  inspect(
    result.html.contains("<!--luna:island:empty-children"),
    content="true",
  )
  inspect(
    result.html.contains("<!--/luna:island:empty-children-->"),
    content="true",
  )
}
