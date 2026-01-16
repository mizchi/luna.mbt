// WC Sample Application demonstrating Luna Web Components features
//
// This file shows Web Components with MoonBit and Luna's reactive system
// using Luna's VNode DSL and inline CSS injection via <style> element.

///|
using @luna {
  fragment,
  h,
  text,
  text_dyn,
  for_each,
  attr_static,
  attr_dynamic,
  attr_handler,
  handler,
  type Node,
}

// =============================================================================
// CSS Definitions
// =============================================================================

///|
let counter_css : String =
  #|:host { display: block; font-family: system-ui, sans-serif; }
  #|.buttons button { font-size: 18px; min-width: 40px; padding: 8px 16px; margin: 4px; cursor: pointer; }

///|
let input_css : String =
  #|:host { display: block; font-family: system-ui, sans-serif; }
  #|input { padding: 8px; margin: 4px; border: 1px solid #ccc; border-radius: 4px; }

///|
let effect_css : String =
  #|:host { display: block; font-family: system-ui, sans-serif; }
  #|button { padding: 8px 16px; margin: 4px; cursor: pointer; }

///|
let conditional_css : String =
  #|:host { display: block; font-family: system-ui, sans-serif; }
  #|button { padding: 8px 16px; margin: 4px; cursor: pointer; }
  #|.message { padding: 10px; background-color: #e0f7fa; border-radius: 4px; margin-top: 8px; }

///|
let style_css : String =
  #|:host { display: block; font-family: system-ui, sans-serif; }
  #|.box { transition: all 0.3s ease; border-radius: 8px; }
  #|label { margin-right: 8px; }
  #|.control { margin: 8px 0; }

///|
let todo_css : String =
  #|:host { display: block; font-family: system-ui, sans-serif; }
  #|input { padding: 8px; margin: 4px; border: 1px solid #ccc; border-radius: 4px; }
  #|button { padding: 8px 16px; margin: 4px; cursor: pointer; }
  #|ul { list-style: none; padding: 0; }
  #|li { padding: 8px; margin: 4px 0; background: #fff; border: 1px solid #eee; border-radius: 4px; display: flex; justify-content: space-between; align-items: center; }
  #|.todo-text { cursor: pointer; }
  #|.completed { text-decoration: line-through; opacity: 0.6; }

///|
let child_button_css : String =
  #|:host { display: inline-block; }
  #|button { padding: 8px 16px; background: #4CAF50; color: white; border: none; border-radius: 4px; cursor: pointer; }
  #|button:hover { background: #45a049; }
  #|.local-count { font-size: 12px; color: #666; margin-top: 4px; }

///|
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
fn style(css : String) -> Node[@js.Any] {
  h("style", [], [text(css)])
}

// =============================================================================
// Counter Component
// =============================================================================

///|
fn register_wc_counter() -> Unit {
  @luna_api.register_shadow("wc-counter", fn(_host) {
    let count = @resource.signal(0)
    let doubled = @resource.memo(fn() { count.get() * 2 })
    let is_even = @resource.memo(fn() { count.get() % 2 == 0 })
    fragment([
      style(counter_css),
      h("h2", [], [text("Counter Example")]),
      h("p", [("class", attr_static("count"))], [
        text_dyn(fn() { "Count: " + count.get().to_string() }),
      ]),
      h("p", [("class", attr_static("doubled"))], [
        text_dyn(fn() { "Doubled: " + doubled().to_string() }),
      ]),
      h("p", [("class", attr_static("parity"))], [
        text_dyn(fn() { if is_even() { "Even" } else { "Odd" } }),
      ]),
      h("div", [("class", attr_static("buttons"))], [
        h(
          "button",
          [
            ("class", attr_static("dec")),
            (
              "onclick",
              attr_handler(handler(fn(_) { count.update(fn(n) { n - 1 }) })),
            ),
          ],
          [text("-")],
        ),
        h(
          "button",
          [
            ("class", attr_static("inc")),
            (
              "onclick",
              attr_handler(handler(fn(_) { count.update(fn(n) { n + 1 }) })),
            ),
          ],
          [text("+")],
        ),
        h(
          "button",
          [
            ("class", attr_static("reset")),
            ("onclick", attr_handler(handler(fn(_) { count.set(0) }))),
          ],
          [text("Reset")],
        ),
      ]),
    ])
  })
}

// =============================================================================
// Input Component
// =============================================================================

///|
fn register_wc_input() -> Unit {
  @luna_api.register_shadow("wc-input", fn(_host) {
    let text_signal = @resource.signal("")
    let char_count = @resource.memo(fn() { text_signal.get().length() })
    fragment([
      style(input_css),
      h("h2", [], [text("Input Example")]),
      h(
        "input",
        [
          ("class", attr_static("text-input")),
          ("type", attr_static("text")),
          ("placeholder", attr_static("Type something...")),
          (
            "oninput",
            attr_handler(
              handler(fn(e : @js.Any) {
                let value : String = e._get("target")._get("value").cast()
                text_signal.set(value)
              }),
            ),
          ),
        ],
        [],
      ),
      h("p", [("class", attr_static("char-count"))], [
        text_dyn(fn() { "Characters: " + char_count().to_string() }),
      ]),
      h("p", [("class", attr_static("typed"))], [
        text_dyn(fn() { "You typed: " + text_signal.get() }),
      ]),
    ])
  })
}

// =============================================================================
// Effect Component
// =============================================================================

///|
fn register_wc_effect() -> Unit {
  @luna_api.register_shadow("wc-effect", fn(_host) {
    let active = @resource.signal(false)
    let ticks = @resource.signal(0)
    fragment([
      style(effect_css),
      h("h2", [], [text("Effect Example")]),
      h("p", [("class", attr_static("status"))], [
        text_dyn(fn() {
          let status = if active.get() { "Active" } else { "Inactive" }
          "Status: " + status
        }),
      ]),
      h("p", [("class", attr_static("ticks"))], [
        text_dyn(fn() { "Ticks: " + ticks.get().to_string() }),
      ]),
      h(
        "button",
        [
          ("class", attr_static("toggle")),
          (
            "onclick",
            attr_handler(handler(fn(_) { active.update(fn(b) { not(b) }) })),
          ),
        ],
        [text_dyn(fn() { if active.get() { "Stop" } else { "Start" } })],
      ),
      h(
        "button",
        [
          ("class", attr_static("tick")),
          (
            "onclick",
            attr_handler(handler(fn(_) { ticks.update(fn(n) { n + 1 }) })),
          ),
        ],
        [text("Tick")],
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
    let show_message = @resource.signal(true)
    fragment([
      style(conditional_css),
      h("h2", [], [text("Conditional Example")]),
      h(
        "button",
        [
          ("class", attr_static("toggle")),
          (
            "onclick",
            attr_handler(
              handler(fn(_) { show_message.update(fn(b) { not(b) }) }),
            ),
          ),
        ],
        [
          text_dyn(fn() {
            if show_message.get() {
              "Hide Message"
            } else {
              "Show Message"
            }
          }),
        ],
      ),
      h(
        "div",
        [
          ("class", attr_static("message")),
          (
            "style",
            attr_dynamic(fn() {
              if show_message.get() {
                "display: block"
              } else {
                "display: none"
              }
            }),
          ),
        ],
        [text("Hello! This message is conditionally rendered.")],
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
    let hue = @resource.signal(180)
    let size = @resource.signal(100)
    fragment([
      style(style_css),
      h("h2", [], [text("Style Example")]),
      h(
        "div",
        [
          ("class", attr_static("box")),
          (
            "style",
            attr_dynamic(fn() {
              let s = size.get()
              let h = hue.get()
              "width: \{s}px; height: \{s}px; background-color: hsl(\{h}, 70%, 50%);"
            }),
          ),
        ],
        [],
      ),
      h("div", [("class", attr_static("control"))], [
        h("label", [], [text("Hue:")]),
        h(
          "input",
          [
            ("class", attr_static("hue")),
            ("type", attr_static("range")),
            ("value", attr_static("180")),
            ("min", attr_static("0")),
            ("max", attr_static("360")),
            (
              "oninput",
              attr_handler(
                handler(fn(e : @js.Any) {
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
      ]),
      h("div", [("class", attr_static("control"))], [
        h("label", [], [text("Size:")]),
        h(
          "input",
          [
            ("class", attr_static("size")),
            ("type", attr_static("range")),
            ("value", attr_static("100")),
            ("min", attr_static("50")),
            ("max", attr_static("200")),
            (
              "oninput",
              attr_handler(
                handler(fn(e : @js.Any) {
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
      ]),
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
    let todos : @resource.Signal[Array[TodoItem]] = @resource.signal([])
    let input_text = @resource.signal("")
    let next_id = @resource.signal(1)
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

    fragment([
      style(todo_css),
      h("h2", [], [text("Todo List Example")]),
      h(
        "form",
        [
          (
            "onsubmit",
            attr_handler(
              handler(fn(e : @js.Any) {
                e._call("preventDefault", []) |> ignore
                add_todo()
              }),
            ),
          ),
        ],
        [
          h(
            "input",
            [
              ("class", attr_static("todo-input")),
              ("type", attr_static("text")),
              ("placeholder", attr_static("Add a todo...")),
              ("value", attr_dynamic(fn() { input_text.get() })),
              (
                "oninput",
                attr_handler(
                  handler(fn(e : @js.Any) {
                    let value : String = e._get("target")._get("value").cast()
                    input_text.set(value)
                  }),
                ),
              ),
            ],
            [],
          ),
          h("button", [("type", attr_static("submit"))], [text("Add")]),
        ],
      ),
      h("p", [("class", attr_static("stats"))], [
        text_dyn(fn() {
          let total = todos.get().length()
          let completed = get_completed_count()
          "\{completed}/\{total} completed"
        }),
      ]),
      h("ul", [("class", attr_static("todo-list"))], [
        for_each(fn() {
          todos
          .get()
          .map(fn(item) {
            let class_name = if item.completed { "completed" } else { "" }
            let item_id = item.id
            h("li", [("class", attr_static(class_name))], [
              h(
                "span",
                [
                  ("class", attr_static("todo-text")),
                  (
                    "onclick",
                    attr_handler(handler(fn(_) { toggle_todo(item_id) })),
                  ),
                ],
                [text(item.text)],
              ),
              h(
                "button",
                [
                  ("class", attr_static("remove")),
                  (
                    "onclick",
                    attr_handler(handler(fn(_) { remove_todo(item_id) })),
                  ),
                ],
                [text("×")],
              ),
            ])
          })
        }),
      ]),
    ])
  })
}

// =============================================================================
// Child Button Component
// =============================================================================

///|
fn register_wc_child_button() -> Unit {
  @luna_api.register_shadow("wc-child-button", fn(host) {
    let click_count = @resource.signal(0)
    fragment([
      style(child_button_css),
      h(
        "button",
        [
          ("class", attr_static("child-btn")),
          (
            "onclick",
            attr_handler(
              handler(fn(_) {
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
        [text("Child Button")],
      ),
      h("div", [("class", attr_static("local-count"))], [
        text_dyn(fn() { click_count.get().to_string() }),
      ]),
    ])
  })
}

// =============================================================================
// Nested Parent Component
// =============================================================================

///|
fn register_wc_nested_parent() -> Unit {
  @luna_api.register_shadow("wc-nested-parent", fn(host) {
    let total_child_clicks = @resource.signal(0)

    // Listen for custom events from children
    add_custom_event_listener(host, "child-clicked", fn(_detail) {
      total_child_clicks.update(fn(n) { n + 1 })
    })
    fragment([
      style(nested_parent_css),
      h("div", [("class", attr_static("parent-container"))], [
        h("h3", [("class", attr_static("parent-header"))], [
          text("Parent Component"),
        ]),
        h("div", [("class", attr_static("children"))], [
          h("wc-child-button", [], []),
          h("wc-child-button", [], []),
          h("wc-child-button", [], []),
        ]),
        h("div", [("class", attr_static("stats"))], [
          text("Total clicks from children: "),
          h("span", [("class", attr_static("total-clicks"))], [
            text_dyn(fn() { total_child_clicks.get().to_string() }),
          ]),
        ]),
      ]),
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
