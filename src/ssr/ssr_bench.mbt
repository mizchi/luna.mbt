///|
///| SSR (Server-Side Rendering) Benchmarks

// =============================================================================
// Basic SSR Rendering
// =============================================================================

///|
test "ssr_simple_text" (b : @bench.T) {
  let node = @ui.vtext("Hello, World!")
  b.bench(name="ssr_simple_text", fn() { b.keep(render_to_string(node)) })
}

///|
test "ssr_simple_element" (b : @bench.T) {
  let node = @ui.vnode("div", [], [@ui.vtext("Hello")])
  b.bench(name="ssr_simple_element", fn() { b.keep(render_to_string(node)) })
}

///|
test "ssr_element_with_attrs" (b : @bench.T) {
  let node = @ui.vnode(
    "div",
    [("class", @ui.attr_static("container")), ("id", @ui.attr_static("main"))],
    [@ui.vtext("Content")],
  )
  b.bench(name="ssr_element_with_attrs", fn() { b.keep(render_to_string(node)) })
}

// =============================================================================
// Nested Elements
// =============================================================================

///|
test "ssr_nested_3_levels" (b : @bench.T) {
  let node = @ui.vnode(
    "div",
    [],
    [
      @ui.vnode(
        "section",
        [],
        [@ui.vnode("p", [], [@ui.vtext("Nested content")])],
      ),
    ],
  )
  b.bench(name="ssr_nested_3_levels", fn() { b.keep(render_to_string(node)) })
}

///|
test "ssr_nested_5_levels" (b : @bench.T) {
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
                [@ui.vnode("span", [], [@ui.vtext("Deep content")])],
              ),
            ],
          ),
        ],
      ),
    ],
  )
  b.bench(name="ssr_nested_5_levels", fn() { b.keep(render_to_string(node)) })
}

// =============================================================================
// Lists
// =============================================================================

///|
fn create_list(count : Int) -> @ui.Node {
  let items : Array[@ui.Node] = []
  for i = 0; i < count; i = i + 1 {
    items.push(@ui.vnode("li", [], [@ui.vtext("Item " + i.to_string())]))
  }
  @ui.vnode("ul", [], items)
}

///|
test "ssr_list_10_items" (b : @bench.T) {
  let node = create_list(10)
  b.bench(name="ssr_list_10_items", fn() { b.keep(render_to_string(node)) })
}

///|
test "ssr_list_100_items" (b : @bench.T) {
  let node = create_list(100)
  b.bench(name="ssr_list_100_items", fn() { b.keep(render_to_string(node)) })
}

///|
test "ssr_list_1000_items" (b : @bench.T) {
  let node = create_list(1000)
  b.bench(name="ssr_list_1000_items", fn() { b.keep(render_to_string(node)) })
}

// =============================================================================
// Complex Page
// =============================================================================

///|
fn create_card(title : String, content : String) -> @ui.Node {
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
fn create_page(card_count : Int) -> @ui.Node {
  let cards : Array[@ui.Node] = []
  for i = 0; i < card_count; i = i + 1 {
    cards.push(create_card("Card " + i.to_string(), "Content for card " + i.to_string()))
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
test "ssr_page_10_cards" (b : @bench.T) {
  let node = create_page(10)
  b.bench(name="ssr_page_10_cards", fn() { b.keep(render_to_string(node)) })
}

///|
test "ssr_page_50_cards" (b : @bench.T) {
  let node = create_page(50)
  b.bench(name="ssr_page_50_cards", fn() { b.keep(render_to_string(node)) })
}

///|
test "ssr_page_100_cards" (b : @bench.T) {
  let node = create_page(100)
  b.bench(name="ssr_page_100_cards", fn() { b.keep(render_to_string(node)) })
}

// =============================================================================
// With Hydration Markers
// =============================================================================

///|
test "ssr_hydration_simple" (b : @bench.T) {
  let node = @ui.vnode("div", [], [@ui.vtext("Hello")])
  b.bench(name="ssr_hydration_simple", fn() {
    b.keep(render_to_string_with_hydration(node))
  })
}

///|
test "ssr_hydration_list_100" (b : @bench.T) {
  let node = create_list(100)
  b.bench(name="ssr_hydration_list_100", fn() {
    b.keep(render_to_string_with_hydration(node))
  })
}

///|
test "ssr_hydration_page_50_cards" (b : @bench.T) {
  let node = create_page(50)
  b.bench(name="ssr_hydration_page_50_cards", fn() {
    b.keep(render_to_string_with_hydration(node))
  })
}

// =============================================================================
// Dynamic Content
// =============================================================================

///|
test "ssr_dynamic_text" (b : @bench.T) {
  let count = @ui.signal(0)
  let node = @ui.text_dyn(fn() { "Count: " + count.get().to_string() })
  b.bench(name="ssr_dynamic_text", fn() { b.keep(render_to_string(node)) })
}

///|
test "ssr_dynamic_attrs" (b : @bench.T) {
  let active = @ui.signal(true)
  let node = @ui.vnode(
    "button",
    [("class", @ui.attr_dynamic(fn() { if active.get() { "active" } else { "inactive" } }))],
    [@ui.vtext("Toggle")],
  )
  b.bench(name="ssr_dynamic_attrs", fn() { b.keep(render_to_string(node)) })
}

///|
test "ssr_show_conditional" (b : @bench.T) {
  let visible = @ui.signal(true)
  let node = @ui.vshow(
    fn() { visible.get() },
    fn() { @ui.vnode("div", [], [@ui.vtext("Visible content")]) },
  )
  b.bench(name="ssr_show_conditional", fn() { b.keep(render_to_string(node)) })
}

///|
test "ssr_for_loop" (b : @bench.T) {
  let items_sig = @ui.signal(["a", "b", "c", "d", "e"])
  let node = @ui.vfor(fn() {
    items_sig.get().map(fn(item) { @ui.vnode("li", [], [@ui.vtext(item)]) })
  })
  b.bench(name="ssr_for_loop", fn() { b.keep(render_to_string(node)) })
}
