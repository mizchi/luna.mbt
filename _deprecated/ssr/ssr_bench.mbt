///|
/// SSR Benchmarks - Pure MoonBit (works on native/wasm/js)

// =============================================================================
// Basic Rendering
// =============================================================================

test "ssr_simple_text" (b : @bench.T) {
  let node = @ui.vtext("Hello, World!")
  b.bench(name="ssr_simple_text", fn() { b.keep(render_to_string(node)) })
}

///|
test "ssr_simple_div" (b : @bench.T) {
  let node = @ui.vdiv([], [])
  b.bench(name="ssr_simple_div", fn() { b.keep(render_to_string(node)) })
}

///|
test "ssr_div_with_text" (b : @bench.T) {
  let node = @ui.vdiv([], [@ui.vtext("Hello")])
  b.bench(name="ssr_div_with_text", fn() { b.keep(render_to_string(node)) })
}

///|
test "ssr_div_with_attrs" (b : @bench.T) {
  let node = @ui.vdiv(
    [@ui.vid("main"), @ui.vclass("container")],
    [@ui.vtext("Content")],
  )
  b.bench(name="ssr_div_with_attrs", fn() { b.keep(render_to_string(node)) })
}

// =============================================================================
// Nested Elements
// =============================================================================

///|
test "ssr_nested_3_levels" (b : @bench.T) {
  let node = @ui.vdiv([], [
    @ui.vdiv([], [@ui.vdiv([], [@ui.vtext("deep")])]),
  ])
  b.bench(name="ssr_nested_3_levels", fn() { b.keep(render_to_string(node)) })
}

///|
test "ssr_nested_5_levels" (b : @bench.T) {
  let node = @ui.vdiv([], [
    @ui.vdiv([], [
      @ui.vdiv([], [
        @ui.vdiv([], [@ui.vdiv([], [@ui.vtext("very deep")])]),
      ]),
    ]),
  ])
  b.bench(name="ssr_nested_5_levels", fn() { b.keep(render_to_string(node)) })
}

///|
test "ssr_nested_10_levels" (b : @bench.T) {
  let node = @ui.vdiv([], [
    @ui.vdiv([], [
      @ui.vdiv([], [
        @ui.vdiv([], [
          @ui.vdiv([], [
            @ui.vdiv([], [
              @ui.vdiv([], [
                @ui.vdiv([], [
                  @ui.vdiv([], [
                    @ui.vdiv([], [@ui.vtext("extremely deep")]),
                  ]),
                ]),
              ]),
            ]),
          ]),
        ]),
      ]),
    ]),
  ])
  b.bench(name="ssr_nested_10_levels", fn() { b.keep(render_to_string(node)) })
}

// =============================================================================
// Lists
// =============================================================================

///|
test "ssr_list_10_items" (b : @bench.T) {
  let items : Array[@ui.VNode] = []
  for i = 0; i < 10; i = i + 1 {
    items.push(@ui.vli([], [@ui.vtext("Item " + i.to_string())]))
  }
  let node = @ui.vul([], items)
  b.bench(name="ssr_list_10_items", fn() { b.keep(render_to_string(node)) })
}

///|
test "ssr_list_100_items" (b : @bench.T) {
  let items : Array[@ui.VNode] = []
  for i = 0; i < 100; i = i + 1 {
    items.push(@ui.vli([], [@ui.vtext("Item " + i.to_string())]))
  }
  let node = @ui.vul([], items)
  b.bench(name="ssr_list_100_items", fn() { b.keep(render_to_string(node)) })
}

///|
test "ssr_list_1000_items" (b : @bench.T) {
  let items : Array[@ui.VNode] = []
  for i = 0; i < 1000; i = i + 1 {
    items.push(@ui.vli([], [@ui.vtext("Item " + i.to_string())]))
  }
  let node = @ui.vul([], items)
  b.bench(name="ssr_list_1000_items", fn() { b.keep(render_to_string(node)) })
}

// =============================================================================
// Complex Components
// =============================================================================

///|
test "ssr_card_component" (b : @bench.T) {
  fn card(title : String, content : String) -> @ui.VNode {
    @ui.vdiv([@ui.vclass("card")], [
      @ui.vdiv([@ui.vclass("card-header")], [
        @ui.vh3([], [@ui.vtext(title)]),
      ]),
      @ui.vdiv([@ui.vclass("card-body")], [
        @ui.vp([], [@ui.vtext(content)]),
      ]),
      @ui.vdiv([@ui.vclass("card-footer")], [
        @ui.vbutton([@ui.vclass("btn")], [@ui.vtext("Action")]),
      ]),
    ])
  }

  let node = card("Title", "Some content here")
  b.bench(name="ssr_card_component", fn() { b.keep(render_to_string(node)) })
}

///|
test "ssr_100_cards" (b : @bench.T) {
  fn card(i : Int) -> @ui.VNode {
    @ui.vdiv([@ui.vclass("card")], [
      @ui.vdiv([@ui.vclass("card-header")], [
        @ui.vh3([], [@ui.vtext("Card " + i.to_string())]),
      ]),
      @ui.vdiv([@ui.vclass("card-body")], [
        @ui.vp([], [@ui.vtext("Content " + i.to_string())]),
      ]),
    ])
  }

  let cards : Array[@ui.VNode] = []
  for i = 0; i < 100; i = i + 1 {
    cards.push(card(i))
  }
  let node = @ui.vdiv([@ui.vclass("cards")], cards)
  b.bench(name="ssr_100_cards", fn() { b.keep(render_to_string(node)) })
}

// =============================================================================
// Dynamic Content
// =============================================================================

///|
test "ssr_dynamic_text" (b : @bench.T) {
  let count = 42
  let node = @ui.vtext_dyn(fn() { "Count: " + count.to_string() })
  b.bench(name="ssr_dynamic_text", fn() { b.keep(render_to_string(node)) })
}

///|
test "ssr_dynamic_attr" (b : @bench.T) {
  let active = true
  let node = @ui.vdiv(
    [@ui.vclass_dyn(fn() { if active { "active" } else { "inactive" } })],
    [],
  )
  b.bench(name="ssr_dynamic_attr", fn() { b.keep(render_to_string(node)) })
}

///|
test "ssr_100_dynamic_items" (b : @bench.T) {
  let count = 100
  let node = @ui.vfor(fn() {
    let result : Array[@ui.VNode] = []
    for i = 0; i < count; i = i + 1 {
      result.push(@ui.vli([], [@ui.vtext("Item " + i.to_string())]))
    }
    result
  })
  b.bench(name="ssr_100_dynamic_items", fn() { b.keep(render_to_string(node)) })
}

// =============================================================================
// With Hydration Markers
// =============================================================================

///|
test "ssr_hydration_simple" (b : @bench.T) {
  let node = @ui.vdiv([@ui.von_click(@ui.event_handler())], [
    @ui.vtext("Click me"),
  ])
  b.bench(name="ssr_hydration_simple", fn() {
    b.keep(render_to_string_with_hydration(node))
  })
}

///|
test "ssr_hydration_100_items" (b : @bench.T) {
  let items : Array[@ui.VNode] = []
  for i = 0; i < 100; i = i + 1 {
    items.push(
      @ui.vli([@ui.von_click(@ui.event_handler())], [
        @ui.vtext("Item " + i.to_string()),
      ]),
    )
  }
  let node = @ui.vul([], items)
  b.bench(name="ssr_hydration_100_items", fn() {
    b.keep(render_to_string_with_hydration(node))
  })
}

// =============================================================================
// Style Rendering
// =============================================================================

///|
test "ssr_inline_style" (b : @bench.T) {
  let node = @ui.vdiv(
    [
      @ui.vstyle([
        ("color", "red"),
        ("fontSize", "16px"),
        ("marginTop", "10px"),
      ]),
    ],
    [],
  )
  b.bench(name="ssr_inline_style", fn() { b.keep(render_to_string(node)) })
}

// =============================================================================
// Full Page Simulation
// =============================================================================

///|
test "ssr_full_page" (b : @bench.T) {
  fn nav() -> @ui.VNode {
    @ui.vdiv([@ui.vclass("nav")], [
      @ui.va([@ui.vhref("/")], [@ui.vtext("Home")]),
      @ui.va([@ui.vhref("/about")], [@ui.vtext("About")]),
      @ui.va([@ui.vhref("/contact")], [@ui.vtext("Contact")]),
    ])
  }

  fn header(title : String) -> @ui.VNode {
    @ui.vdiv([@ui.vclass("header")], [
      @ui.vh1([], [@ui.vtext(title)]),
    ])
  }

  fn sidebar() -> @ui.VNode {
    @ui.vdiv([@ui.vclass("sidebar")], [
      @ui.vul([], [
        @ui.vli([], [@ui.vtext("Menu 1")]),
        @ui.vli([], [@ui.vtext("Menu 2")]),
        @ui.vli([], [@ui.vtext("Menu 3")]),
      ]),
    ])
  }

  fn content() -> @ui.VNode {
    @ui.vdiv([@ui.vclass("content")], [
      @ui.vp([], [@ui.vtext("Welcome to our site!")]),
      @ui.vp([], [@ui.vtext("This is some content.")]),
    ])
  }

  fn footer() -> @ui.VNode {
    @ui.vdiv([@ui.vclass("footer")], [@ui.vtext("© 2025")])
  }

  let page = @ui.vdiv([@ui.vclass("page")], [
    nav(),
    header("My Website"),
    @ui.vdiv([@ui.vclass("main")], [sidebar(), content()]),
    footer(),
  ])
  b.bench(name="ssr_full_page", fn() { b.keep(render_to_string(page)) })
}

///|
test "ssr_blog_page_10_posts" (b : @bench.T) {
  fn post(i : Int) -> @ui.VNode {
    @ui.vdiv([@ui.vclass("post")], [
      @ui.vh2([], [@ui.vtext("Post Title " + i.to_string())]),
      @ui.vp([@ui.vclass("meta")], [
        @ui.vtext("Posted on 2025-01-01"),
      ]),
      @ui.vp([], [
        @ui.vtext(
          "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
        ),
      ]),
      @ui.vdiv([@ui.vclass("tags")], [
        @ui.vspan([@ui.vclass("tag")], [@ui.vtext("MoonBit")]),
        @ui.vspan([@ui.vclass("tag")], [@ui.vtext("SSR")]),
      ]),
    ])
  }

  let posts : Array[@ui.VNode] = []
  for i = 0; i < 10; i = i + 1 {
    posts.push(post(i))
  }
  let page = @ui.vdiv([@ui.vclass("blog")], [
    @ui.vh1([], [@ui.vtext("My Blog")]),
    @ui.vdiv([@ui.vclass("posts")], posts),
  ])
  b.bench(name="ssr_blog_page_10_posts", fn() { b.keep(render_to_string(page)) })
}
