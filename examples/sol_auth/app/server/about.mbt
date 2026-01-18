///| About Page Server Component

///|

///| Static page without client-side hydration.

///|
/// About page - static content (sync server component)
async fn about(props : @router.PageProps) -> @server_dom.ServerNode {
  let content = [
    h1([text("About")]),
    p([text("Built with MoonBit and Sol framework.")]),
  ]

  // Return content only - layout is applied by SolRoutes::Layout
  @server_dom.ServerNode::sync(@luna.fragment(content))
}
