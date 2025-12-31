// Astra Components - Footer
// Element-based compositional footer system

///|
/// Build site footer using element configuration
pub fn build_footer(ctx : @ssg.BuildContext) -> @luna.Node[Unit] {
  match ctx.config.theme.footer {
    Some(footer_config) => {
      let children : Array[@luna.Node[Unit]] = []

      // If top/bottom elements are configured, use element-based rendering
      if not(footer_config.top.is_empty()) ||
        not(footer_config.bottom.is_empty()) {
        // Top section
        if not(footer_config.top.is_empty()) {
          let top_elements = render_footer_elements(
            footer_config.top,
            ctx,
            footer_config,
          )
          children.push(h("div", [attr("class", "footer-top")], top_elements))
        }

        // Bottom section
        if not(footer_config.bottom.is_empty()) {
          let bottom_elements = render_footer_elements(
            footer_config.bottom,
            ctx,
            footer_config,
          )
          children.push(
            h("div", [attr("class", "footer-bottom")], bottom_elements),
          )
        }
      } else {
        // Legacy behavior: use links, message, copyright directly
        // Render link columns if present
        if not(footer_config.links.is_empty()) {
          children.push(build_footer_columns(footer_config.links))
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
          children.push(
            h("div", [attr("class", "footer-bottom")], bottom_items),
          )
        }
      }
      h("footer", [attr("class", "site-footer")], children)
    }
    None => empty()
  }
}

///|
/// Render footer elements
fn render_footer_elements(
  elements : Array[@ssg.FooterElement],
  ctx : @ssg.BuildContext,
  footer_config : @ssg.FooterConfig,
) -> Array[@luna.Node[Unit]] {
  let result : Array[@luna.Node[Unit]] = []
  for element in elements {
    result.push(render_footer_element(element, ctx, footer_config))
  }
  result
}

///|
/// Render a single footer element
fn render_footer_element(
  element : @ssg.FooterElement,
  ctx : @ssg.BuildContext,
  footer_config : @ssg.FooterConfig,
) -> @luna.Node[Unit] {
  match element {
    @ssg.FooterElement::Columns => build_footer_columns(footer_config.links)
    @ssg.FooterElement::Message =>
      match footer_config.message {
        Some(msg) =>
          h("p", [attr("class", "footer-message")], [@luna.text(msg)])
        None => empty()
      }
    @ssg.FooterElement::Copyright =>
      match footer_config.copyright {
        Some(copyright) =>
          h("p", [attr("class", "footer-copyright")], [@luna.text(copyright)])
        None => empty()
      }
    @ssg.FooterElement::SocialLinks =>
      build_social_links(ctx.config.theme.social_links)
    @ssg.FooterElement::Custom(tag) => h(tag, [], [])
  }
}

///|
/// Build footer columns (link groups)
fn build_footer_columns(
  columns : Array[@ssg.FooterColumn],
) -> @luna.Node[Unit] {
  if columns.is_empty() {
    return empty()
  }
  let column_nodes = columns.map(fn(col) {
    let links = col.items.map(fn(link) {
      h("li", [], [
        h("a", [attr("href", link.href), attr("class", "footer-link")], [
          @luna.text(link.label),
        ]),
      ])
    })
    h("div", [attr("class", "footer-column")], [
      h("h3", [attr("class", "footer-column-title")], [@luna.text(col.title)]),
      h("ul", [attr("class", "footer-links")], links),
    ])
  })
  h("div", [attr("class", "footer-columns")], column_nodes)
}
