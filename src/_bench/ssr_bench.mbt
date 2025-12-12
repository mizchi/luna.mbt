///|

///| SSR (Server-Side Rendering) Benchmarks

// =============================================================================
// Basic SSR Rendering
// =============================================================================

///|
test "ssr_simple_text" (b : @bench.T) {
  let node : @luna.Node[Unit] = @luna.vtext("Hello, World!")
  b.bench(name="ssr_simple_text", fn() { b.keep(@ssr.render_to_string(node)) })
}

///|
test "ssr_simple_element" (b : @bench.T) {
  let node : @luna.Node[Unit] = @luna.h("div", [], [@luna.vtext("Hello")])
  b.bench(name="ssr_simple_element", fn() {
    b.keep(@ssr.render_to_string(node))
  })
}

///|
test "ssr_element_with_attrs" (b : @bench.T) {
  let node : @luna.Node[Unit] = @luna.h(
    "div",
    [
      ("class", @luna.attr_static("container")),
      ("id", @luna.attr_static("main")),
    ],
    [@luna.vtext("Content")],
  )
  b.bench(name="ssr_element_with_attrs", fn() {
    b.keep(@ssr.render_to_string(node))
  })
}

// =============================================================================
// Nested Elements
// =============================================================================

///|
test "ssr_nested_3_levels" (b : @bench.T) {
  let node : @luna.Node[Unit] = @luna.h("div", [], [
    @luna.h("section", [], [@luna.h("p", [], [@luna.vtext("Nested content")])]),
  ])
  b.bench(name="ssr_nested_3_levels", fn() {
    b.keep(@ssr.render_to_string(node))
  })
}

///|
test "ssr_nested_5_levels" (b : @bench.T) {
  let node : @luna.Node[Unit] = @luna.h("div", [], [
    @luna.h("section", [], [
      @luna.h("article", [], [
        @luna.h("div", [], [@luna.h("span", [], [@luna.vtext("Deep content")])]),
      ]),
    ]),
  ])
  b.bench(name="ssr_nested_5_levels", fn() {
    b.keep(@ssr.render_to_string(node))
  })
}

// =============================================================================
// Lists
// =============================================================================

///|
fn create_list(count : Int) -> @luna.Node[@js.Any] {
  let items : Array[@luna.Node[@js.Any]] = []
  for i = 0; i < count; i = i + 1 {
    items.push(@luna.h("li", [], [@luna.vtext("Item " + i.to_string())]))
  }
  @luna.h("ul", [], items)
}

///|
test "ssr_list_10_items" (b : @bench.T) {
  let node = create_list(10)
  b.bench(name="ssr_list_10_items", fn() { b.keep(@ssr.render_to_string(node)) })
}

///|
test "ssr_list_100_items" (b : @bench.T) {
  let node = create_list(100)
  b.bench(name="ssr_list_100_items", fn() {
    b.keep(@ssr.render_to_string(node))
  })
}

///|
test "ssr_list_1000_items" (b : @bench.T) {
  let node = create_list(1000)
  b.bench(name="ssr_list_1000_items", fn() {
    b.keep(@ssr.render_to_string(node))
  })
}

// =============================================================================
// Complex Page
// =============================================================================

///|
fn create_card(title : String, content : String) -> @luna.Node[@js.Any] {
  @luna.h("div", [("class", @luna.attr_static("card"))], [
    @luna.h("h3", [("class", @luna.attr_static("card-title"))], [
      @luna.vtext(title),
    ]),
    @luna.h("p", [("class", @luna.attr_static("card-content"))], [
      @luna.vtext(content),
    ]),
    @luna.h("button", [("class", @luna.attr_static("card-button"))], [
      @luna.vtext("Read more"),
    ]),
  ])
}

///|
fn create_page(card_count : Int) -> @luna.Node[@js.Any] {
  let cards : Array[@luna.Node[@js.Any]] = []
  for i = 0; i < card_count; i = i + 1 {
    cards.push(
      create_card("Card " + i.to_string(), "Content for card " + i.to_string()),
    )
  }
  @luna.h("html", [], [
    @luna.h("head", [], [@luna.h("title", [], [@luna.vtext("Test Page")])]),
    @luna.h("body", [], [
      @luna.h("header", [], [@luna.h("h1", [], [@luna.vtext("Welcome")])]),
      @luna.h("main", [("class", @luna.attr_static("container"))], cards),
      @luna.h("footer", [], [@luna.h("p", [], [@luna.vtext("Footer content")])]),
    ]),
  ])
}

///|
test "ssr_page_10_cards" (b : @bench.T) {
  let node = create_page(10)
  b.bench(name="ssr_page_10_cards", fn() { b.keep(@ssr.render_to_string(node)) })
}

///|
test "ssr_page_50_cards" (b : @bench.T) {
  let node = create_page(50)
  b.bench(name="ssr_page_50_cards", fn() { b.keep(@ssr.render_to_string(node)) })
}

///|
test "ssr_page_100_cards" (b : @bench.T) {
  let node = create_page(100)
  b.bench(name="ssr_page_100_cards", fn() {
    b.keep(@ssr.render_to_string(node))
  })
}

// =============================================================================
// With Hydration Markers
// =============================================================================

///|
test "ssr_hydration_simple" (b : @bench.T) {
  let node : @luna.Node[Unit] = @luna.h("div", [], [@luna.vtext("Hello")])
  b.bench(name="ssr_hydration_simple", fn() {
    b.keep(@ssr.render_to_string_with_hydration(node))
  })
}

///|
test "ssr_hydration_list_100" (b : @bench.T) {
  let node = create_list(100)
  b.bench(name="ssr_hydration_list_100", fn() {
    b.keep(@ssr.render_to_string_with_hydration(node))
  })
}

///|
test "ssr_hydration_page_50_cards" (b : @bench.T) {
  let node = create_page(50)
  b.bench(name="ssr_hydration_page_50_cards", fn() {
    b.keep(@ssr.render_to_string_with_hydration(node))
  })
}

// =============================================================================
// Dynamic Content
// =============================================================================

///|
test "ssr_dynamic_text" (b : @bench.T) {
  let count = @signal.signal(0)
  let node : @luna.Node[Unit] = @luna.text_dyn(fn() {
    "Count: " + count.get().to_string()
  })
  b.bench(name="ssr_dynamic_text", fn() { b.keep(@ssr.render_to_string(node)) })
}

///|
test "ssr_dynamic_attrs" (b : @bench.T) {
  let active = @signal.signal(true)
  let node : @luna.Node[Unit] = @luna.h(
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
    [@luna.vtext("Toggle")],
  )
  b.bench(name="ssr_dynamic_attrs", fn() { b.keep(@ssr.render_to_string(node)) })
}

///|
test "ssr_show_conditional" (b : @bench.T) {
  let visible = @signal.signal(true)
  let node : @luna.Node[Unit] = @luna.vshow(fn() { visible.get() }, fn() {
    @luna.h("div", [], [@luna.vtext("Visible content")])
  })
  b.bench(name="ssr_show_conditional", fn() {
    b.keep(@ssr.render_to_string(node))
  })
}

///|
test "ssr_for_loop" (b : @bench.T) {
  let items_sig = @signal.signal(["a", "b", "c", "d", "e"])
  let node : @luna.Node[Unit] = @luna.vfor(fn() {
    items_sig.get().map(fn(item) { @luna.h("li", [], [@luna.vtext(item)]) })
  })
  b.bench(name="ssr_for_loop", fn() { b.keep(@ssr.render_to_string(node)) })
}
