// Astra Components - Table of Contents
// Right-side navigation for document pages

///|
/// Build table of contents sidebar
pub fn build_toc(toc : Array[@markdown.TocItem]) -> @luna.Node[Unit] {
  let items = toc.map(fn(item) {
    let indent_class = "toc-item toc-level-\{item.level}"
    h("li", [attr("class", indent_class)], [
      h("a", [attr("href", "#" + item.id)], [@luna.text(item.text)]),
    ])
  })

  // Collapse button at bottom
  let collapse_btn = h(
    "button",
    [
      attr("class", "toc-collapse-btn"),
      attr("type", "button"),
      attr("onclick", "document.body.classList.toggle('toc-collapsed')"),
      attr("aria-label", "Toggle table of contents"),
    ],
    [h("span", [attr("class", "toc-collapse-icon")], [])],
  )
  let title = h("div", [attr("class", "toc-title")], [
    @luna.text("On this page"),
  ])
  let content = h("div", [attr("class", "toc-content")], [
    title,
    h("ul", [attr("class", "toc-list")], items),
  ])
  h("aside", [attr("class", "toc")], [content, collapse_btn])
}
