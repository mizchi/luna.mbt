///| Browser Test Components - Client-side hydration components for E2E testing

///|

///|
/// Each hydrate_* function is exported and called by ln-loader

// FFI for JSON parsing
extern "js" fn js_getInt(state : @js.Any, key : String) -> Int =
  #|(s, k) => (s && typeof s[k] === 'number') ? s[k] : 0

///|
extern "js" fn js_getString(state : @js.Any, key : String) -> String =
  #|(s, k) => (s && typeof s[k] === 'string') ? s[k] : ''

///|
extern "js" fn js_getBool(state : @js.Any, key : String) -> Bool =
  #|(s, k) => (s && typeof s[k] === 'boolean') ? s[k] : false

///|
extern "js" fn js_getArray(state : @js.Any, key : String) -> Array[String] =
  #|(s, k) => (s && Array.isArray(s[k])) ? s[k] : []

// FFI to set data-hydrated attribute

///|
extern "js" fn js_setAttribute(
  el : @js_dom.Element,
  name : String,
  value : String,
) -> Unit =
  #|(el, n, v) => { el.setAttribute(n, v); }

///|
/// Signal/Effect basic test component
/// Tests: Signal get/set, Effect auto-tracking, reactive text updates
pub fn hydrate_signal_effect(el : @js_dom.Element, state : @js.Any) -> Unit {
  let initial = js_getInt(state, "count")
  let count_sig = @signal.signal(initial)
  let double_sig = @signal.signal(initial * 2)

  // Effect that updates double when count changes
  let _ = @signal.effect(fn() { double_sig.set(count_sig.get() * 2) })
  let vnode = @luna.h("div", [], [
    @luna.h("span", [("data-count", @luna.attr_static("true"))], [
      @luna.text_dyn(fn() { count_sig.get().to_string() }),
    ]),
    @luna.h("span", [("data-double", @luna.attr_static("true"))], [
      @luna.text_dyn(fn() { double_sig.get().to_string() }),
    ]),
    @luna.h(
      "button",
      [
        ("data-inc", @luna.attr_static("true")),
        (
          "onClick",
          @luna.attr_handler(
            @luna.handler(fn(_event : @js.Any) {
              count_sig.update(fn(c) { c + 1 })
            }),
          ),
        ),
      ],
      [@luna.text("+1")],
    ),
    @luna.h(
      "button",
      [
        ("data-dec", @luna.attr_static("true")),
        (
          "onClick",
          @luna.attr_handler(
            @luna.handler(fn(_event : @js.Any) {
              count_sig.update(fn(c) { c - 1 })
            }),
          ),
        ),
      ],
      [@luna.text("-1")],
    ),
    @luna.h(
      "button",
      [
        ("data-reset", @luna.attr_static("true")),
        (
          "onClick",
          @luna.attr_handler(
            @luna.handler(fn(_event : @js.Any) { count_sig.set(0) }),
          ),
        ),
      ],
      [@luna.text("Reset")],
    ),
  ])

  // Client-side rendering: clear container and render VNode
  @client.render_vnode(el, vnode)
  js_setAttribute(el, "data-hydrated", "true")
}

///|
/// Dynamic attributes test component
/// Tests: Dynamic class, dynamic style, attribute updates
pub fn hydrate_dynamic_attrs(el : @js_dom.Element, state : @js.Any) -> Unit {
  let active = @signal.signal(js_getBool(state, "active"))
  let color = @signal.signal(js_getString(state, "color"))
  let vnode = @luna.h("div", [], [
    @luna.h(
      "div",
      [
        ("data-box", @luna.attr_static("true")),
        (
          "class",
          @luna.attr_dynamic(fn() {
            if active.get() {
              "box active"
            } else {
              "box"
            }
          }),
        ),
        (
          "style",
          @luna.attr_dynamic(fn() {
            "background-color: " + color.get() + "; padding: 20px;"
          }),
        ),
      ],
      [
        @luna.text_dyn(fn() { if active.get() { "Active" } else { "Inactive" } }),
      ],
    ),
    @luna.h(
      "button",
      [
        ("data-toggle", @luna.attr_static("true")),
        (
          "onClick",
          @luna.attr_handler(
            @luna.handler(fn(_event : @js.Any) {
              active.update(fn(a) { not(a) })
            }),
          ),
        ),
      ],
      [@luna.text("Toggle Active")],
    ),
    @luna.h(
      "button",
      [
        ("data-red", @luna.attr_static("true")),
        (
          "onClick",
          @luna.attr_handler(
            @luna.handler(fn(_event : @js.Any) { color.set("red") }),
          ),
        ),
      ],
      [@luna.text("Red")],
    ),
    @luna.h(
      "button",
      [
        ("data-blue", @luna.attr_static("true")),
        (
          "onClick",
          @luna.attr_handler(
            @luna.handler(fn(_event : @js.Any) { color.set("blue") }),
          ),
        ),
      ],
      [@luna.text("Blue")],
    ),
  ])

  // Client-side rendering: clear container and render VNode
  @client.render_vnode(el, vnode)
  js_setAttribute(el, "data-hydrated", "true")
}

///|
/// Show/hide toggle test component
/// Tests: Conditional rendering with show()
pub fn hydrate_show_toggle(el : @js_dom.Element, state : @js.Any) -> Unit {
  let visible = @signal.signal(js_getBool(state, "visible"))
  let vnode = @luna.h("div", [], [
    @luna.h(
      "button",
      [
        ("data-toggle", @luna.attr_static("true")),
        (
          "onClick",
          @luna.attr_handler(
            @luna.handler(fn(_event : @js.Any) {
              visible.update(fn(v) { not(v) })
            }),
          ),
        ),
      ],
      [@luna.text_dyn(fn() { if visible.get() { "Hide" } else { "Show" } })],
    ),
    @luna.show(fn() { visible.get() }, fn() {
      @luna.h(
        "div",
        [
          ("data-content", @luna.attr_static("true")),
          ("class", @luna.attr_static("content-box")),
        ],
        [@luna.text("This content is conditionally shown")],
      )
    }),
  ])

  // Client-side rendering: clear container and render VNode
  @client.render_vnode(el, vnode)
  js_setAttribute(el, "data-hydrated", "true")
}

///|
/// For each list test component
/// Tests: List rendering with for_each()
pub fn hydrate_for_each(el : @js_dom.Element, state : @js.Any) -> Unit {
  let items = @signal.signal(js_getArray(state, "items"))
  // Store the pending input value separately since we need to capture it at add time
  let pending_input : Ref[String] = { val: "" }
  let vnode = @luna.h("div", [], [
    @luna.h("div", [("class", @luna.attr_static("input-row"))], [
      @luna.h(
        "input",
        [
          ("data-input", @luna.attr_static("true")),
          ("type", @luna.attr_static("text")),
          ("placeholder", @luna.attr_static("Enter item")),
          // Note: For input handling with events, we need to capture via FFI
          // This is a limitation - the hydration system uses VHandler which is () -> Unit
        ],
        [],
      ),
      @luna.h(
        "button",
        [
          ("data-add", @luna.attr_static("true")),
          (
            "onClick",
            @luna.attr_handler(
              @luna.handler(fn(_event : @js.Any) {
                // In a real app, we'd read from the input element
                // For testing, we'll add a placeholder item
                let current = items.get()
                let new_arr : Array[String] = []
                for i = 0; i < current.length(); i = i + 1 {
                  new_arr.push(current[i])
                }
                // Add new item with timestamp to make it unique
                new_arr.push("Item " + (current.length() + 1).to_string())
                items.set(new_arr)
              }),
            ),
          ),
        ],
        [@luna.text("Add")],
      ),
    ]),
    @luna.h("span", [("data-count", @luna.attr_static("true"))], [
      @luna.text_dyn(fn() { items.get().length().to_string() + " items" }),
    ]),
    @luna.h("ul", [("data-list", @luna.attr_static("true"))], [
      @luna.for_each(fn() {
        let current_items = items.get()
        let result : Array[@luna.Node[@js.Any]] = []
        for i = 0; i < current_items.length(); i = i + 1 {
          let item = current_items[i]
          let index = i
          result.push(
            @luna.h(
              "li",
              [("data-item", @luna.attr_static(index.to_string()))],
              [
                @luna.h("span", [], [@luna.text(item)]),
                @luna.h(
                  "button",
                  [
                    ("data-remove", @luna.attr_static(index.to_string())),
                    (
                      "onClick",
                      @luna.attr_handler(
                        @luna.handler(fn(_event : @js.Any) {
                          let current = items.get()
                          let new_arr : Array[String] = []
                          for j = 0; j < current.length(); j = j + 1 {
                            if j != index {
                              new_arr.push(current[j])
                            }
                          }
                          items.set(new_arr)
                        }),
                      ),
                    ),
                  ],
                  [@luna.text("x")],
                ),
              ],
            ),
          )
        }
        result
      }),
    ]),
  ])

  // Client-side rendering: clear container and render VNode
  @client.render_vnode(el, vnode)
  js_setAttribute(el, "data-hydrated", "true")
  ignore(pending_input)
}

///|
/// Multiple event types test component
/// Tests: click, dblclick handlers
pub fn hydrate_events(el : @js_dom.Element, _state : @js.Any) -> Unit {
  let click_count = @signal.signal(0)
  let dblclick_count = @signal.signal(0)
  let hover_state = @signal.signal("none")
  let vnode = @luna.h("div", [], [
    @luna.h(
      "div",
      [
        ("data-click-area", @luna.attr_static("true")),
        ("class", @luna.attr_static("click-area")),
        (
          "style",
          @luna.attr_static(
            "padding: 20px; border: 1px solid #ccc; cursor: pointer;",
          ),
        ),
        (
          "onClick",
          @luna.attr_handler(
            @luna.handler(fn(_event : @js.Any) {
              click_count.update(fn(c) { c + 1 })
            }),
          ),
        ),
        (
          "onDblclick",
          @luna.attr_handler(
            @luna.handler(fn(_event : @js.Any) {
              dblclick_count.update(fn(c) { c + 1 })
            }),
          ),
        ),
        (
          "onMouseenter",
          @luna.attr_handler(
            @luna.handler(fn(_event : @js.Any) { hover_state.set("hovering") }),
          ),
        ),
        (
          "onMouseleave",
          @luna.attr_handler(
            @luna.handler(fn(_event : @js.Any) { hover_state.set("none") }),
          ),
        ),
      ],
      [@luna.text("Click or double-click me")],
    ),
    @luna.h("div", [], [
      @luna.h("span", [("data-clicks", @luna.attr_static("true"))], [
        @luna.text_dyn(fn() { "Clicks: " + click_count.get().to_string() }),
      ]),
      @luna.text(" | "),
      @luna.h("span", [("data-dblclicks", @luna.attr_static("true"))], [
        @luna.text_dyn(fn() {
          "Double-clicks: " + dblclick_count.get().to_string()
        }),
      ]),
      @luna.text(" | "),
      @luna.h("span", [("data-hover", @luna.attr_static("true"))], [
        @luna.text_dyn(fn() { "Hover: " + hover_state.get() }),
      ]),
    ]),
  ])

  // Client-side rendering: clear container and render VNode
  @client.render_vnode(el, vnode)
  js_setAttribute(el, "data-hydrated", "true")
}

///|
/// Sortable list test component
/// Tests: List reordering without destroying DOM instances
pub fn hydrate_sortable_list(el : @js_dom.Element, state : @js.Any) -> Unit {
  // Item struct with id and label
  struct Item {
    id : Int
    label : String
  }

  // Parse initial items from state
  let initial_items = js_getArray(state, "items")
  let items : Array[Item] = []
  for i = 0; i < initial_items.length(); i = i + 1 {
    items.push({ id: i, label: initial_items[i] })
  }
  let items_sig = @signal.signal(items)

  // Build UI using @dom functions for DOM reuse support
  let controls = @dom.create_element(
    "div",
    [("class", @dom.Static("controls"))],
    [
      @dom.create_element(
        "button",
        [
          ("data-reverse", @dom.Static("true")),
          (
            "click",
            @dom.Handler(fn(_event) {
              let current = items_sig.get()
              let reversed : Array[Item] = []
              for i = current.length() - 1; i >= 0; i = i - 1 {
                reversed.push(current[i])
              }
              items_sig.set(reversed)
            }),
          ),
        ],
        [@dom.text_node(fn() { "Reverse" })],
      ),
      @dom.create_element(
        "button",
        [
          ("data-move-first-to-last", @dom.Static("true")),
          (
            "click",
            @dom.Handler(fn(_event) {
              let current = items_sig.get()
              if current.length() > 1 {
                let reordered : Array[Item] = []
                for i = 1; i < current.length(); i = i + 1 {
                  reordered.push(current[i])
                }
                reordered.push(current[0])
                items_sig.set(reordered)
              }
            }),
          ),
        ],
        [@dom.text_node(fn() { "Move First to Last" })],
      ),
    ],
  )

  // Use @dom.for_each for reference-based DOM reuse
  let list_items = @dom.for_each(fn() { items_sig.get() }, fn(item, _index) {
    @dom.create_element(
      "li",
      [("data-key", @dom.Static(item.id.to_string()))],
      [@dom.text_node(fn() { item.label })],
    )
  })
  let list = @dom.create_element("ul", [("data-list", @dom.Static("true"))], [
    list_items,
  ])
  let container = @dom.create_element("div", [], [controls, list])

  // Clear and mount
  el.as_node().setTextContent("")
  @dom.mount_to(el, container)
  js_setAttribute(el, "data-hydrated", "true")
}

///|
/// Input binding test component
/// Tests: Form interaction via signals
pub fn hydrate_input_binding(el : @js_dom.Element, state : @js.Any) -> Unit {
  let text_value = @signal.signal(js_getString(state, "text"))
  let submitted = @signal.signal("")
  let vnode = @luna.h("div", [], [
    @luna.h("div", [("data-form", @luna.attr_static("true"))], [
      @luna.h(
        "input",
        [
          ("data-text-input", @luna.attr_static("true")),
          ("type", @luna.attr_static("text")),
          ("value", @luna.attr_dynamic(fn() { text_value.get() })),
        ],
        [],
      ),
      @luna.h(
        "button",
        [
          ("data-submit", @luna.attr_static("true")),
          (
            "onClick",
            @luna.attr_handler(
              @luna.handler(fn(_event : @js.Any) {
                submitted.set(text_value.get())
              }),
            ),
          ),
        ],
        [@luna.text("Submit")],
      ),
      @luna.h(
        "button",
        [
          ("data-clear", @luna.attr_static("true")),
          (
            "onClick",
            @luna.attr_handler(
              @luna.handler(fn(_event : @js.Any) { text_value.set("") }),
            ),
          ),
        ],
        [@luna.text("Clear")],
      ),
      @luna.h(
        "button",
        [
          ("data-set-hello", @luna.attr_static("true")),
          (
            "onClick",
            @luna.attr_handler(
              @luna.handler(fn(_event : @js.Any) {
                text_value.set("Hello World")
              }),
            ),
          ),
        ],
        [@luna.text("Set Hello")],
      ),
    ]),
    @luna.h("div", [], [
      @luna.h("span", [("data-preview", @luna.attr_static("true"))], [
        @luna.text_dyn(fn() { "Preview: " + text_value.get() }),
      ]),
    ]),
    @luna.h("div", [], [
      @luna.h("span", [("data-submitted", @luna.attr_static("true"))], [
        @luna.text_dyn(fn() { "Submitted: " + submitted.get() }),
      ]),
    ]),
  ])

  // Client-side rendering: clear container and render VNode
  @client.render_vnode(el, vnode)
  js_setAttribute(el, "data-hydrated", "true")
}

///|
/// Element ref test component
/// Tests: ref_ callback for direct DOM element access
pub fn hydrate_element_ref(el : @js_dom.Element, _state : @js.Any) -> Unit {
  // Store ref to the input element
  let input_ref : Ref[@js_dom.Element?] = { val: None }
  let focus_count = @signal.signal(0)

  // Build UI using @dom DSL with ref_ support
  let container = @dom.div([
    @dom.div(class="ref-demo", [
      @dom.input(
        type_="text",
        placeholder="This input has a ref",
        ref_=fn(input_el) {
          // Store the element reference
          input_ref.val = Some(input_el)
        },
        attrs=[("data-ref-input", @dom.AttrString("true"))],
      ),
      @dom.button(
        on=@dom.events().click(fn(_e) {
          // Use the stored ref to focus the input
          match input_ref.val {
            Some(input_el) => {
              input_el.as_any()._call("focus", []) |> ignore
              focus_count.update(fn(c) { c + 1 })
            }
            None => ()
          }
        }),
        attrs=[("data-focus-btn", @dom.AttrString("true"))],
        [@dom.text("Focus Input")],
      ),
      @dom.button(
        on=@dom.events().click(fn(_e) {
          // Use the stored ref to clear and focus the input
          match input_ref.val {
            Some(input_el) => {
              input_el.as_any()._set("value", @js.any("")) |> ignore
              input_el.as_any()._call("focus", []) |> ignore
              focus_count.update(fn(c) { c + 1 })
            }
            None => ()
          }
        }),
        attrs=[("data-clear-focus-btn", @dom.AttrString("true"))],
        [@dom.text("Clear & Focus")],
      ),
    ]),
    @dom.div([
      @dom.span(attrs=[("data-focus-count", @dom.AttrString("true"))], [
        @dom.text_dyn(fn() { "Focus count: " + focus_count.get().to_string() }),
      ]),
    ]),
    @dom.div([
      @dom.span(attrs=[("data-ref-status", @dom.AttrString("true"))], [
        @dom.text_dyn(fn() {
          match input_ref.val {
            Some(_) => "Ref captured: yes"
            None => "Ref captured: no"
          }
        }),
      ]),
    ]),
  ])

  // Clear and mount
  el.as_node().setTextContent("")
  @dom.mount_to(el, container)
  js_setAttribute(el, "data-hydrated", "true")
}
