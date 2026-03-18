///| Server entry point
///| User-managed mode: you own this file.

async fn main {
  @sol.run_app(fn() {
    let app = @mars.Server::new()
    @router.register_sol_routes(app, routes(), config=config())
    @action.register_actions(app, action_registry())
    @sol.serve_sol_assets(app)
    @sol.serve_static(app)
    app
  })
}
