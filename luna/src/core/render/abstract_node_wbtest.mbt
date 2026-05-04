// Abstract Node Tests

///|
fn empty_json() -> Json {
  Json::object(Map::new())
}

///|
fn null_json() -> Json {
  Json::null()
}

///|
test "create simple element" {
  let node = element("div", [("class", Str("container"))], [text("Hello")])
  assert_eq(node.count_nodes(), 2)
}

///|
test "create nested elements" {
  let node = element("div", [], [
    element("h1", [], [text("Title")]),
    element("p", [], [text("Content")]),
  ])
  assert_eq(node.count_nodes(), 5)
}

///|
test "create component with hydration" {
  let node = component("Counter", empty_json(), Hydration(Load), [text("0")])
  let components = node.get_components()
  assert_eq(components.length(), 1)
  assert_eq(components[0].name, "Counter")
  assert_eq(components[0].mode, Hydration(Load))
}

///|
test "get render modes from tree" {
  let node = element("div", [], [
    component("Header", null_json(), SSROnly, []),
    component("Counter", null_json(), Hydration(Load), []),
    component("Sidebar", null_json(), Hydration(Visible), []),
  ])
  let modes = node.get_render_modes()
  assert_eq(modes.length(), 3)
}

///|
test "check has_client_js" {
  let ssr_only = element("div", [], [
    component("Header", null_json(), SSROnly, []),
  ])
  assert_eq(ssr_only.has_client_js(), false)
  let with_hydration = element("div", [], [
    component("Counter", null_json(), Hydration(Load), []),
  ])
  assert_eq(with_hydration.has_client_js(), true)
  let client_only = element("div", [], [
    component("Widget", null_json(), ClientOnly, []),
  ])
  assert_eq(client_only.has_client_js(), true)
}

///|
test "fragment nodes" {
  let frag = fragment([text("a"), text("b"), text("c")])
  assert_eq(frag.count_nodes(), 3)
}

///|
test "render mode requires_ssr" {
  assert_eq(SSROnly.requires_ssr(), true)
  assert_eq(Hydration(Load).requires_ssr(), true)
  assert_eq(ServerDefer.requires_ssr(), true)
  assert_eq(ClientOnly.requires_ssr(), false)
}

///|
test "render mode requires_client_js" {
  assert_eq(SSROnly.requires_client_js(), false)
  assert_eq(Hydration(Load).requires_client_js(), true)
  assert_eq(ServerDefer.requires_client_js(), false)
  assert_eq(ClientOnly.requires_client_js(), true)
}

///|
test "hydration trigger parsing" {
  assert_eq(HydrationTrigger::parse("load"), Load)
  assert_eq(HydrationTrigger::parse("idle"), Idle)
  assert_eq(HydrationTrigger::parse("visible"), Visible)
  assert_eq(
    HydrationTrigger::parse("media:(max-width: 768px)"),
    Media("(max-width: 768px)"),
  )
}

///|
test "hydration trigger to string" {
  assert_eq(Load.to_attr_string(), "load")
  assert_eq(Idle.to_attr_string(), "idle")
  assert_eq(Visible.to_attr_string(), "visible")
  assert_eq(
    Media("(min-width: 1024px)").to_attr_string(),
    "media:(min-width: 1024px)",
  )
}

///|
test "deeply nested components" {
  let node = element("div", [], [
    component("Layout", null_json(), SSROnly, [
      element("main", [], [
        component("Sidebar", null_json(), Hydration(Idle), [
          component("Menu", null_json(), Hydration(Visible), []),
        ]),
        component("Content", null_json(), SSROnly, []),
      ]),
    ]),
  ])
  let components = node.get_components()
  assert_eq(components.length(), 4)

  // Check component names
  let names = components.map(fn(c) { c.name })
  assert_true(names.contains("Layout"))
  assert_true(names.contains("Sidebar"))
  assert_true(names.contains("Menu"))
  assert_true(names.contains("Content"))
}

// =============================================================================
// HTML Renderer Tests
// =============================================================================

///|
test "render simple element to html" {
  let node = element("div", [("class", Str("container"))], [text("Hello")])
  let html = node.render_html()
  assert_eq(html, "<div class=\"container\">Hello</div>")
}

///|
test "render nested elements to html" {
  let node = element("ul", [], [
    element("li", [], [text("Item 1")]),
    element("li", [], [text("Item 2")]),
  ])
  let html = node.render_html()
  assert_eq(html, "<ul><li>Item 1</li><li>Item 2</li></ul>")
}

///|
test "render void elements" {
  let node = element("div", [], [
    element("img", [("src", Str("test.png")), ("alt", Str("Test"))], []),
    element("br", [], []),
    element("input", [("type", Str("text"))], []),
  ])
  let html = node.render_html()
  assert_true(html.contains("<img src=\"test.png\" alt=\"Test\" />"))
  assert_true(html.contains("<br />"))
  assert_true(html.contains("<input type=\"text\" />"))
}

///|
test "render fragment to html" {
  let node = fragment([text("Hello "), element("strong", [], [text("World")])])
  let html = node.render_html()
  assert_eq(html, "Hello <strong>World</strong>")
}

///|
test "escape html content" {
  let node = text("<script>alert('XSS')</script>")
  let html = node.render_html()
  assert_eq(html, "&lt;script&gt;alert(&#39;XSS&#39;)&lt;/script&gt;")
}

///|
test "escape attribute values" {
  let node = element("a", [("href", Str("test?a=1&b=2"))], [text("Link")])
  let html = node.render_html()
  assert_true(html.contains("href=\"test?a=1&amp;b=2\""))
}

///|
test "render boolean attributes" {
  let node = element(
    "input",
    [
      ("type", Str("checkbox")),
      ("checked", Bool(true)),
      ("disabled", Bool(false)),
    ],
    [],
  )
  let html = node.render_html()
  assert_true(html.contains("checked"))
  assert_false(html.contains("disabled"))
}

///|
test "render numeric attributes" {
  let node = element(
    "input",
    [("type", Str("number")), ("min", Num(0.0)), ("max", Num(100.0))],
    [],
  )
  let html = node.render_html()
  assert_true(html.contains("min=\"0\""))
  assert_true(html.contains("max=\"100\""))
}

///|
test "render ssr-only component" {
  let node = component("Header", null_json(), SSROnly, [text("Header Content")])
  let html = node.render_html()
  // SSROnly renders children directly without wrapper
  assert_eq(html, "Header Content")
}

///|
test "render hydration component" {
  let node = component("Counter", null_json(), Hydration(Load), [text("0")])
  let html = node.render_html()
  assert_true(html.contains("data-island=\"Counter\""))
  assert_true(html.contains("data-trigger=\"load\""))
  assert_true(html.contains(">0</div>"))
}

///|
test "render client-only component" {
  let node = component("Widget", null_json(), ClientOnly, [])
  let html = node.render_html()
  assert_true(html.contains("data-client-only=\"Widget\""))
  assert_true(html.contains("<!--loading-->"))
}

///|
test "render raw html" {
  let node = RawHtml("<custom-element>Content</custom-element>")
  let html = node.render_html()
  assert_eq(html, "<custom-element>Content</custom-element>")
}

///|
test "render slot with fallback" {
  let node = Slot(name="content", fallback=[text("Default content")])
  let html = node.render_html()
  assert_true(html.contains("<!--slot:content-->"))
  assert_true(html.contains("Default content"))
  assert_true(html.contains("<!--/slot-->"))
}
