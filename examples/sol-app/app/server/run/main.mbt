///| Sol App - Server Entry Point

///| Configure the application
fn configure_app(app : @sol.App) -> @sol.App {
  let style = "<style>body { font-family: system-ui; max-width: 800px; margin: 0 auto; padding: 2rem; } .counter { margin: 2rem 0; padding: 1rem; border: 1px solid #ccc; border-radius: 8px; } .buttons { margin-top: 1rem; } .buttons button { font-size: 1.5rem; padding: 0.5rem 1rem; margin: 0 0.5rem; cursor: pointer; }</style>"

  let app = @sol.page(app, "/", @page_home.page, title="Home", head=style, hydration=true, loader_url="/static/loader.min.js")
  let app = @sol.page(app, "/about", @page_about.page, title="About", head=style)
  let app = @sol.api(app, "/api/health", fn(_c) { @sol.json_obj([("status", @core.any("ok"))]) })
  let app = @sol.serve_static(app)
  app
}

///|
fn main {
  @sol.run(configure_app)
}
