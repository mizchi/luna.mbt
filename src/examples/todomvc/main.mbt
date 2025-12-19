// TodoMVC - Luna Framework Implementation
// https://github.com/tastejs/todomvc

///|
/// Console logging helper
fn console_log(msg : String) -> Unit {
  let global = @global.global_this()
  global["console"]._call("log", [@js.any(msg)]) |> ignore
}

// =============================================================================
// Data Structures
// =============================================================================

///|
/// Todo item structure
struct Todo {
  id : Int
  title : String
  completed : Bool
} derive(Eq)

///|
/// Filter type for routing
priv enum Filter {
  All
  Active
  Completed
} derive(Eq)

// =============================================================================
// LocalStorage Persistence
// =============================================================================

///|
/// Storage key for todos
let storage_key : String = "todos-luna"

///|
/// Save todos to localStorage
fn save_todos(todos : Array[Todo]) -> Unit {
  let json = todos_to_json(todos)
  ffi_local_storage_set(storage_key, json)
}

///|
/// Load todos from localStorage
fn load_todos() -> Array[Todo] {
  match ffi_local_storage_get(storage_key) {
    Some(json) => json_to_todos(json)
    None => []
  }
}

///|
extern "js" fn ffi_local_storage_set(key : String, value : String) -> Unit =
  #|(key, value) => localStorage.setItem(key, value)

///|
extern "js" fn ffi_local_storage_get(key : String) -> String? =
  #|(key) => { const v = localStorage.getItem(key); return v === null ? undefined : v; }

///|
/// Convert todos array to JSON string
fn todos_to_json(todos : Array[Todo]) -> String {
  let items : Array[String] = []
  for todo in todos {
    let escaped_title = escape_json_string(todo.title)
    items.push(
      "{\"id\":\{todo.id},\"title\":\"\{escaped_title}\",\"completed\":\{todo.completed}}",
    )
  }
  "[" +
  items.iter().intersperse(",").fold(init="", fn(acc, s) { acc + s }) +
  "]"
}

///|
/// Escape special characters in JSON string
fn escape_json_string(s : String) -> String {
  let mut result = ""
  for c in s {
    match c {
      '"' => result = result + "\\\""
      '\\' => result = result + "\\\\"
      '\n' => result = result + "\\n"
      '\r' => result = result + "\\r"
      '\t' => result = result + "\\t"
      _ => result = result + c.to_string()
    }
  }
  result
}

///|
/// Parse JSON string to todos array
fn json_to_todos(json : String) -> Array[Todo] {
  let todos : Array[Todo] = []
  let parsed : Json = @json.parse(json) catch { _ => return todos }
  match parsed {
    Array(items) =>
      for item in items {
        match item {
          Object(obj) => {
            let mut id = 0
            let mut title = ""
            let mut completed = false
            match obj.get("id") {
              Some(Number(n, ..)) => id = n.to_int()
              _ => ()
            }
            match obj.get("title") {
              Some(String(s)) => title = s
              _ => ()
            }
            match obj.get("completed") {
              Some(True) => completed = true
              Some(False) => completed = false
              _ => ()
            }
            todos.push({ id, title, completed })
          }
          _ => ()
        }
      }
    _ => ()
  }
  todos
}

// =============================================================================
// Hash Routing
// =============================================================================

///|
/// Get current hash from location
fn get_hash() -> String {
  ffi_get_hash()
}

///|
extern "js" fn ffi_get_hash() -> String =
  #|() => location.hash || "#/"

///|
/// Parse hash to filter
fn hash_to_filter(hash : String) -> Filter {
  if hash == "#/active" {
    Active
  } else if hash == "#/completed" {
    Completed
  } else {
    All
  }
}

///|
/// Listen for hash changes
fn on_hash_change(callback : () -> Unit) -> Unit {
  ffi_on_hash_change(callback)
}

///|
extern "js" fn ffi_on_hash_change(callback : () -> Unit) -> Unit =
  #|(callback) => window.addEventListener("hashchange", callback)

// =============================================================================
// DOM Helpers
// =============================================================================

///|
/// Focus an element by ref
fn focus_element(el : @js_dom.Element) -> Unit {
  el.as_any()._call("focus", []) |> ignore
}

///|
/// Get input value
fn get_input_value(el : @js_dom.Element) -> String {
  el.as_any()._get("value").cast()
}

///|
/// Set input value
fn set_input_value(el : @js_dom.Element, value : String) -> Unit {
  el.as_any()._set("value", @js.any(value)) |> ignore
}

///|
/// Select all text in input
fn select_input(el : @js_dom.Element) -> Unit {
  el.as_any()._call("select", []) |> ignore
}

// =============================================================================
// TodoMVC Application
// =============================================================================

///|
fn app() -> @dom.DomNode {
  // State
  let todos : @signal.Signal[Array[Todo]] = @signal.signal(load_todos())
  let filter = @signal.signal(hash_to_filter(get_hash()))
  let editing_id : @signal.Signal[Int?] = @signal.signal(None)
  let new_todo_text = @signal.signal("")
  let is_composing = @signal.signal(false) // Track IME composition state
  let next_id = @signal.signal(
    {
      let loaded = todos.peek()
      if loaded.length() == 0 {
        1
      } else {
        let mut max = 0
        for todo in loaded {
          if todo.id > max {
            max = todo.id
          }
        }
        max + 1
      }
    },
  )

  // Save todos to localStorage whenever they change
  let _ = @signal.effect(fn() {
    let current_todos = todos.get()
    save_todos(current_todos)
  })

  // Listen for hash changes
  on_hash_change(fn() { filter.set(hash_to_filter(get_hash())) })

  // Computed values
  let active_count = @signal.memo(fn() {
    let items = todos.get()
    let mut count = 0
    for todo in items {
      if not(todo.completed) {
        count = count + 1
      }
    }
    count
  })
  let completed_count = @signal.memo(fn() {
    let items = todos.get()
    let mut count = 0
    for todo in items {
      if todo.completed {
        count = count + 1
      }
    }
    count
  })
  let all_completed = @signal.memo(fn() {
    let items = todos.get()
    items.length() > 0 && active_count() == 0
  })

  // Actions
  fn add_todo() {
    // Use peek() in event handlers to avoid effect tracking issues
    let text = new_todo_text.peek().trim(chars=" ").to_string()
    if text != "" {
      let id = next_id.peek()
      next_id.set(id + 1)
      todos.update(fn(items) {
        let new_items = items.copy()
        new_items.push({ id, title: text, completed: false })
        new_items
      })
      new_todo_text.set("")
    }
  }

  fn toggle_todo(id : Int) {
    todos.update(fn(items) {
      let new_items : Array[Todo] = []
      for item in items {
        if item.id == id {
          new_items.push({ ..item, completed: not(item.completed) })
        } else {
          new_items.push(item)
        }
      }
      new_items
    })
  }

  fn remove_todo(id : Int) {
    todos.update(fn(items) {
      let new_items : Array[Todo] = []
      for item in items {
        if item.id != id {
          new_items.push(item)
        }
      }
      new_items
    })
  }

  fn update_todo_title(id : Int, new_title : String) {
    let trimmed = new_title.trim(chars=" ").to_string()
    if trimmed == "" {
      remove_todo(id)
    } else {
      todos.update(fn(items) {
        let new_items : Array[Todo] = []
        for item in items {
          if item.id == id {
            new_items.push({ ..item, title: trimmed })
          } else {
            new_items.push(item)
          }
        }
        new_items
      })
    }
  }

  fn toggle_all() {
    let all_done = all_completed()
    todos.update(fn(items) {
      let new_items : Array[Todo] = []
      for item in items {
        new_items.push({ ..item, completed: not(all_done) })
      }
      new_items
    })
  }

  fn clear_completed() {
    todos.update(fn(items) {
      let new_items : Array[Todo] = []
      for item in items {
        if not(item.completed) {
          new_items.push(item)
        }
      }
      new_items
    })
  }

  // Render single todo item - use index_each for stable rendering
  fn render_todo_item(get_todo : () -> Todo, index : Int) -> @dom.DomNode {
    // Ref to edit input for this item
    let edit_ref : Ref[@js_dom.Element?] = { val: None }
    // Track IME composition state for this item's edit input
    let edit_composing : Ref[Bool] = { val: false }

    // Effect to focus edit input when this item enters edit mode
    let _ = @signal.effect(fn() {
      let todo = get_todo()
      match editing_id.get() {
        Some(id) =>
          if id == todo.id {
            // Use rAF to ensure DOM is ready after class change
            ffi_request_animation_frame(fn() {
              match edit_ref.val {
                Some(el) => {
                  set_input_value(el, todo.title)
                  focus_element(el)
                  select_input(el)
                }
                None => ()
              }
            })
          }
        None => ()
      }
    })

    @dom.create_element(
      "li",
      [
        (
          "className",
          @dom.attr_dynamic(fn() {
            let todo = get_todo()
            let is_editing = match editing_id.get() {
              Some(id) => id == todo.id
              None => false
            }
            let mut classes = if todo.completed { "completed" } else { "" }
            if is_editing {
              classes = if classes == "" {
                "editing"
              } else {
                classes + " editing"
              }
            }
            classes
          }),
        ),
      ],
      [
        // View mode
        @dom.div(class="view", [
          @dom.create_element(
            "input",
            [
              ("className", @dom.attr_static("toggle")),
              ("type", @dom.attr_static("checkbox")),
              (
                "checked",
                @dom.attr_dynamic(fn() {
                  if get_todo().completed {
                    "true"
                  } else {
                    "false"
                  }
                }),
              ),
              (
                "change",
                @dom.Handler(fn(_) {
                  let todo = get_todo()
                  toggle_todo(todo.id)
                }),
              ),
            ],
            [],
          ),
          @dom.label(
            on=@dom.events().dblclick(fn(_) {
              let todo = get_todo()
              editing_id.set(Some(todo.id))
            }),
            [@dom.text_dyn(fn() { get_todo().title })],
          ),
          @dom.button(
            class="destroy",
            on=@dom.events().click(fn(_) {
              let todo = get_todo()
              remove_todo(todo.id)
            }),
            [],
          ),
        ]),
        // Edit mode
        @dom.create_element(
          "input",
          [
            ("className", @dom.attr_static("edit")),
            ("value", @dom.attr_dynamic(fn() { get_todo().title })),
            // Capture ref to this input element
            (
              "__ref",
              @dom.Handler(fn(el) { edit_ref.val = Some(el.cast()) }),
            ),
            // IME composition handling
            (
              "compositionstart",
              @dom.Handler(fn(_) { edit_composing.val = true }),
            ),
            (
              "compositionend",
              @dom.Handler(fn(_) { edit_composing.val = false }),
            ),
            (
              "blur",
              @dom.Handler(fn(e) {
                let todo = get_todo()
                if editing_id.peek() is Some(id) && id == todo.id {
                  let target : @js_dom.Element = e._get("target").cast()
                  let value = get_input_value(target)
                  update_todo_title(todo.id, value)
                  editing_id.set(None)
                }
              }),
            ),
            (
              "keydown",
              @dom.Handler(fn(e) {
                let key : String = e._get("key").cast()
                let todo = get_todo()
                // Don't submit during IME composition
                if key == "Enter" && not(edit_composing.val) {
                  let target : @js_dom.Element = e._get("target").cast()
                  let value = get_input_value(target)
                  update_todo_title(todo.id, value)
                  editing_id.set(None)
                } else if key == "Escape" {
                  // Reset value and cancel editing
                  let target : @js_dom.Element = e._get("target").cast()
                  set_input_value(target, todo.title)
                  editing_id.set(None)
                }
              }),
            ),
          ],
          [],
        ),
      ],
    )
    |> ignore_index(index)
  }

  // Main app structure
  @dom.section(class="todoapp", [
    // Header
    @dom.header_(class="header", [
      @dom.h1([@dom.text("todos")]),
      @dom.input(
        class="new-todo",
        placeholder="What needs to be done?",
        attrs=[("autofocus", @dom.Attr::AttrBool(true))],
        on=@dom.events()
          .input(fn(e) {
            let target = e.target()
            let value = get_input_value(target)
            new_todo_text.set(value)
          })
          .compositionstart(fn(_) { is_composing.set(true) })
          .compositionend(fn(_) { is_composing.set(false) })
          .keydown(fn(e) {
            // Don't submit during IME composition (e.g., Japanese input)
            if e.key == "Enter" && not(is_composing.peek()) {
              add_todo()
              let target = e.target()
              set_input_value(target, "")
            }
          }),
      ),
    ]),
    // Main section
    @dom.create_element(
      "section",
      [
        ("className", @dom.attr_static("main")),
        (
          "style",
          @dom.attr_dynamic(fn() {
            if todos.get().length() > 0 {
              ""
            } else {
              "display: none"
            }
          }),
        ),
      ],
      [
        @dom.create_element(
          "input",
          [
            ("id", @dom.attr_static("toggle-all")),
            ("className", @dom.attr_static("toggle-all")),
            ("type", @dom.attr_static("checkbox")),
            ("checked", @dom.attr_dynamic(fn() { all_completed().to_string() })),
            ("change", @dom.Handler(fn(_) { toggle_all() })),
          ],
          [],
        ),
        @dom.label(for_="toggle-all", [@dom.text("Mark all as complete")]),
        @dom.ul(class="todo-list", [
          @dom.index_each(
            fn() {
              let items = todos.get()
              let current_filter = filter.get()
              let result : Array[Todo] = []
              for todo in items {
                match current_filter {
                  All => result.push(todo)
                  Active => if not(todo.completed) { result.push(todo) }
                  Completed => if todo.completed { result.push(todo) }
                }
              }
              result
            },
            render_todo_item,
          ),
        ]),
      ],
    ),
    // Footer
    @dom.create_element(
      "footer",
      [
        ("className", @dom.attr_static("footer")),
        (
          "style",
          @dom.attr_dynamic(fn() {
            if todos.get().length() > 0 {
              ""
            } else {
              "display: none"
            }
          }),
        ),
      ],
      [
        @dom.span(class="todo-count", [
          @dom.create_element("strong", [], [
            @dom.text_dyn(fn() { active_count().to_string() }),
          ]),
          @dom.text_dyn(fn() {
            if active_count() == 1 {
              " item left"
            } else {
              " items left"
            }
          }),
        ]),
        @dom.ul(class="filters", [
          @dom.li([
            @dom.a(href="#/", [
              @dom.create_element(
                "span",
                [
                  (
                    "className",
                    @dom.attr_dynamic(fn() {
                      if filter.get() == All {
                        "selected"
                      } else {
                        ""
                      }
                    }),
                  ),
                ],
                [@dom.text("All")],
              ),
            ]),
          ]),
          @dom.li([
            @dom.a(href="#/active", [
              @dom.create_element(
                "span",
                [
                  (
                    "className",
                    @dom.attr_dynamic(fn() {
                      if filter.get() == Active {
                        "selected"
                      } else {
                        ""
                      }
                    }),
                  ),
                ],
                [@dom.text("Active")],
              ),
            ]),
          ]),
          @dom.li([
            @dom.a(href="#/completed", [
              @dom.create_element(
                "span",
                [
                  (
                    "className",
                    @dom.attr_dynamic(fn() {
                      if filter.get() == Completed {
                        "selected"
                      } else {
                        ""
                      }
                    }),
                  ),
                ],
                [@dom.text("Completed")],
              ),
            ]),
          ]),
        ]),
        // Clear completed button
        @dom.create_element(
          "button",
          [
            ("className", @dom.attr_static("clear-completed")),
            (
              "style",
              @dom.attr_dynamic(fn() {
                if completed_count() > 0 {
                  ""
                } else {
                  "display: none"
                }
              }),
            ),
            ("click", @dom.Handler(fn(_) { clear_completed() })),
          ],
          [@dom.text("Clear completed")],
        ),
      ],
    ),
  ])
}

///|
/// Helper to ignore index parameter
fn ignore_index(node : @dom.DomNode, _index : Int) -> @dom.DomNode {
  node
}

///|
extern "js" fn ffi_request_animation_frame(callback : () -> Unit) -> Unit =
  #|(callback) => requestAnimationFrame(callback)

// =============================================================================
// Main Entry Point
// =============================================================================

///|
fn main {
  console_log("TodoMVC - Luna Framework")
  let doc = @js_dom.document()
  let container = doc.getElementById("app")
  match container {
    Some(el) => {
      @dom.render(el |> @dom.DomElement::from_jsdom, app())
      console_log("TodoMVC rendered successfully!")
    }
    None => console_log("ERROR: Could not find #app container")
  }
}
