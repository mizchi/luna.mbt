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
  let body_html = @renderer.render_to_string_with_hydration(node)

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
  @renderer.render_to_string_with_hydration(node)
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

// ============================================================================
// Island Architecture Support
// ============================================================================

///|
/// Default loader script URL
pub let default_loader_url : String = "/kg-loader-v1.js"

// Re-export embed types for convenience
pub using @embed {type TriggerType, type StateConfig, type EmbedConfig}

///|
/// Island configuration
pub struct IslandConfig {
  /// Unique identifier for the island
  id : String
  /// ES module URL for hydration script
  script_url : String
  /// Hydration trigger type
  trigger : @embed.TriggerType
  /// State configuration
  state : @embed.StateConfig
  /// SSR rendered content (VNode)
  content : @kaguya.Node?
  /// SSR rendered HTML string (alternative to content)
  ssr_html : String?
}

///|
/// Create a new island configuration
pub fn IslandConfig::new(id : String, script_url : String) -> IslandConfig {
  {
    id,
    script_url,
    trigger: @embed.TriggerType::Load,
    state: @embed.StateConfig::Empty,
    content: None,
    ssr_html: None,
  }
}

///|
/// Builder: set trigger type
pub fn IslandConfig::with_trigger(
  self : IslandConfig,
  trigger : @embed.TriggerType
) -> IslandConfig {
  { ..self, trigger }
}

///|
/// Builder: set inline state from JSON
pub fn IslandConfig::with_state(self : IslandConfig, json : String) -> IslandConfig {
  { ..self, state: @embed.StateConfig::Inline(json) }
}

///|
/// Builder: set state from script reference
pub fn IslandConfig::with_state_ref(
  self : IslandConfig,
  script_id : String
) -> IslandConfig {
  { ..self, state: @embed.StateConfig::ScriptRef(script_id) }
}

///|
/// Builder: set state from URL
pub fn IslandConfig::with_state_url(self : IslandConfig, url : String) -> IslandConfig {
  { ..self, state: @embed.StateConfig::Url(url) }
}

///|
/// Builder: set SSR content from VNode
pub fn IslandConfig::with_content(
  self : IslandConfig,
  node : @kaguya.Node
) -> IslandConfig {
  { ..self, content: Some(node) }
}

///|
/// Builder: set SSR content from raw HTML string
pub fn IslandConfig::with_ssr_html(self : IslandConfig, html : String) -> IslandConfig {
  { ..self, ssr_html: Some(html) }
}

///|
/// Render an island to HTML string
pub fn render_island(config : IslandConfig) -> String {
  // Priority: ssr_html > content (VNode) > empty
  let ssr_content = match config.ssr_html {
    Some(html) => html
    None =>
      match config.content {
        Some(node) => @renderer.render_to_string_with_hydration(node)
        None => ""
      }
  }

  // Convert state to embed format
  let embed_config = @embed.EmbedConfig::new(config.id, config.script_url)
    .with_trigger(config.trigger)
    .with_ssr_content(ssr_content)

  // Apply state configuration
  let final_config = match config.state {
    @embed.StateConfig::Empty => embed_config
    @embed.StateConfig::Inline(json) => embed_config.with_state(json)
    @embed.StateConfig::ScriptRef(id) => embed_config.with_state_ref(id)
    @embed.StateConfig::Url(url) => embed_config.with_state_url(url)
  }

  @embed.generate_embed(final_config).html
}

///|
/// Render a page with islands
/// Includes the loader script automatically
pub fn render_island_page(
  islands : Array[String],
  title? : String,
  head? : String,
  loader_url? : String
) -> String {
  let title_str = title.unwrap_or("App")
  let head_str = head.unwrap_or("")
  let loader = loader_url.unwrap_or(default_loader_url)

  let sb = StringBuilder::new(size_hint=4096)
  sb.write_string("<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"><title>")
  sb.write_string(title_str)
  sb.write_string("</title>")
  sb.write_string(head_str)
  sb.write_string("<script type=\"module\" src=\"")
  sb.write_string(loader)
  sb.write_string("\"></script></head><body>")

  for island_html in islands {
    sb.write_string(island_html)
  }

  sb.write_string("</body></html>")
  sb.to_string()
}

///|
/// Register an island page route
pub fn island_page(
  app : App,
  path : String,
  render_fn : (Ctx) -> Array[IslandConfig],
  title? : String,
  head? : String,
  loader_url? : String
) -> App {
  app.get(path, fn(c) {
    let islands = render_fn(c)
    let island_htmls = islands.map(fn(config) { render_island(config) })
    let html = render_island_page(island_htmls, title?, head?, loader_url?)
    c.html(html)
  })
}

///|
/// Render island with separate state script (for large state)
pub fn render_island_with_state_script(
  config : IslandConfig,
  state_json : String
) -> String {
  // Priority: ssr_html > content (VNode) > empty
  let ssr_content = match config.ssr_html {
    Some(html) => html
    None =>
      match config.content {
        Some(node) => @renderer.render_to_string_with_hydration(node)
        None => ""
      }
  }

  let embed_config = @embed.EmbedConfig::new(config.id, config.script_url)
    .with_trigger(config.trigger)
    .with_ssr_content(ssr_content)

  @embed.generate_embed_with_state_script(embed_config, state_json).html
}

///|
/// Generate state script tag for external state
pub fn generate_state_script(id : String, json : String) -> String {
  @embed.generate_state_script(id, json)
}

///|
/// Escape JSON for safe embedding in HTML attributes
pub fn escape_json_for_attr(json : String) -> String {
  @embed.escape_json_for_attr(json)
}

///|
/// Escape JSON for safe embedding in script tags
pub fn escape_json_for_html(json : String) -> String {
  @embed.escape_json_for_html(json)
}
