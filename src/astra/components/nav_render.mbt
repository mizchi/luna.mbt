// NavContext Renderers - Render navigation components from NavContext
//
// Tree-driven rendering for sidebar, breadcrumb, and prev/next.

// =============================================================================
// Sidebar Rendering
// =============================================================================

///|
/// Render sidebar from NavContext
pub fn render_sidebar(ctx : NavContext) -> @luna.Node[Unit] {
  let tree = build_sidebar_tree(ctx.tree, get_current_url(ctx), ctx.locale)
  render_sidebar_nodes(tree)
}

///|
/// Render sidebar nodes recursively
fn render_sidebar_nodes(nodes : Array[SidebarNode]) -> @luna.Node[Unit] {
  if nodes.is_empty() {
    return empty()
  }
  let items = nodes.map(fn(node) { render_sidebar_node(node) })
  h("ul", [attr("class", "sidebar-list")], items)
}

///|
/// Render single sidebar node
fn render_sidebar_node(node : SidebarNode) -> @luna.Node[Unit] {
  match node {
    Link(text~, url~, active~) => {
      let class_name = if active {
        "sidebar-link active"
      } else {
        "sidebar-link"
      }
      h("li", [attr("class", "sidebar-item")], [
        h("a", [attr("href", url), attr("class", class_name)], [
          @luna.text(text),
        ]),
      ])
    }
    Section(text~, url~, collapsed~, active~, children~) => {
      let class_name = if active {
        "sidebar-section active"
      } else {
        "sidebar-section"
      }

      // Section header
      let header_content : Array[@luna.Node[Unit]] = match url {
        Some(link) =>
          [
            h(
              "a",
              [attr("href", link), attr("class", "sidebar-section-link")],
              [@luna.text(text)],
            ),
          ]
        None => [@luna.text(text)]
      }
      let header = h(
        "div",
        [attr("class", "sidebar-section-header")],
        header_content,
      )

      // Children
      let children_node = render_sidebar_nodes(children)

      // Wrap in details/summary if collapsible
      if collapsed {
        h("li", [attr("class", class_name)], [
          h("details", [attr("open", "")], [
            h("summary", [], [header]),
            children_node,
          ]),
        ])
      } else {
        h("li", [attr("class", class_name)], [header, children_node])
      }
    }
  }
}

// =============================================================================
// Breadcrumb Rendering
// =============================================================================

///|
/// Render breadcrumb from NavContext
pub fn render_breadcrumb(ctx : NavContext) -> @luna.Node[Unit] {
  if ctx.breadcrumb_path.is_empty() {
    return empty()
  }
  let items : Array[@luna.Node[Unit]] = []
  let last_idx = ctx.breadcrumb_path.length() - 1
  for i = 0; i < ctx.breadcrumb_path.length(); i = i + 1 {
    let (title, url) = ctx.breadcrumb_path[i]

    // Add separator (except for first item)
    if i > 0 {
      items.push(
        h("span", [attr("class", "breadcrumb-separator")], [@luna.text("/")]),
      )
    }

    // Last item is current page (no link)
    if i == last_idx {
      items.push(
        h("span", [attr("class", "breadcrumb-current")], [@luna.text(title)]),
      )
    } else {
      items.push(
        h("a", [attr("href", url), attr("class", "breadcrumb-link")], [
          @luna.text(title),
        ]),
      )
    }
  }
  h("nav", [attr("class", "breadcrumb")], items)
}

// =============================================================================
// Prev/Next Rendering
// =============================================================================

///|
/// Render prev/next navigation from NavContext
pub fn render_prev_next(ctx : NavContext) -> @luna.Node[Unit] {
  let children : Array[@luna.Node[Unit]] = []
  match ctx.prev_page {
    Some(page) =>
      children.push(
        h("a", [attr("href", page.url_path), attr("class", "prev-link")], [
          h("span", [attr("class", "label")], [@luna.text("Previous")]),
          h("span", [attr("class", "title")], [@luna.text(page.title)]),
        ]),
      )
    None => ()
  }
  match ctx.next_page {
    Some(page) =>
      children.push(
        h("a", [attr("href", page.url_path), attr("class", "next-link")], [
          h("span", [attr("class", "label")], [@luna.text("Next")]),
          h("span", [attr("class", "title")], [@luna.text(page.title)]),
        ]),
      )
    None => ()
  }
  h("nav", [attr("class", "prev-next")], children)
}

// =============================================================================
// Helpers
// =============================================================================

///|
fn get_current_url(ctx : NavContext) -> String {
  match ctx.current_page {
    Some(page) => page.url_path
    None => "/"
  }
}
