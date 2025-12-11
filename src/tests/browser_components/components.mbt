///| Browser Test Components - Client-side hydration components for E2E testing
///|
///| Each hydrate_* function is exported and called by kg-loader

// FFI for JSON parsing
extern "js" fn js_getInt(state : @core.Any, key : String) -> Int =
  #|(s, k) => (s && typeof s[k] === 'number') ? s[k] : 0

extern "js" fn js_getString(state : @core.Any, key : String) -> String =
  #|(s, k) => (s && typeof s[k] === 'string') ? s[k] : ''

extern "js" fn js_getBool(state : @core.Any, key : String) -> Bool =
  #|(s, k) => (s && typeof s[k] === 'boolean') ? s[k] : false

extern "js" fn js_getArray(state : @core.Any, key : String) -> Array[String] =
  #|(s, k) => (s && Array.isArray(s[k])) ? s[k] : []

// FFI to set data-hydrated attribute
extern "js" fn js_setAttribute(el : @js_dom.Element, name : String, value : String) -> Unit =
  #|(el, n, v) => { el.setAttribute(n, v); }


///|
/// Signal/Effect basic test component
/// Tests: Signal get/set, Effect auto-tracking, reactive text updates
pub fn hydrate_signal_effect(el : @js_dom.Element, state : @core.Any) -> Unit {
  let initial = js_getInt(state, "count")
  let count_sig = @signal.signal(initial)
  let double_sig = @signal.signal(initial * 2)

  // Effect that updates double when count changes
  let _ = @signal.effect(fn() {
    double_sig.set(count_sig.get() * 2)
  })

  let vnode = @element.div(
    [],
    [
      @element.span(
        [("data-count", @kaguya.attr_static("true"))],
        [@kaguya.text_dyn(fn() { count_sig.get().to_string() })],
      ),
      @element.span(
        [("data-double", @kaguya.attr_static("true"))],
        [@kaguya.text_dyn(fn() { double_sig.get().to_string() })],
      ),
      @element.button(
        [
          ("data-inc", @kaguya.attr_static("true")),
          ("onClick", @kaguya.attr_handler(@kaguya.handler_from_callback(fn() {
            count_sig.update(fn(c) { c + 1 })
          }))),
        ],
        [@kaguya.vtext("+1")],
      ),
      @element.button(
        [
          ("data-dec", @kaguya.attr_static("true")),
          ("onClick", @kaguya.attr_handler(@kaguya.handler_from_callback(fn() {
            count_sig.update(fn(c) { c - 1 })
          }))),
        ],
        [@kaguya.vtext("-1")],
      ),
      @element.button(
        [
          ("data-reset", @kaguya.attr_static("true")),
          ("onClick", @kaguya.attr_handler(@kaguya.handler_from_callback(fn() {
            count_sig.set(0)
          }))),
        ],
        [@kaguya.vtext("Reset")],
      ),
    ],
  )

  // Client-side rendering: clear container and render VNode
  @dom.render_vnode(el, vnode)
  js_setAttribute(el, "data-hydrated", "true")
}

///|
/// Dynamic attributes test component
/// Tests: Dynamic class, dynamic style, attribute updates
pub fn hydrate_dynamic_attrs(el : @js_dom.Element, state : @core.Any) -> Unit {
  let active = @signal.signal(js_getBool(state, "active"))
  let color = @signal.signal(js_getString(state, "color"))

  let vnode = @element.div(
    [],
    [
      @element.div(
        [
          ("data-box", @kaguya.attr_static("true")),
          ("class", @kaguya.attr_dynamic(fn() {
            if active.get() { "box active" } else { "box" }
          })),
          ("style", @kaguya.attr_dynamic(fn() {
            "background-color: " + color.get() + "; padding: 20px;"
          })),
        ],
        [@kaguya.text_dyn(fn() {
          if active.get() { "Active" } else { "Inactive" }
        })],
      ),
      @element.button(
        [
          ("data-toggle", @kaguya.attr_static("true")),
          ("onClick", @kaguya.attr_handler(@kaguya.handler_from_callback(fn() {
            active.update(fn(a) { not(a) })
          }))),
        ],
        [@kaguya.vtext("Toggle Active")],
      ),
      @element.button(
        [
          ("data-red", @kaguya.attr_static("true")),
          ("onClick", @kaguya.attr_handler(@kaguya.handler_from_callback(fn() {
            color.set("red")
          }))),
        ],
        [@kaguya.vtext("Red")],
      ),
      @element.button(
        [
          ("data-blue", @kaguya.attr_static("true")),
          ("onClick", @kaguya.attr_handler(@kaguya.handler_from_callback(fn() {
            color.set("blue")
          }))),
        ],
        [@kaguya.vtext("Blue")],
      ),
    ],
  )

  // Client-side rendering: clear container and render VNode
  @dom.render_vnode(el, vnode)
  js_setAttribute(el, "data-hydrated", "true")
}

///|
/// Show/hide toggle test component
/// Tests: Conditional rendering with vshow()
pub fn hydrate_show_toggle(el : @js_dom.Element, state : @core.Any) -> Unit {
  let visible = @signal.signal(js_getBool(state, "visible"))

  let vnode = @element.div(
    [],
    [
      @element.button(
        [
          ("data-toggle", @kaguya.attr_static("true")),
          ("onClick", @kaguya.attr_handler(@kaguya.handler_from_callback(fn() {
            visible.update(fn(v) { not(v) })
          }))),
        ],
        [@kaguya.text_dyn(fn() {
          if visible.get() { "Hide" } else { "Show" }
        })],
      ),
      @kaguya.vshow(
        fn() { visible.get() },
        fn() {
          @element.div(
            [("data-content", @kaguya.attr_static("true")), ("class", @kaguya.attr_static("content-box"))],
            [@kaguya.vtext("This content is conditionally shown")],
          )
        },
      ),
    ],
  )

  // Client-side rendering: clear container and render VNode
  @dom.render_vnode(el, vnode)
  js_setAttribute(el, "data-hydrated", "true")
}

///|
/// For each list test component
/// Tests: List rendering with vfor()
pub fn hydrate_for_each(el : @js_dom.Element, state : @core.Any) -> Unit {
  let items = @signal.signal(js_getArray(state, "items"))
  // Store the pending input value separately since we need to capture it at add time
  let pending_input : Ref[String] = { val: "" }

  let vnode = @element.div(
    [],
    [
      @element.div(
        [("class", @kaguya.attr_static("input-row"))],
        [
          @element.input(
            [
              ("data-input", @kaguya.attr_static("true")),
              ("type", @kaguya.attr_static("text")),
              ("placeholder", @kaguya.attr_static("Enter item")),
              // Note: For input handling with events, we need to capture via FFI
              // This is a limitation - the hydration system uses VHandler which is () -> Unit
            ],
          ),
          @element.button(
            [
              ("data-add", @kaguya.attr_static("true")),
              ("onClick", @kaguya.attr_handler(@kaguya.handler_from_callback(fn() {
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
              }))),
            ],
            [@kaguya.vtext("Add")],
          ),
        ],
      ),
      @element.span(
        [("data-count", @kaguya.attr_static("true"))],
        [@kaguya.text_dyn(fn() { items.get().length().to_string() + " items" })],
      ),
      @element.ul(
        [("data-list", @kaguya.attr_static("true"))],
        [
          @kaguya.vfor(fn() {
            let current_items = items.get()
            let result : Array[@kaguya.Node] = []
            for i = 0; i < current_items.length(); i = i + 1 {
              let item = current_items[i]
              let index = i
              result.push(
                @element.li(
                  [("data-item", @kaguya.attr_static(index.to_string()))],
                  [
                    @element.span([], [@kaguya.vtext(item)]),
                    @element.button(
                      [
                        ("data-remove", @kaguya.attr_static(index.to_string())),
                        ("onClick", @kaguya.attr_handler(@kaguya.handler_from_callback(fn() {
                          let current = items.get()
                          let new_arr : Array[String] = []
                          for j = 0; j < current.length(); j = j + 1 {
                            if j != index {
                              new_arr.push(current[j])
                            }
                          }
                          items.set(new_arr)
                        }))),
                      ],
                      [@kaguya.vtext("x")],
                    ),
                  ],
                ),
              )
            }
            result
          }),
        ],
      ),
    ],
  )

  // Client-side rendering: clear container and render VNode
  @dom.render_vnode(el, vnode)
  js_setAttribute(el, "data-hydrated", "true")
  ignore(pending_input)
}

///|
/// Multiple event types test component
/// Tests: click, dblclick handlers
pub fn hydrate_events(el : @js_dom.Element, _state : @core.Any) -> Unit {
  let click_count = @signal.signal(0)
  let dblclick_count = @signal.signal(0)
  let hover_state = @signal.signal("none")

  let vnode = @element.div(
    [],
    [
      @element.div(
        [
          ("data-click-area", @kaguya.attr_static("true")),
          ("class", @kaguya.attr_static("click-area")),
          ("style", @kaguya.attr_static("padding: 20px; border: 1px solid #ccc; cursor: pointer;")),
          ("onClick", @kaguya.attr_handler(@kaguya.handler_from_callback(fn() {
            click_count.update(fn(c) { c + 1 })
          }))),
          ("onDblclick", @kaguya.attr_handler(@kaguya.handler_from_callback(fn() {
            dblclick_count.update(fn(c) { c + 1 })
          }))),
          ("onMouseenter", @kaguya.attr_handler(@kaguya.handler_from_callback(fn() {
            hover_state.set("hovering")
          }))),
          ("onMouseleave", @kaguya.attr_handler(@kaguya.handler_from_callback(fn() {
            hover_state.set("none")
          }))),
        ],
        [@kaguya.vtext("Click or double-click me")],
      ),
      @element.div(
        [],
        [
          @element.span([("data-clicks", @kaguya.attr_static("true"))], [@kaguya.text_dyn(fn() { "Clicks: " + click_count.get().to_string() })]),
          @kaguya.vtext(" | "),
          @element.span([("data-dblclicks", @kaguya.attr_static("true"))], [@kaguya.text_dyn(fn() { "Double-clicks: " + dblclick_count.get().to_string() })]),
          @kaguya.vtext(" | "),
          @element.span([("data-hover", @kaguya.attr_static("true"))], [@kaguya.text_dyn(fn() { "Hover: " + hover_state.get() })]),
        ],
      ),
    ],
  )

  // Client-side rendering: clear container and render VNode
  @dom.render_vnode(el, vnode)
  js_setAttribute(el, "data-hydrated", "true")
}

///|
/// Input binding test component
/// Tests: Form interaction via signals
pub fn hydrate_input_binding(el : @js_dom.Element, state : @core.Any) -> Unit {
  let text_value = @signal.signal(js_getString(state, "text"))
  let submitted = @signal.signal("")

  let vnode = @element.div(
    [],
    [
      @element.div(
        [("data-form", @kaguya.attr_static("true"))],
        [
          @element.input(
            [
              ("data-text-input", @kaguya.attr_static("true")),
              ("type", @kaguya.attr_static("text")),
              ("value", @kaguya.attr_dynamic(fn() { text_value.get() })),
            ],
          ),
          @element.button(
            [
              ("data-submit", @kaguya.attr_static("true")),
              ("onClick", @kaguya.attr_handler(@kaguya.handler_from_callback(fn() {
                submitted.set(text_value.get())
              }))),
            ],
            [@kaguya.vtext("Submit")],
          ),
          @element.button(
            [
              ("data-clear", @kaguya.attr_static("true")),
              ("onClick", @kaguya.attr_handler(@kaguya.handler_from_callback(fn() {
                text_value.set("")
              }))),
            ],
            [@kaguya.vtext("Clear")],
          ),
          @element.button(
            [
              ("data-set-hello", @kaguya.attr_static("true")),
              ("onClick", @kaguya.attr_handler(@kaguya.handler_from_callback(fn() {
                text_value.set("Hello World")
              }))),
            ],
            [@kaguya.vtext("Set Hello")],
          ),
        ],
      ),
      @element.div(
        [],
        [
          @element.span([("data-preview", @kaguya.attr_static("true"))], [@kaguya.text_dyn(fn() { "Preview: " + text_value.get() })]),
        ],
      ),
      @element.div(
        [],
        [
          @element.span([("data-submitted", @kaguya.attr_static("true"))], [@kaguya.text_dyn(fn() { "Submitted: " + submitted.get() })]),
        ],
      ),
    ],
  )

  // Client-side rendering: clear container and render VNode
  @dom.render_vnode(el, vnode)
  js_setAttribute(el, "data-hydrated", "true")
}
