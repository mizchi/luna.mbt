// SSR Test Component - demonstrates SSR rendering

///|
/// Create a server-side element
fn h(
  tag : String,
  attrs : Array[(String, @luna.Attr[Unit])],
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(tag, attrs, children)
}

///|
/// Create a static attribute
fn attr(key : String, value : String) -> (String, @luna.Attr[Unit]) {
  (key, @luna.attr_static(value))
}

///|
/// Render function - exported for SSR
pub fn render() -> @luna.Node[Unit] {
  h("div", [attr("class", "ssr-test-component")], [
    h("h2", [], [@luna.text("SSR Test Component")]),
    h("p", [], [@luna.text("This component was rendered on the server!")]),
    h("ul", [], [
      h("li", [], [@luna.text("Server-side rendered content")]),
      h("li", [], [@luna.text("No JavaScript required")]),
      h("li", [], [@luna.text("Fast initial load")]),
    ]),
  ])
}
