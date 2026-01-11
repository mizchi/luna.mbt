///|
test "listbox: role and tabindex" {
  let node : @luna.Node[Unit] = listbox(aria_label="Colors", [])
  guard node is @luna.Element(el) else { fail("expected Element") }
  let mut has_role = false
  let mut has_tabindex = false
  for attr in el.attrs {
    if attr.0 == "role" {
      guard attr.1 is @luna.VStatic("listbox") else { fail("wrong role") }
      has_role = true
    }
    if attr.0 == "tabindex" {
      guard attr.1 is @luna.VStatic("0") else { fail("wrong tabindex") }
      has_tabindex = true
    }
  }
  inspect(has_role, content="true")
  inspect(has_tabindex, content="true")
}

///|
test "listbox: multiselectable" {
  let node : @luna.Node[Unit] = listbox(
    aria_label="Items",
    multiselectable=true,
    [],
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  let mut has_multi = false
  for attr in el.attrs {
    if attr.0 == "aria-multiselectable" {
      guard attr.1 is @luna.VStatic("true") else { fail("wrong multi") }
      has_multi = true
    }
  }
  inspect(has_multi, content="true")
}

///|
test "option: selected state" {
  let node : @luna.Node[Unit] = option("red", true, [@luna.text("Red")])
  guard node is @luna.Element(el) else { fail("expected Element") }
  let mut has_role = false
  let mut has_selected = false
  for attr in el.attrs {
    if attr.0 == "role" {
      guard attr.1 is @luna.VStatic("option") else { fail("wrong role") }
      has_role = true
    }
    if attr.0 == "aria-selected" {
      guard attr.1 is @luna.VStatic("true") else { fail("wrong selected") }
      has_selected = true
    }
  }
  inspect(has_role, content="true")
  inspect(has_selected, content="true")
}

///|
test "listbox_from_options: builds structure" {
  let options = [
    listbox_option("a", "Option A"),
    listbox_option("b", "Option B"),
  ]
  let node : @luna.Node[Unit] = listbox_from_options(
    options,
    "a",
    aria_label="Choose",
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.children.length(), content="2")
}

///|
test "optgroup: creates group" {
  let node : @luna.Node[Unit] = optgroup("Colors", [])
  guard node is @luna.Element(el) else { fail("expected Element") }
  let mut has_role = false
  for attr in el.attrs {
    if attr.0 == "role" {
      guard attr.1 is @luna.VStatic("group") else { fail("wrong role") }
      has_role = true
    }
  }
  inspect(has_role, content="true")
}
