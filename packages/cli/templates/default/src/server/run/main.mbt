///| Kaguya App - Server Entry Point

///| Home page component
fn home_page(_ctx : @framework.Ctx) -> @kaguya.Node {
  @kaguya.vnode("div", [("class", @kaguya.attr_static("container"))], [
    @kaguya.vnode("h1", [], [@kaguya.vtext("Welcome to Kaguya")]),
    @kaguya.vnode("p", [], [
      @kaguya.vtext("A SSR-first web framework for MoonBit"),
    ]),
    @kaguya.vnode("nav", [], [
      @kaguya.vnode("ul", [], [
        @kaguya.vnode("li", [], [
          @kaguya.vnode("a", [("href", @kaguya.attr_static("/"))], [@kaguya.vtext("Home")]),
        ]),
        @kaguya.vnode("li", [], [
          @kaguya.vnode("a", [("href", @kaguya.attr_static("/about"))], [@kaguya.vtext("About")]),
        ]),
      ]),
    ]),
  ])
}

///| About page component
fn about_page(_ctx : @framework.Ctx) -> @kaguya.Node {
  @kaguya.vnode("div", [("class", @kaguya.attr_static("container"))], [
    @kaguya.vnode("h1", [], [@kaguya.vtext("About")]),
    @kaguya.vnode("p", [], [@kaguya.vtext("Built with Kaguya and MoonBit.")]),
    @kaguya.vnode("a", [("href", @kaguya.attr_static("/"))], [@kaguya.vtext("← Back")]),
  ])
}

///| Configure routes
fn configure_app(app : @framework.App) -> @framework.App {
  let app = @framework.page(
    app,
    "/",
    home_page,
    title="Home",
    head="<style>body { font-family: system-ui; max-width: 800px; margin: 0 auto; padding: 2rem; }</style>",
  )
  let app = @framework.page(
    app,
    "/about",
    about_page,
    title="About",
    head="<style>body { font-family: system-ui; max-width: 800px; margin: 0 auto; padding: 2rem; }</style>",
  )
  let app = @framework.api(app, "/api/health", fn(_c) {
    @core.any({ "status": "ok" })
  })
  app
}

///| Main entry point
fn main {
  let port = 3000
  @framework.create_app_then(fn(app) {
    let app = configure_app(app)
    println("Server running at http://localhost:" + port.to_string())
    @framework.serve(app, port)
  })
}
