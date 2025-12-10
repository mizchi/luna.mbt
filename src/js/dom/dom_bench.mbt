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

// =============================================================================
// Shallow vs Deep Updates
// =============================================================================

///|
/// Shallow update: single signal at root level
test "dom_shallow_update_root" (b : @bench.T) {
  @global_jsdom.register()
  let title = @ui.signal("Title")
  let node = @ui.vnode(
    "div",
    [],
    [
      @ui.vnode("h1", [], [@ui.text_dyn(fn() { title.get() })]),
      @ui.vnode("p", [], [@ui.vtext("Static content 1")]),
      @ui.vnode("p", [], [@ui.vtext("Static content 2")]),
      @ui.vnode("p", [], [@ui.vtext("Static content 3")]),
    ],
  )
  let _ = render_vnode_to_dom(node)
  let mut i = 0
  b.bench(name="dom_shallow_update_root", fn() {
    i = i + 1
    title.set("Title " + i.to_string())
  })
}

///|
/// Shallow update: signal in sibling elements (3 updates)
test "dom_shallow_update_siblings" (b : @bench.T) {
  @global_jsdom.register()
  let a = @ui.signal("A")
  let b_sig = @ui.signal("B")
  let c = @ui.signal("C")
  let node = @ui.vnode(
    "div",
    [],
    [
      @ui.vnode("span", [], [@ui.text_dyn(fn() { a.get() })]),
      @ui.vnode("span", [], [@ui.text_dyn(fn() { b_sig.get() })]),
      @ui.vnode("span", [], [@ui.text_dyn(fn() { c.get() })]),
    ],
  )
  let _ = render_vnode_to_dom(node)
  let mut i = 0
  b.bench(name="dom_shallow_update_siblings", fn() {
    i = i + 1
    @ui.batch(fn() {
      a.set("A" + i.to_string())
      b_sig.set("B" + i.to_string())
      c.set("C" + i.to_string())
    })
  })
}

///|
/// Deep update: signal nested 3 levels deep
test "dom_deep_update_3_levels" (b : @bench.T) {
  @global_jsdom.register()
  let deep_value = @ui.signal("Deep")
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
            [@ui.vnode("span", [], [@ui.text_dyn(fn() { deep_value.get() })])],
          ),
        ],
      ),
    ],
  )
  let _ = render_vnode_to_dom(node)
  let mut i = 0
  b.bench(name="dom_deep_update_3_levels", fn() {
    i = i + 1
    deep_value.set("Deep " + i.to_string())
  })
}

///|
/// Deep update: signal nested 5 levels deep
test "dom_deep_update_5_levels" (b : @bench.T) {
  @global_jsdom.register()
  let deep_value = @ui.signal("Very Deep")
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
                [
                  @ui.vnode(
                    "p",
                    [],
                    [@ui.text_dyn(fn() { deep_value.get() })],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  )
  let _ = render_vnode_to_dom(node)
  let mut i = 0
  b.bench(name="dom_deep_update_5_levels", fn() {
    i = i + 1
    deep_value.set("Very Deep " + i.to_string())
  })
}

///|
/// Deep update: multiple signals at different depths
test "dom_deep_update_multi_depth" (b : @bench.T) {
  @global_jsdom.register()
  let level1 = @ui.signal("L1")
  let level2 = @ui.signal("L2")
  let level3 = @ui.signal("L3")
  let node = @ui.vnode(
    "div",
    [],
    [
      @ui.text_dyn(fn() { level1.get() }),
      @ui.vnode(
        "section",
        [],
        [
          @ui.text_dyn(fn() { level2.get() }),
          @ui.vnode(
            "article",
            [],
            [@ui.text_dyn(fn() { level3.get() })],
          ),
        ],
      ),
    ],
  )
  let _ = render_vnode_to_dom(node)
  let mut i = 0
  b.bench(name="dom_deep_update_multi_depth", fn() {
    i = i + 1
    @ui.batch(fn() {
      level1.set("L1-" + i.to_string())
      level2.set("L2-" + i.to_string())
      level3.set("L3-" + i.to_string())
    })
  })
}

///|
/// Wide shallow update: many siblings with signals
test "dom_wide_shallow_10" (b : @bench.T) {
  @global_jsdom.register()
  let signals : Array[@ui.Signal[Int]] = []
  let children : Array[@ui.Node] = []
  for i = 0; i < 10; i = i + 1 {
    let sig = @ui.signal(i)
    signals.push(sig)
    children.push(@ui.vnode("span", [], [@ui.text_dyn(fn() { sig.get().to_string() })]))
  }
  let node = @ui.vnode("div", [], children)
  let _ = render_vnode_to_dom(node)
  let mut iter = 0
  b.bench(name="dom_wide_shallow_10", fn() {
    iter = iter + 1
    @ui.batch(fn() {
      for i = 0; i < signals.length(); i = i + 1 {
        signals[i].set(iter + i)
      }
    })
  })
}

///|
/// Wide shallow update: many siblings (50)
test "dom_wide_shallow_50" (b : @bench.T) {
  @global_jsdom.register()
  let signals : Array[@ui.Signal[Int]] = []
  let children : Array[@ui.Node] = []
  for i = 0; i < 50; i = i + 1 {
    let sig = @ui.signal(i)
    signals.push(sig)
    children.push(@ui.vnode("span", [], [@ui.text_dyn(fn() { sig.get().to_string() })]))
  }
  let node = @ui.vnode("div", [], children)
  let _ = render_vnode_to_dom(node)
  let mut iter = 0
  b.bench(name="dom_wide_shallow_50", fn() {
    iter = iter + 1
    @ui.batch(fn() {
      for i = 0; i < signals.length(); i = i + 1 {
        signals[i].set(iter + i)
      }
    })
  })
}

///|
/// Derived value chain: shallow memo dependency
test "dom_derived_shallow" (b : @bench.T) {
  @global_jsdom.register()
  let base = @ui.signal(0)
  let derived = @ui.memo(fn() { base.get() * 2 })
  let node = @ui.vnode(
    "div",
    [],
    [
      @ui.vnode("span", [], [@ui.text_dyn(fn() { base.get().to_string() })]),
      @ui.vnode("span", [], [@ui.text_dyn(fn() { derived().to_string() })]),
    ],
  )
  let _ = render_vnode_to_dom(node)
  let mut i = 0
  b.bench(name="dom_derived_shallow", fn() {
    i = i + 1
    base.set(i)
  })
}

///|
/// Derived value chain: deep memo chain (3 levels)
test "dom_derived_deep_chain" (b : @bench.T) {
  @global_jsdom.register()
  let base = @ui.signal(0)
  let derived1 = @ui.memo(fn() { base.get() + 1 })
  let derived2 = @ui.memo(fn() { derived1() * 2 })
  let derived3 = @ui.memo(fn() { derived2() + 10 })
  let node = @ui.vnode(
    "div",
    [],
    [
      @ui.vnode("span", [], [@ui.text_dyn(fn() { base.get().to_string() })]),
      @ui.vnode("span", [], [@ui.text_dyn(fn() { derived1().to_string() })]),
      @ui.vnode("span", [], [@ui.text_dyn(fn() { derived2().to_string() })]),
      @ui.vnode("span", [], [@ui.text_dyn(fn() { derived3().to_string() })]),
    ],
  )
  let _ = render_vnode_to_dom(node)
  let mut i = 0
  b.bench(name="dom_derived_deep_chain", fn() {
    i = i + 1
    base.set(i)
  })
}

///|
/// Conditional rendering: shallow show toggle
test "dom_conditional_shallow" (b : @bench.T) {
  @global_jsdom.register()
  let show_a = @ui.signal(true)
  let node = @ui.vnode(
    "div",
    [],
    [
      @ui.vshow(fn() { show_a.get() }, fn() { @ui.vtext("A") }),
      @ui.vshow(fn() { not(show_a.get()) }, fn() { @ui.vtext("B") }),
    ],
  )
  let doc = @js_dom.document()
  let container = doc.createElement("div")
  let dom = render_vnode_to_dom(node)
  container.appendChild(dom) |> ignore
  b.bench(name="dom_conditional_shallow", fn() {
    show_a.update(fn(v) { not(v) })
  })
}

///|
/// Conditional rendering: deep nested show
test "dom_conditional_deep" (b : @bench.T) {
  @global_jsdom.register()
  let visible = @ui.signal(true)
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
              @ui.vshow(
                fn() { visible.get() },
                fn() {
                  @ui.vnode(
                    "div",
                    [],
                    [@ui.vnode("p", [], [@ui.vtext("Deep conditional content")])],
                  )
                },
              ),
            ],
          ),
        ],
      ),
    ],
  )
  let doc = @js_dom.document()
  let container = doc.createElement("div")
  let dom = render_vnode_to_dom(node)
  container.appendChild(dom) |> ignore
  b.bench(name="dom_conditional_deep", fn() {
    visible.update(fn(v) { not(v) })
  })
}
