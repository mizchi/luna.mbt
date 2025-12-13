///| SPA Sample Application demonstrating Luna features

///|

///| This file serves as a comprehensive example showing:

///| - Signal basics (signal, get, set, update)

///| - Effects and cleanup (effect, on_cleanup)

///| - Computed values (memo, combine)

///| - DOM elements and attributes

///| - Event handlers

///| - Reactive text and attributes

///| - Conditional rendering (show)

///| - List rendering (for_each)

///| - Client-side routing (ClientRouter)

///| - Async data fetching patterns

///| - Component composition

///|
/// Console logging helper
fn console_log(msg : String) -> Unit {
  let global = @global.global_this()
  global["console"]._call("log", [@js.any(msg)]) |> ignore
}

// =============================================================================
// Async Data Fetching Pattern
// =============================================================================

///|
/// Async state for data fetching
priv struct AsyncState[T] {
  is_loading : @signal.Signal[Bool]
  data : @signal.Signal[T?]
  error : @signal.Signal[String?]
}

///|
/// Create a new async state
fn[T] AsyncState::new() -> AsyncState[T] {
  {
    is_loading: @signal.signal(false),
    data: @signal.signal(None),
    error: @signal.signal(None),
  }
}

///|
/// Simulate async data fetching with setTimeout
extern "js" fn set_timeout(callback : () -> Unit, ms : Int) -> Unit =
  #| (callback, ms) => setTimeout(callback, ms)

///|
/// Simulated user data
priv struct User {
  id : Int
  name : String
  email : String
}

///|
/// Async data fetching example
fn async_data_example(
  router : @client.ClientRouter,
  user_id : Int,
) -> @dom.DomNode {
  let state : AsyncState[User] = AsyncState::new()

  // Simulate data fetching
  fn fetch_user(id : Int) -> Unit {
    state.is_loading.set(true)
    state.error.set(None)
    // Simulate API delay
    set_timeout(
      fn() {
        if id > 0 && id <= 3 {
          state.data.set(
            Some({
              id,
              name: "User " + id.to_string(),
              email: "user" + id.to_string() + "@example.com",
            }),
          )
          state.is_loading.set(false)
        } else {
          state.error.set(Some("User not found"))
          state.is_loading.set(false)
        }
      },
      500,
    )
  }

  // Fetch on mount
  fetch_user(user_id)

  @dom.div(class="async-example", [
    @dom.h2([@dom.text("Async Data Example")]),
    @dom.p([@dom.text("User ID: " + user_id.to_string())]),
    // Loading state
    @dom.show(fn() { state.is_loading.get() }, fn() {
      @dom.p(class="loading", [@dom.text("Loading...")])
    }),
    // Error state
    @dom.show(
      fn() { not(state.error.get() is None) && not(state.is_loading.get()) },
      fn() {
        @dom.p(
          class="error",
          style="color: red;",
          [
            @dom.text_dyn(fn() {
              match state.error.get() {
                Some(err) => "Error: " + err
                None => ""
              }
            }),
          ],
        )
      },
    ),
    // Data display
    @dom.show(
      fn() { not(state.data.get() is None) && not(state.is_loading.get()) },
      fn() {
        @dom.div(class="user-card", style="padding: 10px; border: 1px solid #ccc;", [
          @dom.p([
            @dom.text_dyn(fn() {
              match state.data.get() {
                Some(user) => "Name: " + user.name
                None => ""
              }
            }),
          ]),
          @dom.p([
            @dom.text_dyn(fn() {
              match state.data.get() {
                Some(user) => "Email: " + user.email
                None => ""
              }
            }),
          ]),
        ])
      },
    ),
    @dom.hr(),
    @dom.p([@dom.text("Try different users:")]),
    @dom.div(class="buttons", [
      link_button("/user/1", "User 1", router),
      link_button("/user/2", "User 2", router),
      link_button("/user/3", "User 3", router),
      link_button("/user/999", "User 999 (Not Found)", router),
    ]),
  ])
}

// =============================================================================
// Component Pattern - Props-based composition
// =============================================================================

///|
/// Card component props
priv struct CardProps {
  title : String
  children : Array[@dom.DomNode]
}

///|
/// Reusable Card component
fn card(props : CardProps) -> @dom.DomNode {
  @dom.div(
    class="card",
    style="border: 1px solid #ddd; border-radius: 8px; padding: 16px; margin: 8px 0;",
    [@dom.h3(style="margin-top: 0;", [@dom.text(props.title)]), ..props.children],
  )
}

///|
/// Button component with onClick
fn link_button(
  href : String,
  label : String,
  router : @client.ClientRouter,
) -> @dom.DomNode {
  @dom.button(
    style="margin-right: 8px;",
    on=@dom.on(click=Some(fn(_) { router.navigate(href) })),
    [@dom.text(label)],
  )
}

// =============================================================================
// Counter Example - Basic signals and events
// =============================================================================

///|
fn counter_example() -> @dom.DomNode {
  let count = @signal.signal(0)
  let doubled = @signal.memo(fn() { count.get() * 2 })
  let is_even = @signal.memo(fn() { count.get() % 2 == 0 })
  card(
    {
      title: "Counter Example",
      children: [
        @dom.p([@dom.text_dyn(fn() { "Count: " + count.get().to_string() })]),
        @dom.p([@dom.text_dyn(fn() { "Doubled: " + doubled().to_string() })]),
        @dom.p([@dom.text_dyn(fn() { if is_even() { "Even" } else { "Odd" } })]),
        @dom.div(class="buttons", [
          @dom.button(
            on=@dom.on(click=Some(fn(_) { count.update(fn(n) { n - 1 }) })),
            [@dom.text("-")],
          ),
          @dom.button(
            on=@dom.on(click=Some(fn(_) { count.update(fn(n) { n + 1 }) })),
            [@dom.text("+")],
          ),
          @dom.button(on=@dom.on(click=Some(fn(_) { count.set(0) })), [
            @dom.text("Reset"),
          ]),
        ]),
      ],
    },
  )
}

// =============================================================================
// Input Example - Two-way binding and derived state
// =============================================================================

///|
fn input_example() -> @dom.DomNode {
  let text = @signal.signal("")
  let char_count = @signal.memo(fn() { text.get().length() })
  card(
    {
      title: "Input Example",
      children: [
        @dom.input(
          type_="text",
          placeholder="Type something...",
          on=@dom.on(
            input=Some(fn(e) {
              let target : @js.Any = e.target() |> @js.identity
              let value : String = target._get("value").cast()
              text.set(value)
            }),
          ),
        ),
        @dom.p([
          @dom.text_dyn(fn() { "Characters: " + char_count().to_string() }),
        ]),
        @dom.p([@dom.text_dyn(fn() { "You typed: " + text.get() })]),
      ],
    },
  )
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

  card(
    {
      title: "Todo List",
      children: [
        @dom.form(
          on=@dom.on(
            submit=Some(fn(e) {
              e.preventDefault()
              add_todo()
            }),
          ),
          [
            @dom.input(
              type_="text",
              placeholder="Add a todo...",
              on=@dom.on(
                input=Some(fn(e) {
                  let target : @js.Any = e.target() |> @js.identity
                  input_text.set(target._get("value").cast())
                }),
              ),
            ),
            @dom.create_element(
              "button",
              [("type", @dom.attr_static("submit"))],
              [@dom.text("Add")],
            ),
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
                    let items = todos.get()
                    let mut is_completed = false
                    for i = 0; i < items.length(); i = i + 1 {
                      if items[i].id == todo_id && items[i].completed {
                        is_completed = true
                        break
                      }
                    }
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
                  on=@dom.on(click=Some(fn(_) { toggle_todo(todo_id) })),
                  [@dom.text(todo.text)],
                ),
                @dom.button(
                  style="margin-left: 10px;",
                  on=@dom.on(click=Some(fn(_) { remove_todo(todo_id) })),
                  [@dom.text("x")],
                ),
              ],
            )
          }),
        ]),
      ],
    },
  )
}

// =============================================================================
// Page Components for Routing
// =============================================================================

///|
/// Home page component
fn home_page(router : @client.ClientRouter) -> @dom.DomNode {
  @dom.div(class="page home", [
    @dom.h1([@dom.text("Luna SPA Examples")]),
    @dom.p([
      @dom.text("A collection of examples demonstrating the reactive UI library."),
    ]),
    @dom.hr(),
    counter_example(),
    input_example(),
    todo_example(),
    @dom.hr(),
    @dom.h2([@dom.text("Navigation")]),
    @dom.p([@dom.text("Explore more features:")]),
    @dom.ul([
      @dom.li([
        @dom.a(
          href="/about",
          on=@dom.on(click=Some(fn(e) {
            e.preventDefault()
            router.navigate("/about")
          })),
          [@dom.text("About Page")],
        ),
      ]),
      @dom.li([
        @dom.a(
          href="/user/1",
          on=@dom.on(click=Some(fn(e) {
            e.preventDefault()
            router.navigate("/user/1")
          })),
          [@dom.text("User Profile (Async Data)")],
        ),
      ]),
    ]),
  ])
}

///|
/// About page component
fn about_page(router : @client.ClientRouter) -> @dom.DomNode {
  @dom.div(class="page about", [
    @dom.h1([@dom.text("About Luna")]),
    card(
      {
        title: "Features",
        children: [
          @dom.ul([
            @dom.li([@dom.text("Fine-grained reactivity with Signals")]),
            @dom.li([@dom.text("SPA routing with History API")]),
            @dom.li([@dom.text("Component-based architecture")]),
            @dom.li([@dom.text("Async data fetching patterns")]),
            @dom.li([@dom.text("SSR with Island Architecture")]),
          ]),
        ],
      },
    ),
    @dom.hr(),
    link_button("/", "Back to Home", router),
  ])
}

///|
/// User page component (with async data)
fn user_page(router : @client.ClientRouter, user_id : Int) -> @dom.DomNode {
  @dom.div(class="page user", [
    @dom.h1([@dom.text("User Profile")]),
    async_data_example(router, user_id),
    @dom.hr(),
    link_button("/", "Back to Home", router),
  ])
}

///|
/// 404 Not Found page
fn not_found_page(router : @client.ClientRouter, path : String) -> @dom.DomNode {
  @dom.div(class="page not-found", [
    @dom.h1([@dom.text("404 - Not Found")]),
    @dom.p([@dom.text("Page not found: " + path)]),
    @dom.hr(),
    link_button("/", "Back to Home", router),
  ])
}

// =============================================================================
// Router Setup
// =============================================================================

///|
/// Create routes configuration
fn create_routes() -> Array[@router.Route] {
  [
    @router.Route::Page(path="/", title="Home", meta=[]),
    @router.Route::Page(path="/about", title="About", meta=[]),
    @router.Route::Path(
      "/user",
      [
        @router.Route::Param(
          ":id",
          key="id",
          title="User Profile",
          meta=[],
        ),
      ],
      title="Users",
      meta=[],
    ),
  ]
}

///|
/// Render the current route
fn render_route(
  router : @client.ClientRouter,
  container : @dom.DomElement,
) -> Unit {
  let _ = @signal.effect(fn() {
    // Track route changes
    let match_result = router.current_match_signal().get()
    let path = router.current_path_signal().peek() // Use peek to avoid double subscription
    console_log("Navigating to: " + path)

    // Clear and render new content
    @dom.clear(container)

    // Create components untracked to avoid subscribing to their internal signals
    // This ensures counter's signal changes don't re-trigger the route effect
    let page = @signal.untracked(fn() {
      match match_result {
        Some(m) => {
          let ctx = @router.RouterContext::from_match(m)
          if ctx.path == "/" {
            home_page(router)
          } else if ctx.path == "/about" {
            about_page(router)
          } else {
            // Check for user route
            match ctx.get_param("id") {
              Some(id_str) =>
                match @global.parseInt(id_str) {
                  Some(id) => user_page(router, id)
                  None => not_found_page(router, path)
                }
              None => not_found_page(router, path)
            }
          }
        }
        None => not_found_page(router, path)
      }
    })
    @dom.mount(container, page)
  })
}

// =============================================================================
// Main Application
// =============================================================================

///|
/// Main function - renders the SPA with routing
fn main {
  console_log("Luna SPA Application")
  console_log("====================")

  let doc = @js_dom.document()
  let container = doc.getElementById("app")
  match container {
    Some(el) => {
      // Create router with routes
      let router = @client.ClientRouter::new(create_routes())
      console_log("Router initialized with path: " + router.get_path())

      // Setup reactive routing
      let dom_container = el |> @dom.DomElement::from_jsdom
      render_route(router, dom_container)

      console_log("App rendered successfully!")
    }
    None => console_log("ERROR: Could not find #app container")
  }
}
