// Runtime island helpers

///|
extern "js" fn encode_uri_component(value : String) -> String =
  #| (value) => encodeURIComponent(value)

// ============================================================================
// Island Architecture Support
// ============================================================================

///|
/// Default loader script URL
pub let default_loader_url : String = "/__sol__/loader.js"

///|
/// Island configuration
pub struct IslandConfig[E] {
  /// Unique identifier for the island
  id : String
  /// ES module URL for hydration script
  script_url : String
  /// Hydration trigger type
  trigger : @luna.TriggerType
  /// State configuration
  state : @stella.StateConfig
  /// SSR rendered content (VNode)
  content : @luna.Node[E, String]?
  /// SSR rendered HTML string (alternative to content)
  ssr_html : String?
}

///|
/// Create a new island configuration
pub fn[E] IslandConfig::new(
  id : String,
  script_url : String,
) -> IslandConfig[E] {
  {
    id,
    script_url,
    trigger: @luna.TriggerType::Load,
    state: @stella.StateConfig::Empty,
    content: None,
    ssr_html: None,
  }
}

///|
/// Builder: set trigger type
pub fn[E] IslandConfig::with_trigger(
  self : IslandConfig[E],
  trigger : @luna.TriggerType,
) -> IslandConfig[E] {
  { ..self, trigger, }
}

///|
/// Builder: set inline state from JSON
pub fn[E] IslandConfig::with_state(
  self : IslandConfig[E],
  json : String,
) -> IslandConfig[E] {
  { ..self, state: @stella.StateConfig::Inline(json) }
}

///|
/// Builder: set state from script reference
pub fn[E] IslandConfig::with_state_ref(
  self : IslandConfig[E],
  script_id : String,
) -> IslandConfig[E] {
  { ..self, state: @stella.StateConfig::ScriptRef(script_id) }
}

///|
/// Builder: set state from URL
pub fn[E] IslandConfig::with_state_url(
  self : IslandConfig[E],
  url : String,
) -> IslandConfig[E] {
  { ..self, state: @stella.StateConfig::Url(url) }
}

///|
/// Builder: set SSR content from VNode
pub fn[E] IslandConfig::with_content(
  self : IslandConfig[E],
  node : @luna.Node[E, String],
) -> IslandConfig[E] {
  { ..self, content: Some(node) }
}

///|
/// Builder: set SSR content from raw HTML string
pub fn[E] IslandConfig::with_ssr_html(
  self : IslandConfig[E],
  html : String,
) -> IslandConfig[E] {
  { ..self, ssr_html: Some(html) }
}

///|
/// Render an island to HTML string
pub fn[E] render_island(config : IslandConfig[E]) -> String {
  // Priority: ssr_html > content (VNode) > empty
  let ssr_content = match config.ssr_html {
    Some(html) => html
    None =>
      match config.content {
        Some(node) => @render.render_to_string_with_hydration(node)
        None => ""
      }
  }

  // Convert state to shard format
  let shard_config = @stella.ShardConfig::new(config.id, config.script_url)
    .with_trigger(config.trigger)
    .with_ssr_content(ssr_content)

  // Apply state configuration
  let final_config = match config.state {
    @stella.StateConfig::Empty => shard_config
    @stella.StateConfig::Inline(json) => shard_config.with_state(json)
    @stella.StateConfig::ScriptRef(id) => shard_config.with_state_ref(id)
    @stella.StateConfig::Url(url) => shard_config.with_state_url(url)
  }
  @stella.generate_shard(final_config).html
}

///|
/// Render a page with islands
/// Includes the loader script automatically
pub fn render_island_page(
  islands : Array[String],
  title? : String,
  head? : String,
  loader_url? : String,
) -> String {
  let title_str = title.unwrap_or("App")
  let head_str = head.unwrap_or("")
  let loader = loader_url.unwrap_or(default_loader_url)
  let full_head = head_str +
    "<script type=\"module\" src=\"" +
    loader +
    "\"></script>"
  let sb = StringBuilder::new(size_hint=4096)
  for island_html in islands {
    sb.write_string(island_html)
  }
  @page_shell.render_document(
    title_str,
    full_head,
    sb.to_string(),
    wrap_in_app=false,
  )
}

///|
/// Register an island page route
pub fn[E] island_page(
  app : App,
  path : String,
  render_fn : (Ctx) -> Array[IslandConfig[E]],
  title? : String,
  head? : String,
  loader_url? : String,
) -> Unit {
  app.get(
    path,
    @mars.handler(async fn(c) {
      let islands = render_fn(c)
      let island_htmls = islands.map(fn(config) { render_island(config) })
      let html = render_island_page(island_htmls, title?, head?, loader_url?)
      c.html(html)
    }),
  )
}

///|
/// Render island with separate state script (for large state)
pub fn[E] render_island_with_state_script(
  config : IslandConfig[E],
  state_json : String,
) -> String {
  // Priority: ssr_html > content (VNode) > empty
  let ssr_content = match config.ssr_html {
    Some(html) => html
    None =>
      match config.content {
        Some(node) => @render.render_to_string_with_hydration(node)
        None => ""
      }
  }
  let shard_config = @stella.ShardConfig::new(config.id, config.script_url)
    .with_trigger(config.trigger)
    .with_ssr_content(ssr_content)
  @stella.generate_shard_with_state_script(shard_config, state_json).html
}

///|
/// Generate state script tag for external state
pub fn generate_state_script(id : String, json : String) -> String {
  @stella.generate_state_script(id, json)
}

// ============================================================================
// Server Island VNode Support (deferred server-side rendering)
// ============================================================================

///|
/// Create a Server Island VNode that renders a placeholder with `luna:defer` attribute.
/// The client-side loader will fetch the actual content from `/_sol/defer/:id`.
///
/// Example:
/// ```moonbit nocheck
/// @sol.server_island(
///   id="user-profile",
///   props=Json::Object({ "userId": Json::String("123") }),
///   fallback=div([text("Loading...")]),
/// )
/// ```
pub fn[E] server_island(
  id~ : String,
  props? : Json? = None,
  fallback? : @luna.Node[E, String] = @luna.text(""),
  revalidate? : Int? = None,
) -> @luna.Node[E, String] {
  // Build the defer URL with encoded props
  let props_json = props.unwrap_or(().to_json())
  let props_encoded = encode_uri_component(props_json.stringify())
  let defer_url = "/_sol/defer/" + id + "?props=" + props_encoded
  // Build attributes
  let attrs : Array[(String, @luna.Attr[E, String])] = [
    ("luna:defer", @luna.attr_static(defer_url)),
  ]
  // Add revalidate as data attribute for potential client-side use
  match revalidate {
    Some(seconds) =>
      attrs.push(("data-revalidate", @luna.attr_static(seconds.to_string())))
    None => ()
  }
  @luna.h("div", attrs, [fallback])
}

///|
/// Create a Server Island VNode with typed props (convenience wrapper)
pub fn[T : ToJson, E] server_island_typed(
  id~ : String,
  props~ : T,
  fallback? : @luna.Node[E, String] = @luna.text(""),
  revalidate? : Int? = None,
) -> @luna.Node[E, String] {
  server_island(id~, props=Some(props.to_json()), fallback~, revalidate~)
}

// ============================================================================
// Island VNode Support (ComponentRef-based, recommended)
// ============================================================================

///|
/// Create an Island VNode from a ComponentRef (type-safe, recommended)
///
/// Example:
/// ```moonbit nocheck
/// @sol.island(
///   @types.counter({ initial_count: 42 }),
///   [div([button([text("Count: 42")])])],
/// )
/// ```
pub fn[T : ToJson, E] island(
  cref : @luna.ComponentRef[T],
  children : Array[@luna.Node[E, String]],
) -> @luna.Node[E, String] {
  @luna.internal_ref(
    cref.url,
    cref.props.to_json().stringify(),
    trigger=cref.trigger,
    children~,
  )
}

///|
/// Create an Island VNode from a ComponentRef with a render function for children
pub fn[T : ToJson, E] island_with(
  cref : @luna.ComponentRef[T],
  render : () -> @luna.Node[E, String],
) -> @luna.Node[E, String] {
  island(cref, [render()])
}

// ============================================================================
// Web Components Island VNode Support (string-based, low-level)
// ============================================================================

///|
/// Create a Web Components Island VNode from raw strings (low-level API)
/// Prefer `island(cref, children)` with ComponentRef for type safety
pub fn[E] island_raw(
  name : String,
  url : String,
  state : String,
  children : Array[@luna.Node[E, String]],
  trigger? : @luna.TriggerType = @luna.TriggerType::Load,
) -> @luna.Node[E, String] {
  @luna.wc_island(name, url, "", state, children, trigger~)
}

///|
/// Create a Web Components Island VNode with a render function (low-level API)
/// Prefer `island_with(cref, render)` with ComponentRef for type safety
pub fn[E] island_with_raw(
  name : String,
  url : String,
  state : String,
  render : () -> @luna.Node[E, String],
  trigger? : @luna.TriggerType = @luna.TriggerType::Load,
) -> @luna.Node[E, String] {
  @luna.wc_island(name, url, "", state, [render()], trigger~)
}

///|
/// Render a VNode to HTML string
/// Use hydration=true to enable hydration markers
pub fn[E] render_node(
  node : @luna.Node[E, String],
  hydration? : Bool = false,
) -> String {
  if hydration {
    @render.render_to_string_with_hydration(node)
  } else {
    @render.render_to_string(node).html
  }
}

// ============================================================================
// Web Components Island VNode Support (using @luna.wc_island)
// ============================================================================

///|
/// Default wc-loader script URL
pub let default_wc_loader_url : String = "/__sol__/wc-loader.js"

///|
/// Create a Web Components Island VNode from raw strings (low-level API)
/// Prefer `island(cref, children)` with ComponentRef (wc=true) for type safety
pub fn[E] wc_island_raw(
  name : String,
  url : String,
  styles : String,
  state : String,
  children : Array[@luna.Node[E, String]],
  trigger? : @luna.TriggerType = @luna.TriggerType::Load,
) -> @luna.Node[E, String] {
  @luna.wc_island(name, url, styles, state, children, trigger~)
}

///|
/// Create a Web Components Island VNode with a render function (low-level API)
/// Prefer `island_with(cref, render)` with ComponentRef (wc=true) for type safety
pub fn[E] wc_island_with_raw(
  name : String,
  url : String,
  styles : String,
  state : String,
  render : () -> @luna.Node[E, String],
  trigger? : @luna.TriggerType = @luna.TriggerType::Load,
) -> @luna.Node[E, String] {
  @luna.wc_island(name, url, styles, state, [render()], trigger~)
}

///|
/// Register a page route with Web Components islands
/// Uses wc-loader for hydration
pub fn[E] wc_page(
  app : App,
  path : String,
  render_fn : (Ctx) -> @luna.Node[E, String],
  title? : String,
  head? : String,
  wc_loader_url? : String,
) -> Unit {
  app.get(
    path,
    @mars.handler(async fn(c) {
      let node = render_fn(c)
      let loader = wc_loader_url.unwrap_or(default_wc_loader_url)
      let loader_script = "<script type=\"module\" src=\"" +
        loader +
        "\"></script>"
      let full_head = @hot_reload.with_dev_head_script(
        head.unwrap_or("") + loader_script,
      )
      let html = render_page(node, title?, head=full_head, hydration=true)
      c.html(html)
    }),
  )
}

// ============================================================================

///|
pub fn[E] render_with_island_preloads(
  node : @luna.Node[E, String],
) -> @render.SSRResult {
  @render.render_to_string(node, preload=true)
}

///|
/// Render a page with automatic modulepreload tags for islands
pub fn[E] render_page_with_preloads(
  node : @luna.Node[E, String],
  title? : String,
  head? : String,
  hydration? : Bool,
) -> String {
  let title_str = title.unwrap_or("App")
  let enable_hydration = hydration.unwrap_or(false)

  // Render and collect preload URLs
  let _ = enable_hydration // Reserved for future use
  let result = @render.render_to_string(node, preload=true)

  // Generate preload tags
  let preload_tags = @render.generate_preload_tags(result.preload_urls)

  // Combine head with preload tags
  let head_str = head.unwrap_or("") + preload_tags
  @page_shell.render_document(title_str, head_str, result.html)
}

// ============================================================================
