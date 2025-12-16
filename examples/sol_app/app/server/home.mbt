///| Home Page Server Component
///|
///| Uses island() to embed the counter client component.

///| Home page - with counter island
pub fn home(props : @router.PageProps) -> @luna.Node[Unit] {
  let _ = props // Available for dynamic pages
  // Create props using generated types - auto-serializes to JSON
  let counter_props : @types.CounterProps = { initial_count: 0 }
  let state_json = counter_props.to_json().stringify()

  layout([
    @luna.h("h1", [], [@luna.vtext("Welcome to Sol")]),
    @luna.h("p", [], [
      @luna.vtext("A SSR-first web framework for MoonBit"),
    ]),
    @server_dom.island(
      "counter",
      "/static/counter.js",
      state=state_json,
      trigger=@luna.Load,
      // SSR placeholder - will be hydrated on client
      children=[
        @luna.h("div", [("class", @luna.attr_static("counter"))], [
          @luna.h("span", [("class", @luna.attr_static("count-display"))], [
            @luna.vtext(counter_props.initial_count.to_string()),
          ]),
          @luna.h("div", [("class", @luna.attr_static("buttons"))], [
            @luna.h("button", [("class", @luna.attr_static("dec"))], [
              @luna.vtext("-"),
            ]),
            @luna.h("button", [("class", @luna.attr_static("inc"))], [
              @luna.vtext("+"),
            ]),
          ]),
        ]),
      ],
    ),
  ])
}
