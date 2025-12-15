///| About Page

///| About page
pub fn page(_ctx : @sol.Ctx) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("container"))], [
    @luna.h("h1", [], [@luna.vtext("About")]),
    @luna.h("p", [], [@luna.vtext("Built with MoonBit and Sol framework.")]),
    @luna.h("a", [("href", @luna.attr_static("/"))], [@luna.vtext("← Back")]),
  ])
}
