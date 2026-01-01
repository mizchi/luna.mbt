// SSR Test Component - locally defined component for SSR demo
// Note: @element DSL returns DomNode for browser, so SSR uses VNode API directly

///|
using @luna { h, text, attr_static, type Node, type Attr }

///|
fn attr(key : String, value : String) -> (String, Attr[Unit]) {
  (key, attr_static(value))
}

///|
/// Render function - exported for SSR
pub fn render() -> Node[Unit] {
  h("div", [attr("class", "ssr-local-component")], [
    h("h2", [], [text("Local SSR Component")]),
    h("p", [], [text("This component is defined in docs/ssr_test_component/")]),
    h("ul", [], [
      h("li", [], [text("Built from local .mbt file")]),
      h("li", [], [text("Part of sol_docs example")]),
      h("li", [], [text("SSR rendered on server")]),
    ]),
  ])
}
