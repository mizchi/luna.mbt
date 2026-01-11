///|
test "banner: creates header element" {
  let node : @luna.Node[Unit] = banner([@luna.text("Site Title")])
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="header")
}

///|
test "banner: with aria-label" {
  let node : @luna.Node[Unit] = banner(
    aria_label="Main header",
    [@luna.text("Logo")],
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  let mut has_label = false
  for attr in el.attrs {
    if attr.0 == "aria-label" {
      guard attr.1 is @luna.VStatic("Main header") else { fail("wrong label") }
      has_label = true
    }
  }
  inspect(has_label, content="true")
}

///|
test "nav: creates nav element" {
  let node : @luna.Node[Unit] = nav([@luna.text("Links")])
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="nav")
}

///|
test "nav: with aria-label" {
  let node : @luna.Node[Unit] = nav(
    aria_label="Main navigation",
    [@luna.text("Menu")],
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  let mut has_label = false
  for attr in el.attrs {
    if attr.0 == "aria-label" {
      guard attr.1 is @luna.VStatic("Main navigation") else {
        fail("wrong label")
      }
      has_label = true
    }
  }
  inspect(has_label, content="true")
}

///|
test "main_content: creates main element" {
  let node : @luna.Node[Unit] = main_content([@luna.text("Content")])
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="main")
}

///|
test "aside: creates aside element" {
  let node : @luna.Node[Unit] = aside([@luna.text("Sidebar")])
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="aside")
}

///|
test "contentinfo: creates footer element" {
  let node : @luna.Node[Unit] = contentinfo([@luna.text("© 2024")])
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="footer")
}

///|
test "search: creates search element" {
  let node : @luna.Node[Unit] = search([@luna.text("Search form")])
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="search")
}

///|
test "search_role: creates form with role=search" {
  let node : @luna.Node[Unit] = search_role([@luna.text("Search")])
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="form")
  let mut has_role = false
  for attr in el.attrs {
    if attr.0 == "role" {
      guard attr.1 is @luna.VStatic("search") else { fail("wrong role") }
      has_role = true
    }
  }
  inspect(has_role, content="true")
}

///|
test "form_landmark: creates form with aria-label" {
  let node : @luna.Node[Unit] = form_landmark(
    aria_label="Contact form",
    [@luna.text("Form")],
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="form")
  let mut has_label = false
  for attr in el.attrs {
    if attr.0 == "aria-label" {
      guard attr.1 is @luna.VStatic("Contact form") else { fail("wrong label") }
      has_label = true
    }
  }
  inspect(has_label, content="true")
}

///|
test "region: creates section with aria-label" {
  let node : @luna.Node[Unit] = region(
    aria_label="Quick Stats",
    [@luna.text("Stats")],
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="section")
  let mut has_label = false
  for attr in el.attrs {
    if attr.0 == "aria-label" {
      guard attr.1 is @luna.VStatic("Quick Stats") else { fail("wrong label") }
      has_label = true
    }
  }
  inspect(has_label, content="true")
}

///|
test "page_layout: creates full structure" {
  let node : @luna.Node[Unit] = page_layout(
    header=[@luna.text("Header")],
    nav_content=[@luna.text("Nav")],
    [@luna.text("Main")],
    aside_content=[@luna.text("Aside")],
    footer_content=[@luna.text("Footer")],
  )
  guard node is @luna.Fragment(children) else { fail("expected Fragment") }
  inspect(children.length(), content="5")
  // Check each landmark element
  guard children[0] is @luna.Element(h) && h.tag == "header" else {
    fail("expected header")
  }
  guard children[1] is @luna.Element(n) && n.tag == "nav" else {
    fail("expected nav")
  }
  guard children[2] is @luna.Element(m) && m.tag == "main" else {
    fail("expected main")
  }
  guard children[3] is @luna.Element(a) && a.tag == "aside" else {
    fail("expected aside")
  }
  guard children[4] is @luna.Element(f) && f.tag == "footer" else {
    fail("expected footer")
  }
}

///|
test "page_layout: minimal structure" {
  let node : @luna.Node[Unit] = page_layout([@luna.text("Content only")])
  guard node is @luna.Fragment(children) else { fail("expected Fragment") }
  inspect(children.length(), content="1")
  guard children[0] is @luna.Element(m) && m.tag == "main" else {
    fail("expected main")
  }
}
