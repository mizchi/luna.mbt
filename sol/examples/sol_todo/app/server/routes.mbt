///| Sol Todo Example - Routes and Actions

///| Demonstrates SSR, CSR navigation, Islands, and Server Actions

// =============================================================================
// Routes Definition
// =============================================================================

///|
/// Application routes
pub fn routes() -> Array[@sol.SolRoutes] {
  [
    @sol.with_mw([@mw.security_headers_relaxed(), @mw.logger()], [
      @sol.wrap("", @layout.root_layout, [
        // Home - Todo list with Island
        @sol.route("/", home_page, title="Todo List"),
        // Add Todo - Form with Server Actions
        @sol.route("/add", add_page, title="Add Todo"),
        // About - Static page for CSR navigation test
        @sol.route("/about", about_page, title="About"),
      ]),
      // API endpoints
      @sol.with_mw([@mw.cors()], [
        @sol.api_get("/api/todos", api_get_todos),
        @sol.api_post("/api/todos", api_add_todo),
        @sol.api_delete("/api/todos/:id", api_delete_todo),
      ]),
    ]),
  ]
}

// =============================================================================
// Page Handlers
// =============================================================================

///|
/// Home page - displays todo list with form-based interactions
async fn home_page(_props : @sol.PageProps) -> @server_dom.ServerNode {
  @server_dom.ServerNode::async_(fn() {
    let todos = get_todos()
    let completed_count = todos.iter().filter(fn(t) { t.completed }).count()
    let total_count = todos.length()
    let add_todo_url = @action.action_url(@types.action_add_todo())
    let toggle_todo_url = @action.action_url(@types.action_toggle_todo())
    let delete_todo_url = @action.action_url(@types.action_delete_todo())

    // Server-rendered todo items with form actions
    let todo_items = todos.map(fn(todo) {
      let item_class = if todo.completed {
        "todo-item completed"
      } else {
        "todo-item"
      }
      li(class=item_class, [
        // Toggle form (checkbox-like)
        form(
          http_method="POST",
          action=toggle_todo_url,
          style="display: inline;",
          [
            input(type_="hidden", name="id", value=todo.id.to_string()),
            button(
              class="todo-checkbox-btn",
              attrs=[
                ("type", @luna.attr_static("submit")),
                ("title", @luna.attr_static("Toggle")),
              ],
              [text(if todo.completed { "[x]" } else { "[ ]" })],
            ),
          ],
        ),
        span(class="todo-text", [text(todo.text)]),
        // Delete form
        form(
          http_method="POST",
          action=delete_todo_url,
          style="display: inline;",
          [
            input(type_="hidden", name="id", value=todo.id.to_string()),
            button(
              class="todo-delete",
              attrs=[("type", @luna.attr_static("submit"))],
              [text("Delete")],
            ),
          ],
        ),
      ])
    })

    // Island props for stats
    let stats_props : @types.TodoListProps = {
      total: total_count,
      completed: completed_count,
    }

    let content = [
      div(class="card", [
        h1([text("Todo List")]),
        // Quick add form at top
        form(
          http_method="POST",
          action=add_todo_url,
          class="add-form",
          style="margin-bottom: 1rem;",
          [
            input(
              type_="text",
              name="text",
              placeholder="Quick add...",
              required=true,
            ),
            button(attrs=[("type", @luna.attr_static("submit"))], [text("Add")]),
          ],
        ),
        // Todo list
        ul(class="todo-list", todo_items),
        // Stats island (hydrated)
        h3([text("Statistics")]),
        @server_dom.client(@types.todo_list(stats_props), [
          div(class="stats-island", [
            div(class="stat-row", [
              span(class="stat-label", [text("Total: ")]),
              span(class="stat-value", [text(total_count.to_string())]),
            ]),
            div(class="stat-row", [
              span(class="stat-label", [text("Completed: ")]),
              span(class="stat-value", [text(completed_count.to_string())]),
            ]),
            div(class="stat-actions", [
              button(class="btn refresh-btn", disabled=true, [
                text("Refresh Stats"),
              ]),
            ]),
          ]),
        ]),
      ]),
    ]

    @luna.fragment(content)
  })
}

///|
/// Add todo page - dedicated form page
async fn add_page(_props : @sol.PageProps) -> @server_dom.ServerNode {
  let add_todo_url = @action.action_url(@types.action_add_todo())
  @sol.nodes([
    div(class="card", [
      h1([text("Add New Todo")]),
      p([text("Enter a new todo item below.")]),
      form(http_method="POST", action=add_todo_url, class="add-form", [
        input(
          type_="text",
          name="text",
          placeholder="What needs to be done?",
          required=true,
        ),
        button(attrs=[("type", @luna.attr_static("submit"))], [text("Add Todo")]),
      ]),
      p(style="color: #666; font-size: 0.9rem; margin-top: 1rem;", [
        text("This form works with or without JavaScript enabled."),
      ]),
      p([sol_link(href="/", [text("Back to List")])]),
    ]),
  ])
}

///|
/// About page - static content for CSR navigation testing
async fn about_page(_props : @sol.PageProps) -> @server_dom.ServerNode {
  @sol.nodes([
    div(class="card", [
      h1([text("About Sol Todo")]),
      p([text("This is a simple Todo application built with Sol framework.")]),
      h2([text("Features Demonstrated")]),
      ul([
        li([text("SSR (Server-Side Rendering) with MoonBit")]),
        li([text("CSR Navigation using data-sol-link")]),
        li([text("Island Architecture for partial hydration")]),
        li([text("Server Actions with CSRF protection")]),
        li([text("Progressive Enhancement (works without JS)")]),
      ]),
      h2([text("Technology Stack")]),
      ul([
        li([text("MoonBit - Systems programming language")]),
        li([text("Sol - SSR-first web framework")]),
        li([text("Luna - Virtual DOM library")]),
        li([text("Hono - Lightweight web server")]),
      ]),
      p([sol_link(href="/", [text("Back to Todo List")])]),
    ]),
  ])
}

// =============================================================================
// In-Memory Todo Store
// =============================================================================

///|
/// Todo item structure
pub(all) struct Todo {
  id : Int
  text : String
  completed : Bool
} derive(ToJson, FromJson)

///|
/// Global todo store
let todo_store : Ref[Array[Todo]] = { val: [] }

///|
/// Next ID counter
let next_id : Ref[Int] = { val: 1 }

///|
/// Initialize with sample data
fn ensure_initialized() -> Unit {
  if todo_store.val.is_empty() {
    todo_store.val = [
      { id: 1, text: "Learn MoonBit", completed: true },
      { id: 2, text: "Build a Sol app", completed: false },
      { id: 3, text: "Write tests", completed: false },
    ]
    next_id.val = 4
  }
}

///|
/// Get all todos
fn get_todos() -> Array[Todo] {
  ensure_initialized()
  todo_store.val
}

///|
/// Add a new todo
fn add_todo(text : String) -> Todo {
  ensure_initialized()
  let todo : Todo = { id: next_id.val, text, completed: false }
  next_id.val = next_id.val + 1
  todo_store.val.push(todo)
  todo
}

///|
/// Toggle todo completion
fn toggle_todo(id : Int) -> Bool {
  ensure_initialized()
  for i, todo in todo_store.val {
    if todo.id == id {
      todo_store.val[i] = { ..todo, completed: !todo.completed }
      return true
    }
  }
  false
}

///|
/// Delete a todo
fn delete_todo(id : Int) -> Bool {
  ensure_initialized()
  let initial_len = todo_store.val.length()
  todo_store.val = todo_store.val.iter().filter(fn(t) { t.id != id }).collect()
  todo_store.val.length() < initial_len
}

// =============================================================================
// API Handlers
// =============================================================================

///|
/// GET /api/todos - List all todos
async fn api_get_todos(_props : @sol.PageProps) -> Json {
  let todos = get_todos()
  let todos_json : Array[Json] = todos.map(fn(t) { t.to_json() })
  { "todos": todos_json.to_json() }.to_json()
}

///|
/// Extract string field from JSON object
fn get_json_string(json : Json?, field : String) -> String {
  match json {
    Some(Object(obj)) =>
      match obj.get(field) {
        Some(String(s)) => s
        _ => ""
      }
    _ => ""
  }
}

///|
/// POST /api/todos - Add a new todo
async fn api_add_todo(props : @sol.PageProps) -> Json {
  let json = props.body_json()
  let text = get_json_string(json, "text")
  if text == "" {
    return { "error": "text is required" }.to_json()
  }
  let todo = add_todo(text)
  todo.to_json()
}

///|
/// DELETE /api/todos/:id - Delete a todo
async fn api_delete_todo(props : @sol.PageProps) -> Json {
  let id_str = match @types.params_api_todos_id(props) {
    Ok(p) => p.id
    Err(_) => ""
  }
  let id = parse_int(id_str)
  if id <= 0 {
    return { "error": "invalid id" }.to_json()
  }
  let deleted = delete_todo(id)
  { "deleted": deleted.to_json() }.to_json()
}

// =============================================================================
// Server Actions
// =============================================================================

///|
priv struct AddTodoRequest {
  text : String
} derive(FromJson)

///|
priv struct TodoIdRequest {
  id : Int
} derive(FromJson)

///|
priv struct ToggleTodoResponse {
  toggled : Bool
} derive(ToJson)

///|
priv struct DeleteTodoResponse {
  deleted : Bool
} derive(ToJson)

///|
/// Add todo action handler
let add_todo_action : @action.ActionHandler = @action.ActionHandler(async fn(
  ctx,
) {
  let content_type = ctx.get_header("Content-Type").unwrap_or("")
  let is_form = content_type.contains("application/x-www-form-urlencoded")

  let text = if is_form {
    let data = parse_form_urlencoded(ctx.body)
    get_string_field(data, "text")
  } else {
    let req : AddTodoRequest = match ctx.decode_json() {
      Some(req) => req
      None => return @action.ActionResult::bad_request("Invalid JSON payload")
    }
    req.text
  }

  if text == "" {
    return @action.ActionResult::bad_request("Todo text is required")
  }

  let todo = add_todo(text)

  if is_form {
    @action.ActionResult::http_redirect("/")
  } else {
    @action.ActionResult::json(todo)
  }
})

///|
/// Toggle todo action handler
let toggle_todo_action : @action.ActionHandler = @action.ActionHandler(async fn(
  ctx,
) {
  let content_type = ctx.get_header("Content-Type").unwrap_or("")
  let is_form = content_type.contains("application/x-www-form-urlencoded")

  let id = if is_form {
    let data = parse_form_urlencoded(ctx.body)
    get_int_field(data, "id")
  } else {
    let req : TodoIdRequest = match ctx.decode_json() {
      Some(req) => req
      None => return @action.ActionResult::bad_request("Invalid JSON payload")
    }
    req.id
  }

  if id <= 0 {
    return @action.ActionResult::bad_request("Invalid todo id")
  }

  let success = toggle_todo(id)
  if is_form {
    @action.ActionResult::http_redirect("/")
  } else if success {
    @action.ActionResult::json(ToggleTodoResponse::{ toggled: true })
  } else {
    @action.ActionResult::not_found(message="Todo not found")
  }
})

///|
/// Delete todo action handler
let delete_todo_action : @action.ActionHandler = @action.ActionHandler(async fn(
  ctx,
) {
  let content_type = ctx.get_header("Content-Type").unwrap_or("")
  let is_form = content_type.contains("application/x-www-form-urlencoded")

  let id = if is_form {
    let data = parse_form_urlencoded(ctx.body)
    get_int_field(data, "id")
  } else {
    let req : TodoIdRequest = match ctx.decode_json() {
      Some(req) => req
      None => return @action.ActionResult::bad_request("Invalid JSON payload")
    }
    req.id
  }

  if id <= 0 {
    return @action.ActionResult::bad_request("Invalid todo id")
  }

  let success = delete_todo(id)
  if is_form {
    @action.ActionResult::http_redirect("/")
  } else if success {
    @action.ActionResult::json(DeleteTodoResponse::{ deleted: true })
  } else {
    @action.ActionResult::not_found(message="Todo not found")
  }
})

///|
/// Action registry
pub fn action_registry() -> @action.ActionRegistry {
  @action.ActionRegistry::new(allowed_origins=[
    "http://localhost:3000", "http://localhost:7777",
  ])
  .register(
    @action.ActionDef::from_key(@types.action_add_todo(), add_todo_action).with_require_json(
      false,
    ),
  )
  .register(
    @action.ActionDef::from_key(@types.action_toggle_todo(), toggle_todo_action).with_require_json(
      false,
    ),
  )
  .register(
    @action.ActionDef::from_key(@types.action_delete_todo(), delete_todo_action).with_require_json(
      false,
    ),
  )
}

// =============================================================================
// FFI Utilities
// =============================================================================

///|
extern "js" fn parse_form_urlencoded(s : String) -> @core.Any =
  #| (s) => Object.fromEntries(new URLSearchParams(s))

///|
extern "js" fn get_string_field(obj : @core.Any, field : String) -> String =
  #| (obj, field) => obj[field] || ""

///|
extern "js" fn get_int_field(obj : @core.Any, field : String) -> Int =
  #| (obj, field) => parseInt(obj[field], 10) || 0

///|
extern "js" fn parse_int(s : String) -> Int =
  #| (s) => parseInt(s, 10) || 0

// =============================================================================
// Router Config
// =============================================================================

///|
const ROOT : String =
  #|<!DOCTYPE html>
  #|<html lang="en">
  #|<head>
  #|  <meta charset="UTF-8">
  #|  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  #|  <title>__LUNA_TITLE__</title>
  #|  __LUNA_PRELOAD__
  #|  __LUNA_HEAD__
  #|</head>
  #|<body>
  #|  <div id="__sol__">__LUNA_MAIN__</div>
  #|</body>
  #|</html>

///|
pub fn config() -> @sol.RouterConfig {
  @sol.RouterConfig::default()
  .with_root_template(ROOT)
  .with_default_head(@layout.head())
}
