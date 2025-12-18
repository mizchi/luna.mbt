///| Server Layout Component
///|
///| Provides the basic HTML structure for all pages.
///| This is a server component - no event handlers.

///| Default page styles
let default_style : String = "<style>body { font-family: system-ui; max-width: 800px; margin: 0 auto; padding: 2rem; } .counter { margin: 2rem 0; padding: 1rem; border: 1px solid #ccc; border-radius: 8px; } .buttons { margin-top: 1rem; } .buttons button { font-size: 1.5rem; padding: 0.5rem 1rem; margin: 0 0.5rem; cursor: pointer; } nav { margin-bottom: 1rem; } nav a { margin-right: 1rem; } .contact-form { margin: 2rem 0; padding: 1rem; border: 1px solid #ccc; border-radius: 8px; } .form-group { margin-bottom: 1rem; } .form-group label { display: block; margin-bottom: 0.25rem; font-weight: 500; } .form-group input { width: 100%; padding: 0.5rem; border: 1px solid #ccc; border-radius: 4px; box-sizing: border-box; } .form-preview { margin: 1rem 0; padding: 0.5rem; background: #f5f5f5; border-radius: 4px; } .form-actions { margin-top: 1rem; } .form-actions button { padding: 0.5rem 1rem; background: #007bff; color: white; border: none; border-radius: 4px; cursor: pointer; } .form-result { margin-top: 1rem; color: #666; }</style>"

///| Luna loader script (for island hydration)
let loader_script : String = "<script type=\"module\" src=\"/static/loader.js\"></script>"

///| WC loader script (for Web Components hydration)
let wc_loader_script : String = "<script type=\"module\" src=\"/static/wc-loader.js\"></script>"

///| Sol navigation script
let sol_nav_script : String = "<script type=\"module\" src=\"/static/sol-nav.js\"></script>"

///| Get default head HTML (styles + loader + wc-loader + sol-nav)
///| Note: HMR script is auto-injected by Sol runtime in dev mode (SOL_DEV=1)
pub fn head() -> String {
  default_style + loader_script + wc_loader_script + sol_nav_script
}

///| Basic layout wrapper - wraps content in container with navigation
pub fn layout(inner : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  div(class="container", [
    nav([
      sol_link(href="/", [text("Home")]),
      sol_link(href="/about", [text("About")]),
      sol_link(href="/form", [text("Form")]),
      sol_link(href="/wc-counter", [text("WC Counter")]),
    ]),
    outlet(name="main", inner),
  ])
}
