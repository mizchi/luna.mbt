///|
test "tablist: role and aria-label" {
  let node : @luna.Node[Unit] = @apg.tablist(
    aria_label="Content tabs",
    [],
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  guard el.attrs[0] is ("role", @luna.VStatic("tablist")) else {
    fail("expected role=tablist")
  }
}

///|
test "tablist: vertical orientation" {
  let node : @luna.Node[Unit] = @apg.tablist(orientation=Vertical, [])
  guard node is @luna.Element(el) else { fail("expected Element") }
  let mut has_orientation = false
  for attr in el.attrs {
    if attr.0 == "aria-orientation" {
      guard attr.1 is @luna.VStatic("vertical") else { fail("wrong orient") }
      has_orientation = true
    }
  }
  inspect(has_orientation, content="true")
}

///|
test "tab: selected state" {
  let node : @luna.Node[Unit] = @apg.tab(
    "tab-1",
    true,
    "panel-1",
    [@luna.text("Tab 1")],
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="button")
  let mut has_selected = false
  let mut has_tabindex = false
  for attr in el.attrs {
    if attr.0 == "aria-selected" {
      guard attr.1 is @luna.VStatic("true") else { fail("wrong selected") }
      has_selected = true
    }
    if attr.0 == "tabindex" {
      guard attr.1 is @luna.VStatic("0") else { fail("wrong tabindex") }
      has_tabindex = true
    }
  }
  inspect(has_selected, content="true")
  inspect(has_tabindex, content="true")
}

///|
test "tab: unselected state" {
  let node : @luna.Node[Unit] = @apg.tab(
    "tab-2",
    false,
    "panel-2",
    [@luna.text("Tab 2")],
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  let mut selected_val = ""
  let mut tabindex_val = ""
  for attr in el.attrs {
    if attr.0 == "aria-selected" {
      guard attr.1 is @luna.VStatic(v) else { fail("expected VStatic") }
      selected_val = v
    }
    if attr.0 == "tabindex" {
      guard attr.1 is @luna.VStatic(v) else { fail("expected VStatic") }
      tabindex_val = v
    }
  }
  inspect(selected_val, content="false")
  inspect(tabindex_val, content="-1")
}

///|
test "tabpanel: role and labelledby" {
  let node : @luna.Node[Unit] = @apg.tabpanel(
    "panel-1",
    "tab-1",
    false,
    [@luna.text("Content")],
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="div")
  let mut has_role = false
  let mut has_labelledby = false
  for attr in el.attrs {
    if attr.0 == "role" {
      guard attr.1 is @luna.VStatic("tabpanel") else { fail("wrong role") }
      has_role = true
    }
    if attr.0 == "aria-labelledby" {
      guard attr.1 is @luna.VStatic("tab-1") else { fail("wrong labelledby") }
      has_labelledby = true
    }
  }
  inspect(has_role, content="true")
  inspect(has_labelledby, content="true")
}

///|
test "tabs: builds complete structure" {
  let items : Array[@apg.TabItem[Unit]] = [
    @apg.tab_item("first", "First", [@luna.text("Panel 1")]),
    @apg.tab_item("second", "Second", [@luna.text("Panel 2")]),
  ]
  let node : @luna.Node[Unit] = @apg.tabs(items, 0, aria_label="Demo")
  guard node is @luna.Fragment(children) else { fail("expected Fragment") }
  // First child is tablist, rest are panels
  inspect(children.length(), content="3")
  guard children[0] is @luna.Element(list) && list.tag == "div" else {
    fail("expected tablist")
  }
}
