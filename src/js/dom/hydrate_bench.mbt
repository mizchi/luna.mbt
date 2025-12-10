///|
///| Hydration Benchmarks
///| Measures performance of connecting VNodes to server-rendered DOM

// =============================================================================
// Helper Functions
// =============================================================================

///|
fn setup_container_with_html(html : String) -> @js_dom.Element {
  let doc = @js_dom.document()
  let container = doc.createElement("div")
  js_set_inner_html(container, html)
  match doc.body() {
    Some(body) => body.appendChild(container.as_node()) |> ignore
    None => ()
  }
  container
}

///|
extern "js" fn js_set_inner_html(elem : @js_dom.Element, html : String) -> Unit =
  #| (elem, html) => { elem.innerHTML = html; }

// =============================================================================
// Basic Hydration
// =============================================================================

///|
test "hydrate_simple_text" (b : @bench.T) {
  @global_jsdom.register()
  let node = @ui.vtext("Hello, World!")
  let html = @ssr.render_to_string(node)
  b.bench(name="hydrate_simple_text", fn() {
    let container = setup_container_with_html(html)
    b.keep(hydrate(container, node))
  })
}

///|
test "hydrate_simple_element" (b : @bench.T) {
  @global_jsdom.register()
  let node = @ui.vnode("div", [], [@ui.vtext("Hello")])
  let html = @ssr.render_to_string(node)
  b.bench(name="hydrate_simple_element", fn() {
    let container = setup_container_with_html(html)
    b.keep(hydrate(container, node))
  })
}

///|
test "hydrate_element_with_attrs" (b : @bench.T) {
  @global_jsdom.register()
  let node = @ui.vnode(
    "div",
    [("class", @ui.attr_static("container")), ("id", @ui.attr_static("main"))],
    [@ui.vtext("Content")],
  )
  let html = @ssr.render_to_string(node)
  b.bench(name="hydrate_element_with_attrs", fn() {
    let container = setup_container_with_html(html)
    b.keep(hydrate(container, node))
  })
}

// =============================================================================
// Nested Elements
// =============================================================================

///|
test "hydrate_nested_3" (b : @bench.T) {
  @global_jsdom.register()
  let node = @ui.vnode(
    "div",
    [],
    [
      @ui.vnode(
        "section",
        [],
        [@ui.vnode("p", [], [@ui.vtext("Nested")])],
      ),
    ],
  )
  let html = @ssr.render_to_string(node)
  b.bench(name="hydrate_nested_3", fn() {
    let container = setup_container_with_html(html)
    b.keep(hydrate(container, node))
  })
}

///|
test "hydrate_nested_5" (b : @bench.T) {
  @global_jsdom.register()
  let node = @ui.vnode(
    "div",
    [],
    [
      @ui.vnode(
        "section",
        [],
        [
          @ui.vnode(
            "article",
            [],
            [
              @ui.vnode(
                "div",
                [],
                [@ui.vnode("span", [], [@ui.vtext("Deep")])],
              ),
            ],
          ),
        ],
      ),
    ],
  )
  let html = @ssr.render_to_string(node)
  b.bench(name="hydrate_nested_5", fn() {
    let container = setup_container_with_html(html)
    b.keep(hydrate(container, node))
  })
}

// =============================================================================
// List Hydration
// =============================================================================

///|
fn create_hydrate_list_node(count : Int) -> @ui.Node {
  let items : Array[@ui.Node] = []
  for i = 0; i < count; i = i + 1 {
    items.push(@ui.vnode("li", [], [@ui.vtext("Item " + i.to_string())]))
  }
  @ui.vnode("ul", [], items)
}

///|
test "hydrate_list_10" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_hydrate_list_node(10)
  let html = @ssr.render_to_string(node)
  b.bench(name="hydrate_list_10", fn() {
    let container = setup_container_with_html(html)
    b.keep(hydrate(container, node))
  })
}

///|
test "hydrate_list_100" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_hydrate_list_node(100)
  let html = @ssr.render_to_string(node)
  b.bench(name="hydrate_list_100", fn() {
    let container = setup_container_with_html(html)
    b.keep(hydrate(container, node))
  })
}

// =============================================================================
// Dynamic Content Hydration
// =============================================================================

///|
test "hydrate_dynamic_text" (b : @bench.T) {
  @global_jsdom.register()
  let count = @ui.signal(42)
  let node = @ui.text_dyn(fn() { "Count: " + count.get().to_string() })
  let html = @ssr.render_to_string_with_hydration(node)
  b.bench(name="hydrate_dynamic_text", fn() {
    let container = setup_container_with_html(html)
    b.keep(hydrate(container, node))
  })
}

///|
test "hydrate_dynamic_attrs" (b : @bench.T) {
  @global_jsdom.register()
  let active = @ui.signal(true)
  let node = @ui.vnode(
    "button",
    [("class", @ui.attr_dynamic(fn() { if active.get() { "active" } else { "inactive" } }))],
    [@ui.vtext("Toggle")],
  )
  let html = @ssr.render_to_string_with_hydration(node)
  b.bench(name="hydrate_dynamic_attrs", fn() {
    let container = setup_container_with_html(html)
    b.keep(hydrate(container, node))
  })
}

// =============================================================================
// Show Hydration
// =============================================================================

///|
test "hydrate_show_visible" (b : @bench.T) {
  @global_jsdom.register()
  let visible = @ui.signal(true)
  let node = @ui.vshow(
    fn() { visible.get() },
    fn() { @ui.vnode("div", [], [@ui.vtext("Visible content")]) },
  )
  let html = @ssr.render_to_string_with_hydration(node)
  b.bench(name="hydrate_show_visible", fn() {
    let container = setup_container_with_html(html)
    b.keep(hydrate(container, node))
  })
}

///|
test "hydrate_show_hidden" (b : @bench.T) {
  @global_jsdom.register()
  let visible = @ui.signal(false)
  let node = @ui.vshow(
    fn() { visible.get() },
    fn() { @ui.vnode("div", [], [@ui.vtext("Hidden content")]) },
  )
  let html = @ssr.render_to_string_with_hydration(node)
  b.bench(name="hydrate_show_hidden", fn() {
    let container = setup_container_with_html(html)
    b.keep(hydrate(container, node))
  })
}

// =============================================================================
// For Loop Hydration
// =============================================================================

///|
test "hydrate_for_5_items" (b : @bench.T) {
  @global_jsdom.register()
  let items_sig = @ui.signal(["a", "b", "c", "d", "e"])
  let node = @ui.vfor(fn() {
    items_sig.get().map(fn(item) { @ui.vnode("li", [], [@ui.vtext(item)]) })
  })
  let html = @ssr.render_to_string_with_hydration(node)
  b.bench(name="hydrate_for_5_items", fn() {
    let container = setup_container_with_html(html)
    b.keep(hydrate(container, node))
  })
}

///|
test "hydrate_for_20_items" (b : @bench.T) {
  @global_jsdom.register()
  let items : Array[String] = []
  for i = 0; i < 20; i = i + 1 {
    items.push("item_" + i.to_string())
  }
  let items_sig = @ui.signal(items)
  let node = @ui.vfor(fn() {
    items_sig.get().map(fn(item) { @ui.vnode("li", [], [@ui.vtext(item)]) })
  })
  let html = @ssr.render_to_string_with_hydration(node)
  b.bench(name="hydrate_for_20_items", fn() {
    let container = setup_container_with_html(html)
    b.keep(hydrate(container, node))
  })
}

// =============================================================================
// Complex Page Hydration
// =============================================================================

///|
fn create_hydrate_card(title : String, content : String) -> @ui.Node {
  @ui.vnode(
    "div",
    [("class", @ui.attr_static("card"))],
    [
      @ui.vnode(
        "h3",
        [("class", @ui.attr_static("card-title"))],
        [@ui.vtext(title)],
      ),
      @ui.vnode(
        "p",
        [("class", @ui.attr_static("card-content"))],
        [@ui.vtext(content)],
      ),
      @ui.vnode(
        "button",
        [("class", @ui.attr_static("card-button"))],
        [@ui.vtext("Read more")],
      ),
    ],
  )
}

///|
fn create_hydrate_page(card_count : Int) -> @ui.Node {
  let cards : Array[@ui.Node] = []
  for i = 0; i < card_count; i = i + 1 {
    cards.push(create_hydrate_card("Card " + i.to_string(), "Content for card " + i.to_string()))
  }
  @ui.vnode(
    "html",
    [],
    [
      @ui.vnode(
        "head",
        [],
        [@ui.vnode("title", [], [@ui.vtext("Test Page")])],
      ),
      @ui.vnode(
        "body",
        [],
        [
          @ui.vnode("header", [], [@ui.vnode("h1", [], [@ui.vtext("Welcome")])]),
          @ui.vnode("main", [("class", @ui.attr_static("container"))], cards),
          @ui.vnode(
            "footer",
            [],
            [@ui.vnode("p", [], [@ui.vtext("Footer content")])],
          ),
        ],
      ),
    ],
  )
}

///|
test "hydrate_page_10_cards" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_hydrate_page(10)
  let html = @ssr.render_to_string(node)
  b.bench(name="hydrate_page_10_cards", fn() {
    let container = setup_container_with_html(html)
    b.keep(hydrate(container, node))
  })
}

///|
test "hydrate_page_50_cards" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_hydrate_page(50)
  let html = @ssr.render_to_string(node)
  b.bench(name="hydrate_page_50_cards", fn() {
    let container = setup_container_with_html(html)
    b.keep(hydrate(container, node))
  })
}

// =============================================================================
// Hydration with Event Handlers
// =============================================================================

///|
test "hydrate_with_click_handler" (b : @bench.T) {
  @global_jsdom.register()
  let count = @ui.signal(0)
  let node = @ui.vnode(
    "button",
    [
      ("class", @ui.attr_dynamic(fn() { "count-" + count.get().to_string() })),
      ("onClick", @ui.attr_handler(@ui.event_handler())),
    ],
    [@ui.text_dyn(fn() { "Count: " + count.get().to_string() })],
  )
  let html = @ssr.render_to_string_with_hydration(node)
  b.bench(name="hydrate_with_click_handler", fn() {
    let container = setup_container_with_html(html)
    b.keep(hydrate(container, node))
  })
}

///|
test "hydrate_form_with_handlers" (b : @bench.T) {
  @global_jsdom.register()
  let value = @ui.signal("")
  let node = @ui.vnode(
    "form",
    [("onSubmit", @ui.attr_handler(@ui.event_handler()))],
    [
      @ui.vnode(
        "input",
        [
          ("type", @ui.attr_static("text")),
          ("value", @ui.attr_dynamic(fn() { value.get() })),
          ("onInput", @ui.attr_handler(@ui.event_handler())),
        ],
        [],
      ),
      @ui.vnode(
        "button",
        [("type", @ui.attr_static("submit"))],
        [@ui.vtext("Submit")],
      ),
    ],
  )
  let html = @ssr.render_to_string_with_hydration(node)
  b.bench(name="hydrate_form_with_handlers", fn() {
    let container = setup_container_with_html(html)
    b.keep(hydrate(container, node))
  })
}
