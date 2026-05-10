///|
test "breadcrumb: creates nav with aria-label" {
  let items = [
    breadcrumb_item("/", "Home"),
    breadcrumb_item("/docs", "Docs"),
    breadcrumb_item("/docs/guide", "Guide", current=true),
  ]
  let node : @luna.Node[Unit, String] = breadcrumb(items)
  guard node is @core.Element(nav) else { fail("expected Element") }
  inspect(nav.tag, content="nav")
  let mut has_label = false
  for attr in nav.attrs {
    if attr.0 == "aria-label" {
      guard attr.1 is @core.VStatic("Breadcrumb") else { fail("wrong label") }
      has_label = true
    }
  }
  inspect(has_label, content="true")
}

///|
test "breadcrumb: custom separator" {
  let items = [
    breadcrumb_item("/", "Home"),
    breadcrumb_item("/about", "About", current=true),
  ]
  let node : @luna.Node[Unit, String] = breadcrumb(separator=">", items)
  guard node is @core.Element(nav) else { fail("expected Element") }
  guard nav.children[0] is @core.Element(ol) else { fail("expected ol") }
  inspect(ol.tag, content="ol")
}

///|
test "breadcrumb: current page has aria-current" {
  let items = [
    breadcrumb_item("/", "Home"),
    breadcrumb_item("/page", "Current", current=true),
  ]
  let node : @luna.Node[Unit, String] = breadcrumb(items)
  guard node is @core.Element(nav) else { fail("expected nav") }
  guard nav.children[0] is @core.Element(ol) else { fail("expected ol") }
  guard ol.children[1] is @core.Element(li) else { fail("expected li") }
  guard li.children[0] is @core.Element(a) else { fail("expected a") }
  let mut has_current = false
  for attr in a.attrs {
    if attr.0 == "aria-current" {
      guard attr.1 is @core.VStatic("page") else { fail("wrong current") }
      has_current = true
    }
  }
  inspect(has_current, content="true")
}

///|
test "breadcrumb_from_path: builds from segments" {
  let node : @luna.Node[Unit, String] = breadcrumb_from_path(
    "/docs",
    [("guide", "Guide"), ("install", "Installation")],
    "Current Page",
  )
  guard node is @core.Element(nav) else { fail("expected nav") }
  guard nav.children[0] is @core.Element(ol) else { fail("expected ol") }
  inspect(ol.children.length(), content="3")
}
