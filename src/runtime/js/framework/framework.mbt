///| Framework - SSR-first Web Framework for MoonBit
///|
///| Built on top of Hono, providing SSR with ui.mbt VNodes.
///| Inspired by Next.js, Solid Start, and Qwik City.

///|
/// Environment bindings (e.g., Cloudflare Workers KV)
pub type Env = Unit

///|
/// Execution context (e.g., Cloudflare Workers context)
pub type ExecutionContext = Unit

///|
/// Hono app type alias
pub type App = @hono.Hono[Env, ExecutionContext]

///|
/// Hono context type alias
pub type Ctx = @hono.Context[Env, ExecutionContext]

///|
/// Create a new framework application (async)
pub async fn create_app() -> App {
  @hono.Hono::new()
}

///|
extern "js" fn ffi_new_hono_async() -> @core.Promise[@core.Any] =
  #| () => import("hono").then(m => new m.Hono())

///|
/// Create a new framework application and run callback with it
/// This is useful for main function that cannot be async
pub fn create_app_then(callback : (App) -> Unit) -> Unit {
  let _ = ffi_new_hono_async().then(fn(app) {
    callback(app.cast())
    @core.Promise::resolve(@core.any(()))
  })
}

///|
/// Render a VNode to HTML string with full document wrapper
pub fn render_page(
  node : @kaguya.Node,
  title? : String,
  head? : String,
) -> String {
  let title_str = title.unwrap_or("App")
  let head_str = head.unwrap_or("")
  let body_html = @ssr.render_to_string_with_hydration(node)

  "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"><title>" +
  title_str +
  "</title>" +
  head_str +
  "</head><body><div id=\"app\">" +
  body_html +
  "</div></body></html>"
}

///|
/// Render a VNode to HTML string without document wrapper (for partial/fragment responses)
pub fn render_fragment(node : @kaguya.Node) -> String {
  @ssr.render_to_string_with_hydration(node)
}

///|
/// Register a page route that renders a VNode
pub fn page(
  app : App,
  path : String,
  render_fn : (Ctx) -> @kaguya.Node,
  title? : String,
  head? : String,
) -> App {
  app.get(path, fn(c) {
    let node = render_fn(c)
    let html = render_page(node, title?, head?)
    c.html(html)
  })
}

///|
/// Register an API route that returns JSON
pub fn api(
  app : App,
  path : String,
  handler : (Ctx) -> @core.Any,
) -> App {
  app.get(path, fn(c) { c.json(handler(c)) })
}

///|
/// Register a POST API route
pub fn api_post(
  app : App,
  path : String,
  handler : (Ctx) -> @core.Any,
) -> App {
  app.post(path, fn(c) { c.json(handler(c)) })
}

///|
/// Serve the app using @hono/node-server
pub fn serve(app : App, port : Int) -> Unit {
  ffi_serve(app.as_any(), port)
}

///|
extern "js" fn ffi_serve(app : @core.Any, port : Int) -> Unit =
  #|(app, port) => {
  #|  const { serve } = require('@hono/node-server');
  #|  serve({ fetch: app.fetch, port });
  #|  console.log(`Server running at http://localhost:${port}`);
  #|}
