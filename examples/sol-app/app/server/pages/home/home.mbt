///| Home Page

///| Home page with counter component
pub fn page(_ctx : @sol.Ctx) -> @luna.Node[Unit] {
  let initial_count = 0
  let state_json = "{\"count\":" + initial_count.to_string() + "}"
  let count_signal = @signal.signal(initial_count)

  @luna.vfragment([
    @luna.h("div", [("class", @luna.attr_static("container"))], [
      @luna.h("h1", [], [@luna.vtext("Welcome to Sol")]),
      @luna.h("p", [], [@luna.vtext("A SSR-first web framework for MoonBit")]),
      @luna.h("nav", [], [
        @luna.h("a", [("href", @luna.attr_static("/"))], [@luna.vtext("Home")]),
        @luna.vtext(" | "),
        @luna.h("a", [("href", @luna.attr_static("/about"))], [@luna.vtext("About")]),
      ]),
    ]),
    @sol.island(
      "counter",
      "/static/hydrate_counter.js",
      state_json,
      [@counter.render(count_signal)],
    ),
  ])
}
