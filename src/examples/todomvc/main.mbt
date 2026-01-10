// TodoMVC - Luna UI Implementation
// https://github.com/tastejs/todomvc

///|
using @element {
  li,
  a,
  span,
  text,
  div,
  input,
  label,
  button,
  header_,
  h1,
  section,
  ul,
  footer_,
  strong,
  text_dyn,
  index_each,
  events,
  type Attr,
  type DomNode,
  type DomElement,
  render,
}

///|
using @signal {type Signal, signal, effect, memo}

// =============================================================================
// Data Structures
// =============================================================================

///|
struct Todo {
  id : Int
  title : String
  completed : Bool
} derive(Eq, FromJson, ToJson)

///|
priv enum Filter {
  All
  Active
  Completed
} derive(Eq)

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
fn select_input(el : @dom.HTMLInputElement) -> Unit {
  el.as_any()._call("select", []) |> ignore
}

///|
/// Schedule a callback for the next animation frame
fn next_frame(callback : () -> Unit) -> Unit {
  @dom.window().requestAnimationFrame(_ => callback()) |> ignore
}

// =============================================================================
// CSS Utilities (imported from styles.mbt)
// =============================================================================
// All Luna CSS utilities are defined in styles.mbt for zero-runtime extraction

// =============================================================================
// UI Helpers
// =============================================================================

///|
/// Conditionally show/hide element based on condition (returns inline style)
fn visible_when(condition : () -> Bool) -> () -> String {
  fn() { if condition() { "" } else { "display: none;" } }
}

///|
/// Create a filter link with selected state (using Luna CSS utilities)
fn filter_link(
  href : String,
  label_ : String,
  current_filter : Signal[Filter],
  target_filter : Filter,
) -> DomNode {
  // Base classes for all filter links (hover, transition)
  let base_classes = classes([hover_border_color, transition_border])
  let class_getter = () => if current_filter.get() == target_filter {
    classes([base_classes, "selected", border_color_selected])
  } else {
    classes([base_classes, border_color_transparent])
  }
  li([a(href~, [span(dyn_class=class_getter, [text(label_)])])])
}

// =============================================================================
// TodoMVC Application
// =============================================================================

///|
fn app() -> DomNode {
  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------
  let todos : Signal[Array[Todo]] = signal(load_todos())
  let filter = signal(get_current_filter())
  let editing_id : Signal[Int?] = signal(None)
  let new_todo_text = signal("")
  let is_composing = signal(false)
  let next_id = signal(
    todos.peek().iter().map(t => t.id).maximum().unwrap_or(0) + 1,
  )

  // Auto-save todos to localStorage
  let _ = effect(() => save_todos(todos.get()))

  // Listen for hash changes
  @dom.window().add_hashchange_listener(_ => filter.set(get_current_filter()))

  // ---------------------------------------------------------------------------
  // Computed Values
  // ---------------------------------------------------------------------------
  let active_count = memo(() => todos
    .get()
    .iter()
    .filter(t => not(t.completed))
    .count())
  let completed_count = memo(() => todos
    .get()
    .iter()
    .filter(t => t.completed)
    .count())
  let all_completed = memo(() => {
    let items = todos.get()
    items.length() > 0 && active_count() == 0
  })
  let has_todos = () => todos.get().length() > 0
  let filtered_todos = () => {
    let items = todos.get()
    let f = filter.get()
    items.filter(t => match f {
      All => true
      Active => not(t.completed)
      Completed => t.completed
    })
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------
  fn add_todo() {
    let txt = new_todo_text.peek().trim(chars=" ").to_string()
    if txt != "" {
      let id = next_id.peek()
      next_id.set(id + 1)
      todos.update(items => {
        let new_items = items.copy()
        new_items.push({ id, title: txt, completed: false })
        new_items
      })
      new_todo_text.set("")
    }
  }

  fn toggle_todo(id : Int) {
    todos.update(items => items.map(t => if t.id == id {
      { ..t, completed: not(t.completed) }
    } else {
      t
    }))
  }

  fn remove_todo(id : Int) {
    todos.update(items => items.filter(t => t.id != id))
  }

  fn update_todo_title(id : Int, new_title : String) {
    let trimmed = new_title.trim(chars=" ").to_string()
    if trimmed == "" {
      remove_todo(id)
    } else {
      todos.update(items => items.map(t => if t.id == id {
        { ..t, title: trimmed }
      } else {
        t
      }))
    }
  }

  fn toggle_all() {
    let all_done = all_completed()
    todos.update(items => items.map(t => { ..t, completed: not(all_done) }))
  }

  fn clear_completed() {
    todos.update(items => items.filter(t => not(t.completed)))
  }

  // ---------------------------------------------------------------------------
  // Components
  // ---------------------------------------------------------------------------

  /// Render a single todo item
  fn render_todo_item(get_todo : () -> Todo, _index : Int) -> DomNode {
    let edit_ref : Ref[@dom.HTMLInputElement?] = Ref::new(None)
    let edit_composing : Ref[Bool] = Ref::new(false)

    // Focus edit input when entering edit mode
    let _ = effect(() => {
      let todo = get_todo()
      if editing_id.get() == Some(todo.id) {
        next_frame(() => if edit_ref.val is Some(inp) {
          inp.value = todo.title
          inp.as_html_element().focus()
          select_input(inp)
        })
      }
    })

    // Build class name dynamically (combining TodoMVC classes with Luna CSS utilities)
    let class_name = () => {
      let todo = get_todo()
      let is_editing = editing_id.get() == Some(todo.id)
      let completed_styles = if todo.completed {
        classes(["completed", text_decoration_line_through, color_muted])
      } else {
        ""
      }
      let editing_class = if is_editing { "editing" } else { "" }
      classes([completed_styles, editing_class])
    }
    li(dyn_class=class_name, [
      // View mode
      div(class="view", [
        // Toggle checkbox
        input(
          class="toggle",
          type_="checkbox",
          dyn_checked=fn() { get_todo().completed },
          on=events().change(_ => toggle_todo(get_todo().id)),
        ),
        // Label (double-click to edit)
        label(on=events().dblclick(_ => editing_id.set(Some(get_todo().id))), [
          text_dyn(() => get_todo().title),
        ]),
        // Delete button
        button(
          class="destroy",
          on=events().click(_ => remove_todo(get_todo().id)),
          [],
        ),
      ]),
      // Edit mode input
      input(
        class="edit",
        ref_=el => edit_ref.val = Some(
          @dom.HTMLInputElement::cast_from_element(el),
        ),
        dyn_value=fn() { get_todo().title },
        on=events()
          .compositionstart(_ => edit_composing.val = true)
          .compositionend(_ => edit_composing.val = false)
          .blur(e => {
            let todo = get_todo()
            if editing_id.peek() == Some(todo.id) {
              let inp = @dom.HTMLInputElement::cast_from_element(e.target())
              update_todo_title(todo.id, inp.value)
              editing_id.set(None)
            }
          })
          .keydown(e => {
            let todo = get_todo()
            let inp = @dom.HTMLInputElement::cast_from_element(e.target())
            if e.key == "Enter" && not(edit_composing.val) {
              update_todo_title(todo.id, inp.value)
              editing_id.set(None)
            } else if e.key == "Escape" {
              inp.value = todo.title
              editing_id.set(None)
            }
          }),
      ),
    ])
  }

  /// Render header with new todo input
  fn render_header() -> DomNode {
    header_(class="header", [
      h1([text("todos")]),
      input(
        class="new-todo",
        placeholder="What needs to be done?",
        attrs=[("autofocus", Attr::AttrBool(true))],
        on=events()
          .input(e => {
            let inp = @dom.HTMLInputElement::cast_from_element(e.target())
            new_todo_text.set(inp.value)
          })
          .compositionstart(_ => is_composing.set(true))
          .compositionend(_ => is_composing.set(false))
          .keydown(e => if e.key == "Enter" && not(is_composing.peek()) {
            add_todo()
            @dom.HTMLInputElement::cast_from_element(e.target()).value = ""
          }),
      ),
    ])
  }

  /// Render main section with todo list
  fn render_main() -> DomNode {
    section(class="main", dyn_style=visible_when(has_todos), [
      // Toggle all checkbox
      input(
        id="toggle-all",
        class="toggle-all",
        type_="checkbox",
        dyn_checked=all_completed,
        on=events().change(_ => toggle_all()),
      ),
      label(for_="toggle-all", [text("Mark all as complete")]),
      // Todo list
      ul(class="todo-list", [index_each(filtered_todos, render_todo_item)]),
    ])
  }

  /// Render footer with count and filters
  fn render_footer() -> DomNode {
    footer_(class="footer", dyn_style=visible_when(has_todos), [
      // Item count
      span(class="todo-count", [
        strong([text_dyn(fn() { active_count().to_string() })]),
        text_dyn(fn() {
          if active_count() == 1 {
            " item left"
          } else {
            " items left"
          }
        }),
      ]),
      // Filter links
      ul(class="filters", [
        filter_link("#/", "All", filter, All),
        filter_link("#/active", "Active", filter, Active),
        filter_link("#/completed", "Completed", filter, Completed),
      ]),
      // Clear completed button (with Luna CSS hover effect)
      button(
        class=classes(["clear-completed", hover_underline]),
        on=events().click(_ => clear_completed()),
        dyn_style=visible_when(fn() { completed_count() > 0 }),
        [text("Clear completed")],
      ),
    ])
  }

  // ---------------------------------------------------------------------------
  // Main App Structure
  // ---------------------------------------------------------------------------
  section(class="todoapp", [render_header(), render_main(), render_footer()])
}

// =============================================================================
// Main Entry Point
// =============================================================================

///|
/// Check if Luna utility CSS is already embedded in HTML
/// (via static build with `luna css inject`)
extern "js" fn has_static_css() -> Bool =
  #| () => {
  #|   const styles = document.querySelectorAll('style');
  #|   for (const s of styles) {
  #|     if (s.textContent && s.textContent.includes('LUNA_CSS_START')) {
  #|       return true;
  #|     }
  #|   }
  #|   return false;
  #| }

///|
fn main {
  let doc = @dom.document()
  match doc.getElementById("app") {
    Some(el) => {
      render(el |> DomElement::from_dom, app())
      // Inject utility CSS only if not pre-embedded (zero-runtime for production)
      if not(has_static_css()) {
        let css = @css.generate_full_css()
        if css.length() > 0 {
          @element.use_style(css, el)
        }
      }
    }
    None => ()
  }
}
