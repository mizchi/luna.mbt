// TodoMVC - Luna UI Implementation
// https://github.com/tastejs/todomvc

// =============================================================================
// Data Structures
// =============================================================================

///|
struct Todo {
  id : Int
  title : String
  completed : Bool
} derive(Eq)

///|
priv enum Filter {
  All
  Active
  Completed
} derive(Eq)

// =============================================================================
// LocalStorage Persistence
// =============================================================================

///|
let storage_key : String = "todos-luna"

///|
fn save_todos(todos : Array[Todo]) -> Unit {
  @storage.localStorage().setItem(storage_key, todos_to_json(todos))
}

///|
fn load_todos() -> Array[Todo] {
  match @storage.localStorage().getItem(storage_key) {
    Some(json) => json_to_todos(json)
    None => []
  }
}

///|
fn todos_to_json(todos : Array[Todo]) -> String {
  let items = todos.map(fn(todo) {
    let title = escape_json_string(todo.title)
    "{\"id\":\{todo.id},\"title\":\"\{title}\",\"completed\":\{todo.completed}}"
  })
  "[" +
  items.iter().intersperse(",").fold(init="", fn(acc, s) { acc + s }) +
  "]"
}

///|
fn escape_json_string(s : String) -> String {
  let mut result = ""
  for c in s {
    let escaped = match c {
      '"' => "\\\""
      '\\' => "\\\\"
      '\n' => "\\n"
      '\r' => "\\r"
      '\t' => "\\t"
      _ => c.to_string()
    }
    result = result + escaped
  }
  result
}

///|
fn json_to_todos(json : String) -> Array[Todo] {
  let todos : Array[Todo] = []
  let parsed : Json = @json.parse(json) catch { _ => return todos }
  match parsed {
    Array(items) =>
      for item in items {
        match item {
          Object(obj) => {
            let id = match obj.get("id") {
              Some(Number(n, ..)) => n.to_int()
              _ => 0
            }
            let title = match obj.get("title") {
              Some(String(s)) => s
              _ => ""
            }
            let completed = match obj.get("completed") {
              Some(True) => true
              _ => false
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
fn get_current_filter() -> Filter {
  let hash = @location.location().hash
  match hash {
    "#/active" => Active
    "#/completed" => Completed
    _ => All
  }
}

// =============================================================================
// DOM Helpers
// =============================================================================

///|
/// Select all text in an input element
fn select_input(el : @js_dom.HTMLInputElement) -> Unit {
  el.as_any()._call("select", []) |> ignore
}

///|
/// Schedule a callback for the next animation frame
fn next_frame(callback : () -> Unit) -> Unit {
  @js_dom.window().requestAnimationFrame(fn(_) { callback() }) |> ignore
}

// =============================================================================
// UI Helpers
// =============================================================================

///|
/// Conditionally show/hide element based on condition
fn visible_when(condition : () -> Bool) -> (String, @dom.AttrValue) {
  (
    "style",
    @dom.attr_dynamic(fn() { if condition() { "" } else { "display: none" } }),
  )
}

///|
/// Create a filter link with selected state
fn filter_link(
  href : String,
  label : String,
  current_filter : @signal.Signal[Filter],
  target_filter : Filter,
) -> @dom.DomNode {
  let class_getter = fn() {
    if current_filter.get() == target_filter {
      "selected"
    } else {
      ""
    }
  }
  @dom.li([
    @dom.a(href~, [
      @dom.span(dyn_attrs=[("className", @dom.attr_dynamic(class_getter))], [
        @dom.text(label),
      ]),
    ]),
  ])
}

// =============================================================================
// TodoMVC Application
// =============================================================================

///|
fn app() -> @dom.DomNode {
  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------
  let todos : @signal.Signal[Array[Todo]] = @signal.signal(load_todos())
  let filter = @signal.signal(get_current_filter())
  let editing_id : @signal.Signal[Int?] = @signal.signal(None)
  let new_todo_text = @signal.signal("")
  let is_composing = @signal.signal(false)
  let next_id = @signal.signal(
    todos
    .peek()
    .fold(init=0, fn(max, t) { if t.id > max { t.id } else { max } }) +
    1,
  )

  // Auto-save todos to localStorage
  let _ = @signal.effect(fn() { save_todos(todos.get()) })

  // Listen for hash changes
  @js_dom.window().add_hashchange_listener(fn(_) {
    filter.set(get_current_filter())
  })

  // ---------------------------------------------------------------------------
  // Computed Values
  // ---------------------------------------------------------------------------
  let active_count = @signal.memo(fn() {
    todos
    .get()
    .fold(init=0, fn(count, t) {
      if not(t.completed) {
        count + 1
      } else {
        count
      }
    })
  })
  let completed_count = @signal.memo(() => todos
    .get()
    .fold(init=0, (count, t) => if t.completed { count + 1 } else { count }))
  let all_completed = @signal.memo(fn() {
    let items = todos.get()
    items.length() > 0 && active_count() == 0
  })
  let has_todos = fn() { todos.get().length() > 0 }
  let filtered_todos = fn() {
    let items = todos.get()
    let f = filter.get()
    items.filter(fn(t) {
      match f {
        All => true
        Active => not(t.completed)
        Completed => t.completed
      }
    })
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------
  fn add_todo() {
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
      items.map(fn(t) {
        if t.id == id {
          { ..t, completed: not(t.completed) }
        } else {
          t
        }
      })
    })
  }

  fn remove_todo(id : Int) {
    todos.update(fn(items) { items.filter(fn(t) { t.id != id }) })
  }

  fn update_todo_title(id : Int, new_title : String) {
    let trimmed = new_title.trim(chars=" ").to_string()
    if trimmed == "" {
      remove_todo(id)
    } else {
      todos.update(fn(items) {
        items.map(fn(t) { if t.id == id { { ..t, title: trimmed } } else { t } })
      })
    }
  }

  fn toggle_all() {
    let all_done = all_completed()
    todos.update(fn(items) {
      items.map(fn(t) { { ..t, completed: not(all_done) } })
    })
  }

  fn clear_completed() {
    todos.update(fn(items) { items.filter(fn(t) { not(t.completed) }) })
  }

  // ---------------------------------------------------------------------------
  // Components
  // ---------------------------------------------------------------------------

  /// Render a single todo item
  fn render_todo_item(get_todo : () -> Todo, _index : Int) -> @dom.DomNode {
    let edit_ref : Ref[@js_dom.HTMLInputElement?] = { val: None }
    let edit_composing : Ref[Bool] = { val: false }

    // Focus edit input when entering edit mode
    let _ = @signal.effect(fn() {
      let todo = get_todo()
      if editing_id.get() == Some(todo.id) {
        next_frame(fn() {
          if edit_ref.val is Some(input) {
            input.value = todo.title
            input.as_html_element().focus()
            select_input(input)
          }
        })
      }
    })

    // Build class name dynamically
    let class_name = fn() {
      let todo = get_todo()
      let is_editing = editing_id.get() == Some(todo.id)
      match (todo.completed, is_editing) {
        (true, true) => "completed editing"
        (true, false) => "completed"
        (false, true) => "editing"
        (false, false) => ""
      }
    }
    @dom.li(dyn_attrs=[("className", @dom.attr_dynamic(class_name))], [
      // View mode
      @dom.div(class="view", [
        // Toggle checkbox
        @dom.input(class="toggle", type_="checkbox", dyn_attrs=[
          (
            "checked",
            @dom.attr_dynamic(fn() { get_todo().completed.to_string() }),
          ),
          ("change", @dom.Handler(fn(_) { toggle_todo(get_todo().id) })),
        ]),
        // Label (double-click to edit)
        @dom.label(
          on=@dom.events().dblclick(fn(_) {
            editing_id.set(Some(get_todo().id))
          }),
          [@dom.text_dyn(fn() { get_todo().title })],
        ),
        // Delete button
        @dom.button(
          class="destroy",
          on=@dom.events().click(fn(_) { remove_todo(get_todo().id) }),
          [],
        ),
      ]),
      // Edit mode input
      @dom.input(
        class="edit",
        ref_=fn(el) {
          edit_ref.val = Some(@js_dom.HTMLInputElement::cast_from_element(el))
        },
        dyn_attrs=[
          ("value", @dom.attr_dynamic(fn() { get_todo().title })),
          (
            "compositionstart",
            @dom.Handler(fn(_) { edit_composing.val = true }),
          ),
          ("compositionend", @dom.Handler(fn(_) { edit_composing.val = false })),
          (
            "blur",
            @dom.Handler(fn(e) {
              let todo = get_todo()
              if editing_id.peek() == Some(todo.id) {
                let input : @js_dom.HTMLInputElement = e._get("target").cast()
                update_todo_title(todo.id, input.value)
                editing_id.set(None)
              }
            }),
          ),
          (
            "keydown",
            @dom.Handler(fn(e) {
              let key : String = e._get("key").cast()
              let todo = get_todo()
              let input : @js_dom.HTMLInputElement = e._get("target").cast()
              if key == "Enter" && not(edit_composing.val) {
                update_todo_title(todo.id, input.value)
                editing_id.set(None)
              } else if key == "Escape" {
                input.value = todo.title
                editing_id.set(None)
              }
            }),
          ),
        ],
      ),
    ])
  }

  /// Render header with new todo input
  fn render_header() -> @dom.DomNode {
    @dom.header_(class="header", [
      @dom.h1([@dom.text("todos")]),
      @dom.input(
        class="new-todo",
        placeholder="What needs to be done?",
        attrs=[("autofocus", @dom.Attr::AttrBool(true))],
        on=@dom.events()
          .input(fn(e) {
            let input = @js_dom.HTMLInputElement::cast_from_element(e.target())
            new_todo_text.set(input.value)
          })
          .compositionstart(fn(_) { is_composing.set(true) })
          .compositionend(fn(_) { is_composing.set(false) })
          .keydown(fn(e) {
            if e.key == "Enter" && not(is_composing.peek()) {
              add_todo()
              @js_dom.HTMLInputElement::cast_from_element(e.target()).value = ""
            }
          }),
      ),
    ])
  }

  /// Render main section with todo list
  fn render_main() -> @dom.DomNode {
    @dom.section(class="main", dyn_attrs=[visible_when(has_todos)], [
      // Toggle all checkbox
      @dom.input(id="toggle-all", class="toggle-all", type_="checkbox", dyn_attrs=[
        ("checked", @dom.attr_dynamic(fn() { all_completed().to_string() })),
        ("change", @dom.Handler(fn(_) { toggle_all() })),
      ]),
      @dom.label(for_="toggle-all", [@dom.text("Mark all as complete")]),
      // Todo list
      @dom.ul(class="todo-list", [
        @dom.index_each(filtered_todos, render_todo_item),
      ]),
    ])
  }

  /// Render footer with count and filters
  fn render_footer() -> @dom.DomNode {
    @dom.footer_(class="footer", dyn_attrs=[visible_when(has_todos)], [
      // Item count
      @dom.span(class="todo-count", [
        @dom.strong([@dom.text_dyn(fn() { active_count().to_string() })]),
        @dom.text_dyn(fn() {
          if active_count() == 1 {
            " item left"
          } else {
            " items left"
          }
        }),
      ]),
      // Filter links
      @dom.ul(class="filters", [
        filter_link("#/", "All", filter, All),
        filter_link("#/active", "Active", filter, Active),
        filter_link("#/completed", "Completed", filter, Completed),
      ]),
      // Clear completed button
      @dom.button(
        class="clear-completed",
        on=@dom.events().click(fn(_) { clear_completed() }),
        dyn_attrs=[visible_when(fn() { completed_count() > 0 })],
        [@dom.text("Clear completed")],
      ),
    ])
  }

  // ---------------------------------------------------------------------------
  // Main App Structure
  // ---------------------------------------------------------------------------
  @dom.section(class="todoapp", [
    render_header(),
    render_main(),
    render_footer(),
  ])
}

// =============================================================================
// Main Entry Point
// =============================================================================

///|
fn main {
  let doc = @js_dom.document()
  match doc.getElementById("app") {
    Some(el) => @dom.render(el |> @dom.DomElement::from_jsdom, app())
    None => ()
  }
}
