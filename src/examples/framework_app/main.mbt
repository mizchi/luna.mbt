///| Framework Example Application

///|

///| Demonstrates SSR with ui.mbt VNodes using the framework.

///|
/// Home page component
fn home_page(_ctx : @framework.Ctx) -> @kaguya.Node {
  @element.div([@element.class("container")], [
    @element.h1([], [@kaguya.vtext("Welcome to MoonBit Framework")]),
    @element.p([], [
      @kaguya.vtext("A SSR-first web framework built on Hono and ui.mbt"),
    ]),
    @element.div([@element.class("nav")], [
      @element.ul([], [
        @element.li([], [@element.a([@element.href("/")], [@kaguya.vtext("Home")])]),
        @element.li([], [
          @element.a([@element.href("/about")], [@kaguya.vtext("About")]),
        ]),
        @element.li([], [
          @element.a([@element.href("/counter")], [@kaguya.vtext("Counter Demo")]),
        ]),
      ]),
    ]),
  ])
}

///|
/// About page component
fn about_page(_ctx : @framework.Ctx) -> @kaguya.Node {
  @element.div([@element.class("container")], [
    @element.h1([], [@kaguya.vtext("About")]),
    @element.p([], [@kaguya.vtext("This is a demonstration of SSR with MoonBit.")]),
    @element.p([], [
      @kaguya.vtext("The HTML is rendered on the server using ui.mbt VNodes."),
    ]),
    @element.a([@element.href("/")], [@kaguya.vtext("← Back to Home")]),
  ])
}

///|
/// Counter page with reactive state (demonstrates hydration markers)
fn counter_page(_ctx : @framework.Ctx) -> @kaguya.Node {
  let count = @signal.signal(0)
  @element.div([@element.class("container")], [
    @element.h1([], [@kaguya.vtext("Counter Demo")]),
    @element.p([], [
      @kaguya.vtext("This page demonstrates reactive state with hydration markers."),
    ]),
    @element.div([@element.class("counter")], [
      @element.span([], [@kaguya.vtext("Count: ")]),
      @element.span([], [@kaguya.text_dyn(fn() { count.get().to_string() })]),
    ]),
    @element.div([@element.class("buttons")], [
      @element.button([@element.on_click(@kaguya.event_handler())], [@kaguya.vtext("-")]),
      @element.button([@element.on_click(@kaguya.event_handler())], [@kaguya.vtext("+")]),
    ]),
    @element.a([@element.href("/")], [@kaguya.vtext("← Back to Home")]),
  ])
}

///|
/// Configure the application with routes
fn configure_app(app : @framework.App) -> @framework.App {
  // Register pages
  let app = @framework.page(
    app,
    "/",
    home_page,
    title="Home - MoonBit Framework",
    head="<style>body { font-family: system-ui; max-width: 800px; margin: 0 auto; padding: 2rem; }</style>",
  )
  let app = @framework.page(
    app,
    "/about",
    about_page,
    title="About - MoonBit Framework",
    head="<style>body { font-family: system-ui; max-width: 800px; margin: 0 auto; padding: 2rem; }</style>",
  )
  let app = @framework.page(
    app,
    "/counter",
    counter_page,
    title="Counter - MoonBit Framework",
    head="<style>body { font-family: system-ui; max-width: 800px; margin: 0 auto; padding: 2rem; } .counter { font-size: 2rem; margin: 1rem 0; } .buttons button { font-size: 1.5rem; padding: 0.5rem 1rem; margin: 0.25rem; }</style>",
  )

  // Register API endpoint
  let app = @framework.api(app, "/api/health", fn(_c) {
    @core.any({ "status": "ok" })
  })
  app
}

///|
fn main {
  let port = 3000
  @framework.create_app_then(fn(app) {
    let app = configure_app(app)
    println("Starting MoonBit Framework on port " + port.to_string() + "...")
    @framework.serve(app, port)
  })
}
