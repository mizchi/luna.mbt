///| Framework Example Application

///|

///| Demonstrates SSR with ui.mbt VNodes using the framework.

///|
/// Home page component
fn home_page(_ctx : @framework.Ctx) -> @kaguya.Node {
  @kaguya.vnode("div", [("class", @kaguya.attr_static("container"))], [
    @kaguya.vnode("h1", [], [@kaguya.vtext("Welcome to MoonBit Framework")]),
    @kaguya.vnode("p", [], [
      @kaguya.vtext("A SSR-first web framework built on Hono and ui.mbt"),
    ]),
    @kaguya.vnode("div", [("class", @kaguya.attr_static("nav"))], [
      @kaguya.vnode("ul", [], [
        @kaguya.vnode("li", [], [
          @kaguya.vnode("a", [("href", @kaguya.attr_static("/"))], [@kaguya.vtext("Home")]),
        ]),
        @kaguya.vnode("li", [], [
          @kaguya.vnode("a", [("href", @kaguya.attr_static("/about"))], [@kaguya.vtext("About")]),
        ]),
        @kaguya.vnode("li", [], [
          @kaguya.vnode("a", [("href", @kaguya.attr_static("/counter"))], [@kaguya.vtext("Counter Demo")]),
        ]),
      ]),
    ]),
  ])
}

///|
/// About page component
fn about_page(_ctx : @framework.Ctx) -> @kaguya.Node {
  @kaguya.vnode("div", [("class", @kaguya.attr_static("container"))], [
    @kaguya.vnode("h1", [], [@kaguya.vtext("About")]),
    @kaguya.vnode("p", [], [@kaguya.vtext("This is a demonstration of SSR with MoonBit.")]),
    @kaguya.vnode("p", [], [
      @kaguya.vtext("The HTML is rendered on the server using ui.mbt VNodes."),
    ]),
    @kaguya.vnode("a", [("href", @kaguya.attr_static("/"))], [@kaguya.vtext("← Back to Home")]),
  ])
}

///|
/// Counter page with reactive state (demonstrates hydration markers)
fn counter_page(_ctx : @framework.Ctx) -> @kaguya.Node {
  let count = @signal.signal(0)
  @kaguya.vnode("div", [("class", @kaguya.attr_static("container"))], [
    @kaguya.vnode("h1", [], [@kaguya.vtext("Counter Demo")]),
    @kaguya.vnode("p", [], [
      @kaguya.vtext("This page demonstrates reactive state with hydration markers."),
    ]),
    @kaguya.vnode("div", [("class", @kaguya.attr_static("counter"))], [
      @kaguya.vnode("span", [], [@kaguya.vtext("Count: ")]),
      @kaguya.vnode("span", [], [@kaguya.text_dyn(fn() { count.get().to_string() })]),
    ]),
    @kaguya.vnode("div", [("class", @kaguya.attr_static("buttons"))], [
      @kaguya.vnode("button", [("onClick", @kaguya.attr_handler(@kaguya.event_handler()))], [@kaguya.vtext("-")]),
      @kaguya.vnode("button", [("onClick", @kaguya.attr_handler(@kaguya.event_handler()))], [@kaguya.vtext("+")]),
    ]),
    @kaguya.vnode("a", [("href", @kaguya.attr_static("/"))], [@kaguya.vtext("← Back to Home")]),
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
