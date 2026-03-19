///| About Page Server Component

///|

///| Static page without client-side hydration.

///|
/// About page - static content (sync server component)
async fn about(_props : @sol.PageProps) -> @server_dom.ServerNode {
  let content = [
    h1([text("About")]),
    p([text("Built with MoonBit and Sol framework.")]),
    // luna/x/components — typed SSR-compatible UI components
    @alert_ui.alert(
      @alert_ui.Success,
      title="Type-Safe SSR",
      description="This alert is rendered on the server using luna/x/components with generic Node[E, String].",
    ),
    @alert_ui.alert(
      @alert_ui.Warning,
      title="Island Architecture",
      description="Interactive components hydrate on the client. Static components like this alert are SSR-only.",
    ),
  ]
  @sol.nodes(content)
}
