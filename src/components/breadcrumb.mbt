///|
/// APG Breadcrumb Pattern
/// https://www.w3.org/WAI/ARIA/apg/patterns/breadcrumb/
///
/// A breadcrumb trail shows the path from home to the current page.
///
/// ARIA:
/// - nav element with aria-label="Breadcrumb"
/// - Current page link has aria-current="page"

///|
/// Breadcrumb item data
pub(all) struct BreadcrumbItem {
  href : String
  label : String
  current : Bool  // If true, this is the current page
}

///|
/// Create a breadcrumb item
pub fn breadcrumb_item(
  href : String,
  label : String,
  current? : Bool,
) -> BreadcrumbItem {
  let cur = match current {
    Some(c) => c
    None => false
  }
  { href, label, current: cur }
}

///|
/// Create a breadcrumb navigation.
///
/// Parameters:
/// - aria_label: Accessible label (default: "Breadcrumb")
/// - separator: Separator between items (default: "/")
/// - items: Breadcrumb items
pub fn[E] breadcrumb(
  aria_label? : String,
  separator? : String,
  items : Array[BreadcrumbItem],
) -> @luna.Node[E] {
  let label = match aria_label {
    Some(l) => l
    None => "Breadcrumb"
  }
  let sep = match separator {
    Some(s) => s
    None => "/"
  }
  let list_items : Array[@luna.Node[E]] = []
  for i, item in items {
    let link_attrs : Array[(String, @luna.Attr[E])] = [
      ("href", @luna.attr_static(item.href)),
    ]
    if item.current {
      link_attrs.push(("aria-current", @luna.attr_static("page")))
    }
    let link_node = @luna.h("a", link_attrs, [@luna.text(item.label)])
    let li_children : Array[@luna.Node[E]] = [link_node]
    if i < items.length() - 1 {
      li_children.push(
        @luna.h(
          "span",
          [("aria-hidden", @luna.attr_static("true"))],
          [@luna.text(" " + sep + " ")],
        ),
      )
    }
    list_items.push(@luna.h("li", [], li_children))
  }
  let ol = @luna.h("ol", [], list_items)
  @luna.h(
    "nav",
    [("aria-label", @luna.attr_static(label))],
    [ol],
  )
}

///|
/// Create a simple breadcrumb from path segments.
///
/// Parameters:
/// - base_path: Base path (e.g., "/docs")
/// - segments: Path segments (e.g., ["Getting Started", "Installation"])
/// - current_label: Label for current page
pub fn[E] breadcrumb_from_path(
  base_path : String,
  segments : Array[(String, String)],  // (path_segment, label)
  current_label : String,
) -> @luna.Node[E] {
  let items : Array[BreadcrumbItem] = []
  let mut path = base_path
  for seg in segments {
    let (segment, label) = seg
    path = path + "/" + segment
    items.push(breadcrumb_item(path, label))
  }
  items.push(breadcrumb_item("#", current_label, current=true))
  breadcrumb(items)
}
