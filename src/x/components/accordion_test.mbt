///|
test "accordion_header: expanded state" {
  let node : @luna.Node[Unit] = accordion_header("header-1", true, "panel-1", [
    @luna.text("Section 1"),
  ])
  guard node is @core.Element(heading) else { fail("expected Element") }
  inspect(heading.tag, content="h3")
  guard heading.children[0] is @core.Element(btn) else {
    fail("expected button")
  }
  let mut has_expanded = false
  for attr in btn.attrs {
    if attr.0 == "aria-expanded" {
      guard attr.1 is @core.VStatic("true") else { fail("wrong expanded") }
      has_expanded = true
    }
  }
  inspect(has_expanded, content="true")
}

///|
test "accordion_header: collapsed state" {
  let node : @luna.Node[Unit] = accordion_header(
    "header-2",
    false,
    "panel-2",
    level=2,
    [@luna.text("Section 2")],
  )
  guard node is @core.Element(heading) else { fail("expected Element") }
  inspect(heading.tag, content="h2")
  guard heading.children[0] is @core.Element(btn) else {
    fail("expected button")
  }
  let mut expanded_val = ""
  for attr in btn.attrs {
    if attr.0 == "aria-expanded" {
      guard attr.1 is @core.VStatic(v) else { fail("expected VStatic") }
      expanded_val = v
    }
  }
  inspect(expanded_val, content="false")
}

///|
test "accordion_panel: with region role" {
  let node : @luna.Node[Unit] = accordion_panel(
    "panel-1",
    "header-1",
    false,
    use_region=true,
    [@luna.text("Content")],
  )
  guard node is @core.Element(el) else { fail("expected Element") }
  let mut has_role = false
  let mut has_labelledby = false
  for attr in el.attrs {
    if attr.0 == "role" {
      guard attr.1 is @core.VStatic("region") else { fail("wrong role") }
      has_role = true
    }
    if attr.0 == "aria-labelledby" {
      guard attr.1 is @core.VStatic("header-1") else {
        fail("wrong labelledby")
      }
      has_labelledby = true
    }
  }
  inspect(has_role, content="true")
  inspect(has_labelledby, content="true")
}

///|
test "accordion_panel: hidden when collapsed" {
  let node : @luna.Node[Unit] = accordion_panel("panel-x", "header-x", true, [])
  guard node is @core.Element(el) else { fail("expected Element") }
  let mut has_hidden = false
  for attr in el.attrs {
    if attr.0 == "hidden" {
      has_hidden = true
    }
  }
  inspect(has_hidden, content="true")
}

///|
test "accordion: builds structure" {
  let items : Array[AccordionItem[Unit]] = [
    accordion_item("sec1", "Section 1", [@luna.text("Content 1")]),
    accordion_item("sec2", "Section 2", [@luna.text("Content 2")]),
  ]
  let node : @luna.Node[Unit] = accordion(items, 0)
  guard node is @core.Element(container) else { fail("expected Element") }
  // 2 items = 4 children (header + panel each)
  inspect(container.children.length(), content="4")
}

///|
test "accordion_multi: multiple expanded" {
  let items : Array[AccordionItem[Unit]] = [
    accordion_item("a", "A", [@luna.text("A")]),
    accordion_item("b", "B", [@luna.text("B")]),
    accordion_item("c", "C", [@luna.text("C")]),
  ]
  let node : @luna.Node[Unit] = accordion_multi(items, ["a", "c"])
  guard node is @core.Element(container) else { fail("expected Element") }
  // 3 items = 6 children
  inspect(container.children.length(), content="6")
}

///|
test "accordion_header_dyn: dynamic expanded" {
  let expanded = @resource.signal(false)
  let node : @luna.Node[Unit] = accordion_header_dyn("h1", expanded, "p1", [
    @luna.text("Title"),
  ])
  guard node is @core.Element(heading) else { fail("expected Element") }
  guard heading.children[0] is @core.Element(btn) else {
    fail("expected button")
  }
  let mut dynamic_attr : (() -> String)? = None
  for attr in btn.attrs {
    if attr.0 == "aria-expanded" {
      guard attr.1 is @core.VDynamic(getter) else { fail("expected VDynamic") }
      dynamic_attr = Some(getter)
    }
  }
  guard dynamic_attr is Some(getter) else { fail("expected expanded attr") }
  inspect(getter(), content="false")
  expanded.set(true)
  inspect(getter(), content="true")
}
