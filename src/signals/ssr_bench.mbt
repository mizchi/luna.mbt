///| SSR Benchmarks

// =============================================================================
// Basic Rendering
// =============================================================================

test "ssr_simple_text" (b : @bench.T) {
  let node = vtext("Hello, World!")
  b.bench(name="ssr_simple_text", fn() { b.keep(render_to_string(node)) })
}

test "ssr_simple_div" (b : @bench.T) {
  let node = vdiv([], [])
  b.bench(name="ssr_simple_div", fn() { b.keep(render_to_string(node)) })
}

test "ssr_div_with_text" (b : @bench.T) {
  let node = vdiv([], [vtext("Hello")])
  b.bench(name="ssr_div_with_text", fn() { b.keep(render_to_string(node)) })
}

test "ssr_div_with_attrs" (b : @bench.T) {
  let node = vdiv([vid("main"), vclass("container")], [vtext("Content")])
  b.bench(name="ssr_div_with_attrs", fn() { b.keep(render_to_string(node)) })
}

// =============================================================================
// Nested Elements
// =============================================================================

test "ssr_nested_3_levels" (b : @bench.T) {
  let node = vdiv([], [
    vdiv([], [
      vdiv([], [vtext("deep")])
    ])
  ])
  b.bench(name="ssr_nested_3_levels", fn() { b.keep(render_to_string(node)) })
}

test "ssr_nested_5_levels" (b : @bench.T) {
  let node = vdiv([], [
    vdiv([], [
      vdiv([], [
        vdiv([], [
          vdiv([], [vtext("very deep")])
        ])
      ])
    ])
  ])
  b.bench(name="ssr_nested_5_levels", fn() { b.keep(render_to_string(node)) })
}

test "ssr_nested_10_levels" (b : @bench.T) {
  let node = vdiv([], [
    vdiv([], [
      vdiv([], [
        vdiv([], [
          vdiv([], [
            vdiv([], [
              vdiv([], [
                vdiv([], [
                  vdiv([], [
                    vdiv([], [vtext("extremely deep")])
                  ])
                ])
              ])
            ])
          ])
        ])
      ])
    ])
  ])
  b.bench(name="ssr_nested_10_levels", fn() { b.keep(render_to_string(node)) })
}

// =============================================================================
// Lists
// =============================================================================

test "ssr_list_10_items" (b : @bench.T) {
  let items : Array[VNode] = []
  for i = 0; i < 10; i = i + 1 {
    items.push(vli([], [vtext("Item " + i.to_string())]))
  }
  let node = vul([], items)
  b.bench(name="ssr_list_10_items", fn() { b.keep(render_to_string(node)) })
}

test "ssr_list_100_items" (b : @bench.T) {
  let items : Array[VNode] = []
  for i = 0; i < 100; i = i + 1 {
    items.push(vli([], [vtext("Item " + i.to_string())]))
  }
  let node = vul([], items)
  b.bench(name="ssr_list_100_items", fn() { b.keep(render_to_string(node)) })
}

test "ssr_list_1000_items" (b : @bench.T) {
  let items : Array[VNode] = []
  for i = 0; i < 1000; i = i + 1 {
    items.push(vli([], [vtext("Item " + i.to_string())]))
  }
  let node = vul([], items)
  b.bench(name="ssr_list_1000_items", fn() { b.keep(render_to_string(node)) })
}

// =============================================================================
// Complex Components
// =============================================================================

test "ssr_card_component" (b : @bench.T) {
  fn card(title : String, content : String) -> VNode {
    vdiv([vclass("card")], [
      vdiv([vclass("card-header")], [vh3([], [vtext(title)])]),
      vdiv([vclass("card-body")], [vp([], [vtext(content)])]),
      vdiv([vclass("card-footer")], [
        vbutton([vclass("btn")], [vtext("Action")])
      ])
    ])
  }
  let node = card("Title", "Some content here")
  b.bench(name="ssr_card_component", fn() { b.keep(render_to_string(node)) })
}

test "ssr_100_cards" (b : @bench.T) {
  fn card(i : Int) -> VNode {
    vdiv([vclass("card")], [
      vdiv([vclass("card-header")], [vh3([], [vtext("Card " + i.to_string())])]),
      vdiv([vclass("card-body")], [vp([], [vtext("Content " + i.to_string())])]),
    ])
  }
  let cards : Array[VNode] = []
  for i = 0; i < 100; i = i + 1 {
    cards.push(card(i))
  }
  let node = vdiv([vclass("cards")], cards)
  b.bench(name="ssr_100_cards", fn() { b.keep(render_to_string(node)) })
}

// =============================================================================
// With Signals (Dynamic Content)
// =============================================================================

test "ssr_dynamic_text" (b : @bench.T) {
  let count = Signal::new(42)
  let node = vtext_dyn(fn() { "Count: " + count.get().to_string() })
  b.bench(name="ssr_dynamic_text", fn() { b.keep(render_to_string(node)) })
}

test "ssr_dynamic_attr" (b : @bench.T) {
  let active = Signal::new(true)
  let node = vdiv([vclass_dyn(fn() { if active.get() { "active" } else { "inactive" } })], [])
  b.bench(name="ssr_dynamic_attr", fn() { b.keep(render_to_string(node)) })
}

test "ssr_100_dynamic_items" (b : @bench.T) {
  let items = Signal::new(100)
  let node = vfor(fn() {
    let count = items.get()
    let result : Array[VNode] = []
    for i = 0; i < count; i = i + 1 {
      result.push(vli([], [vtext("Item " + i.to_string())]))
    }
    result
  })
  b.bench(name="ssr_100_dynamic_items", fn() { b.keep(render_to_string(node)) })
}

// =============================================================================
// With Hydration Markers
// =============================================================================

test "ssr_hydration_simple" (b : @bench.T) {
  let node = vdiv([von_click(fn(_) { () })], [vtext("Click me")])
  b.bench(name="ssr_hydration_simple", fn() { b.keep(render_to_string_with_hydration(node)) })
}

test "ssr_hydration_dynamic_text" (b : @bench.T) {
  let count = Signal::new(0)
  let node = vtext_dyn(fn() { count.get().to_string() })
  b.bench(name="ssr_hydration_dynamic_text", fn() { b.keep(render_to_string_with_hydration(node)) })
}

test "ssr_hydration_100_items" (b : @bench.T) {
  let items : Array[VNode] = []
  for i = 0; i < 100; i = i + 1 {
    items.push(vli([von_click(fn(_) { () })], [vtext("Item " + i.to_string())]))
  }
  let node = vul([], items)
  b.bench(name="ssr_hydration_100_items", fn() { b.keep(render_to_string_with_hydration(node)) })
}

// =============================================================================
// Style Rendering
// =============================================================================

test "ssr_inline_style" (b : @bench.T) {
  let node = vdiv([vstyle([("color", "red"), ("fontSize", "16px"), ("marginTop", "10px")])], [])
  b.bench(name="ssr_inline_style", fn() { b.keep(render_to_string(node)) })
}

// =============================================================================
// Full Page Simulation
// =============================================================================

test "ssr_full_page" (b : @bench.T) {
  fn nav() -> VNode {
    vdiv([vclass("nav")], [
      va([vhref("/")], [vtext("Home")]),
      va([vhref("/about")], [vtext("About")]),
      va([vhref("/contact")], [vtext("Contact")]),
    ])
  }
  fn header(title : String) -> VNode {
    vdiv([vclass("header")], [vh1([], [vtext(title)])])
  }
  fn sidebar() -> VNode {
    vdiv([vclass("sidebar")], [
      vul([], [
        vli([], [vtext("Menu 1")]),
        vli([], [vtext("Menu 2")]),
        vli([], [vtext("Menu 3")]),
      ])
    ])
  }
  fn content() -> VNode {
    vdiv([vclass("content")], [
      vp([], [vtext("Welcome to our site!")]),
      vp([], [vtext("This is some content.")])
    ])
  }
  fn footer() -> VNode {
    vdiv([vclass("footer")], [vtext("© 2025")])
  }

  let page = vdiv([vclass("page")], [
    nav(),
    header("My Website"),
    vdiv([vclass("main")], [sidebar(), content()]),
    footer()
  ])
  b.bench(name="ssr_full_page", fn() { b.keep(render_to_string(page)) })
}

test "ssr_blog_page_10_posts" (b : @bench.T) {
  fn post(i : Int) -> VNode {
    vdiv([vclass("post")], [
      vh2([], [vtext("Post Title " + i.to_string())]),
      vp([vclass("meta")], [vtext("Posted on 2025-01-01")]),
      vp([], [vtext("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")]),
      vdiv([vclass("tags")], [
        vspan([vclass("tag")], [vtext("MoonBit")]),
        vspan([vclass("tag")], [vtext("SSR")]),
      ])
    ])
  }
  let posts : Array[VNode] = []
  for i = 0; i < 10; i = i + 1 {
    posts.push(post(i))
  }
  let page = vdiv([vclass("blog")], [
    vh1([], [vtext("My Blog")]),
    vdiv([vclass("posts")], posts)
  ])
  b.bench(name="ssr_blog_page_10_posts", fn() { b.keep(render_to_string(page)) })
}
