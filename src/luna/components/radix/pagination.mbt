///|
/// Radix-style Pagination component for Luna (Headless)
/// Page navigation

///|
/// Create a headless pagination root
/// Outputs: <nav class="radix-pagination" role="navigation" aria-label="pagination">children</nav>
pub fn radix_pagination(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "nav",
    [
      ("class", @luna.attr_static("radix-pagination")),
      ("role", @luna.attr_static("navigation")),
      ("aria-label", @luna.attr_static("pagination")),
    ],
    children,
  )
}

///|
/// Create a headless pagination content (list of items)
/// Outputs: <ul class="radix-pagination-content">children</ul>
pub fn radix_pagination_content(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "ul",
    [("class", @luna.attr_static("radix-pagination-content"))],
    children,
  )
}

///|
/// Create a headless pagination item
/// Outputs: <li class="radix-pagination-item">children</li>
pub fn radix_pagination_item(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "li",
    [("class", @luna.attr_static("radix-pagination-item"))],
    children,
  )
}

///|
/// Create a headless pagination link
/// Outputs: <a class="radix-pagination-link" href="..." data-active="...">children</a>
pub fn radix_pagination_link(
  href : String,
  active? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_active = match active {
    Some(true) => true
    _ => false
  }

  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-pagination-link")),
    ("href", @luna.attr_static(href)),
  ]

  if is_active {
    attrs.push(("data-active", @luna.attr_static("")))
    attrs.push(("aria-current", @luna.attr_static("page")))
  }

  @luna.h("a", attrs, children)
}

///|
/// Create a headless pagination previous button
/// Outputs: <a class="radix-pagination-previous" href="...">children</a>
pub fn radix_pagination_previous(
  href : String,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-pagination-previous")),
    ("href", @luna.attr_static(href)),
  ]

  match disabled {
    Some(true) => {
      attrs.push(("data-disabled", @luna.attr_static("")))
      attrs.push(("aria-disabled", @luna.attr_static("true")))
    }
    _ => ()
  }

  @luna.h("a", attrs, children)
}

///|
/// Create a headless pagination next button
/// Outputs: <a class="radix-pagination-next" href="...">children</a>
pub fn radix_pagination_next(
  href : String,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-pagination-next")),
    ("href", @luna.attr_static(href)),
  ]

  match disabled {
    Some(true) => {
      attrs.push(("data-disabled", @luna.attr_static("")))
      attrs.push(("aria-disabled", @luna.attr_static("true")))
    }
    _ => ()
  }

  @luna.h("a", attrs, children)
}

///|
/// Create a headless pagination ellipsis
/// Outputs: <span class="radix-pagination-ellipsis">...</span>
pub fn radix_pagination_ellipsis() -> @luna.Node[Unit] {
  @luna.h(
    "span",
    [("class", @luna.attr_static("radix-pagination-ellipsis"))],
    [@luna.text("...")],
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the pagination component
fn pagination_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.pagination {
    #|  display: flex;
    #|  justify-content: center;
    #|}
    #|
    #|.pagination-content {
    #|  display: flex;
    #|  align-items: center;
    #|  gap: 0.25rem;
    #|  list-style: none;
    #|  margin: 0;
    #|  padding: 0;
    #|}
    #|
    #|.pagination-link,
    #|.pagination-previous,
    #|.pagination-next {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  min-width: 2.25rem;
    #|  height: 2.25rem;
    #|  padding: 0 0.5rem;
    #|  font-size: 0.875rem;
    #|  text-decoration: none;
    #|  color: #18181b;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|  transition: background 0.15s ease;
    #|}
    #|
    #|.pagination-link:hover,
    #|.pagination-previous:hover,
    #|.pagination-next:hover {
    #|  background: #f4f4f5;
    #|}
    #|
    #|.pagination-link[data-active] {
    #|  background: #18181b;
    #|  color: white;
    #|  border-color: #18181b;
    #|}
    #|
    #|.pagination-previous[data-disabled],
    #|.pagination-next[data-disabled] {
    #|  opacity: 0.5;
    #|  pointer-events: none;
    #|}
    #|
    #|.pagination-ellipsis {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  min-width: 2.25rem;
    #|  height: 2.25rem;
    #|  font-size: 0.875rem;
    #|  color: #71717a;
    #|}
  css
}

///|
/// Create a styled pagination with Declarative Shadow DOM
pub fn radix_pagination_styled(
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => pagination_styles()
  }

  // Build template content
  let template_children : Array[@luna.Node[Unit]] = [
    @luna.h("style", [], [@luna.text(css)]),
    @luna.h("slot", [], []),
  ]

  // Create DSD structure
  let all_children : Array[@luna.Node[Unit]] = [
    @luna.h(
      "template",
      [("shadowrootmode", @luna.attr_static("open"))],
      template_children,
    ),
  ]

  for child in children {
    all_children.push(child)
  }

  @luna.h("radix-pagination", [], all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a pagination with luna/css atomic styles
pub fn radix_pagination_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = pagination_base_styles()
  @luna.h(
    "nav",
    [
      ("class", @luna.attr_static(class_names)),
      ("role", @luna.attr_static("navigation")),
      ("aria-label", @luna.attr_static("pagination")),
    ],
    children,
  )
}

///|
/// Create a pagination content with luna/css atomic styles
pub fn radix_pagination_content_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = pagination_content_styles()
  @luna.h("ul", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a pagination link with luna/css atomic styles
pub fn radix_pagination_link_ucss(
  href : String,
  active? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_active = match active {
    Some(true) => true
    _ => false
  }

  let mut class_names = pagination_link_styles()
  if is_active {
    class_names = class_names + " " + pagination_link_active_styles()
  }

  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("href", @luna.attr_static(href)),
  ]

  if is_active {
    attrs.push(("aria-current", @luna.attr_static("page")))
  }

  @luna.h("a", attrs, children)
}

///|
/// Create a pagination previous button with luna/css atomic styles
pub fn radix_pagination_previous_ucss(
  href : String,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let mut class_names = pagination_nav_styles()

  match disabled {
    Some(true) =>
      class_names = class_names +
        " " +
        @css.styles([("opacity", "0.5"), ("pointer-events", "none")])
    _ => ()
  }

  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("href", @luna.attr_static(href)),
  ]

  match disabled {
    Some(true) => attrs.push(("aria-disabled", @luna.attr_static("true")))
    _ => ()
  }

  @luna.h("a", attrs, children)
}

///|
/// Create a pagination next button with luna/css atomic styles
pub fn radix_pagination_next_ucss(
  href : String,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let mut class_names = pagination_nav_styles()

  match disabled {
    Some(true) =>
      class_names = class_names +
        " " +
        @css.styles([("opacity", "0.5"), ("pointer-events", "none")])
    _ => ()
  }

  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("href", @luna.attr_static(href)),
  ]

  match disabled {
    Some(true) => attrs.push(("aria-disabled", @luna.attr_static("true")))
    _ => ()
  }

  @luna.h("a", attrs, children)
}

///|
/// Create a pagination ellipsis with luna/css atomic styles
pub fn radix_pagination_ellipsis_ucss() -> @luna.Node[Unit] {
  let class_names = pagination_ellipsis_styles()
  @luna.h(
    "span",
    [("class", @luna.attr_static(class_names))],
    [@luna.text("...")],
  )
}
