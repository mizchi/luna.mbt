///| UI Library Benchmarks

///|

///| This file contains performance benchmarks for the UI library,

///| measuring VNode creation, Props manipulation, and Context API operations.

// =============================================================================
// VNode Creation Benchmarks
// =============================================================================

///|
/// Benchmark: Create simple text node
test "bench: create text node" (b : @bench.T) {
  b.bench(fn() { b.keep((text("Hello, World!") : JSVNode)) })
}

///|
/// Benchmark: Create simple element (div with no props, no children)
test "bench: create empty div" (b : @bench.T) {
  b.bench(fn() { b.keep((div([], []) : JSVNode)) })
}

///|
/// Benchmark: Create element with single text child
test "bench: create div with text" (b : @bench.T) {
  b.bench(fn() { b.keep((div([], [text("Hello")]) : JSVNode)) })
}

///|
/// Benchmark: Create element with multiple text children
test "bench: create div with 3 text children" (b : @bench.T) {
  b.bench(fn() {
    b.keep((div([], [text("Hello"), text(", "), text("World!")]) : JSVNode))
  })
}

///|
/// Benchmark: Create nested elements (2 levels)
test "bench: create nested elements (2 levels)" (b : @bench.T) {
  b.bench(fn() { b.keep((div([], [div([], [text("Nested")])]) : JSVNode)) })
}

///|
/// Benchmark: Create nested elements (3 levels)
test "bench: create nested elements (3 levels)" (b : @bench.T) {
  b.bench(fn() {
    b.keep((div([], [div([], [div([], [text("Deep nested")])])]) : JSVNode))
  })
}

///|
/// Benchmark: Create complex component tree (realistic)
test "bench: create complex component tree" (b : @bench.T) {
  b.bench(fn() {
    b.keep(
      (
        div([class_name("app")], [
          // Header
          el("header", [], [
            el("nav", [], [
              el("ul", [], [
                el("li", [], [el("a", [], [text("Home")])]),
                el("li", [], [el("a", [], [text("About")])]),
                el("li", [], [el("a", [], [text("Contact")])]),
              ]),
            ]),
          ]),
          // Main content
          el("main", [], [
            el("h1", [], [text("Welcome")]),
            el("p", [], [
              text("This is a complex component tree for benchmarking."),
            ]),
          ]),
        ]) : JSVNode),
    )
  })
}

///|
/// Benchmark: Create fragment with multiple children
test "bench: create fragment with 5 children" (b : @bench.T) {
  b.bench(fn() {
    b.keep(
      (
        fragment([
          div([], [text("Child 1")]),
          div([], [text("Child 2")]),
          div([], [text("Child 3")]),
          div([], [text("Child 4")]),
          div([], [text("Child 5")]),
        ]) : JSVNode),
    )
  })
}

///|
/// Benchmark: Create list of 10 items (typical list rendering)
test "bench: create list of 10 items" (b : @bench.T) {
  b.bench(fn() {
    b.keep(
      (
        el("ul", [], [
          el("li", [], [text("Item 1")]),
          el("li", [], [text("Item 2")]),
          el("li", [], [text("Item 3")]),
          el("li", [], [text("Item 4")]),
          el("li", [], [text("Item 5")]),
          el("li", [], [text("Item 6")]),
          el("li", [], [text("Item 7")]),
          el("li", [], [text("Item 8")]),
          el("li", [], [text("Item 9")]),
          el("li", [], [text("Item 10")]),
        ]) : JSVNode),
    )
  })
}

// =============================================================================
// Props Creation Benchmarks
// =============================================================================

///|
/// Benchmark: Create empty props
test "bench: create empty props" (b : @bench.T) {
  b.bench(fn() { b.keep(([] : JSProps)) })
}

///|
/// Benchmark: Create props with 1 property
test "bench: create props with 1 property" (b : @bench.T) {
  b.bench(fn() { b.keep(([class_name("button")] : JSProps)) })
}

///|
/// Benchmark: Create props with 3 properties
test "bench: create props with 3 properties" (b : @bench.T) {
  b.bench(fn() {
    b.keep(([class_name("button"), id("submit"), disabled(false)] : JSProps))
  })
}

///|
/// Benchmark: Create props with 5 properties
test "bench: create props with 5 properties" (b : @bench.T) {
  b.bench(fn() {
    b.keep(
      (
        [
          class_name("button"),
          id("submit"),
          disabled(false),
          type_("submit"),
          attr("aria-label", "Submit form"),
        ] : JSProps),
    )
  })
}

///|
/// Benchmark: Create props with 10 properties
test "bench: create props with 10 properties" (b : @bench.T) {
  b.bench(fn() {
    b.keep(
      (
        [
          class_name("button"),
          id("submit"),
          disabled(false),
          type_("submit"),
          attr("aria-label", "Submit form"),
          data_("data-action", "submit"),
          data_("data-test-id", "submit-btn"),
          attr("role", "button"),
          tab_index(0),
          name("submit-button"),
        ] : JSProps),
    )
  })
}

///|
/// Benchmark: Create props with event handler
test "bench: create props with onClick" (b : @bench.T) {
  b.bench(fn() { b.keep(([on_click(fn(_evt : @core.Any) { () })] : JSProps)) })
}

///|
/// Benchmark: Create props with multiple event handlers
test "bench: create props with 3 event handlers" (b : @bench.T) {
  b.bench(fn() {
    b.keep(
      (
        [
          on_click(fn(_evt : @core.Any) { () }),
          on_mouse_enter(fn(_evt : @core.Any) { () }),
          on_mouse_leave(fn(_evt : @core.Any) { () }),
        ] : JSProps),
    )
  })
}

// =============================================================================
// Context API Benchmarks
// =============================================================================

///|
/// Benchmark: Create context
test "bench: create context" (b : @bench.T) {
  b.bench(fn() { b.keep(create_context("default")) })
}

///|
/// Benchmark: Get context (default value, no set)
test "bench: get context (default value)" (b : @bench.T) {
  let ctx = create_context("default")
  b.bench(fn() { b.keep(get_context(ctx)) })
}

///|
/// Benchmark: Set context
test "bench: set context" (b : @bench.T) {
  let ctx = create_context("default")
  b.bench(fn() { set_context(ctx, "new value") })
}

///|
/// Benchmark: Get context (after set)
test "bench: get context (set value)" (b : @bench.T) {
  let ctx = create_context("default")
  set_context(ctx, "value")
  b.bench(fn() { b.keep(get_context(ctx)) })
}

///|
/// Benchmark: Clear context
test "bench: clear context" (b : @bench.T) {
  let ctx = create_context("default")
  set_context(ctx, "value")
  b.bench(fn() { clear_context(ctx) })
}

///|
/// Benchmark: Multiple context operations (realistic workflow)
test "bench: context workflow (create + set + get)" (b : @bench.T) {
  b.bench(fn() {
    let ctx = create_context("default")
    set_context(ctx, "new value")
    b.keep(get_context(ctx))
  })
}

///|
/// Benchmark: Multiple independent contexts
test "bench: 5 independent contexts" (b : @bench.T) {
  b.bench(fn() {
    let ctx1 = create_context("value1")
    let ctx2 = create_context(42)
    let ctx3 = create_context(true)
    let ctx4 = create_context("value4")
    let ctx5 = create_context(100)
    set_context(ctx1, "new1")
    set_context(ctx2, 84)
    set_context(ctx3, false)
    set_context(ctx4, "new4")
    set_context(ctx5, 200)
    b.keep((get_context(ctx1), get_context(ctx2), get_context(ctx3)))
  })
}

// =============================================================================
// Combined Benchmarks (Realistic Usage)
// =============================================================================

///|
/// Benchmark: Create element with props and children (realistic)
test "bench: realistic button component" (b : @bench.T) {
  b.bench(fn() {
    b.keep(
      (
        button(
          [
            class_name("btn btn-primary"),
            id("submit-btn"),
            on_click(fn(_evt : @core.Any) { () }),
          ],
          [text("Submit")],
        ) : JSVNode),
    )
  })
}

///|
/// Benchmark: Create form with multiple inputs
test "bench: realistic form component" (b : @bench.T) {
  b.bench(fn() {
    b.keep(
      (
        form([on_submit(fn(_evt : @core.Any) { () })], [
          div([], [
            label([], [text("Name:")]),
            input([type_("text"), id("name")]),
          ]),
          div([], [
            label([], [text("Email:")]),
            input([type_("email"), id("email")]),
          ]),
          button([type_("submit")], [text("Submit")]),
        ]) : JSVNode),
    )
  })
}

///|
/// Benchmark: Create card component (realistic)
test "bench: realistic card component" (b : @bench.T) {
  b.bench(fn() {
    b.keep(
      (
        div([class_name("card")], [
          div([class_name("card-header")], [h3([], [text("Card Title")])]),
          div([class_name("card-body")], [
            p([], [text("This is the card content with some text.")]),
          ]),
          div([class_name("card-footer")], [
            button([class_name("btn btn-primary")], [text("Action")]),
            button([class_name("btn btn-secondary")], [text("Cancel")]),
          ]),
        ]) : JSVNode),
    )
  })
}

// =============================================================================
// Large Scale Benchmarks
// =============================================================================

///|
/// Benchmark: Create list of 100 items
test "bench: create list of 100 items" (b : @bench.T) {
  b.bench(name="vdom_100_items", fn() {
    let items : Array[JSVNode] = []
    for i = 0; i < 100; i = i + 1 {
      items.push(el("li", [], [text("Item " + i.to_string())]))
    }
    b.keep((el("ul", [], items) : JSVNode))
  })
}

///|
/// Benchmark: Create list of 1000 items
test "bench: create list of 1000 items" (b : @bench.T) {
  b.bench(name="vdom_1000_items", fn() {
    let items : Array[JSVNode] = []
    for i = 0; i < 1000; i = i + 1 {
      items.push(el("li", [], [text("Item " + i.to_string())]))
    }
    b.keep((el("ul", [], items) : JSVNode))
  })
}

///|
/// Benchmark: Create nested tree 10 levels deep
test "bench: create nested tree 10 levels" (b : @bench.T) {
  b.bench(name="vdom_nested_10_levels", fn() {
    b.keep(
      (
        div([], [
          div([], [
            div([], [
              div([], [
                div([], [
                  div([], [
                    div([], [div([], [div([], [div([], [text("Deep")])])])]),
                  ]),
                ]),
              ]),
            ]),
          ]),
        ]) : JSVNode),
    )
  })
}

///|
/// Benchmark: Create 100 divs with props
test "bench: create 100 divs with props" (b : @bench.T) {
  b.bench(name="vdom_100_divs_with_props", fn() {
    let items : Array[JSVNode] = []
    for i = 0; i < 100; i = i + 1 {
      items.push(
        div(
          [
            class_name("item"),
            id("item-" + i.to_string()),
            data_("data-index", i.to_string()),
          ],
          [text("Content " + i.to_string())],
        ),
      )
    }
    b.keep((div([], items) : JSVNode))
  })
}

///|
/// Benchmark: Create fragment with 100 children
test "bench: create fragment with 100 children" (b : @bench.T) {
  b.bench(name="vdom_fragment_100", fn() {
    let items : Array[JSVNode] = []
    for i = 0; i < 100; i = i + 1 {
      items.push(span([], [text(i.to_string())]))
    }
    b.keep((fragment(items) : JSVNode))
  })
}

///|
/// Benchmark: Create complex tree with 100 card components
test "bench: create 100 card components" (b : @bench.T) {
  b.bench(name="vdom_100_cards", fn() {
    let cards : Array[JSVNode] = []
    for i = 0; i < 100; i = i + 1 {
      cards.push(
        div([class_name("card")], [
          div([class_name("card-header")], [
            h3([], [text("Card " + i.to_string())]),
          ]),
          div([class_name("card-body")], [p([], [text("Content")])]),
        ]),
      )
    }
    b.keep((div([class_name("card-list")], cards) : JSVNode))
  })
}
