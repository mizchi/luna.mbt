//
// Hydration Benchmarks
//

///|
/// Measures performance of connecting VNodes to server-rendered DOM

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
extern "js" fn hydrate_set_inner_html(
  elem : @js_dom.Element,
  html : String,
) -> Unit =
  #| (elem, html) => { elem.innerHTML = html; }

// =============================================================================
// Basic Hydration
// =============================================================================

///|
test "hydrate_simple_text" (b : @bench.T) {
  @global_jsdom.register()
  let node = @luna.text("Hello, World!")
  let html = @ssr.render_to_string(node).html
  b.bench(name="hydrate_simple_text", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@client.hydrate(container, node))
  })
}

///|
test "hydrate_simple_element" (b : @bench.T) {
  @global_jsdom.register()
  let node = @luna.h("div", [], [@luna.text("Hello")])
  let html = @ssr.render_to_string(node).html
  b.bench(name="hydrate_simple_element", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@client.hydrate(container, node))
  })
}

///|
test "hydrate_element_with_attrs" (b : @bench.T) {
  @global_jsdom.register()
  let node = @luna.h(
    "div",
    [
      ("class", @luna.attr_static("container")),
      ("id", @luna.attr_static("main")),
    ],
    [@luna.text("Content")],
  )
  let html = @ssr.render_to_string(node).html
  b.bench(name="hydrate_element_with_attrs", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@client.hydrate(container, node))
  })
}

// =============================================================================
// Nested Elements
// =============================================================================

///|
test "hydrate_nested_3" (b : @bench.T) {
  @global_jsdom.register()
  let node = @luna.h("div", [], [
    @luna.h("section", [], [@luna.h("p", [], [@luna.text("Nested")])]),
  ])
  let html = @ssr.render_to_string(node).html
  b.bench(name="hydrate_nested_3", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@client.hydrate(container, node))
  })
}

///|
test "hydrate_nested_5" (b : @bench.T) {
  @global_jsdom.register()
  let node = @luna.h("div", [], [
    @luna.h("section", [], [
      @luna.h("article", [], [
        @luna.h("div", [], [@luna.h("span", [], [@luna.text("Deep")])]),
      ]),
    ]),
  ])
  let html = @ssr.render_to_string(node).html
  b.bench(name="hydrate_nested_5", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@client.hydrate(container, node))
  })
}

// =============================================================================
// List Hydration
// =============================================================================

///|
fn create_hydrate_list_node(count : Int) -> @luna.Node[@js.Any] {
  let items : Array[@luna.Node[@js.Any]] = []
  for i = 0; i < count; i = i + 1 {
    items.push(@luna.h("li", [], [@luna.text("Item " + i.to_string())]))
  }
  @luna.h("ul", [], items)
}

///|
test "hydrate_list_10" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_hydrate_list_node(10)
  let html = @ssr.render_to_string(node).html
  b.bench(name="hydrate_list_10", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@client.hydrate(container, node))
  })
}

///|
test "hydrate_list_100" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_hydrate_list_node(100)
  let html = @ssr.render_to_string(node).html
  b.bench(name="hydrate_list_100", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@client.hydrate(container, node))
  })
}

// =============================================================================
// Dynamic Content Hydration
// =============================================================================

///|
test "hydrate_dynamic_text" (b : @bench.T) {
  @global_jsdom.register()
  let count = @signal.signal(42)
  let node = @luna.text_dyn(fn() { "Count: " + count.get().to_string() })
  let html = @ssr.render_to_string_with_hydration(node)
  b.bench(name="hydrate_dynamic_text", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@client.hydrate(container, node))
  })
}

///|
test "hydrate_dynamic_attrs" (b : @bench.T) {
  @global_jsdom.register()
  let active = @signal.signal(true)
  let node = @luna.h(
    "button",
    [
      (
        "class",
        @luna.attr_dynamic(fn() {
          if active.get() {
            "active"
          } else {
            "inactive"
          }
        }),
      ),
    ],
    [@luna.text("Toggle")],
  )
  let html = @ssr.render_to_string_with_hydration(node)
  b.bench(name="hydrate_dynamic_attrs", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@client.hydrate(container, node))
  })
}

// =============================================================================
// Show Hydration
// =============================================================================

///|
test "hydrate_show_visible" (b : @bench.T) {
  @global_jsdom.register()
  let visible = @signal.signal(true)
  let node = @luna.show(fn() { visible.get() }, fn() {
    @luna.h("div", [], [@luna.text("Visible content")])
  })
  let html = @ssr.render_to_string_with_hydration(node)
  b.bench(name="hydrate_show_visible", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@client.hydrate(container, node))
  })
}

///|
test "hydrate_show_hidden" (b : @bench.T) {
  @global_jsdom.register()
  let visible = @signal.signal(false)
  let node = @luna.show(fn() { visible.get() }, fn() {
    @luna.h("div", [], [@luna.text("Hidden content")])
  })
  let html = @ssr.render_to_string_with_hydration(node)
  b.bench(name="hydrate_show_hidden", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@client.hydrate(container, node))
  })
}

// =============================================================================
// For Loop Hydration
// =============================================================================

///|
test "hydrate_for_5_items" (b : @bench.T) {
  @global_jsdom.register()
  let items_sig = @signal.signal(["a", "b", "c", "d", "e"])
  let node = @luna.for_each(fn() {
    items_sig.get().map(fn(item) { @luna.h("li", [], [@luna.text(item)]) })
  })
  let html = @ssr.render_to_string_with_hydration(node)
  b.bench(name="hydrate_for_5_items", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@client.hydrate(container, node))
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
  let node = @luna.for_each(fn() {
    items_sig.get().map(fn(item) { @luna.h("li", [], [@luna.text(item)]) })
  })
  let html = @ssr.render_to_string_with_hydration(node)
  b.bench(name="hydrate_for_20_items", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@client.hydrate(container, node))
  })
}

// =============================================================================
// Complex Page Hydration
// =============================================================================

///|
fn create_hydrate_card(title : String, content : String) -> @luna.Node[@js.Any] {
  @luna.h("div", [("class", @luna.attr_static("card"))], [
    @luna.h("h3", [("class", @luna.attr_static("card-title"))], [
      @luna.text(title),
    ]),
    @luna.h("p", [("class", @luna.attr_static("card-content"))], [
      @luna.text(content),
    ]),
    @luna.h("button", [("class", @luna.attr_static("card-button"))], [
      @luna.text("Read more"),
    ]),
  ])
}

///|
fn create_hydrate_page(card_count : Int) -> @luna.Node[@js.Any] {
  let cards : Array[@luna.Node[@js.Any]] = []
  for i = 0; i < card_count; i = i + 1 {
    cards.push(
      create_hydrate_card(
        "Card " + i.to_string(),
        "Content for card " + i.to_string(),
      ),
    )
  }
  @luna.h("html", [], [
    @luna.h("head", [], [@luna.h("title", [], [@luna.text("Test Page")])]),
    @luna.h("body", [], [
      @luna.h("header", [], [@luna.h("h1", [], [@luna.text("Welcome")])]),
      @luna.h("main", [("class", @luna.attr_static("container"))], cards),
      @luna.h("footer", [], [@luna.h("p", [], [@luna.text("Footer content")])]),
    ]),
  ])
}

///|
test "hydrate_page_10_cards" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_hydrate_page(10)
  let html = @ssr.render_to_string(node).html
  b.bench(name="hydrate_page_10_cards", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@client.hydrate(container, node))
  })
}

///|
test "hydrate_page_50_cards" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_hydrate_page(50)
  let html = @ssr.render_to_string(node).html
  b.bench(name="hydrate_page_50_cards", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@client.hydrate(container, node))
  })
}

// =============================================================================
// Hydration with Event Handlers
// =============================================================================

///|
test "hydrate_with_click_handler" (b : @bench.T) {
  @global_jsdom.register()
  let count = @signal.signal(0)
  let node = @luna.h(
    "button",
    [
      ("class", @luna.attr_dynamic(fn() { "count-" + count.get().to_string() })),
      ("onClick", @luna.attr_handler(@luna.handler(fn(_) { () }))),
    ],
    [@luna.text_dyn(fn() { "Count: " + count.get().to_string() })],
  )
  let html = @ssr.render_to_string_with_hydration(node)
  b.bench(name="hydrate_with_click_handler", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@client.hydrate(container, node))
  })
}

///|
test "hydrate_form_with_handlers" (b : @bench.T) {
  @global_jsdom.register()
  let value = @signal.signal("")
  let node = @luna.h(
    "form",
    [("onSubmit", @luna.attr_handler(@luna.handler(fn(_) { () })))],
    [
      @luna.h(
        "input",
        [
          ("type", @luna.attr_static("text")),
          ("value", @luna.attr_dynamic(fn() { value.get() })),
          ("onInput", @luna.attr_handler(@luna.handler(fn(_) { () }))),
        ],
        [],
      ),
      @luna.h("button", [("type", @luna.attr_static("submit"))], [
        @luna.text("Submit"),
      ]),
    ],
  )
  let html = @ssr.render_to_string_with_hydration(node)
  b.bench(name="hydrate_form_with_handlers", fn() {
    let container = setup_hydrate_container(html)
    b.keep(@client.hydrate(container, node))
  })
}
