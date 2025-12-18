///| About Page Server Component
///|
///| Static page without client-side hydration.

///| About page - static content (sync server component)
pub fn about(props : @router.PageProps) -> @server_dom.ServerNode {
  let content = [
    h1([text("About")]),
    p([text("Built with MoonBit and Sol framework.")]),
  ]

  // Fragment request: return content only (no layout)
  // Full page request: wrap with layout
  let node = if props.params.is_fragment {
    @luna.fragment(content)
  } else {
    layout(content)
  }
  @server_dom.ServerNode::sync(node)
}
