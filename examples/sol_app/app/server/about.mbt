///| About Page Server Component
///|
///| Static page without client-side hydration.

///| About page - static content
pub fn about(props : @router.PageProps) -> @luna.Node[Unit] {
  let _ = props
  layout([
    h1(children=[text("About")]),
    p(children=[text("Built with MoonBit and Sol framework.")]),
  ])
}
