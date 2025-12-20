// WC Sample Application demonstrating Luna Web Components features
//
// This file shows Web Components with MoonBit and Luna's reactive system
// using Luna's VNode DSL and inline CSS injection via <style> element.

// =============================================================================
// CSS Definitions
// =============================================================================

let counter_css : String =
  #|:host { display: block; font-family: system-ui, sans-serif; }
  #|.buttons button { font-size: 18px; min-width: 40px; padding: 8px 16px; margin: 4px; cursor: pointer; }

let input_css : String =
  #|:host { display: block; font-family: system-ui, sans-serif; }
  #|input { padding: 8px; margin: 4px; border: 1px solid #ccc; border-radius: 4px; }

let effect_css : String =
  #|:host { display: block; font-family: system-ui, sans-serif; }
  #|button { padding: 8px 16px; margin: 4px; cursor: pointer; }

let conditional_css : String =
  #|:host { display: block; font-family: system-ui, sans-serif; }
  #|button { padding: 8px 16px; margin: 4px; cursor: pointer; }
  #|.message { padding: 10px; background-color: #e0f7fa; border-radius: 4px; margin-top: 8px; }

let style_css : String =
  #|:host { display: block; font-family: system-ui, sans-serif; }
  #|.box { transition: all 0.3s ease; border-radius: 8px; }
  #|label { margin-right: 8px; }
  #|.control { margin: 8px 0; }

let todo_css : String =
  #|:host { display: block; font-family: system-ui, sans-serif; }
  #|input { padding: 8px; margin: 4px; border: 1px solid #ccc; border-radius: 4px; }
  #|button { padding: 8px 16px; margin: 4px; cursor: pointer; }
  #|ul { list-style: none; padding: 0; }
  #|li { padding: 8px; margin: 4px 0; background: #fff; border: 1px solid #eee; border-radius: 4px; display: flex; justify-content: space-between; align-items: center; }
  #|.todo-text { cursor: pointer; }
  #|.completed { text-decoration: line-through; opacity: 0.6; }

let child_button_css : String =
  #|:host { display: inline-block; }
  #|button { padding: 8px 16px; background: #4CAF50; color: white; border: none; border-radius: 4px; cursor: pointer; }
  #|button:hover { background: #45a049; }
  #|.local-count { font-size: 12px; color: #666; margin-top: 4px; }

let nested_parent_css : String =
  #|:host { display: block; font-family: system-ui, sans-serif; }
  #|.parent-container { border: 2px solid #2196F3; padding: 16px; border-radius: 8px; }
  #|.parent-header { color: #2196F3; margin-bottom: 16px; }
  #|.children { display: flex; gap: 16px; flex-wrap: wrap; }
  #|.stats { margin-top: 16px; padding: 8px; background: #e3f2fd; border-radius: 4px; }

// =============================================================================
// FFI for custom events (needed for nested components)
// =============================================================================

///|
extern "js" fn dispatch_custom_event(
  element : @js_dom.Element,
  event_name : String,
  detail : @js.Any,
) -> Unit =
  #| (el, name, detail) => {
  #|   el.dispatchEvent(new CustomEvent(name, {
  #|     bubbles: true,
  #|     composed: true,
  #|     detail
  #|   }));
  #| }

///|
extern "js" fn add_custom_event_listener(
  element : @js_dom.Element,
  event_name : String,
  handler : (@js.Any) -> Unit,
) -> Unit =
  #| (el, name, handler) => el.addEventListener(name, (e) => handler(e.detail))

///|
extern "js" fn int_to_any(n : Int) -> @js.Any =
  #| (n) => n

// =============================================================================
// Helper: Create style element
// =============================================================================

///|
fn style(css : String) -> @luna.Node[@js.Any] {
  @luna.h("style", [], [@luna.text(css)])
}

// =============================================================================
// Counter Component
// =============================================================================

///|
fn register_wc_counter() -> Unit {
  @luna_api.register_shadow("wc-counter", fn(_host) {
    let count = @signal.signal(0)
    let doubled = @signal.memo(fn() { count.get() * 2 })
    let is_even = @signal.memo(fn() { count.get() % 2 == 0 })

    @luna.fragment([
      style(counter_css),
      @luna.h("h2", [], [@luna.text("Counter Example")]),
      @luna.h(
        "p",
        [("class", @luna.attr_static("count"))],
        [@luna.text_dyn(fn() { "Count: " + count.get().to_string() })],
      ),
      @luna.h(
        "p",
        [("class", @luna.attr_static("doubled"))],
        [@luna.text_dyn(fn() { "Doubled: " + doubled().to_string() })],
      ),
      @luna.h(
        "p",
        [("class", @luna.attr_static("parity"))],
        [@luna.text_dyn(fn() { if is_even() { "Even" } else { "Odd" } })],
      ),
      @luna.h(
        "div",
        [("class", @luna.attr_static("buttons"))],
        [
          @luna.h(
            "button",
            [
              ("class", @luna.attr_static("dec")),
              (
                "onclick",
                @luna.attr_handler(
                  @luna.handler(fn(_) { count.update(fn(n) { n - 1 }) }),
                ),
              ),
            ],
            [@luna.text("-")],
          ),
          @luna.h(
            "button",
            [
              ("class", @luna.attr_static("inc")),
              (
                "onclick",
                @luna.attr_handler(
                  @luna.handler(fn(_) { count.update(fn(n) { n + 1 }) }),
                ),
              ),
            ],
            [@luna.text("+")],
          ),
          @luna.h(
            "button",
            [
              ("class", @luna.attr_static("reset")),
              (
                "onclick",
                @luna.attr_handler(@luna.handler(fn(_) { count.set(0) })),
              ),
            ],
            [@luna.text("Reset")],
          ),
        ],
      ),
    ])
  })
}

// =============================================================================
// Input Component
// =============================================================================

///|
fn register_wc_input() -> Unit {
  @luna_api.register_shadow("wc-input", fn(_host) {
    let text_signal = @signal.signal("")
    let char_count = @signal.memo(fn() { text_signal.get().length() })

    @luna.fragment([
      style(input_css),
      @luna.h("h2", [], [@luna.text("Input Example")]),
      @luna.h(
        "input",
        [
          ("class", @luna.attr_static("text-input")),
          ("type", @luna.attr_static("text")),
          ("placeholder", @luna.attr_static("Type something...")),
          (
            "oninput",
            @luna.attr_handler(
              @luna.handler(fn(e : @js.Any) {
                let value : String = e._get("target")._get("value").cast()
                text_signal.set(value)
              }),
            ),
          ),
        ],
        [],
      ),
      @luna.h(
        "p",
        [("class", @luna.attr_static("char-count"))],
        [@luna.text_dyn(fn() { "Characters: " + char_count().to_string() })],
      ),
      @luna.h(
        "p",
        [("class", @luna.attr_static("typed"))],
        [@luna.text_dyn(fn() { "You typed: " + text_signal.get() })],
      ),
    ])
  })
}

// =============================================================================
// Effect Component
// =============================================================================

///|
fn register_wc_effect() -> Unit {
  @luna_api.register_shadow("wc-effect", fn(_host) {
    let active = @signal.signal(false)
    let ticks = @signal.signal(0)

    @luna.fragment([
      style(effect_css),
      @luna.h("h2", [], [@luna.text("Effect Example")]),
      @luna.h(
        "p",
        [("class", @luna.attr_static("status"))],
        [
          @luna.text_dyn(fn() {
            let status = if active.get() { "Active" } else { "Inactive" }
            "Status: " + status
          }),
        ],
      ),
      @luna.h(
        "p",
        [("class", @luna.attr_static("ticks"))],
        [@luna.text_dyn(fn() { "Ticks: " + ticks.get().to_string() })],
      ),
      @luna.h(
        "button",
        [
          ("class", @luna.attr_static("toggle")),
          (
            "onclick",
            @luna.attr_handler(
              @luna.handler(fn(_) { active.update(fn(b) { not(b) }) }),
            ),
          ),
        ],
        [@luna.text_dyn(fn() { if active.get() { "Stop" } else { "Start" } })],
      ),
      @luna.h(
        "button",
        [
          ("class", @luna.attr_static("tick")),
          (
            "onclick",
            @luna.attr_handler(
              @luna.handler(fn(_) { ticks.update(fn(n) { n + 1 }) }),
            ),
          ),
        ],
        [@luna.text("Tick")],
      ),
    ])
  })
}

// =============================================================================
// Conditional Component
// =============================================================================

///|
fn register_wc_conditional() -> Unit {
  @luna_api.register_shadow("wc-conditional", fn(_host) {
    let show_message = @signal.signal(true)

    @luna.fragment([
      style(conditional_css),
      @luna.h("h2", [], [@luna.text("Conditional Example")]),
      @luna.h(
        "button",
        [
          ("class", @luna.attr_static("toggle")),
          (
            "onclick",
            @luna.attr_handler(
              @luna.handler(fn(_) { show_message.update(fn(b) { not(b) }) }),
            ),
          ),
        ],
        [
          @luna.text_dyn(fn() {
            if show_message.get() {
              "Hide Message"
            } else {
              "Show Message"
            }
          }),
        ],
      ),
      @luna.show(
        fn() { show_message.get() },
        fn() {
          @luna.h(
            "div",
            [("class", @luna.attr_static("message"))],
            [@luna.text("Hello! This message is conditionally rendered.")],
          )
        },
      ),
    ])
  })
}

// =============================================================================
// Style Component
// =============================================================================

///|
fn register_wc_style() -> Unit {
  @luna_api.register_shadow("wc-style", fn(_host) {
    let hue = @signal.signal(180)
    let size = @signal.signal(100)

    @luna.fragment([
      style(style_css),
      @luna.h("h2", [], [@luna.text("Style Example")]),
      @luna.h(
        "div",
        [
          ("class", @luna.attr_static("box")),
          (
            "style",
            @luna.attr_dynamic(fn() {
              let s = size.get()
              let h = hue.get()
              "width: " +
              s.to_string() +
              "px; height: " +
              s.to_string() +
              "px; background-color: hsl(" +
              h.to_string() +
              ", 70%, 50%);"
            }),
          ),
        ],
        [],
      ),
      @luna.h(
        "div",
        [("class", @luna.attr_static("control"))],
        [
          @luna.h("label", [], [@luna.text("Hue:")]),
          @luna.h(
            "input",
            [
              ("class", @luna.attr_static("hue")),
              ("type", @luna.attr_static("range")),
              ("value", @luna.attr_static("180")),
              ("min", @luna.attr_static("0")),
              ("max", @luna.attr_static("360")),
              (
                "oninput",
                @luna.attr_handler(
                  @luna.handler(fn(e : @js.Any) {
                    let value : String = e._get("target")._get("value").cast()
                    match @global.parseInt(value) {
                      Some(n) => hue.set(n)
                      None => ()
                    }
                  }),
                ),
              ),
            ],
            [],
          ),
        ],
      ),
      @luna.h(
        "div",
        [("class", @luna.attr_static("control"))],
        [
          @luna.h("label", [], [@luna.text("Size:")]),
          @luna.h(
            "input",
            [
              ("class", @luna.attr_static("size")),
              ("type", @luna.attr_static("range")),
              ("value", @luna.attr_static("100")),
              ("min", @luna.attr_static("50")),
              ("max", @luna.attr_static("200")),
              (
                "oninput",
                @luna.attr_handler(
                  @luna.handler(fn(e : @js.Any) {
                    let value : String = e._get("target")._get("value").cast()
                    match @global.parseInt(value) {
                      Some(n) => size.set(n)
                      None => ()
                    }
                  }),
                ),
              ),
            ],
            [],
          ),
        ],
      ),
    ])
  })
}

// =============================================================================
// Todo Component
// =============================================================================

///|
priv struct TodoItem {
  id : Int
  text : String
  completed : Bool
}

///|
fn register_wc_todo() -> Unit {
  @luna_api.register_shadow("wc-todo", fn(_host) {
    let todos : @signal.Signal[Array[TodoItem]] = @signal.signal([])
    let input_text = @signal.signal("")
    let next_id = @signal.signal(1)

    fn add_todo() -> Unit {
      let t = input_text.get()
      if t != "" {
        let id = next_id.get()
        next_id.set(id + 1)
        todos.update(fn(items) {
          let new_items = items.copy()
          new_items.push({ id, text: t, completed: false })
          new_items
        })
        input_text.set("")
      }
    }

    fn toggle_todo(id : Int) -> Unit {
      todos.update(fn(items) {
        items.map(fn(item) {
          if item.id == id {
            { ..item, completed: not(item.completed) }
          } else {
            item
          }
        })
      })
    }

    fn remove_todo(id : Int) -> Unit {
      todos.update(fn(items) { items.filter(fn(item) { item.id != id }) })
    }

    fn get_completed_count() -> Int {
      todos.get().iter().filter(fn(item) { item.completed }).count()
    }

    @luna.fragment([
      style(todo_css),
      @luna.h("h2", [], [@luna.text("Todo List Example")]),
      @luna.h(
        "form",
        [
          (
            "onsubmit",
            @luna.attr_handler(
              @luna.handler(fn(e : @js.Any) {
                // Prevent form submission
                e._call("preventDefault", []) |> ignore
                add_todo()
              }),
            ),
          ),
        ],
        [
          @luna.h(
            "input",
            [
              ("class", @luna.attr_static("todo-input")),
              ("type", @luna.attr_static("text")),
              ("placeholder", @luna.attr_static("Add a todo...")),
              ("value", @luna.attr_dynamic(fn() { input_text.get() })),
              (
                "oninput",
                @luna.attr_handler(
                  @luna.handler(fn(e : @js.Any) {
                    let value : String = e._get("target")._get("value").cast()
                    input_text.set(value)
                  }),
                ),
              ),
            ],
            [],
          ),
          @luna.h(
            "button",
            [("type", @luna.attr_static("submit"))],
            [@luna.text("Add")],
          ),
        ],
      ),
      @luna.h(
        "p",
        [("class", @luna.attr_static("stats"))],
        [
          @luna.text_dyn(fn() {
            let total = todos.get().length()
            let completed = get_completed_count()
            completed.to_string() + "/" + total.to_string() + " completed"
          }),
        ],
      ),
      @luna.h(
        "ul",
        [("class", @luna.attr_static("todo-list"))],
        [
          @luna.for_each(fn() {
            todos.get().map(fn(item) {
              let class_name = if item.completed { "completed" } else { "" }
              let item_id = item.id
              @luna.h(
                "li",
                [("class", @luna.attr_static(class_name))],
                [
                  @luna.h(
                    "span",
                    [
                      ("class", @luna.attr_static("todo-text")),
                      (
                        "onclick",
                        @luna.attr_handler(
                          @luna.handler(fn(_) { toggle_todo(item_id) }),
                        ),
                      ),
                    ],
                    [@luna.text(item.text)],
                  ),
                  @luna.h(
                    "button",
                    [
                      ("class", @luna.attr_static("remove")),
                      (
                        "onclick",
                        @luna.attr_handler(
                          @luna.handler(fn(_) { remove_todo(item_id) }),
                        ),
                      ),
                    ],
                    [@luna.text("×")],
                  ),
                ],
              )
            })
          }),
        ],
      ),
    ])
  })
}

// =============================================================================
// Child Button Component
// =============================================================================

///|
fn register_wc_child_button() -> Unit {
  @luna_api.register_shadow("wc-child-button", fn(host) {
    let click_count = @signal.signal(0)

    @luna.fragment([
      style(child_button_css),
      @luna.h(
        "button",
        [
          ("class", @luna.attr_static("child-btn")),
          (
            "onclick",
            @luna.attr_handler(
              @luna.handler(fn(_) {
                click_count.update(fn(n) { n + 1 })
                dispatch_custom_event(
                  host,
                  "child-clicked",
                  int_to_any(click_count.get()),
                )
              }),
            ),
          ),
        ],
        [@luna.text("Child Button")],
      ),
      @luna.h(
        "div",
        [("class", @luna.attr_static("local-count"))],
        [
          @luna.text_dyn(fn() { click_count.get().to_string() }),
        ],
      ),
    ])
  })
}

// =============================================================================
// Nested Parent Component
// =============================================================================

///|
fn register_wc_nested_parent() -> Unit {
  @luna_api.register_shadow("wc-nested-parent", fn(host) {
    let total_child_clicks = @signal.signal(0)

    // Listen for custom events from children
    add_custom_event_listener(host, "child-clicked", fn(_detail) {
      total_child_clicks.update(fn(n) { n + 1 })
    })

    @luna.fragment([
      style(nested_parent_css),
      @luna.h(
        "div",
        [("class", @luna.attr_static("parent-container"))],
        [
          @luna.h(
            "h3",
            [("class", @luna.attr_static("parent-header"))],
            [@luna.text("Parent Component")],
          ),
          @luna.h(
            "div",
            [("class", @luna.attr_static("children"))],
            [
              // Use custom element tag directly
              @luna.h("wc-child-button", [], []),
              @luna.h("wc-child-button", [], []),
              @luna.h("wc-child-button", [], []),
            ],
          ),
          @luna.h(
            "div",
            [("class", @luna.attr_static("stats"))],
            [
              @luna.text("Total clicks from children: "),
              @luna.h(
                "span",
                [("class", @luna.attr_static("total-clicks"))],
                [
                  @luna.text_dyn(fn() { total_child_clicks.get().to_string() }),
                ],
              ),
            ],
          ),
        ],
      ),
    ])
  })
}

// =============================================================================
// Main Application
// =============================================================================

///|
fn main {
  // Register all Web Components
  register_wc_counter()
  register_wc_input()
  register_wc_effect()
  register_wc_conditional()
  register_wc_style()
  register_wc_todo()

  // Register nested components (child must be registered before parent uses it)
  register_wc_child_button()
  register_wc_nested_parent()
}
