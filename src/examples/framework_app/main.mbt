///| Framework Example Application
///|
///| Demonstrates SSR with ui.mbt VNodes using the framework.

///|
/// Home page component
fn home_page(_ctx : @framework.Ctx) -> @ui.Node {
  @element.vdiv([@element.vclass("container")], [
    @element.vh1([], [@ui.vtext("Welcome to MoonBit Framework")]),
    @element.vp([], [
      @ui.vtext("A SSR-first web framework built on Hono and ui.mbt"),
    ]),
    @element.vdiv([@element.vclass("nav")], [
      @element.vul([], [
        @element.vli([], [
          @element.va([@element.vhref("/")], [@ui.vtext("Home")]),
        ]),
        @element.vli([], [
          @element.va([@element.vhref("/about")], [@ui.vtext("About")]),
        ]),
        @element.vli([], [
          @element.va([@element.vhref("/counter")], [@ui.vtext("Counter Demo")]),
        ]),
      ]),
    ]),
  ])
}

///|
/// About page component
fn about_page(_ctx : @framework.Ctx) -> @ui.Node {
  @element.vdiv([@element.vclass("container")], [
    @element.vh1([], [@ui.vtext("About")]),
    @element.vp([], [
      @ui.vtext("This is a demonstration of SSR with MoonBit."),
    ]),
    @element.vp([], [
      @ui.vtext("The HTML is rendered on the server using ui.mbt VNodes."),
    ]),
    @element.va([@element.vhref("/")], [@ui.vtext("← Back to Home")]),
  ])
}

///|
/// Counter page with reactive state (demonstrates hydration markers)
fn counter_page(_ctx : @framework.Ctx) -> @ui.Node {
  let count = @ui.signal(0)
  @element.vdiv([@element.vclass("container")], [
    @element.vh1([], [@ui.vtext("Counter Demo")]),
    @element.vp([], [
      @ui.vtext("This page demonstrates reactive state with hydration markers."),
    ]),
    @element.vdiv([@element.vclass("counter")], [
      @element.vspan([], [@ui.vtext("Count: ")]),
      @element.vspan([], [@ui.vtext_dyn(fn() { count.get().to_string() })]),
    ]),
    @element.vdiv([@element.vclass("buttons")], [
      @element.vbutton([@element.von_click(@ui.event_handler())], [@ui.vtext("-")]),
      @element.vbutton([@element.von_click(@ui.event_handler())], [@ui.vtext("+")]),
    ]),
    @element.va([@element.vhref("/")], [@ui.vtext("← Back to Home")]),
  ])
}

///|
/// Create and configure the application
fn create_app() -> @framework.App {
  let app = @framework.create_app()

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
  let app = @framework.api(app, "/api/health", fn(_c) { @core.any({ "status": "ok" }) })

  app
}

///|
fn main {
  let app = create_app()
  let port = 3000
  println("Starting MoonBit Framework on port " + port.to_string() + "...")
  @framework.serve(app, port)
}
