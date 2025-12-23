// SPA Sample Application demonstrating Luna features
//
// This file serves as a comprehensive example showing:
// - Signal basics (signal, get, set, update)
// - Effects and cleanup (effect, on_cleanup)
// - Computed values (memo, combine)
// - DOM elements and attributes
// - Event handlers
// - Reactive text and attributes
// - Conditional rendering (show)
// - List rendering (for_each)
//

///|
/// Console logging helper
fn console_log(msg : String) -> Unit {
  let global = @global.global_this()
  global["console"]._call("log", [@js.any(msg)]) |> ignore
}

// =============================================================================
// Counter Example - Basic signals and events
// =============================================================================

///|
fn counter_example() -> @dom.DomNode {
  let count = @signal.signal(0)
  let doubled = @signal.memo(fn() { count.get() * 2 })
  let is_even = @signal.memo(fn() { count.get() % 2 == 0 })
  @dom.div(class="counter-example", [
    @dom.h2([@dom.text("Counter Example")]),
    @dom.p([@dom.text_dyn(fn() { "Count: " + count.get().to_string() })]),
    @dom.p([@dom.text_dyn(fn() { "Doubled: " + doubled().to_string() })]),
    @dom.p([@dom.text_dyn(fn() { if is_even() { "Even" } else { "Odd" } })]),
    @dom.div(class="buttons", [
      @dom.button(on=@dom.events().click(_ => count.update(n => n - 1)), [
        @dom.text("-"),
      ]),
      @dom.button(on=@dom.events().click(_ => count.update(n => n + 1)), [
        @dom.text("+"),
      ]),
      @dom.button(on=@dom.events().click(_ => count.set(0)), [
        @dom.text("Reset"),
      ]),
    ]),
  ])
}

// =============================================================================
// Input Example - Two-way binding and derived state
// =============================================================================

///|
fn input_example() -> @dom.DomNode {
  let text = @signal.signal("")
  let char_count = @signal.memo(fn() { text.get().length() })
  @dom.div(class="input-example", [
    @dom.h2([@dom.text("Input Example")]),
    @dom.input(
      type_="text",
      placeholder="Type something...",
      on=@dom.events().input(fn(e) {
        let target : @js.Any = e.target() |> @js.identity
        let value : String = target._get("value").cast()
        text.set(value)
      }),
    ),
    @dom.p([@dom.text_dyn(fn() { "Characters: " + char_count().to_string() })]),
    @dom.p([@dom.text_dyn(fn() { "You typed: " + text.get() })]),
  ])
}

// =============================================================================
// Effect Example - Side effects and cleanup
// =============================================================================

///|
fn effect_example() -> @dom.DomNode {
  let active = @signal.signal(false)
  let ticks = @signal.signal(0)
  let _ = @signal.effect(fn() {
    let is_active = active.get()
    console_log("Active state changed: " + is_active.to_string())
    @signal.on_cleanup(fn() { console_log("Cleaning up effect") })
  })
  @dom.div(class="effect-example", [
    @dom.h2([@dom.text("Effect Example")]),
    @dom.p([
      @dom.text_dyn(fn() {
        let status = if active.get() { "Active" } else { "Inactive" }
        "Status: " + status
      }),
    ]),
    @dom.p([@dom.text_dyn(fn() { "Ticks: " + ticks.get().to_string() })]),
    @dom.button(on=@dom.events().click(_ => active.update(b => not(b))), [
      @dom.text_dyn(fn() { if active.get() { "Stop" } else { "Start" } }),
    ]),
    @dom.button(on=@dom.events().click(_ => ticks.update(n => n + 1)), [
      @dom.text("Tick"),
    ]),
  ])
}

// =============================================================================
// Conditional Example - show/hide
// =============================================================================

///|
fn conditional_example() -> @dom.DomNode {
  let show_message = @signal.signal(true)
  @dom.div(class="conditional-example", [
    @dom.h2([@dom.text("Conditional Example")]),
    @dom.button(on=@dom.events().click(_ => show_message.update(b => not(b))), [
      @dom.text_dyn(fn() {
        if show_message.get() {
          "Hide Message"
        } else {
          "Show Message"
        }
      }),
    ]),
    @dom.show(fn() { show_message.get() }, fn() {
      @dom.div(
        class="message",
        style="padding: 10px; background-color: #e0f7fa;",
        [@dom.text("Hello! This message is conditionally rendered.")],
      )
    }),
  ])
}

// =============================================================================
// Style Example - Dynamic styles with range inputs
// =============================================================================

///|
fn style_example() -> @dom.DomNode {
  let hue = @signal.signal(180)
  let size = @signal.signal(100)
  @dom.div(class="style-example", [
    @dom.h2([@dom.text("Style Example")]),
    @dom.create_element(
      "div",
      [
        (
          "style",
          @dom.attr_dynamic(fn() {
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
    @dom.div([
      @dom.label([@dom.text("Hue: ")]),
      @dom.input(
        type_="range",
        value="180",
        attrs=[("min", @dom.Attr::AttrInt(0)), ("max", @dom.Attr::AttrInt(360))],
        on=@dom.events().input(fn(e) {
          let target : @js.Any = e.target() |> @js.identity
          let value : String = target._get("value").cast()
          match @global.parseInt(value) {
            Some(n) => hue.set(n)
            None => ()
          }
        }),
      ),
    ]),
    @dom.div([
      @dom.label([@dom.text("Size: ")]),
      @dom.input(
        type_="range",
        value="100",
        attrs=[
          ("min", @dom.Attr::AttrInt(50)),
          ("max", @dom.Attr::AttrInt(200)),
        ],
        on=@dom.events().input(fn(e) {
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
fn todo_example() -> @dom.DomNode {
  let todos : @signal.Signal[Array[TodoItem]] = @signal.signal([])
  let input_text = @signal.signal("")
  let next_id = @signal.signal(1)
  let total = @signal.memo(fn() { todos.get().length() })
  let completed_count = @signal.memo(fn() {
    todos.get().filter(fn(item) { item.completed }).length()
  })
  fn add_todo() -> Unit {
    let text = input_text.get()
    if text != "" {
      let id = next_id.get()
      next_id.set(id + 1)
      todos.update(fn(items) {
        let new_items = items.copy()
        new_items.push({ id, text, completed: false })
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

  @dom.div(class="todo-example", [
    @dom.h2([@dom.text("Todo List Example")]),
    @dom.form(
      on=@dom.events().submit(fn(e) {
        e.preventDefault()
        add_todo()
      }),
      [
        @dom.input(
          type_="text",
          placeholder="Add a todo...",
          on=@dom.events().input(fn(e) {
            let target : @js.Any = e.target() |> @js.identity
            input_text.set(target._get("value").cast())
          }),
        ),
        @dom.create_element("button", [("type", @dom.attr_static("submit"))], [
          @dom.text("Add"),
        ]),
      ],
    ),
    @dom.p([
      @dom.text_dyn(fn() {
        completed_count().to_string() + "/" + total().to_string() + " completed"
      }),
    ]),
    @dom.ul([
      @dom.for_each(fn() { todos.get() }, fn(todo, _index) {
        let todo_id = todo.id
        @dom.create_element(
          "li",
          [
            (
              "style",
              @dom.attr_dynamic(fn() {
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
            @dom.span(
              style="cursor: pointer;",
              on=@dom.events().click(_ => toggle_todo(todo_id)),
              [@dom.text(todo.text)],
            ),
            @dom.button(
              style="margin-left: 10px;",
              on=@dom.events().click(_ => remove_todo(todo_id)),
              [@dom.text("x")],
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
/// Convert DomNode from element to portal
fn to_portal_node(n : @dom.DomNode) -> @portal.DomNode {
  @portal.DomNode::Raw(n.to_jsdom())
}

///|
/// Convert DomNode from portal to element
fn from_portal_node(n : @portal.DomNode) -> @dom.DomNode {
  @dom.dom_node(n.to_jsdom())
}

///|
fn modal_example() -> @dom.DomNode {
  let is_open = @signal.signal(false)
  @dom.div(class="modal-example", [
    @dom.h2([@dom.text("Modal Example (Portal)")]),
    @dom.p([@dom.text("Modal renders outside the component tree using Portal.")]),
    @dom.button(
      on=@dom.events().click(_ => is_open.set(true)),
      id="open-modal-btn",
      [@dom.text("Open Modal")],
    ),
    @dom.show(fn() { is_open.get() }, fn() {
      // The modal content will be rendered to document.body via Portal
      let modal_content = @dom.div(
        class="modal-overlay",
        style="position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; z-index: 1000;",
        id="modal-overlay",
        on=@dom.events().click(fn(e) {
          // Close when clicking the overlay (not the modal content)
          let target : @js.Any = e.target() |> @js.identity
          let target_id : String = target._get("id").cast()
          if target_id == "modal-overlay" {
            is_open.set(false)
          }
        }),
        [
          @dom.div(
            class="modal-content",
            style="background: white; padding: 20px; border-radius: 8px; min-width: 300px; max-width: 500px;",
            id="modal-content",
            [
              @dom.h3([@dom.text("Modal Title")]),
              @dom.p([
                @dom.text(
                  "This modal is rendered using Portal, which teleports the content to document.body. This helps avoid z-index and overflow issues.",
                ),
              ]),
              @dom.button(
                on=@dom.events().click(_ => is_open.set(false)),
                id="close-modal-btn",
                [@dom.text("Close")],
              ),
            ],
          ),
        ],
      )
      from_portal_node(@portal.portal_to_body([to_portal_node(modal_content)]))
    }),
  ])
}

// =============================================================================
// Main Application
// =============================================================================

///|
/// Main function - renders the sample app
fn main {
  console_log("Luna SPA Sample Application")
  console_log("==============================")
  let doc = @js_dom.document()
  let container = doc.getElementById("app")
  match container {
    Some(el) => {
      let app = @dom.div(
        class="app",
        style="padding: 20px; max-width: 800px; margin: 0 auto;",
        [
          @dom.h1([@dom.text("Luna Examples")]),
          @dom.p([
            @dom.text(
              "A collection of examples demonstrating the reactive UI library.",
            ),
          ]),
          @dom.hr(),
          counter_example(),
          @dom.hr(),
          input_example(),
          @dom.hr(),
          effect_example(),
          @dom.hr(),
          conditional_example(),
          @dom.hr(),
          style_example(),
          @dom.hr(),
          todo_example(),
          @dom.hr(),
          modal_example(),
        ],
      )
      @dom.render(el |> @dom.DomElement::from_jsdom, app)
      console_log("App rendered successfully!")
    }
    None => console_log("ERROR: Could not find #app container")
  }
}
