///|
/// SSR Benchmarks - Pure MoonBit (works on native/wasm/js)

// =============================================================================
// Basic Rendering
// =============================================================================

test "ssr_simple_text" (b : @bench.T) {
  let node = @signals.vtext("Hello, World!")
  b.bench(name="ssr_simple_text", fn() { b.keep(render_to_string(node)) })
}

///|
test "ssr_simple_div" (b : @bench.T) {
  let node = @signals.vdiv([], [])
  b.bench(name="ssr_simple_div", fn() { b.keep(render_to_string(node)) })
}

///|
test "ssr_div_with_text" (b : @bench.T) {
  let node = @signals.vdiv([], [@signals.vtext("Hello")])
  b.bench(name="ssr_div_with_text", fn() { b.keep(render_to_string(node)) })
}

///|
test "ssr_div_with_attrs" (b : @bench.T) {
  let node = @signals.vdiv(
    [@signals.vid("main"), @signals.vclass("container")],
    [@signals.vtext("Content")],
  )
  b.bench(name="ssr_div_with_attrs", fn() { b.keep(render_to_string(node)) })
}

// =============================================================================
// Nested Elements
// =============================================================================

///|
test "ssr_nested_3_levels" (b : @bench.T) {
  let node = @signals.vdiv([], [
    @signals.vdiv([], [@signals.vdiv([], [@signals.vtext("deep")])]),
  ])
  b.bench(name="ssr_nested_3_levels", fn() { b.keep(render_to_string(node)) })
}

///|
test "ssr_nested_5_levels" (b : @bench.T) {
  let node = @signals.vdiv([], [
    @signals.vdiv([], [
      @signals.vdiv([], [
        @signals.vdiv([], [@signals.vdiv([], [@signals.vtext("very deep")])]),
      ]),
    ]),
  ])
  b.bench(name="ssr_nested_5_levels", fn() { b.keep(render_to_string(node)) })
}

///|
test "ssr_nested_10_levels" (b : @bench.T) {
  let node = @signals.vdiv([], [
    @signals.vdiv([], [
      @signals.vdiv([], [
        @signals.vdiv([], [
          @signals.vdiv([], [
            @signals.vdiv([], [
              @signals.vdiv([], [
                @signals.vdiv([], [
                  @signals.vdiv([], [
                    @signals.vdiv([], [@signals.vtext("extremely deep")]),
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
  let items : Array[@signals.VNode] = []
  for i = 0; i < 10; i = i + 1 {
    items.push(@signals.vli([], [@signals.vtext("Item " + i.to_string())]))
  }
  let node = @signals.vul([], items)
  b.bench(name="ssr_list_10_items", fn() { b.keep(render_to_string(node)) })
}

///|
test "ssr_list_100_items" (b : @bench.T) {
  let items : Array[@signals.VNode] = []
  for i = 0; i < 100; i = i + 1 {
    items.push(@signals.vli([], [@signals.vtext("Item " + i.to_string())]))
  }
  let node = @signals.vul([], items)
  b.bench(name="ssr_list_100_items", fn() { b.keep(render_to_string(node)) })
}

///|
test "ssr_list_1000_items" (b : @bench.T) {
  let items : Array[@signals.VNode] = []
  for i = 0; i < 1000; i = i + 1 {
    items.push(@signals.vli([], [@signals.vtext("Item " + i.to_string())]))
  }
  let node = @signals.vul([], items)
  b.bench(name="ssr_list_1000_items", fn() { b.keep(render_to_string(node)) })
}

// =============================================================================
// Complex Components
// =============================================================================

///|
test "ssr_card_component" (b : @bench.T) {
  fn card(title : String, content : String) -> @signals.VNode {
    @signals.vdiv([@signals.vclass("card")], [
      @signals.vdiv([@signals.vclass("card-header")], [
        @signals.vh3([], [@signals.vtext(title)]),
      ]),
      @signals.vdiv([@signals.vclass("card-body")], [
        @signals.vp([], [@signals.vtext(content)]),
      ]),
      @signals.vdiv([@signals.vclass("card-footer")], [
        @signals.vbutton([@signals.vclass("btn")], [@signals.vtext("Action")]),
      ]),
    ])
  }

  let node = card("Title", "Some content here")
  b.bench(name="ssr_card_component", fn() { b.keep(render_to_string(node)) })
}

///|
test "ssr_100_cards" (b : @bench.T) {
  fn card(i : Int) -> @signals.VNode {
    @signals.vdiv([@signals.vclass("card")], [
      @signals.vdiv([@signals.vclass("card-header")], [
        @signals.vh3([], [@signals.vtext("Card " + i.to_string())]),
      ]),
      @signals.vdiv([@signals.vclass("card-body")], [
        @signals.vp([], [@signals.vtext("Content " + i.to_string())]),
      ]),
    ])
  }

  let cards : Array[@signals.VNode] = []
  for i = 0; i < 100; i = i + 1 {
    cards.push(card(i))
  }
  let node = @signals.vdiv([@signals.vclass("cards")], cards)
  b.bench(name="ssr_100_cards", fn() { b.keep(render_to_string(node)) })
}

// =============================================================================
// Dynamic Content
// =============================================================================

///|
test "ssr_dynamic_text" (b : @bench.T) {
  let count = 42
  let node = @signals.vtext_dyn(fn() { "Count: " + count.to_string() })
  b.bench(name="ssr_dynamic_text", fn() { b.keep(render_to_string(node)) })
}

///|
test "ssr_dynamic_attr" (b : @bench.T) {
  let active = true
  let node = @signals.vdiv(
    [@signals.vclass_dyn(fn() { if active { "active" } else { "inactive" } })],
    [],
  )
  b.bench(name="ssr_dynamic_attr", fn() { b.keep(render_to_string(node)) })
}

///|
test "ssr_100_dynamic_items" (b : @bench.T) {
  let count = 100
  let node = @signals.vfor(fn() {
    let result : Array[@signals.VNode] = []
    for i = 0; i < count; i = i + 1 {
      result.push(@signals.vli([], [@signals.vtext("Item " + i.to_string())]))
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
  let node = @signals.vdiv([@signals.von_click(@signals.event_handler())], [
    @signals.vtext("Click me"),
  ])
  b.bench(name="ssr_hydration_simple", fn() {
    b.keep(render_to_string_with_hydration(node))
  })
}

///|
test "ssr_hydration_100_items" (b : @bench.T) {
  let items : Array[@signals.VNode] = []
  for i = 0; i < 100; i = i + 1 {
    items.push(
      @signals.vli([@signals.von_click(@signals.event_handler())], [
        @signals.vtext("Item " + i.to_string()),
      ]),
    )
  }
  let node = @signals.vul([], items)
  b.bench(name="ssr_hydration_100_items", fn() {
    b.keep(render_to_string_with_hydration(node))
  })
}

// =============================================================================
// Style Rendering
// =============================================================================

///|
test "ssr_inline_style" (b : @bench.T) {
  let node = @signals.vdiv(
    [
      @signals.vstyle([
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
  fn nav() -> @signals.VNode {
    @signals.vdiv([@signals.vclass("nav")], [
      @signals.va([@signals.vhref("/")], [@signals.vtext("Home")]),
      @signals.va([@signals.vhref("/about")], [@signals.vtext("About")]),
      @signals.va([@signals.vhref("/contact")], [@signals.vtext("Contact")]),
    ])
  }

  fn header(title : String) -> @signals.VNode {
    @signals.vdiv([@signals.vclass("header")], [
      @signals.vh1([], [@signals.vtext(title)]),
    ])
  }

  fn sidebar() -> @signals.VNode {
    @signals.vdiv([@signals.vclass("sidebar")], [
      @signals.vul([], [
        @signals.vli([], [@signals.vtext("Menu 1")]),
        @signals.vli([], [@signals.vtext("Menu 2")]),
        @signals.vli([], [@signals.vtext("Menu 3")]),
      ]),
    ])
  }

  fn content() -> @signals.VNode {
    @signals.vdiv([@signals.vclass("content")], [
      @signals.vp([], [@signals.vtext("Welcome to our site!")]),
      @signals.vp([], [@signals.vtext("This is some content.")]),
    ])
  }

  fn footer() -> @signals.VNode {
    @signals.vdiv([@signals.vclass("footer")], [@signals.vtext("© 2025")])
  }

  let page = @signals.vdiv([@signals.vclass("page")], [
    nav(),
    header("My Website"),
    @signals.vdiv([@signals.vclass("main")], [sidebar(), content()]),
    footer(),
  ])
  b.bench(name="ssr_full_page", fn() { b.keep(render_to_string(page)) })
}

///|
test "ssr_blog_page_10_posts" (b : @bench.T) {
  fn post(i : Int) -> @signals.VNode {
    @signals.vdiv([@signals.vclass("post")], [
      @signals.vh2([], [@signals.vtext("Post Title " + i.to_string())]),
      @signals.vp([@signals.vclass("meta")], [
        @signals.vtext("Posted on 2025-01-01"),
      ]),
      @signals.vp([], [
        @signals.vtext(
          "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
        ),
      ]),
      @signals.vdiv([@signals.vclass("tags")], [
        @signals.vspan([@signals.vclass("tag")], [@signals.vtext("MoonBit")]),
        @signals.vspan([@signals.vclass("tag")], [@signals.vtext("SSR")]),
      ]),
    ])
  }

  let posts : Array[@signals.VNode] = []
  for i = 0; i < 10; i = i + 1 {
    posts.push(post(i))
  }
  let page = @signals.vdiv([@signals.vclass("blog")], [
    @signals.vh1([], [@signals.vtext("My Blog")]),
    @signals.vdiv([@signals.vclass("posts")], posts),
  ])
  b.bench(name="ssr_blog_page_10_posts", fn() { b.keep(render_to_string(page)) })
}
