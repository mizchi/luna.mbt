///| Sample Application demonstrating @mizchi/ui features
///|
///| This file serves as a comprehensive example showing:
///| - Signal basics (signal, get, set, update)
///| - Effects and cleanup (effect, on_cleanup)
///| - Computed values (memo, combine)
///| - Owner system (create_root)
///| - Batching (batch)
///| - DOM elements and attributes
///| - Event handlers with typed events
///| - Reactive text and attributes
///| - Conditional rendering (show)

///|
/// Console logging helper
fn console_log(msg : String) -> Unit {
  let global = @global.global_this()
  global["console"]._call("log", [@core.any(msg)]) |> ignore
}

// =============================================================================
// Counter Example - Basic signals and events
// =============================================================================

///|
fn counter_example() -> @dom.Node {
  // Create a signal for count state
  let count = @signal.signal(0)

  // Create computed values
  let doubled = @signal.memo(fn() { count.get() * 2 })
  let is_even = @signal.memo(fn() { count.get() % 2 == 0 })

  // Create the UI
  @dom.div(
    [@dom.class("counter-example")],
    [
      @dom.h2([], [@dom.text("Counter Example")]),
      // Display count with reactive text
      @dom.p([], [@dom.text_dyn(fn() { "Count: " + count.get().to_string() })]),
      @dom.p([], [@dom.text_dyn(fn() { "Doubled: " + doubled().to_string() })]),
      @dom.p([], [
        @dom.text_dyn(fn() {
          if is_even() {
            "Even"
          } else {
            "Odd"
          }
        }),
      ]),
      // Buttons with typed click handlers
      @dom.div(
        [@dom.class("buttons")],
        [
          @dom.button(
            [
              @dom.on_click(fn(_e : @js_dom.MouseEvent) {
                count.update(fn(n) { n - 1 })
              }),
            ],
            [@dom.text("-")],
          ),
          @dom.button(
            [
              @dom.on_click(fn(_e : @js_dom.MouseEvent) {
                count.update(fn(n) { n + 1 })
              }),
            ],
            [@dom.text("+")],
          ),
          @dom.button(
            [@dom.on_click(fn(_e : @js_dom.MouseEvent) { count.set(0) })],
            [@dom.text("Reset")],
          ),
        ],
      ),
    ],
  )
}

// =============================================================================
// Input Example - Two-way binding and derived state
// =============================================================================

///|
fn input_example() -> @dom.Node {
  let text = @signal.signal("")
  let char_count = @signal.memo(fn() { text.get().length() })

  @dom.div(
    [@dom.class("input-example")],
    [
      @dom.h2([], [@dom.text("Input Example")]),
      @dom.input([
        @dom.type_("text"),
        @dom.placeholder("Type something..."),
        @dom.value_dyn(fn() { text.get() }),
        @dom.on_input(fn(e : @js_dom.InputEvent) {
          let target : @core.Any = e.target() |> @core.identity
          let value : String = target._get("value").cast()
          text.set(value)
        }),
      ]),
      @dom.p([], [
        @dom.text_dyn(fn() { "Characters: " + char_count().to_string() }),
      ]),
      @dom.p([], [@dom.text_dyn(fn() { "You typed: " + text.get() })]),
    ],
  )
}

// =============================================================================
// Effect Example - Side effects and cleanup
// =============================================================================

///|
fn effect_example() -> @dom.Node {
  let active = @signal.signal(false)
  let ticks = @signal.signal(0)

  // Effect that logs on change
  let _ = @signal.effect(fn() {
    let is_active = active.get()
    console_log("Active state changed: " + is_active.to_string())
    // Register cleanup for this effect
    @signal.on_cleanup(fn() { console_log("Cleaning up effect") })
  })

  @dom.div(
    [@dom.class("effect-example")],
    [
      @dom.h2([], [@dom.text("Effect Example")]),
      @dom.p([], [
        @dom.text_dyn(fn() {
          let status = if active.get() { "Active" } else { "Inactive" }
          "Status: " + status
        }),
      ]),
      @dom.p([], [
        @dom.text_dyn(fn() { "Ticks: " + ticks.get().to_string() }),
      ]),
      @dom.button(
        [
          @dom.on_click(fn(_e : @js_dom.MouseEvent) {
            active.update(fn(b) { not(b) })
          }),
        ],
        [
          @dom.text_dyn(fn() {
            if active.get() {
              "Stop"
            } else {
              "Start"
            }
          }),
        ],
      ),
      @dom.button(
        [
          @dom.on_click(fn(_e : @js_dom.MouseEvent) {
            ticks.update(fn(n) { n + 1 })
          }),
        ],
        [@dom.text("Tick")],
      ),
    ],
  )
}

// =============================================================================
// Batch Example - Batched updates
// =============================================================================

///|
fn batch_example() -> @dom.Node {
  let a = @signal.signal(0)
  let b = @signal.signal(0)
  let update_count = @signal.signal(0)

  // Effect that counts updates
  let _ = @signal.effect(fn() {
    let _ = a.get()
    let _ = b.get()
    update_count.update(fn(n) { n + 1 })
  })

  @dom.div(
    [@dom.class("batch-example")],
    [
      @dom.h2([], [@dom.text("Batch Example")]),
      @dom.p([], [
        @dom.text_dyn(fn() {
          "a=" + a.get().to_string() + ", b=" + b.get().to_string()
        }),
      ]),
      @dom.p([], [
        @dom.text_dyn(fn() {
          "Effect ran: " + update_count.get().to_string() + " times"
        }),
      ]),
      @dom.div(
        [@dom.class("buttons")],
        [
          @dom.button(
            [
              @dom.on_click(fn(_e : @js_dom.MouseEvent) {
                // Without batch - effect runs twice
                a.update(fn(n) { n + 1 })
                b.update(fn(n) { n + 1 })
              }),
            ],
            [@dom.text("Update (no batch)")],
          ),
          @dom.button(
            [
              @dom.on_click(fn(_e : @js_dom.MouseEvent) {
                // With batch - effect runs once
                @signal.batch(fn() {
                  a.update(fn(n) { n + 1 })
                  b.update(fn(n) { n + 1 })
                })
              }),
            ],
            [@dom.text("Update (batched)")],
          ),
        ],
      ),
    ],
  )
}

// =============================================================================
// Combine Example - Combining multiple signals
// =============================================================================

///|
fn combine_example() -> @dom.Node {
  let first_name = @signal.signal("John")
  let last_name = @signal.signal("Doe")

  // Combine two signals
  let full_name = @signal.combine2(first_name, last_name, fn(f, l) { f + " " + l })

  @dom.div(
    [@dom.class("combine-example")],
    [
      @dom.h2([], [@dom.text("Combine Example")]),
      @dom.div(
        [],
        [
          @dom.label([], [@dom.text("First Name: ")]),
          @dom.input([
            @dom.type_("text"),
            @dom.value_dyn(fn() { first_name.get() }),
            @dom.on_input(fn(e : @js_dom.InputEvent) {
              let target : @core.Any = e.target() |> @core.identity
              first_name.set(target._get("value").cast())
            }),
          ]),
        ],
      ),
      @dom.div(
        [],
        [
          @dom.label([], [@dom.text("Last Name: ")]),
          @dom.input([
            @dom.type_("text"),
            @dom.value_dyn(fn() { last_name.get() }),
            @dom.on_input(fn(e : @js_dom.InputEvent) {
              let target : @core.Any = e.target() |> @core.identity
              last_name.set(target._get("value").cast())
            }),
          ]),
        ],
      ),
      @dom.p([], [@dom.text_dyn(fn() { "Full Name: " + full_name() })]),
    ],
  )
}

// =============================================================================
// Style Example - Dynamic styles
// =============================================================================

///|
fn style_example() -> @dom.Node {
  let hue = @signal.signal(180)
  let size = @signal.signal(100)

  @dom.div(
    [@dom.class("style-example")],
    [
      @dom.h2([], [@dom.text("Style Example")]),
      @dom.div(
        [
          @dom.style_dyn(fn() {
            [
              ("width", size.get().to_string() + "px"),
              ("height", size.get().to_string() + "px"),
              (
                "backgroundColor",
                "hsl(" + hue.get().to_string() + ", 70%, 50%)",
              ),
              ("transition", "all 0.3s ease"),
              ("borderRadius", "8px"),
            ]
          }),
        ],
        [],
      ),
      @dom.div(
        [],
        [
          @dom.label([], [@dom.text("Hue: ")]),
          @dom.input([
            @dom.type_("range"),
            @dom.attr("min", "0"),
            @dom.attr("max", "360"),
            @dom.value_dyn(fn() { hue.get().to_string() }),
            @dom.on_input(fn(e : @js_dom.InputEvent) {
              let target : @core.Any = e.target() |> @core.identity
              let value : String = target._get("value").cast()
              match @global.parseInt(value) {
                Some(n) => hue.set(n)
                None => ()
              }
            }),
          ]),
        ],
      ),
      @dom.div(
        [],
        [
          @dom.label([], [@dom.text("Size: ")]),
          @dom.input([
            @dom.type_("range"),
            @dom.attr("min", "50"),
            @dom.attr("max", "200"),
            @dom.value_dyn(fn() { size.get().to_string() }),
            @dom.on_input(fn(e : @js_dom.InputEvent) {
              let target : @core.Any = e.target() |> @core.identity
              let value : String = target._get("value").cast()
              match @global.parseInt(value) {
                Some(n) => size.set(n)
                None => ()
              }
            }),
          ]),
        ],
      ),
    ],
  )
}

// =============================================================================
// Conditional Example - show/hide
// =============================================================================

///|
fn conditional_example() -> @dom.Node {
  let show_message = @signal.signal(true)

  @dom.div(
    [@dom.class("conditional-example")],
    [
      @dom.h2([], [@dom.text("Conditional Example")]),
      @dom.button(
        [
          @dom.on_click(fn(_e : @js_dom.MouseEvent) {
            show_message.update(fn(b) { not(b) })
          }),
        ],
        [
          @dom.text_dyn(fn() {
            if show_message.get() {
              "Hide Message"
            } else {
              "Show Message"
            }
          }),
        ],
      ),
      @dom.show(
        fn() { show_message.get() },
        fn() {
          @dom.div(
            [
              @dom.class("message"),
              @dom.style([("padding", "10px"), ("backgroundColor", "#e0f7fa")]),
            ],
            [@dom.text("Hello! This message is conditionally rendered.")],
          )
        },
      ),
    ],
  )
}

// =============================================================================
// Owner Example - Scoped cleanup with create_root
// =============================================================================

///|
fn owner_example() -> @dom.Node {
  let log_messages = @signal.signal("")

  fn add_log(msg : String) -> Unit {
    log_messages.update(fn(current) {
      if current == "" {
        msg
      } else {
        current + "\n" + msg
      }
    })
  }

  @dom.div(
    [@dom.class("owner-example")],
    [
      @dom.h2([], [@dom.text("Owner Example")]),
      @dom.p([], [
        @dom.text("Click to create a scoped reactive context that auto-disposes"),
      ]),
      @dom.button(
        [
          @dom.on_click(fn(_e : @js_dom.MouseEvent) {
            add_log("Creating root...")
            @signal.create_root(fn(dispose) {
              add_log("Inside root - setting up effect")
              let counter = @signal.signal(0)
              let _ = @signal.effect(fn() {
                let val = counter.get()
                add_log("Effect: counter = " + val.to_string())
              })
              // Simulate some updates
              counter.set(1)
              counter.set(2)
              // Dispose to clean up all effects
              add_log("Disposing root...")
              dispose()
              // This won't trigger the effect
              counter.set(3)
              add_log("Set counter to 3 (after dispose)")
            })
          }),
        ],
        [@dom.text("Run Owner Demo")],
      ),
      @dom.button(
        [@dom.on_click(fn(_e : @js_dom.MouseEvent) { log_messages.set("") })],
        [@dom.text("Clear Log")],
      ),
      @dom.div(
        [
          @dom.style([
            ("whiteSpace", "pre-wrap"),
            ("fontFamily", "monospace"),
            ("padding", "10px"),
            ("backgroundColor", "#f5f5f5"),
            ("minHeight", "100px"),
          ]),
        ],
        [@dom.text_dyn(fn() { log_messages.get() })],
      ),
    ],
  )
}

// =============================================================================
// Todo List Example - Practical application
// =============================================================================

///|
priv struct TodoItem {
  id : Int
  text : String
  completed : Bool
}

///|
fn todo_example() -> @dom.Node {
  let todos : @signal.Signal[Array[TodoItem]] = @signal.signal([])
  let input_text = @signal.signal("")
  let next_id = @signal.signal(1)

  // Computed stats
  let total = @signal.memo(fn() { todos.get().length() })
  let completed_count = @signal.memo(fn() {
    let items = todos.get()
    let mut count = 0
    for i = 0; i < items.length(); i = i + 1 {
      if items[i].completed {
        count = count + 1
      }
    }
    count
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
      let new_items : Array[TodoItem] = []
      for i = 0; i < items.length(); i = i + 1 {
        let item = items[i]
        if item.id == id {
          new_items.push({ ..item, completed: not(item.completed) })
        } else {
          new_items.push(item)
        }
      }
      new_items
    })
  }

  fn remove_todo(id : Int) -> Unit {
    todos.update(fn(items) {
      let new_items : Array[TodoItem] = []
      for i = 0; i < items.length(); i = i + 1 {
        if items[i].id != id {
          new_items.push(items[i])
        }
      }
      new_items
    })
  }

  @dom.div(
    [@dom.class("todo-example")],
    [
      @dom.h2([], [@dom.text("Todo List Example")]),
      // Input form
      @dom.form(
        [
          @dom.on_submit(fn(e : @js_dom.FormEvent) {
            e.preventDefault()
            add_todo()
          }),
        ],
        [
          @dom.input([
            @dom.type_("text"),
            @dom.placeholder("Add a todo..."),
            @dom.value_dyn(fn() { input_text.get() }),
            @dom.on_input(fn(e : @js_dom.InputEvent) {
              let target : @core.Any = e.target() |> @core.identity
              input_text.set(target._get("value").cast())
            }),
          ]),
          @dom.button([@dom.type_("submit")], [@dom.text("Add")]),
        ],
      ),
      // Stats
      @dom.p([], [
        @dom.text_dyn(fn() {
          completed_count().to_string() +
          "/" +
          total().to_string() +
          " completed"
        }),
      ]),
      // Todo list
      @dom.ul(
        [],
        [
          @dom.for_each(
            fn() { todos.get() },
            fn(todo, _index) {
              let todo_id = todo.id
              @dom.li(
                [
                  @dom.style_dyn(fn() {
                    let items = todos.get()
                    let mut is_completed = false
                    for i = 0; i < items.length(); i = i + 1 {
                      if items[i].id == todo_id && items[i].completed {
                        is_completed = true
                        break
                      }
                    }
                    if is_completed {
                      [("textDecoration", "line-through"), ("opacity", "0.6")]
                    } else {
                      [("textDecoration", "none"), ("opacity", "1")]
                    }
                  }),
                ],
                [
                  @dom.span(
                    [
                      @dom.on_click(fn(_e : @js_dom.MouseEvent) {
                        toggle_todo(todo_id)
                      }),
                      @dom.style([("cursor", "pointer")]),
                    ],
                    [@dom.text(todo.text)],
                  ),
                  @dom.button(
                    [
                      @dom.on_click(fn(_e : @js_dom.MouseEvent) {
                        remove_todo(todo_id)
                      }),
                      @dom.style([("marginLeft", "10px")]),
                    ],
                    [@dom.text("x")],
                  ),
                ],
              )
            },
          ),
        ],
      ),
    ],
  )
}

// =============================================================================
// Main Application
// =============================================================================

///|
/// Main function - renders the sample app
fn main {
  console_log("@mizchi/ui Sample Application")
  console_log("==============================")

  // Get the app container from document
  let doc = @js_dom.document()
  let container = doc.getElementById("app")
  match container {
    Some(el) => {
      // Build the main app
      let app = @dom.div(
        [
          @dom.class("app"),
          @dom.style([
            ("padding", "20px"),
            ("maxWidth", "800px"),
            ("margin", "0 auto"),
          ]),
        ],
        [
          @dom.h1([], [@dom.text("@mizchi/ui Examples")]),
          @dom.p([], [
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
          batch_example(),
          @dom.hr(),
          combine_example(),
          @dom.hr(),
          style_example(),
          @dom.hr(),
          conditional_example(),
          @dom.hr(),
          owner_example(),
          @dom.hr(),
          todo_example(),
        ],
      )
      @dom.render(el |> @dom.Element::from_jsdom, app)
      console_log("App rendered successfully!")
    }
    None => console_log("ERROR: Could not find #app container")
  }
}
