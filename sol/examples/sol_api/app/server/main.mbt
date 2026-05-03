///| Server entry point

async fn main {
  @sol.run_app(fn() {
    @sol.create_app(routes(), config=config())
  })
}
