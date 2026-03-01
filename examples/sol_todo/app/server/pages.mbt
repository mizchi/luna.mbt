///| Page Handlers

// =============================================================================
// Home Page - Todo List with Island
// =============================================================================

///|
/// Home page - displays todo list with form-based interactions
async fn home_page(_props : @router.PageProps) -> @server_dom.ServerNode {
  @server_dom.ServerNode::async_(fn() {
    let todos = get_todos()
    let completed_count = todos.iter().filter(fn(t) { t.completed }).count()
    let total_count = todos.length()

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
          action="/_action/toggle-todo",
          style="display: inline;",
          [
            input(type_="hidden", name="id", value=todo.id.to_string()),
            button(
              class="todo-checkbox-btn",
              attrs=[("type", @luna.attr_static("submit")), ("title", @luna.attr_static("Toggle"))],
              [text(if todo.completed { "[x]" } else { "[ ]" })],
            ),
          ],
        ),
        span(class="todo-text", [text(todo.text)]),
        // Delete form
        form(
          http_method="POST",
          action="/_action/delete-todo",
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
          action="/_action/add-todo",
          class="add-form",
          style="margin-bottom: 1rem;",
          [
            input(
              type_="text",
              name="text",
              placeholder="Quick add...",
              required=true,
            ),
            button(
              attrs=[("type", @luna.attr_static("submit"))],
              [text("Add")],
            ),
          ],
        ),
        // Todo list
        ul(class="todo-list", todo_items),
        // Stats island (hydrated)
        h3([text("Statistics")]),
        @server_dom.client(
          @types.todo_list(stats_props),
          [
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
                button(class="btn refresh-btn", disabled=true, [text("Refresh Stats")]),
              ]),
            ]),
          ],
        ),
      ]),
    ]

    @luna.fragment(content)
  })
}

// =============================================================================
// Add Page - Form with Server Actions
// =============================================================================

///|
/// Add todo page - dedicated form page
async fn add_page(_props : @router.PageProps) -> @server_dom.ServerNode {
  @server_dom.ServerNode::sync(@luna.fragment([
    div(class="card", [
      h1([text("Add New Todo")]),
      p([text("Enter a new todo item below.")]),
      form(
        http_method="POST",
        action="/_action/add-todo",
        class="add-form",
        [
          input(
            type_="text",
            name="text",
            placeholder="What needs to be done?",
            required=true,
          ),
          button(
            attrs=[("type", @luna.attr_static("submit"))],
            [text("Add Todo")],
          ),
        ],
      ),
      p(style="color: #666; font-size: 0.9rem; margin-top: 1rem;", [
        text("This form works with or without JavaScript enabled."),
      ]),
      p([
        sol_link(href="/", [text("Back to List")]),
      ]),
    ]),
  ]))
}

// =============================================================================
// About Page - Static (CSR Navigation Test)
// =============================================================================

///|
/// About page - static content for CSR navigation testing
async fn about_page(_props : @router.PageProps) -> @server_dom.ServerNode {
  @server_dom.ServerNode::sync(@luna.fragment([
    div(class="card", [
      h1([text("About Sol Todo")]),
      p([
        text("This is a simple Todo application built with Sol framework."),
      ]),
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
      p([
        sol_link(href="/", [text("Back to Todo List")]),
      ]),
    ]),
  ]))
}
