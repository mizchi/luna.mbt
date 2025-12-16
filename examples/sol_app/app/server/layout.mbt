///| Server Layout Component
///|
///| Provides the basic HTML structure for all pages.
///| This is a server component - no event handlers.

///| Default page styles
let default_style : String = "<style>body { font-family: system-ui; max-width: 800px; margin: 0 auto; padding: 2rem; } .counter { margin: 2rem 0; padding: 1rem; border: 1px solid #ccc; border-radius: 8px; } .buttons { margin-top: 1rem; } .buttons button { font-size: 1.5rem; padding: 0.5rem 1rem; margin: 0 0.5rem; cursor: pointer; } nav { margin-bottom: 1rem; } nav a { margin-right: 1rem; }</style>"

///| Get default head HTML (styles)
pub fn head() -> String {
  default_style
}

///| Basic layout wrapper - wraps content in container with navigation
pub fn layout(inner : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  div(class="container", children=[
    nav(children=[
      a(href="/", children=[text("Home")]),
      a(href="/about", children=[text("About")]),
    ]),
    fragment(inner),
  ])
}
