///| About Page Server Component

///|

///| Static page without client-side hydration.

///|
/// About page - static content (sync server component)
async fn about(_props : @sol.PageProps) -> @server_dom.ServerNode {
  let content = [
    h1([text("About")]),
    p([text("Built with MoonBit and Sol framework.")]),
  ]

  // Return content only - layout is applied by SolRoutes::Layout
  @sol.nodes(content)
}
