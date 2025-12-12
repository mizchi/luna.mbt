///|

///| DOM Rendering Benchmarks

///| Fine-grained reactive DOM updates

// =============================================================================
// VNode to DOM Rendering
// =============================================================================

///|
test "dom_render_simple_text" (b : @bench.T) {
  @global_jsdom.register()
  let node = @kaguya.vtext("Hello, World!")
  b.bench(name="dom_render_simple_text", fn() {
    b.keep(@dom.render_vnode_to_dom(node))
  })
}

///|
test "dom_render_simple_element" (b : @bench.T) {
  @global_jsdom.register()
  let node = @kaguya.h("div", [], [@kaguya.vtext("Hello")])
  b.bench(name="dom_render_simple_element", fn() {
    b.keep(@dom.render_vnode_to_dom(node))
  })
}

///|
test "dom_render_element_with_attrs" (b : @bench.T) {
  @global_jsdom.register()
  let node = @kaguya.h(
    "div",
    [
      ("class", @kaguya.attr_static("container")),
      ("id", @kaguya.attr_static("main")),
    ],
    [@kaguya.vtext("Content")],
  )
  b.bench(name="dom_render_element_with_attrs", fn() {
    b.keep(@dom.render_vnode_to_dom(node))
  })
}

// =============================================================================
// Nested Elements
// =============================================================================

///|
test "dom_render_nested_3" (b : @bench.T) {
  @global_jsdom.register()
  let node = @kaguya.h("div", [], [
    @kaguya.h("section", [], [@kaguya.h("p", [], [@kaguya.vtext("Nested")])]),
  ])
  b.bench(name="dom_render_nested_3", fn() {
    b.keep(@dom.render_vnode_to_dom(node))
  })
}

///|
test "dom_render_nested_5" (b : @bench.T) {
  @global_jsdom.register()
  let node = @kaguya.h("div", [], [
    @kaguya.h("section", [], [
      @kaguya.h("article", [], [
        @kaguya.h("div", [], [@kaguya.h("span", [], [@kaguya.vtext("Deep")])]),
      ]),
    ]),
  ])
  b.bench(name="dom_render_nested_5", fn() {
    b.keep(@dom.render_vnode_to_dom(node))
  })
}

// =============================================================================
// List Rendering
// =============================================================================

///|
fn create_list_node(count : Int) -> @kaguya.Node[@core.Any] {
  let items : Array[@kaguya.Node[@core.Any]] = []
  for i = 0; i < count; i = i + 1 {
    items.push(@kaguya.h("li", [], [@kaguya.vtext("Item " + i.to_string())]))
  }
  @kaguya.h("ul", [], items)
}

///|
test "dom_render_list_10" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_list_node(10)
  b.bench(name="dom_render_list_10", fn() {
    b.keep(@dom.render_vnode_to_dom(node))
  })
}

///|
test "dom_render_list_100" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_list_node(100)
  b.bench(name="dom_render_list_100", fn() {
    b.keep(@dom.render_vnode_to_dom(node))
  })
}

// =============================================================================
// Reactive Updates (Fine-grained)
// =============================================================================

///|
test "dom_reactive_text_update" (b : @bench.T) {
  @global_jsdom.register()
  let count = @signal.signal(0)
  let node = @kaguya.text_dyn(fn() { count.get().to_string() })
  let _ = @dom.render_vnode_to_dom(node)
  let mut i = 0
  b.bench(name="dom_reactive_text_update", fn() {
    i = i + 1
    count.set(i)
  })
}

///|
test "dom_reactive_attr_update" (b : @bench.T) {
  @global_jsdom.register()
  let active = @signal.signal(false)
  let node = @kaguya.h(
    "button",
    [
      (
        "class",
        @kaguya.attr_dynamic(fn() { if active.get() { "on" } else { "off" } }),
      ),
    ],
    [@kaguya.vtext("Toggle")],
  )
  let _ = @dom.render_vnode_to_dom(node)
  b.bench(name="dom_reactive_attr_update", fn() {
    active.update(fn(b) { not(b) })
  })
}

///|
test "dom_reactive_style_update" (b : @bench.T) {
  @global_jsdom.register()
  let width = @signal.signal(100)
  let node = @kaguya.h(
    "div",
    [
      (
        "style",
        @kaguya.attr_dynamic_style(fn() {
          "width: " + width.get().to_string() + "px"
        }),
      ),
    ],
    [],
  )
  let _ = @dom.render_vnode_to_dom(node)
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
  let visible = @signal.signal(true)
  let node = @kaguya.vshow(fn() { visible.get() }, fn() {
    @kaguya.h("div", [], [@kaguya.vtext("Content")])
  })
  let doc = @js_dom.document()
  let container = doc.createElement("div")
  let dom = @dom.render_vnode_to_dom(node)
  container.appendChild(dom) |> ignore
  b.bench(name="dom_show_toggle", fn() { visible.update(fn(v) { not(v) }) })
}

// =============================================================================
// For List Updates
// =============================================================================

///|
test "dom_for_list_update" (b : @bench.T) {
  @global_jsdom.register()
  let items_sig = @signal.signal(["a", "b", "c"])
  let node = @kaguya.vfor(fn() {
    items_sig.get().map(fn(item) { @kaguya.h("li", [], [@kaguya.vtext(item)]) })
  })
  let doc = @js_dom.document()
  let container = doc.createElement("div")
  let dom = @dom.render_vnode_to_dom(node)
  container.appendChild(dom) |> ignore
  let mut i = 0
  b.bench(name="dom_for_list_update", fn() {
    i = i + 1
    items_sig.set([
      "x" + i.to_string(),
      "y" + i.to_string(),
      "z" + i.to_string(),
    ])
  })
}

// =============================================================================
// Complex Component Update
// =============================================================================

///|
test "dom_component_counter" (b : @bench.T) {
  @global_jsdom.register()
  let count = @signal.signal(0)
  let doubled = @signal.memo(fn() { count.get() * 2 })
  let node = @kaguya.h("div", [], [
    @kaguya.h("span", [("id", @kaguya.attr_static("count"))], [
      @kaguya.text_dyn(fn() { count.get().to_string() }),
    ]),
    @kaguya.h("span", [("id", @kaguya.attr_static("doubled"))], [
      @kaguya.text_dyn(fn() { doubled().to_string() }),
    ]),
  ])
  let _ = @dom.render_vnode_to_dom(node)
  let mut i = 0
  b.bench(name="dom_component_counter", fn() {
    i = i + 1
    count.set(i)
  })
}

///|
test "dom_batched_updates" (b : @bench.T) {
  @global_jsdom.register()
  let a = @signal.signal(0)
  let b_ = @signal.signal(0)
  let c = @signal.signal(0)
  let node = @kaguya.h("div", [], [
    @kaguya.text_dyn(fn() { a.get().to_string() }),
    @kaguya.text_dyn(fn() { b_.get().to_string() }),
    @kaguya.text_dyn(fn() { c.get().to_string() }),
  ])
  let _ = @dom.render_vnode_to_dom(node)
  let mut i = 0
  b.bench(name="dom_batched_3_updates", fn() {
    i = i + 1
    @signal.batch(fn() {
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
  let title = @signal.signal("Title")
  let node = @kaguya.h("div", [], [
    @kaguya.h("h1", [], [@kaguya.text_dyn(fn() { title.get() })]),
    @kaguya.h("p", [], [@kaguya.vtext("Static content 1")]),
    @kaguya.h("p", [], [@kaguya.vtext("Static content 2")]),
    @kaguya.h("p", [], [@kaguya.vtext("Static content 3")]),
  ])
  let _ = @dom.render_vnode_to_dom(node)
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
  let a = @signal.signal("A")
  let b_sig = @signal.signal("B")
  let c = @signal.signal("C")
  let node = @kaguya.h("div", [], [
    @kaguya.h("span", [], [@kaguya.text_dyn(fn() { a.get() })]),
    @kaguya.h("span", [], [@kaguya.text_dyn(fn() { b_sig.get() })]),
    @kaguya.h("span", [], [@kaguya.text_dyn(fn() { c.get() })]),
  ])
  let _ = @dom.render_vnode_to_dom(node)
  let mut i = 0
  b.bench(name="dom_shallow_update_siblings", fn() {
    i = i + 1
    @signal.batch(fn() {
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
  let deep_value = @signal.signal("Deep")
  let node = @kaguya.h("div", [], [
    @kaguya.h("section", [], [
      @kaguya.h("article", [], [
        @kaguya.h("span", [], [@kaguya.text_dyn(fn() { deep_value.get() })]),
      ]),
    ]),
  ])
  let _ = @dom.render_vnode_to_dom(node)
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
  let deep_value = @signal.signal("Very Deep")
  let node = @kaguya.h("div", [], [
    @kaguya.h("section", [], [
      @kaguya.h("article", [], [
        @kaguya.h("div", [], [
          @kaguya.h("p", [], [@kaguya.text_dyn(fn() { deep_value.get() })]),
        ]),
      ]),
    ]),
  ])
  let _ = @dom.render_vnode_to_dom(node)
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
  let level1 = @signal.signal("L1")
  let level2 = @signal.signal("L2")
  let level3 = @signal.signal("L3")
  let node = @kaguya.h("div", [], [
    @kaguya.text_dyn(fn() { level1.get() }),
    @kaguya.h("section", [], [
      @kaguya.text_dyn(fn() { level2.get() }),
      @kaguya.h("article", [], [@kaguya.text_dyn(fn() { level3.get() })]),
    ]),
  ])
  let _ = @dom.render_vnode_to_dom(node)
  let mut i = 0
  b.bench(name="dom_deep_update_multi_depth", fn() {
    i = i + 1
    @signal.batch(fn() {
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
  let signals : Array[@signal.Signal[Int]] = []
  let children : Array[@kaguya.Node[@core.Any]] = []
  for i = 0; i < 10; i = i + 1 {
    let sig = @signal.signal(i)
    signals.push(sig)
    children.push(
      @kaguya.h("span", [], [@kaguya.text_dyn(fn() { sig.get().to_string() })]),
    )
  }
  let node = @kaguya.h("div", [], children)
  let _ = @dom.render_vnode_to_dom(node)
  let mut iter = 0
  b.bench(name="dom_wide_shallow_10", fn() {
    iter = iter + 1
    @signal.batch(fn() {
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
  let signals : Array[@signal.Signal[Int]] = []
  let children : Array[@kaguya.Node[@core.Any]] = []
  for i = 0; i < 50; i = i + 1 {
    let sig = @signal.signal(i)
    signals.push(sig)
    children.push(
      @kaguya.h("span", [], [@kaguya.text_dyn(fn() { sig.get().to_string() })]),
    )
  }
  let node = @kaguya.h("div", [], children)
  let _ = @dom.render_vnode_to_dom(node)
  let mut iter = 0
  b.bench(name="dom_wide_shallow_50", fn() {
    iter = iter + 1
    @signal.batch(fn() {
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
  let base = @signal.signal(0)
  let derived = @signal.memo(fn() { base.get() * 2 })
  let node = @kaguya.h("div", [], [
    @kaguya.h("span", [], [@kaguya.text_dyn(fn() { base.get().to_string() })]),
    @kaguya.h("span", [], [@kaguya.text_dyn(fn() { derived().to_string() })]),
  ])
  let _ = @dom.render_vnode_to_dom(node)
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
  let base = @signal.signal(0)
  let derived1 = @signal.memo(fn() { base.get() + 1 })
  let derived2 = @signal.memo(fn() { derived1() * 2 })
  let derived3 = @signal.memo(fn() { derived2() + 10 })
  let node = @kaguya.h("div", [], [
    @kaguya.h("span", [], [@kaguya.text_dyn(fn() { base.get().to_string() })]),
    @kaguya.h("span", [], [@kaguya.text_dyn(fn() { derived1().to_string() })]),
    @kaguya.h("span", [], [@kaguya.text_dyn(fn() { derived2().to_string() })]),
    @kaguya.h("span", [], [@kaguya.text_dyn(fn() { derived3().to_string() })]),
  ])
  let _ = @dom.render_vnode_to_dom(node)
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
  let show_a = @signal.signal(true)
  let node = @kaguya.h("div", [], [
    @kaguya.vshow(fn() { show_a.get() }, fn() { @kaguya.vtext("A") }),
    @kaguya.vshow(fn() { not(show_a.get()) }, fn() { @kaguya.vtext("B") }),
  ])
  let doc = @js_dom.document()
  let container = doc.createElement("div")
  let dom = @dom.render_vnode_to_dom(node)
  container.appendChild(dom) |> ignore
  b.bench(name="dom_conditional_shallow", fn() {
    show_a.update(fn(v) { not(v) })
  })
}

///|
/// Conditional rendering: deep nested show
test "dom_conditional_deep" (b : @bench.T) {
  @global_jsdom.register()
  let visible = @signal.signal(true)
  let node = @kaguya.h("div", [], [
    @kaguya.h("section", [], [
      @kaguya.h("article", [], [
        @kaguya.vshow(fn() { visible.get() }, fn() {
          @kaguya.h("div", [], [
            @kaguya.h("p", [], [@kaguya.vtext("Deep conditional content")]),
          ])
        }),
      ]),
    ]),
  ])
  let doc = @js_dom.document()
  let container = doc.createElement("div")
  let dom = @dom.render_vnode_to_dom(node)
  container.appendChild(dom) |> ignore
  b.bench(name="dom_conditional_deep", fn() { visible.update(fn(v) { not(v) }) })
}
