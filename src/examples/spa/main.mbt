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
fn counter_example() -> @luna_dom.DomNode {
  let count = @signal.signal(0)
  let doubled = @signal.memo(fn() { count.get() * 2 })
  let is_even = @signal.memo(fn() { count.get() % 2 == 0 })
  @luna_dom.div(class="counter-example", [
    @luna_dom.h2([@luna_dom.text("Counter Example")]),
    @luna_dom.p([
      @luna_dom.text_dyn(fn() { "Count: " + count.get().to_string() }),
    ]),
    @luna_dom.p([
      @luna_dom.text_dyn(fn() { "Doubled: " + doubled().to_string() }),
    ]),
    @luna_dom.p([
      @luna_dom.text_dyn(fn() { if is_even() { "Even" } else { "Odd" } }),
    ]),
    @luna_dom.div(class="buttons", [
      @luna_dom.button(
        on=@luna_dom.events().click(_ => count.update(n => n - 1)),
        [@luna_dom.text("-")],
      ),
      @luna_dom.button(
        on=@luna_dom.events().click(_ => count.update(n => n + 1)),
        [@luna_dom.text("+")],
      ),
      @luna_dom.button(on=@luna_dom.events().click(_ => count.set(0)), [
        @luna_dom.text("Reset"),
      ]),
    ]),
  ])
}

// =============================================================================
// Input Example - Two-way binding and derived state
// =============================================================================

///|
fn input_example() -> @luna_dom.DomNode {
  let text = @signal.signal("")
  let char_count = @signal.memo(fn() { text.get().length() })
  @luna_dom.div(class="input-example", [
    @luna_dom.h2([@luna_dom.text("Input Example")]),
    @luna_dom.input(
      type_="text",
      placeholder="Type something...",
      on=@luna_dom.events().input(fn(e) {
        let target : @js.Any = e.target() |> @js.identity
        let value : String = target._get("value").cast()
        text.set(value)
      }),
    ),
    @luna_dom.p([
      @luna_dom.text_dyn(fn() { "Characters: " + char_count().to_string() }),
    ]),
    @luna_dom.p([@luna_dom.text_dyn(fn() { "You typed: " + text.get() })]),
  ])
}

// =============================================================================
// Effect Example - Side effects and cleanup
// =============================================================================

///|
fn effect_example() -> @luna_dom.DomNode {
  let active = @signal.signal(false)
  let ticks = @signal.signal(0)
  let _ = @signal.effect(fn() {
    let is_active = active.get()
    console_log("Active state changed: " + is_active.to_string())
    @signal.on_cleanup(fn() { console_log("Cleaning up effect") })
  })
  @luna_dom.div(class="effect-example", [
    @luna_dom.h2([@luna_dom.text("Effect Example")]),
    @luna_dom.p([
      @luna_dom.text_dyn(fn() {
        let status = if active.get() { "Active" } else { "Inactive" }
        "Status: " + status
      }),
    ]),
    @luna_dom.p([
      @luna_dom.text_dyn(fn() { "Ticks: " + ticks.get().to_string() }),
    ]),
    @luna_dom.button(
      on=@luna_dom.events().click(_ => active.update(b => not(b))),
      [@luna_dom.text_dyn(fn() { if active.get() { "Stop" } else { "Start" } })],
    ),
    @luna_dom.button(
      on=@luna_dom.events().click(_ => ticks.update(n => n + 1)),
      [@luna_dom.text("Tick")],
    ),
  ])
}

// =============================================================================
// Conditional Example - show/hide
// =============================================================================

///|
fn conditional_example() -> @luna_dom.DomNode {
  let show_message = @signal.signal(true)
  @luna_dom.div(class="conditional-example", [
    @luna_dom.h2([@luna_dom.text("Conditional Example")]),
    @luna_dom.button(
      on=@luna_dom.events().click(_ => show_message.update(b => not(b))),
      [
        @luna_dom.text_dyn(fn() {
          if show_message.get() {
            "Hide Message"
          } else {
            "Show Message"
          }
        }),
      ],
    ),
    @luna_dom.show(fn() { show_message.get() }, fn() {
      @luna_dom.div(
        class="message",
        style="padding: 10px; background-color: #e0f7fa;",
        [@luna_dom.text("Hello! This message is conditionally rendered.")],
      )
    }),
  ])
}

// =============================================================================
// Style Example - Dynamic styles with range inputs
// =============================================================================

///|
fn style_example() -> @luna_dom.DomNode {
  let hue = @signal.signal(180)
  let size = @signal.signal(100)
  @luna_dom.div(class="style-example", [
    @luna_dom.h2([@luna_dom.text("Style Example")]),
    @luna_dom.create_element(
      "div",
      [
        (
          "style",
          @luna_dom.attr_dynamic(fn() {
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
    @luna_dom.div([
      @luna_dom.label([@luna_dom.text("Hue: ")]),
      @luna_dom.input(
        type_="range",
        value="180",
        attrs=[
          ("min", @luna_dom.Attr::AttrInt(0)),
          ("max", @luna_dom.Attr::AttrInt(360)),
        ],
        on=@luna_dom.events().input(fn(e) {
          let target : @js.Any = e.target() |> @js.identity
          let value : String = target._get("value").cast()
          match @global.parseInt(value) {
            Some(n) => hue.set(n)
            None => ()
          }
        }),
      ),
    ]),
    @luna_dom.div([
      @luna_dom.label([@luna_dom.text("Size: ")]),
      @luna_dom.input(
        type_="range",
        value="100",
        attrs=[
          ("min", @luna_dom.Attr::AttrInt(50)),
          ("max", @luna_dom.Attr::AttrInt(200)),
        ],
        on=@luna_dom.events().input(fn(e) {
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
fn todo_example() -> @luna_dom.DomNode {
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

  @luna_dom.div(class="todo-example", [
    @luna_dom.h2([@luna_dom.text("Todo List Example")]),
    @luna_dom.form(
      on=@luna_dom.events().submit(fn(e) {
        e.preventDefault()
        add_todo()
      }),
      [
        @luna_dom.input(
          type_="text",
          placeholder="Add a todo...",
          on=@luna_dom.events().input(fn(e) {
            let target : @js.Any = e.target() |> @js.identity
            input_text.set(target._get("value").cast())
          }),
        ),
        @luna_dom.create_element(
          "button",
          [("type", @luna_dom.attr_static("submit"))],
          [@luna_dom.text("Add")],
        ),
      ],
    ),
    @luna_dom.p([
      @luna_dom.text_dyn(fn() {
        completed_count().to_string() + "/" + total().to_string() + " completed"
      }),
    ]),
    @luna_dom.ul([
      @luna_dom.for_each(fn() { todos.get() }, fn(todo, _index) {
        let todo_id = todo.id
        @luna_dom.create_element(
          "li",
          [
            (
              "style",
              @luna_dom.attr_dynamic(fn() {
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
            @luna_dom.span(
              style="cursor: pointer;",
              on=@luna_dom.events().click(_ => toggle_todo(todo_id)),
              [@luna_dom.text(todo.text)],
            ),
            @luna_dom.button(
              style="margin-left: 10px;",
              on=@luna_dom.events().click(_ => remove_todo(todo_id)),
              [@luna_dom.text("x")],
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
fn to_portal_node(n : @luna_dom.DomNode) -> @portal.DomNode {
  @portal.DomNode::Raw(n.to_dom())
}

///|
/// Convert DomNode from portal to element
fn from_portal_node(n : @portal.DomNode) -> @luna_dom.DomNode {
  @luna_dom.dom_node(n.to_dom())
}

///|
fn modal_example() -> @luna_dom.DomNode {
  let is_open = @signal.signal(false)
  @luna_dom.div(class="modal-example", [
    @luna_dom.h2([@luna_dom.text("Modal Example (Portal)")]),
    @luna_dom.p([
      @luna_dom.text("Modal renders outside the component tree using Portal."),
    ]),
    @luna_dom.button(
      on=@luna_dom.events().click(_ => is_open.set(true)),
      id="open-modal-btn",
      [@luna_dom.text("Open Modal")],
    ),
    @luna_dom.show(fn() { is_open.get() }, fn() {
      // The modal content will be rendered to document.body via Portal
      let modal_content = @luna_dom.div(
        class="modal-overlay",
        style="position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; z-index: 1000;",
        id="modal-overlay",
        on=@luna_dom.events().click(fn(e) {
          // Close when clicking the overlay (not the modal content)
          let target : @js.Any = e.target() |> @js.identity
          let target_id : String = target._get("id").cast()
          if target_id == "modal-overlay" {
            is_open.set(false)
          }
        }),
        [
          @luna_dom.div(
            class="modal-content",
            style="background: white; padding: 20px; border-radius: 8px; min-width: 300px; max-width: 500px;",
            id="modal-content",
            [
              @luna_dom.h3([@luna_dom.text("Modal Title")]),
              @luna_dom.p([
                @luna_dom.text(
                  "This modal is rendered using Portal, which teleports the content to document.body. This helps avoid z-index and overflow issues.",
                ),
              ]),
              @luna_dom.button(
                on=@luna_dom.events().click(_ => is_open.set(false)),
                id="close-modal-btn",
                [@luna_dom.text("Close")],
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
  let doc = @dom.document()
  let container = doc.getElementById("app")
  match container {
    Some(el) => {
      let app = @luna_dom.div(
        class="app",
        style="padding: 20px; max-width: 800px; margin: 0 auto;",
        [
          @luna_dom.h1([@luna_dom.text("Luna Examples")]),
          @luna_dom.p([
            @luna_dom.text(
              "A collection of examples demonstrating the reactive UI library.",
            ),
          ]),
          @luna_dom.hr(),
          counter_example(),
          @luna_dom.hr(),
          input_example(),
          @luna_dom.hr(),
          effect_example(),
          @luna_dom.hr(),
          conditional_example(),
          @luna_dom.hr(),
          style_example(),
          @luna_dom.hr(),
          todo_example(),
          @luna_dom.hr(),
          modal_example(),
        ],
      )
      @luna_dom.render(el |> @luna_dom.DomElement::from_dom, app)
      console_log("App rendered successfully!")
    }
    None => console_log("ERROR: Could not find #app container")
  }
}
