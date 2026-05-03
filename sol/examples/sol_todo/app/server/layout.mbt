///| Layout and Styles

///|
/// Default styles
let default_style : String =
  #|<style>
  #|  * { box-sizing: border-box; }
  #|  body {
  #|    font-family: system-ui, -apple-system, sans-serif;
  #|    max-width: 600px;
  #|    margin: 0 auto;
  #|    padding: 2rem;
  #|    background: #f5f5f5;
  #|  }
  #|  nav {
  #|    margin-bottom: 2rem;
  #|    padding: 1rem;
  #|    background: white;
  #|    border-radius: 8px;
  #|    box-shadow: 0 1px 3px rgba(0,0,0,0.1);
  #|  }
  #|  nav a {
  #|    margin-right: 1.5rem;
  #|    color: #0066cc;
  #|    text-decoration: none;
  #|    font-weight: 500;
  #|  }
  #|  nav a:hover { text-decoration: underline; }
  #|  .card {
  #|    background: white;
  #|    padding: 1.5rem;
  #|    border-radius: 8px;
  #|    box-shadow: 0 1px 3px rgba(0,0,0,0.1);
  #|    margin-bottom: 1rem;
  #|  }
  #|  h1 { margin-top: 0; color: #333; }
  #|  h2 { color: #555; }
  #|  .todo-list { list-style: none; padding: 0; margin: 0; }
  #|  .todo-item {
  #|    display: flex;
  #|    align-items: center;
  #|    padding: 0.75rem;
  #|    border-bottom: 1px solid #eee;
  #|    gap: 0.75rem;
  #|  }
  #|  .todo-item:last-child { border-bottom: none; }
  #|  .todo-item.completed .todo-text {
  #|    text-decoration: line-through;
  #|    color: #999;
  #|  }
  #|  .todo-text { flex: 1; }
  #|  .todo-checkbox {
  #|    width: 20px;
  #|    height: 20px;
  #|    cursor: pointer;
  #|  }
  #|  .todo-delete {
  #|    background: #ff4444;
  #|    color: white;
  #|    border: none;
  #|    padding: 0.25rem 0.5rem;
  #|    border-radius: 4px;
  #|    cursor: pointer;
  #|    font-size: 0.8rem;
  #|  }
  #|  .todo-delete:hover { background: #cc0000; }
  #|  .add-form {
  #|    display: flex;
  #|    gap: 0.5rem;
  #|  }
  #|  .add-form input {
  #|    flex: 1;
  #|    padding: 0.75rem;
  #|    border: 1px solid #ddd;
  #|    border-radius: 4px;
  #|    font-size: 1rem;
  #|  }
  #|  .add-form button, .btn {
  #|    background: #0066cc;
  #|    color: white;
  #|    border: none;
  #|    padding: 0.75rem 1.5rem;
  #|    border-radius: 4px;
  #|    cursor: pointer;
  #|    font-size: 1rem;
  #|  }
  #|  .add-form button:hover, .btn:hover { background: #0055aa; }
  #|  .stats {
  #|    margin-top: 1rem;
  #|    padding: 0.75rem;
  #|    background: #f0f0f0;
  #|    border-radius: 4px;
  #|    font-size: 0.9rem;
  #|    color: #666;
  #|  }
  #|  .error { color: #cc0000; margin-top: 0.5rem; }
  #|  .success { color: #00aa00; margin-top: 0.5rem; }
  #|</style>

///|
/// Loader script
let loader_script : String = "<script type=\"module\" src=\"/__sol__/loader.js\"></script>"

///|
/// Sol navigation script for CSR
let sol_nav_script : String = "<script type=\"module\" src=\"/__sol__/sol-nav.js\"></script>"

///|
/// Head HTML
pub fn head() -> String {
  default_style + loader_script + sol_nav_script
}

///|
/// Navigation component
fn navigation() -> @luna.Node[Unit, String] {
  nav([
    sol_link(href="/", [text("Todo List")]),
    sol_link(href="/add", [text("Add Todo")]),
    sol_link(href="/about", [text("About")]),
  ])
}

///|
/// Root layout
pub fn root_layout(
  _props : @sol.PageProps,
  content : @server_dom.ServerNode,
) -> @server_dom.ServerNode raise Error {
  @server_dom.ServerNode::async_(async fn() {
    let inner = content.resolve()
    div(class="app", [
      navigation(),
      // Use outlet for CSR navigation - sol-nav.js will replace this content
      outlet(name="main", class="content", [inner]),
    ])
  })
}
