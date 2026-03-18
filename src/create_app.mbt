///| Create a fully configured Sol app from routes and config.
///|
///| This is the main facade API for user-managed server entry points.
///| It creates a mars Server, registers routes, actions, and static serving.
///|
///| ```mbt
///| async fn main {
///|   @sol.run_app(fn() {
///|     @sol.create_app(routes(), config=config())
///|   })
///| }
///| ```
pub fn create_app(
  routes : Array[@router.SolRoutes],
  config? : @router.RouterConfig,
  actions? : @action.ActionRegistry,
) -> @mars.Server {
  let app = @mars.Server::new()
  @router.register_sol_routes(app, routes, config?)
  match actions {
    Some(registry) => @action.register_actions(app, registry)
    None => ()
  }
  serve_sol_assets(app)
  serve_static(app)
  app
}
