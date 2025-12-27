// Astra Components - Footer
// Site footer with optional link columns

///|
/// Build site footer
pub fn build_footer(ctx : @astra.BuildContext) -> @luna.Node[Unit] {
  match ctx.config.theme.footer {
    Some(footer_config) => {
      let children : Array[@luna.Node[Unit]] = []

      // Render link columns if present
      if not(footer_config.links.is_empty()) {
        let columns = footer_config.links.map(fn(col) {
          let links = col.items.map(fn(link) {
            h("li", [], [
              h("a", [attr("href", link.href), attr("class", "footer-link")], [
                @luna.text(link.label),
              ]),
            ])
          })
          h("div", [attr("class", "footer-column")], [
            h("h3", [attr("class", "footer-column-title")], [
              @luna.text(col.title),
            ]),
            h("ul", [attr("class", "footer-links")], links),
          ])
        })
        children.push(h("div", [attr("class", "footer-columns")], columns))
      }

      // Bottom section with message and copyright
      let bottom_items : Array[@luna.Node[Unit]] = []
      if footer_config.message is Some(msg) {
        bottom_items.push(
          h("p", [attr("class", "footer-message")], [@luna.text(msg)]),
        )
      }
      if footer_config.copyright is Some(copyright) {
        bottom_items.push(
          h("p", [attr("class", "footer-copyright")], [@luna.text(copyright)]),
        )
      }
      if not(bottom_items.is_empty()) {
        children.push(h("div", [attr("class", "footer-bottom")], bottom_items))
      }
      h("footer", [attr("class", "site-footer")], children)
    }
    None => empty()
  }
}
