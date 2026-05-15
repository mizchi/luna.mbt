///|
/// Server entry point
async fn main {
  @sol_cloudflare.run_app(fn() {
    @sol.create_app(routes(), config=config(), actions=action_registry())
  })
}
