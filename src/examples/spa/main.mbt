///|
/// SPA Sample Application demonstrating Luna features
///
/// This file serves as a comprehensive example showing:
/// - Signal basics (signal, get, set, update)
/// - Effects and cleanup (effect, on_cleanup)
/// - Computed values (memo)
/// - DOM elements and attributes
/// - Event handlers
/// - Reactive text and attributes
/// - Conditional rendering (show)
/// - List rendering (for_each)

///|
using @element {
  div,
  p,
  span,
  button,
  input,
  form,
  label,
  ul,
  h1,
  h2,
  h3,
  hr,
  text,
  text_dyn,
  show,
  for_each,
  render,
  events,
  create_element,
  attr_static,
  attr_dynamic,
  dom_node,
  type DomNode,
  type DomElement,
  type Attr,
}

///|
using @signal {signal, memo, effect, on_cleanup}

///|
using @portal {portal_to_body}

///|
fn console_log(msg : String) -> Unit {
  let global = @global.global_this()
  global["console"]._call("log", [@js.any(msg)]) |> ignore
}

// =============================================================================
// Counter Example - Basic signals and events
// =============================================================================

///|
fn counter_example() -> DomNode {
  let count = signal(0)
  let doubled = memo(fn() { count.get() * 2 })
  let is_even = memo(fn() { count.get() % 2 == 0 })
  div(class="counter-example", [
    h2([text("Counter Example")]),
    p([text_dyn(fn() { "Count: " + count.get().to_string() })]),
    p([text_dyn(fn() { "Doubled: " + doubled().to_string() })]),
    p([text_dyn(fn() { if is_even() { "Even" } else { "Odd" } })]),
    div(class="buttons", [
      button(on=events().click(_ => count.update(n => n - 1)), [text("-")]),
      button(on=events().click(_ => count.update(n => n + 1)), [text("+")]),
      button(on=events().click(_ => count.set(0)), [text("Reset")]),
    ]),
  ])
}

// =============================================================================
// Input Example - Two-way binding and derived state
// =============================================================================

///|
fn input_example() -> DomNode {
  let txt = signal("")
  let char_count = memo(fn() { txt.get().length() })
  div(class="input-example", [
    h2([text("Input Example")]),
    input(
      type_="text",
      placeholder="Type something...",
      on=events().input(fn(e) {
        let target : @js.Any = e.target() |> @js.identity
        let value : String = target._get("value").cast()
        txt.set(value)
      }),
    ),
    p([text_dyn(fn() { "Characters: " + char_count().to_string() })]),
    p([text_dyn(fn() { "You typed: " + txt.get() })]),
  ])
}

// =============================================================================
// Effect Example - Side effects and cleanup
// =============================================================================

///|
fn effect_example() -> DomNode {
  let active = signal(false)
  let ticks = signal(0)
  let _ = effect(fn() {
    let is_active = active.get()
    console_log("Active state changed: " + is_active.to_string())
    on_cleanup(fn() { console_log("Cleaning up effect") })
  })
  div(class="effect-example", [
    h2([text("Effect Example")]),
    p([
      text_dyn(fn() {
        let status = if active.get() { "Active" } else { "Inactive" }
        "Status: " + status
      }),
    ]),
    p([text_dyn(fn() { "Ticks: " + ticks.get().to_string() })]),
    button(on=events().click(_ => active.update(b => not(b))), [
      text_dyn(fn() { if active.get() { "Stop" } else { "Start" } }),
    ]),
    button(on=events().click(_ => ticks.update(n => n + 1)), [text("Tick")]),
  ])
}

// =============================================================================
// Conditional Example - show/hide
// =============================================================================

///|
fn conditional_example() -> DomNode {
  let show_message = signal(true)
  div(class="conditional-example", [
    h2([text("Conditional Example")]),
    button(on=events().click(_ => show_message.update(b => not(b))), [
      text_dyn(fn() {
        if show_message.get() {
          "Hide Message"
        } else {
          "Show Message"
        }
      }),
    ]),
    show(fn() { show_message.get() }, fn() {
      div(class="message", style="padding: 10px; background-color: #e0f7fa;", [
        text("Hello! This message is conditionally rendered."),
      ])
    }),
  ])
}

// =============================================================================
// Style Example - Dynamic styles with range inputs
// =============================================================================

///|
fn style_example() -> DomNode {
  let hue = signal(180)
  let size = signal(100)
  div(class="style-example", [
    h2([text("Style Example")]),
    create_element(
      "div",
      [
        (
          "style",
          attr_dynamic(fn() {
            "width: " +
            size.get().to_string() +
            "px; height: " +
            size.get().to_string() +
            "px; background-color: hsl(" +
            hue.get().to_string() +
            ", 70%, 50%); transition: all 0.3s ease; border-radius: 8px;"
          }),
        ),
      ],
      [],
    ),
    div([
      label([text("Hue: ")]),
      input(
        type_="range",
        value="180",
        attrs=[("min", Attr::AttrInt(0)), ("max", Attr::AttrInt(360))],
        on=events().input(fn(e) {
          let target : @js.Any = e.target() |> @js.identity
          let value : String = target._get("value").cast()
          match @global.parseInt(value) {
            Some(n) => hue.set(n)
            None => ()
          }
        }),
      ),
    ]),
    div([
      label([text("Size: ")]),
      input(
        type_="range",
        value="100",
        attrs=[("min", Attr::AttrInt(50)), ("max", Attr::AttrInt(200))],
        on=events().input(fn(e) {
          let target : @js.Any = e.target() |> @js.identity
          let value : String = target._get("value").cast()
          match @global.parseInt(value) {
            Some(n) => size.set(n)
            None => ()
          }
        }),
      ),
    ]),
  ])
}

// =============================================================================
// Todo List Example - Practical application with for_each
// =============================================================================

///|
priv struct TodoItem {
  id : Int
  text : String
  completed : Bool
}

///|
fn todo_example() -> DomNode {
  let todos : @signal.Signal[Array[TodoItem]] = signal([])
  let input_text = signal("")
  let next_id = signal(1)
  let total = memo(fn() { todos.get().length() })
  let completed_count = memo(fn() {
    todos.get().filter(fn(item) { item.completed }).length()
  })
  fn add_todo() -> Unit {
    let txt = input_text.get()
    if txt != "" {
      let id = next_id.get()
      next_id.set(id + 1)
      todos.update(fn(items) {
        let new_items = items.copy()
        new_items.push({ id, text: txt, completed: false })
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

  div(class="todo-example", [
    h2([text("Todo List Example")]),
    form(
      on=events().submit(fn(e) {
        e.preventDefault()
        add_todo()
      }),
      [
        input(
          type_="text",
          placeholder="Add a todo...",
          on=events().input(fn(e) {
            let target : @js.Any = e.target() |> @js.identity
            input_text.set(target._get("value").cast())
          }),
        ),
        create_element("button", [("type", attr_static("submit"))], [
          text("Add"),
        ]),
      ],
    ),
    p([
      text_dyn(fn() {
        completed_count().to_string() + "/" + total().to_string() + " completed"
      }),
    ]),
    ul([
      for_each(fn() { todos.get() }, fn(todo, _index) {
        let todo_id = todo.id
        create_element(
          "li",
          [
            (
              "style",
              attr_dynamic(fn() {
                let is_completed = todos
                  .get()
                  .iter()
                  .any(fn(item) { item.id == todo_id && item.completed })
                if is_completed {
                  "text-decoration: line-through; opacity: 0.6;"
                } else {
                  "text-decoration: none; opacity: 1;"
                }
              }),
            ),
          ],
          [
            span(
              style="cursor: pointer;",
              on=events().click(_ => toggle_todo(todo_id)),
              [text(todo.text)],
            ),
            button(
              style="margin-left: 10px;",
              on=events().click(_ => remove_todo(todo_id)),
              [text("x")],
            ),
          ],
        )
      }),
    ]),
  ])
}

// =============================================================================
// Modal Example - Portal for rendering outside component tree
// =============================================================================

///|
fn to_portal_node(n : DomNode) -> @portal.DomNode {
  @portal.DomNode::Raw(n.to_dom())
}

///|
fn from_portal_node(n : @portal.DomNode) -> DomNode {
  dom_node(n.to_dom())
}

///|
fn modal_example() -> DomNode {
  let is_open = signal(false)
  div(class="modal-example", [
    h2([text("Modal Example (Portal)")]),
    p([text("Modal renders outside the component tree using Portal.")]),
    button(on=events().click(_ => is_open.set(true)), id="open-modal-btn", [
      text("Open Modal"),
    ]),
    show(fn() { is_open.get() }, fn() {
      let modal_content = div(
        class="modal-overlay",
        style="position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; z-index: 1000;",
        id="modal-overlay",
        on=events().click(fn(e) {
          let target : @js.Any = e.target() |> @js.identity
          let target_id : String = target._get("id").cast()
          if target_id == "modal-overlay" {
            is_open.set(false)
          }
        }),
        [
          div(
            class="modal-content",
            style="background: white; padding: 20px; border-radius: 8px; min-width: 300px; max-width: 500px;",
            id="modal-content",
            [
              h3([text("Modal Title")]),
              p([
                text(
                  "This modal is rendered using Portal, which teleports the content to document.body. This helps avoid z-index and overflow issues.",
                ),
              ]),
              button(
                on=events().click(_ => is_open.set(false)),
                id="close-modal-btn",
                [text("Close")],
              ),
            ],
          ),
        ],
      )
      from_portal_node(portal_to_body([to_portal_node(modal_content)]))
    }),
  ])
}

// =============================================================================
// Main Application
// =============================================================================

///|
fn main {
  console_log("Luna SPA Sample Application")
  console_log("==============================")
  let doc = @dom.document()
  match doc.getElementById("app") {
    Some(el) => {
      let app = div(
        class="app",
        style="padding: 20px; max-width: 800px; margin: 0 auto;",
        [
          h1([text("Luna Examples")]),
          p([
            text(
              "A collection of examples demonstrating the reactive UI library.",
            ),
          ]),
          hr(),
          counter_example(),
          hr(),
          input_example(),
          hr(),
          effect_example(),
          hr(),
          conditional_example(),
          hr(),
          style_example(),
          hr(),
          todo_example(),
          hr(),
          modal_example(),
        ],
      )
      render(el |> DomElement::from_dom, app)
      console_log("App rendered successfully!")
    }
    None => console_log("ERROR: Could not find #app container")
  }
}
