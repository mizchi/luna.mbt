///| Render functions for server_dom

///|

///| Converts Node tree to HTML string.

///|
/// Render a node tree to HTML string
pub fn render(node : @luna.Node[Unit]) -> String {
  @render.render_to_string(node).html
}

///|
/// Render a node tree to HTML with preload URLs for islands
pub fn render_with_preloads(node : @luna.Node[Unit]) -> RenderResult {
  let result = @render.render_to_string(node, preload=true)
  { html: result.html, preload_urls: result.preload_urls }
}

///|
/// Render a complete HTML document with DOCTYPE
pub fn render_document(node : @luna.Node[Unit]) -> String {
  "<!DOCTYPE html>\n" + render(node)
}

///|
/// Render a complete HTML document with DOCTYPE and preloads
pub fn render_document_with_preloads(node : @luna.Node[Unit]) -> RenderResult {
  let result = render_with_preloads(node)
  { html: "<!DOCTYPE html>\n" + result.html, preload_urls: result.preload_urls }
}

///|
/// Generate modulepreload link tags for island scripts
pub fn generate_preload_tags(urls : Array[String]) -> String {
  @render.generate_preload_tags(urls)
}

///|
/// Create a basic HTML document structure
///
/// Example:
/// ```moonbit
/// document(
///   lang="en",
///   head_children=[
///     title("My App"),
///     meta(charset="UTF-8"),
///   ],
///   body_children=[
///     h1(children=[text("Hello!")]),
///   ],
/// )
/// ```
pub fn document(
  lang? : String,
  head_children~ : Array[@luna.Node[Unit]],
  body_children~ : Array[@luna.Node[Unit]],
  body_class? : String,
  body_id? : String,
) -> @luna.Node[Unit] {
  let body_node = match (body_class, body_id) {
    (Some(c), Some(i)) => @element.body(class=c, id=i, children=body_children)
    (Some(c), None) => @element.body(class=c, children=body_children)
    (None, Some(i)) => @element.body(id=i, children=body_children)
    (None, None) => @element.body(children=body_children)
  }
  @element.html(lang?, children=[@element.head(children=head_children), body_node])
}
