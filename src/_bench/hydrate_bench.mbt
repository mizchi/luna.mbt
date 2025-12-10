///|
///| Hydration Benchmarks
///| Measures performance of connecting VNodes to server-rendered DOM

// =============================================================================
// Helper Functions
// =============================================================================

// Global container reused across benchmarks to prevent memory leak
let hydrate_bench_container : Ref[@js_dom.Element?] = { val: None }

///|
fn get_or_create_hydrate_container() -> @js_dom.Element {
  match hydrate_bench_container.val {
    Some(c) => c
    None => {
      let doc = @js_dom.document()
      let container = doc.createElement("div")
      container.setAttribute("id", "hydrate-bench-container")
      match doc.body() {
        Some(body) => body.appendChild(container.as_node()) |> ignore
        None => ()
      }
      hydrate_bench_container.val = Some(container)
      container
    }
  }
}

///|
fn setup_hydrate_container(html : String) -> @js_dom.Element {
  let container = get_or_create_hydrate_container()
  hydrate_set_inner_html(container, html)
  container
}

///|
extern "js" fn hydrate_set_inner_html(elem : @js_dom.Element, html : String) -> Unit =
  #| (elem, html) => { elem.innerHTML = html; }

// =============================================================================
// Basic Hydration
// =============================================================================

///|
test "hydrate_simple_text" (b : @bench.T) {
  @global_jsdom.register()
  let node = @kaguya.vtext("Hello, World!")
  let html = @ssr.render_to_string(node)
  b.bench(name="hydrate_simple_text", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@dom.hydrate(container, node))
  })
}

///|
test "hydrate_simple_element" (b : @bench.T) {
  @global_jsdom.register()
  let node = @kaguya.vnode("div", [], [@kaguya.vtext("Hello")])
  let html = @ssr.render_to_string(node)
  b.bench(name="hydrate_simple_element", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@dom.hydrate(container, node))
  })
}

///|
test "hydrate_element_with_attrs" (b : @bench.T) {
  @global_jsdom.register()
  let node = @kaguya.vnode(
    "div",
    [("class", @kaguya.attr_static("container")), ("id", @kaguya.attr_static("main"))],
    [@kaguya.vtext("Content")],
  )
  let html = @ssr.render_to_string(node)
  b.bench(name="hydrate_element_with_attrs", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@dom.hydrate(container, node))
  })
}

// =============================================================================
// Nested Elements
// =============================================================================

///|
test "hydrate_nested_3" (b : @bench.T) {
  @global_jsdom.register()
  let node = @kaguya.vnode(
    "div",
    [],
    [
      @kaguya.vnode(
        "section",
        [],
        [@kaguya.vnode("p", [], [@kaguya.vtext("Nested")])],
      ),
    ],
  )
  let html = @ssr.render_to_string(node)
  b.bench(name="hydrate_nested_3", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@dom.hydrate(container, node))
  })
}

///|
test "hydrate_nested_5" (b : @bench.T) {
  @global_jsdom.register()
  let node = @kaguya.vnode(
    "div",
    [],
    [
      @kaguya.vnode(
        "section",
        [],
        [
          @kaguya.vnode(
            "article",
            [],
            [
              @kaguya.vnode(
                "div",
                [],
                [@kaguya.vnode("span", [], [@kaguya.vtext("Deep")])],
              ),
            ],
          ),
        ],
      ),
    ],
  )
  let html = @ssr.render_to_string(node)
  b.bench(name="hydrate_nested_5", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@dom.hydrate(container, node))
  })
}

// =============================================================================
// List Hydration
// =============================================================================

///|
fn create_hydrate_list_node(count : Int) -> @kaguya.Node {
  let items : Array[@kaguya.Node] = []
  for i = 0; i < count; i = i + 1 {
    items.push(@kaguya.vnode("li", [], [@kaguya.vtext("Item " + i.to_string())]))
  }
  @kaguya.vnode("ul", [], items)
}

///|
test "hydrate_list_10" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_hydrate_list_node(10)
  let html = @ssr.render_to_string(node)
  b.bench(name="hydrate_list_10", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@dom.hydrate(container, node))
  })
}

///|
test "hydrate_list_100" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_hydrate_list_node(100)
  let html = @ssr.render_to_string(node)
  b.bench(name="hydrate_list_100", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@dom.hydrate(container, node))
  })
}

// =============================================================================
// Dynamic Content Hydration
// =============================================================================

///|
test "hydrate_dynamic_text" (b : @bench.T) {
  @global_jsdom.register()
  let count = @signal.signal(42)
  let node = @kaguya.text_dyn(fn() { "Count: " + count.get().to_string() })
  let html = @ssr.render_to_string_with_hydration(node)
  b.bench(name="hydrate_dynamic_text", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@dom.hydrate(container, node))
  })
}

///|
test "hydrate_dynamic_attrs" (b : @bench.T) {
  @global_jsdom.register()
  let active = @signal.signal(true)
  let node = @kaguya.vnode(
    "button",
    [("class", @kaguya.attr_dynamic(fn() { if active.get() { "active" } else { "inactive" } }))],
    [@kaguya.vtext("Toggle")],
  )
  let html = @ssr.render_to_string_with_hydration(node)
  b.bench(name="hydrate_dynamic_attrs", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@dom.hydrate(container, node))
  })
}

// =============================================================================
// Show Hydration
// =============================================================================

///|
test "hydrate_show_visible" (b : @bench.T) {
  @global_jsdom.register()
  let visible = @signal.signal(true)
  let node = @kaguya.vshow(
    fn() { visible.get() },
    fn() { @kaguya.vnode("div", [], [@kaguya.vtext("Visible content")]) },
  )
  let html = @ssr.render_to_string_with_hydration(node)
  b.bench(name="hydrate_show_visible", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@dom.hydrate(container, node))
  })
}

///|
test "hydrate_show_hidden" (b : @bench.T) {
  @global_jsdom.register()
  let visible = @signal.signal(false)
  let node = @kaguya.vshow(
    fn() { visible.get() },
    fn() { @kaguya.vnode("div", [], [@kaguya.vtext("Hidden content")]) },
  )
  let html = @ssr.render_to_string_with_hydration(node)
  b.bench(name="hydrate_show_hidden", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@dom.hydrate(container, node))
  })
}

// =============================================================================
// For Loop Hydration
// =============================================================================

///|
test "hydrate_for_5_items" (b : @bench.T) {
  @global_jsdom.register()
  let items_sig = @signal.signal(["a", "b", "c", "d", "e"])
  let node = @kaguya.vfor(fn() {
    items_sig.get().map(fn(item) { @kaguya.vnode("li", [], [@kaguya.vtext(item)]) })
  })
  let html = @ssr.render_to_string_with_hydration(node)
  b.bench(name="hydrate_for_5_items", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@dom.hydrate(container, node))
  })
}

///|
test "hydrate_for_20_items" (b : @bench.T) {
  @global_jsdom.register()
  let items : Array[String] = []
  for i = 0; i < 20; i = i + 1 {
    items.push("item_" + i.to_string())
  }
  let items_sig = @signal.signal(items)
  let node = @kaguya.vfor(fn() {
    items_sig.get().map(fn(item) { @kaguya.vnode("li", [], [@kaguya.vtext(item)]) })
  })
  let html = @ssr.render_to_string_with_hydration(node)
  b.bench(name="hydrate_for_20_items", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@dom.hydrate(container, node))
  })
}

// =============================================================================
// Complex Page Hydration
// =============================================================================

///|
fn create_hydrate_card(title : String, content : String) -> @kaguya.Node {
  @kaguya.vnode(
    "div",
    [("class", @kaguya.attr_static("card"))],
    [
      @kaguya.vnode(
        "h3",
        [("class", @kaguya.attr_static("card-title"))],
        [@kaguya.vtext(title)],
      ),
      @kaguya.vnode(
        "p",
        [("class", @kaguya.attr_static("card-content"))],
        [@kaguya.vtext(content)],
      ),
      @kaguya.vnode(
        "button",
        [("class", @kaguya.attr_static("card-button"))],
        [@kaguya.vtext("Read more")],
      ),
    ],
  )
}

///|
fn create_hydrate_page(card_count : Int) -> @kaguya.Node {
  let cards : Array[@kaguya.Node] = []
  for i = 0; i < card_count; i = i + 1 {
    cards.push(create_hydrate_card("Card " + i.to_string(), "Content for card " + i.to_string()))
  }
  @kaguya.vnode(
    "html",
    [],
    [
      @kaguya.vnode(
        "head",
        [],
        [@kaguya.vnode("title", [], [@kaguya.vtext("Test Page")])],
      ),
      @kaguya.vnode(
        "body",
        [],
        [
          @kaguya.vnode("header", [], [@kaguya.vnode("h1", [], [@kaguya.vtext("Welcome")])]),
          @kaguya.vnode("main", [("class", @kaguya.attr_static("container"))], cards),
          @kaguya.vnode(
            "footer",
            [],
            [@kaguya.vnode("p", [], [@kaguya.vtext("Footer content")])],
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
    let container = setup_hydrate_container(html)
    b.keep(@dom.hydrate(container, node))
  })
}

///|
test "hydrate_page_50_cards" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_hydrate_page(50)
  let html = @ssr.render_to_string(node)
  b.bench(name="hydrate_page_50_cards", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@dom.hydrate(container, node))
  })
}

// =============================================================================
// Hydration with Event Handlers
// =============================================================================

///|
test "hydrate_with_click_handler" (b : @bench.T) {
  @global_jsdom.register()
  let count = @signal.signal(0)
  let node = @kaguya.vnode(
    "button",
    [
      ("class", @kaguya.attr_dynamic(fn() { "count-" + count.get().to_string() })),
      ("onClick", @kaguya.attr_handler(@kaguya.event_handler())),
    ],
    [@kaguya.text_dyn(fn() { "Count: " + count.get().to_string() })],
  )
  let html = @ssr.render_to_string_with_hydration(node)
  b.bench(name="hydrate_with_click_handler", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@dom.hydrate(container, node))
  })
}

///|
test "hydrate_form_with_handlers" (b : @bench.T) {
  @global_jsdom.register()
  let value = @signal.signal("")
  let node = @kaguya.vnode(
    "form",
    [("onSubmit", @kaguya.attr_handler(@kaguya.event_handler()))],
    [
      @kaguya.vnode(
        "input",
        [
          ("type", @kaguya.attr_static("text")),
          ("value", @kaguya.attr_dynamic(fn() { value.get() })),
          ("onInput", @kaguya.attr_handler(@kaguya.event_handler())),
        ],
        [],
      ),
      @kaguya.vnode(
        "button",
        [("type", @kaguya.attr_static("submit"))],
        [@kaguya.vtext("Submit")],
      ),
    ],
  )
  let html = @ssr.render_to_string_with_hydration(node)
  b.bench(name="hydrate_form_with_handlers", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@dom.hydrate(container, node))
  })
}
