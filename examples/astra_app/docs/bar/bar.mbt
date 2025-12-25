// Bar component - demonstrates SSR rendering for component directories

///|
/// Render the Bar component - this function is called during SSR
pub fn render() -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("bar-component"))], [
    @luna.h("h2", [], [@luna.text("Bar Component")]),
    @luna.h("p", [], [
      @luna.text("This component is SSR rendered from bar.mbt"),
    ]),
    @luna.h("ul", [], [
      @luna.h("li", [], [@luna.text("Defined in docs/bar/bar.mbt")]),
      @luna.h("li", [], [@luna.text("Uses Luna's VNode system")]),
      @luna.h("li", [], [@luna.text("Can be hydrated on client")]),
    ]),
    @luna.h(
      "div",
      [
        ("class", @luna.attr_static("demo-box")),
        (
          "style",
          @luna.attr_static(
            "padding: 1rem; background: #f0f0f0; border-radius: 8px; margin-top: 1rem;",
          ),
        ),
      ],
      [@luna.h("p", [], [@luna.text("This is a demo box rendered on the server.")])],
    ),
  ])
}
