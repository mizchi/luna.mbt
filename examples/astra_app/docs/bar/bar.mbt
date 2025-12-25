// Bar component - demonstrates SSR rendering for component directories

///|
/// Helper to create an element
fn h(
  tag : String,
  attrs : Array[(String, @luna.Attr[Unit])],
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(tag, attrs, children)
}

///|
/// Helper to create a static attribute
fn attr(key : String, value : String) -> (String, @luna.Attr[Unit]) {
  (key, @luna.attr_static(value))
}

///|
/// Render the Bar component - this function is called during SSR
pub fn render() -> @luna.Node[Unit] {
  h("div", [attr("class", "bar-component")], [
    h("h2", [], [@luna.text("Bar Component")]),
    h("p", [], [@luna.text("This component is SSR rendered from bar.mbt")]),
    h("ul", [], [
      h("li", [], [@luna.text("Defined in docs/bar/bar.mbt")]),
      h("li", [], [@luna.text("Uses Luna's VNode system")]),
      h("li", [], [@luna.text("Can be hydrated on client")]),
    ]),
    h("div", [attr("class", "demo-box"), attr("style", "padding: 1rem; background: #f0f0f0; border-radius: 8px; margin-top: 1rem;")], [
      h("p", [], [@luna.text("This is a demo box rendered on the server.")]),
    ]),
  ])
}
