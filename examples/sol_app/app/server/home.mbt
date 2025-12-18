///| Home Page Server Component
///|
///| Uses island() to embed the counter client component.
///| This is an async server component that supports data fetching.

///| Home page - with counter island (async server component)
pub fn home(props : @router.PageProps) -> @server_dom.ServerNode {
  // Return an async ServerNode that can perform data fetching
  @server_dom.ServerNode::async_(async fn() {
    // Generate a random number on the server side
    // This demonstrates async data fetching capability
    let server_random = generate_random_int(1, 1000)

    // Create props using generated types - auto-serializes to JSON
    // Use the server-generated random number as initial count
    let counter_props : @types.CounterProps = { initial_count: server_random }
    let state_json = counter_props.to_json().stringify()

    let content = [
      h1(children=[text("Welcome to Sol")]),
      p(children=[text("A SSR-first web framework for MoonBit")]),
      p(children=[
        text("Server-generated random number: "),
        span(
          style="font-weight: bold; color: #0066cc;",
          children=[text(server_random.to_string())],
        ),
      ]),
      p(
        style="color: #666; font-size: 0.9em;",
        children=[text("(Refresh to see a new random number from the server)")],
      ),
      @server_dom.island(
        "counter",
        "/static/counter.js",
        state=state_json,
        trigger=@luna.Load,
        children=[
          div(class="counter", children=[
            span(class="count-display", children=[
              text(counter_props.initial_count.to_string()),
            ]),
            div(class="buttons", children=[
              button(class="dec", children=[text("-")]),
              button(class="inc", children=[text("+")]),
            ]),
          ]),
        ],
      ),
    ]

    // Fragment request: return content only (no layout)
    // Full page request: wrap with layout
    if props.params.is_fragment {
      @luna.fragment(content)
    } else {
      layout(content)
    }
  })
}

///| Generate a random integer between min and max (inclusive)
fn generate_random_int(min : Int, max : Int) -> Int {
  let random = ffi_math_random()
  min + ((random * (max - min + 1).to_double()).to_int())
}

///| FFI for Math.random()
extern "js" fn ffi_math_random() -> Double =
  #| () => Math.random()
