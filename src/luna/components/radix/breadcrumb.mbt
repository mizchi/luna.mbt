///|
/// Radix-style Breadcrumb component for Luna (Headless)
/// Navigation breadcrumb trail

///|
/// Create a headless breadcrumb root
/// Outputs: <nav class="radix-breadcrumb" aria-label="Breadcrumb"><ol>children</ol></nav>
pub fn radix_breadcrumb(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "nav",
    [
      ("class", @luna.attr_static("radix-breadcrumb")),
      ("aria-label", @luna.attr_static("Breadcrumb")),
    ],
    [
      @luna.h(
        "ol",
        [("class", @luna.attr_static("radix-breadcrumb-list"))],
        children,
      ),
    ],
  )
}

///|
/// Create a headless breadcrumb item
/// Outputs: <li class="radix-breadcrumb-item">children</li>
pub fn radix_breadcrumb_item(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "li",
    [("class", @luna.attr_static("radix-breadcrumb-item"))],
    children,
  )
}

///|
/// Create a headless breadcrumb link
/// Outputs: <a class="radix-breadcrumb-link" href="...">children</a>
pub fn radix_breadcrumb_link(
  href : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "a",
    [
      ("class", @luna.attr_static("radix-breadcrumb-link")),
      ("href", @luna.attr_static(href)),
    ],
    children,
  )
}

///|
/// Create a headless breadcrumb page (current page, not a link)
/// Outputs: <span class="radix-breadcrumb-page" aria-current="page">children</span>
pub fn radix_breadcrumb_page(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "span",
    [
      ("class", @luna.attr_static("radix-breadcrumb-page")),
      ("aria-current", @luna.attr_static("page")),
    ],
    children,
  )
}

///|
/// Create a headless breadcrumb separator
/// Outputs: <span class="radix-breadcrumb-separator" aria-hidden="true">children</span>
pub fn radix_breadcrumb_separator(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "span",
    [
      ("class", @luna.attr_static("radix-breadcrumb-separator")),
      ("aria-hidden", @luna.attr_static("true")),
    ],
    children,
  )
}

///|
/// Create a headless breadcrumb ellipsis (for collapsed items)
/// Outputs: <span class="radix-breadcrumb-ellipsis">...</span>
pub fn radix_breadcrumb_ellipsis() -> @luna.Node[Unit] {
  @luna.h(
    "span",
    [("class", @luna.attr_static("radix-breadcrumb-ellipsis"))],
    [@luna.text("...")],
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the breadcrumb component
fn breadcrumb_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.breadcrumb-list {
    #|  display: flex;
    #|  flex-wrap: wrap;
    #|  align-items: center;
    #|  gap: 0.375rem;
    #|  list-style: none;
    #|  margin: 0;
    #|  padding: 0;
    #|}
    #|
    #|.breadcrumb-item {
    #|  display: flex;
    #|  align-items: center;
    #|  gap: 0.375rem;
    #|}
    #|
    #|.breadcrumb-link {
    #|  font-size: 0.875rem;
    #|  color: #71717a;
    #|  text-decoration: none;
    #|  transition: color 0.15s ease;
    #|}
    #|
    #|.breadcrumb-link:hover {
    #|  color: #18181b;
    #|}
    #|
    #|.breadcrumb-page {
    #|  font-size: 0.875rem;
    #|  font-weight: 500;
    #|  color: #18181b;
    #|}
    #|
    #|.breadcrumb-separator {
    #|  font-size: 0.875rem;
    #|  color: #a1a1aa;
    #|}
    #|
    #|.breadcrumb-ellipsis {
    #|  font-size: 0.875rem;
    #|  color: #a1a1aa;
    #|}
  css
}

///|
/// Create a styled breadcrumb with Declarative Shadow DOM
pub fn radix_breadcrumb_styled(
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => breadcrumb_styles()
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

  @luna.h("radix-breadcrumb", [], all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a breadcrumb with luna/css atomic styles
pub fn radix_breadcrumb_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let list_class = breadcrumb_list_styles()
  @luna.h(
    "nav",
    [("aria-label", @luna.attr_static("Breadcrumb"))],
    [@luna.h("ol", [("class", @luna.attr_static(list_class))], children)],
  )
}

///|
/// Create a breadcrumb item with luna/css atomic styles
pub fn radix_breadcrumb_item_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = breadcrumb_item_styles()
  @luna.h("li", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a breadcrumb link with luna/css atomic styles
pub fn radix_breadcrumb_link_ucss(
  href : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = breadcrumb_link_styles()
  @luna.h(
    "a",
    [
      ("class", @luna.attr_static(class_names)),
      ("href", @luna.attr_static(href)),
    ],
    children,
  )
}

///|
/// Create a breadcrumb page with luna/css atomic styles
pub fn radix_breadcrumb_page_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = breadcrumb_page_styles()
  @luna.h(
    "span",
    [
      ("class", @luna.attr_static(class_names)),
      ("aria-current", @luna.attr_static("page")),
    ],
    children,
  )
}

///|
/// Create a breadcrumb separator with luna/css atomic styles
pub fn radix_breadcrumb_separator_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = breadcrumb_separator_styles()
  @luna.h(
    "span",
    [
      ("class", @luna.attr_static(class_names)),
      ("aria-hidden", @luna.attr_static("true")),
    ],
    children,
  )
}
