// InfoBox - MoonBit SSR component for the components demo.
//
// Uses @luna.h / text / attr_static to build a Node[Unit] tree that
// astra renders to HTML at build time (selected by page.json's
// { "ssr": true }). No client JS unless hydration is requested.

///|
using @luna { h, text, attr_static, type Node, type Attr }

///|
fn attr(key : String, value : String) -> (String, Attr[Unit]) {
  (key, attr_static(value))
}

///|
/// Render function - exported for SSR.
pub fn render() -> Node[Unit] {
  h("div", [attr("class", "info-box-component")], [
    h("h2", [], [text("InfoBox (MoonBit)")]),
    h("p", [], [
      text("Static box rendered from a local .mbt file using @luna.h."),
    ]),
    h("div", [attr("class", "info-box")], [
      h("span", [attr("class", "icon")], [text("i")]),
      h("div", [attr("class", "body")], [
        h("strong", [], [text("MoonBit-rendered box")]),
        text("Defined in docs/info_box/info_box.mbt and SSR'd to HTML."),
      ]),
    ]),
  ])
}
