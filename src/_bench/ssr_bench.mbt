///|

///| SSR (Server-Side Rendering) Benchmarks

// =============================================================================
// Basic SSR Rendering
// =============================================================================

///|
test "ssr_simple_text" (b : @bench.T) {
  let node = @kaguya.vtext("Hello, World!")
  b.bench(name="ssr_simple_text", fn() { b.keep(@ssr.render_to_string(node)) })
}

///|
test "ssr_simple_element" (b : @bench.T) {
  let node = @kaguya.h("div", [], [@kaguya.vtext("Hello")])
  b.bench(name="ssr_simple_element", fn() {
    b.keep(@ssr.render_to_string(node))
  })
}

///|
test "ssr_element_with_attrs" (b : @bench.T) {
  let node = @kaguya.h(
    "div",
    [
      ("class", @kaguya.attr_static("container")),
      ("id", @kaguya.attr_static("main")),
    ],
    [@kaguya.vtext("Content")],
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
  let node = @kaguya.h("div", [], [
    @kaguya.h("section", [], [
      @kaguya.h("p", [], [@kaguya.vtext("Nested content")]),
    ]),
  ])
  b.bench(name="ssr_nested_3_levels", fn() {
    b.keep(@ssr.render_to_string(node))
  })
}

///|
test "ssr_nested_5_levels" (b : @bench.T) {
  let node = @kaguya.h("div", [], [
    @kaguya.h("section", [], [
      @kaguya.h("article", [], [
        @kaguya.h("div", [], [
          @kaguya.h("span", [], [@kaguya.vtext("Deep content")]),
        ]),
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
fn create_list(count : Int) -> @kaguya.Node[@core.Any] {
  let items : Array[@kaguya.Node[@core.Any]] = []
  for i = 0; i < count; i = i + 1 {
    items.push(@kaguya.h("li", [], [@kaguya.vtext("Item " + i.to_string())]))
  }
  @kaguya.h("ul", [], items)
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
fn create_card(title : String, content : String) -> @kaguya.Node[@core.Any] {
  @kaguya.h("div", [("class", @kaguya.attr_static("card"))], [
    @kaguya.h("h3", [("class", @kaguya.attr_static("card-title"))], [
      @kaguya.vtext(title),
    ]),
    @kaguya.h("p", [("class", @kaguya.attr_static("card-content"))], [
      @kaguya.vtext(content),
    ]),
    @kaguya.h("button", [("class", @kaguya.attr_static("card-button"))], [
      @kaguya.vtext("Read more"),
    ]),
  ])
}

///|
fn create_page(card_count : Int) -> @kaguya.Node[@core.Any] {
  let cards : Array[@kaguya.Node[@core.Any]] = []
  for i = 0; i < card_count; i = i + 1 {
    cards.push(
      create_card("Card " + i.to_string(), "Content for card " + i.to_string()),
    )
  }
  @kaguya.h("html", [], [
    @kaguya.h("head", [], [@kaguya.h("title", [], [@kaguya.vtext("Test Page")])]),
    @kaguya.h("body", [], [
      @kaguya.h("header", [], [@kaguya.h("h1", [], [@kaguya.vtext("Welcome")])]),
      @kaguya.h("main", [("class", @kaguya.attr_static("container"))], cards),
      @kaguya.h("footer", [], [
        @kaguya.h("p", [], [@kaguya.vtext("Footer content")]),
      ]),
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
  let node = @kaguya.h("div", [], [@kaguya.vtext("Hello")])
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
  let node = @kaguya.text_dyn(fn() { "Count: " + count.get().to_string() })
  b.bench(name="ssr_dynamic_text", fn() { b.keep(@ssr.render_to_string(node)) })
}

///|
test "ssr_dynamic_attrs" (b : @bench.T) {
  let active = @signal.signal(true)
  let node = @kaguya.h(
    "button",
    [
      (
        "class",
        @kaguya.attr_dynamic(fn() {
          if active.get() {
            "active"
          } else {
            "inactive"
          }
        }),
      ),
    ],
    [@kaguya.vtext("Toggle")],
  )
  b.bench(name="ssr_dynamic_attrs", fn() { b.keep(@ssr.render_to_string(node)) })
}

///|
test "ssr_show_conditional" (b : @bench.T) {
  let visible = @signal.signal(true)
  let node = @kaguya.vshow(fn() { visible.get() }, fn() {
    @kaguya.h("div", [], [@kaguya.vtext("Visible content")])
  })
  b.bench(name="ssr_show_conditional", fn() {
    b.keep(@ssr.render_to_string(node))
  })
}

///|
test "ssr_for_loop" (b : @bench.T) {
  let items_sig = @signal.signal(["a", "b", "c", "d", "e"])
  let node = @kaguya.vfor(fn() {
    items_sig.get().map(fn(item) { @kaguya.h("li", [], [@kaguya.vtext(item)]) })
  })
  b.bench(name="ssr_for_loop", fn() { b.keep(@ssr.render_to_string(node)) })
}
