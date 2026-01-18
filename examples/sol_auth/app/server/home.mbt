///| Home Page Server Component

///|

///| Uses client() to embed the counter client component.

///| This is an async server component that supports data fetching.

///|
/// Home page - with counter client component (async server component)
async fn home(props : @router.PageProps) -> @server_dom.ServerNode {
  // Return an async ServerNode that can perform data fetching
  @server_dom.ServerNode::async_(async fn() {
    // Generate a random number on the server side
    // This demonstrates async data fetching capability
    let server_random = generate_random_int(1, 1000)

    // Create props using generated types
    let counter_props : @types.CounterProps = { initial_count: server_random }
    let content = [
      h1([text("Welcome to Sol")]),
      p([text("A SSR-first web framework for MoonBit")]),
      p([
        text("Server-generated random number: "),
        span(style="font-weight: bold; color: #0066cc;", [
          text(server_random.to_string()),
        ]),
      ]),
      p(style="color: #666; font-size: 0.9em;", [
        text("(Refresh to see a new random number from the server)"),
      ]),
      @server_dom.client(@types.counter(counter_props), [
        div(class="counter", [
          span(class="count-display", [
            text(counter_props.initial_count.to_string()),
          ]),
          div(class="buttons", [
            button(class="dec", [text("-")]),
            button(class="inc", [text("+")]),
          ]),
        ]),
      ]),
    ]

    // Return content only - layout is applied by SolRoutes::Layout
    @luna.fragment(content)
  })
}

///|
/// Generate a random integer between min and max (inclusive)
fn generate_random_int(min : Int, max : Int) -> Int {
  let random = ffi_math_random()
  min + (random * (max - min + 1).to_double()).to_int()
}

///|
/// FFI for Math.random()
extern "js" fn ffi_math_random() -> Double =
  #| () => Math.random()
