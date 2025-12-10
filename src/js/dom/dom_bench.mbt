///|
///| DOM Rendering Benchmarks
///| Fine-grained reactive DOM updates

// =============================================================================
// VNode to DOM Rendering
// =============================================================================

///|
test "dom_render_simple_text" (b : @bench.T) {
  @global_jsdom.register()
  let node = @ui.vtext("Hello, World!")
  b.bench(name="dom_render_simple_text", fn() {
    b.keep(render_vnode_to_dom(node))
  })
}

///|
test "dom_render_simple_element" (b : @bench.T) {
  @global_jsdom.register()
  let node = @ui.vnode("div", [], [@ui.vtext("Hello")])
  b.bench(name="dom_render_simple_element", fn() {
    b.keep(render_vnode_to_dom(node))
  })
}

///|
test "dom_render_element_with_attrs" (b : @bench.T) {
  @global_jsdom.register()
  let node = @ui.vnode(
    "div",
    [("class", @ui.attr_static("container")), ("id", @ui.attr_static("main"))],
    [@ui.vtext("Content")],
  )
  b.bench(name="dom_render_element_with_attrs", fn() {
    b.keep(render_vnode_to_dom(node))
  })
}

// =============================================================================
// Nested Elements
// =============================================================================

///|
test "dom_render_nested_3" (b : @bench.T) {
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
  b.bench(name="dom_render_nested_3", fn() { b.keep(render_vnode_to_dom(node)) })
}

///|
test "dom_render_nested_5" (b : @bench.T) {
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
  b.bench(name="dom_render_nested_5", fn() { b.keep(render_vnode_to_dom(node)) })
}

// =============================================================================
// List Rendering
// =============================================================================

///|
fn create_list_node(count : Int) -> @ui.Node {
  let items : Array[@ui.Node] = []
  for i = 0; i < count; i = i + 1 {
    items.push(@ui.vnode("li", [], [@ui.vtext("Item " + i.to_string())]))
  }
  @ui.vnode("ul", [], items)
}

///|
test "dom_render_list_10" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_list_node(10)
  b.bench(name="dom_render_list_10", fn() { b.keep(render_vnode_to_dom(node)) })
}

///|
test "dom_render_list_100" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_list_node(100)
  b.bench(name="dom_render_list_100", fn() { b.keep(render_vnode_to_dom(node)) })
}

// =============================================================================
// Reactive Updates (Fine-grained)
// =============================================================================

///|
test "dom_reactive_text_update" (b : @bench.T) {
  @global_jsdom.register()
  let count = @ui.signal(0)
  let node = @ui.text_dyn(fn() { count.get().to_string() })
  let _ = render_vnode_to_dom(node)
  let mut i = 0
  b.bench(name="dom_reactive_text_update", fn() {
    i = i + 1
    count.set(i)
  })
}

///|
test "dom_reactive_attr_update" (b : @bench.T) {
  @global_jsdom.register()
  let active = @ui.signal(false)
  let node = @ui.vnode(
    "button",
    [("class", @ui.attr_dynamic(fn() { if active.get() { "on" } else { "off" } }))],
    [@ui.vtext("Toggle")],
  )
  let _ = render_vnode_to_dom(node)
  b.bench(name="dom_reactive_attr_update", fn() {
    active.update(fn(b) { not(b) })
  })
}

///|
test "dom_reactive_style_update" (b : @bench.T) {
  @global_jsdom.register()
  let width = @ui.signal(100)
  let node = @ui.vnode(
    "div",
    [
      (
        "style",
        @ui.attr_dynamic_style(fn() { [("width", width.get().to_string() + "px")] }),
      ),
    ],
    [],
  )
  let _ = render_vnode_to_dom(node)
  let mut i = 100
  b.bench(name="dom_reactive_style_update", fn() {
    i = i + 1
    width.set(i)
  })
}

// =============================================================================
// Show/Hide Toggle
// =============================================================================

///|
test "dom_show_toggle" (b : @bench.T) {
  @global_jsdom.register()
  let visible = @ui.signal(true)
  let node = @ui.vshow(
    fn() { visible.get() },
    fn() { @ui.vnode("div", [], [@ui.vtext("Content")]) },
  )
  let doc = @js_dom.document()
  let container = doc.createElement("div")
  let dom = render_vnode_to_dom(node)
  container.appendChild(dom) |> ignore
  b.bench(name="dom_show_toggle", fn() {
    visible.update(fn(v) { not(v) })
  })
}

// =============================================================================
// For List Updates
// =============================================================================

///|
test "dom_for_list_update" (b : @bench.T) {
  @global_jsdom.register()
  let items_sig = @ui.signal(["a", "b", "c"])
  let node = @ui.vfor(fn() {
    items_sig.get().map(fn(item) { @ui.vnode("li", [], [@ui.vtext(item)]) })
  })
  let doc = @js_dom.document()
  let container = doc.createElement("div")
  let dom = render_vnode_to_dom(node)
  container.appendChild(dom) |> ignore
  let mut i = 0
  b.bench(name="dom_for_list_update", fn() {
    i = i + 1
    items_sig.set(["x" + i.to_string(), "y" + i.to_string(), "z" + i.to_string()])
  })
}

// =============================================================================
// Complex Component Update
// =============================================================================

///|
test "dom_component_counter" (b : @bench.T) {
  @global_jsdom.register()
  let count = @ui.signal(0)
  let doubled = @ui.memo(fn() { count.get() * 2 })
  let node = @ui.vnode(
    "div",
    [],
    [
      @ui.vnode(
        "span",
        [("id", @ui.attr_static("count"))],
        [@ui.text_dyn(fn() { count.get().to_string() })],
      ),
      @ui.vnode(
        "span",
        [("id", @ui.attr_static("doubled"))],
        [@ui.text_dyn(fn() { doubled().to_string() })],
      ),
    ],
  )
  let _ = render_vnode_to_dom(node)
  let mut i = 0
  b.bench(name="dom_component_counter", fn() {
    i = i + 1
    count.set(i)
  })
}

///|
test "dom_batched_updates" (b : @bench.T) {
  @global_jsdom.register()
  let a = @ui.signal(0)
  let b_ = @ui.signal(0)
  let c = @ui.signal(0)
  let node = @ui.vnode(
    "div",
    [],
    [
      @ui.text_dyn(fn() { a.get().to_string() }),
      @ui.text_dyn(fn() { b_.get().to_string() }),
      @ui.text_dyn(fn() { c.get().to_string() }),
    ],
  )
  let _ = render_vnode_to_dom(node)
  let mut i = 0
  b.bench(name="dom_batched_3_updates", fn() {
    i = i + 1
    @ui.batch(fn() {
      a.set(i)
      b_.set(i)
      c.set(i)
    })
  })
}
