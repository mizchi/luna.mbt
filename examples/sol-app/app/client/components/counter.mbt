///| Counter Component - Shared between SSR and client

///| Counter component VNode
pub fn render(count : @signal.Signal[Int]) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("counter"))], [
    @luna.h("span", [("class", @luna.attr_static("count-display"))], [
      @luna.vtext_sig(count),
    ]),
    @luna.h("div", [("class", @luna.attr_static("buttons"))], [
      @luna.h("button", [
        ("class", @luna.attr_static("dec")),
        ("onclick", @luna.action("decrement")),
      ], [@luna.vtext("-")]),
      @luna.h("button", [
        ("class", @luna.attr_static("inc")),
        ("onclick", @luna.action("increment")),
      ], [@luna.vtext("+")]),
    ]),
  ])
}
