// Sol - SSR-first Web Framework for MoonBit
//
// Built on top of Mars, providing SSR with Luna VNodes.
// Inspired by Next.js, Solid Start, and Qwik City.
//

///|
/// Mars app type alias
type App = @mars.Server

///|
/// Mars context type alias
type Ctx = @mars.Context

///|
/// Render a VNode to HTML string with full document wrapper
/// Use hydration=true to enable hydration markers (for pages with Islands)
pub fn[E] render_page(
  node : @luna.Node[E, String],
  title? : String,
  head? : String,
  hydration? : Bool,
) -> String {
  let title_str = title.unwrap_or("App")
  let head_str = head.unwrap_or("")
  let enable_hydration = hydration.unwrap_or(false)
  let body_html = if enable_hydration {
    @render.render_to_string_with_hydration(node)
  } else {
    @render.render_to_string(node).html
  }
  @page_shell.render_document(title_str, head_str, body_html)
}

///|
/// Render a VNode to HTML string without document wrapper (for partial/fragment responses)
pub fn[E] render_fragment(node : @luna.Node[E, String]) -> String {
  @render.render_to_string_with_hydration(node)
}

///|
/// Register a page route that renders a VNode
/// Use hydration=true for pages with Islands (adds loader script and hydration markers)
pub fn[E] page(
  app : App,
  path : String,
  render_fn : (Ctx) -> @luna.Node[E, String],
  title? : String,
  head? : String,
  hydration? : Bool,
  loader_url? : String,
) -> Unit {
  app.get(
    path,
    @mars.handler(async fn(c) {
      let node = render_fn(c)
      let enable_hydration = hydration.unwrap_or(false)
      let base_head = head.unwrap_or("")
      if enable_hydration {
        // Hydration enabled: render with hydration markers and include loader script
        let loader = loader_url.unwrap_or(default_loader_url)
        let loader_script = "<script type=\"module\" src=\"" +
          loader +
          "\"></script>"
        let full_head = @hot_reload.with_dev_head_script(
          base_head + loader_script,
        )
        let html = render_page(node, title?, head=full_head, hydration=true)
        c.html(html)
      } else {
        // Static page: render without hydration (but still add HMR in dev)
        let full_head = @hot_reload.with_dev_head_script(base_head)
        let html = render_page(node, title?, head=full_head)
        c.html(html)
      }
    }),
  )
}
