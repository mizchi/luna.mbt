///|
test "tooltip: role and id" {
  let node : @luna.Node[Unit] = tooltip(
    "tip-1",
    [@luna.text("Help text")],
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  let mut has_role = false
  let mut has_id = false
  for attr in el.attrs {
    if attr.0 == "role" {
      guard attr.1 is @luna.VStatic("tooltip") else { fail("wrong role") }
      has_role = true
    }
    if attr.0 == "id" {
      guard attr.1 is @luna.VStatic("tip-1") else { fail("wrong id") }
      has_id = true
    }
  }
  inspect(has_role, content="true")
  inspect(has_id, content="true")
}

///|
test "tooltip_popup: hidden when not visible" {
  let node : @luna.Node[Unit] = tooltip_popup(
    "tip-2",
    false,
    [@luna.text("Hidden")],
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  let mut has_hidden = false
  for attr in el.attrs {
    if attr.0 == "hidden" {
      has_hidden = true
    }
  }
  inspect(has_hidden, content="true")
}

///|
test "tooltip_trigger: aria-describedby" {
  let node : @luna.Node[Unit] = tooltip_trigger(
    "my-tooltip",
    [@luna.text("?")],
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="button")
  let mut has_describedby = false
  for attr in el.attrs {
    if attr.0 == "aria-describedby" {
      guard attr.1 is @luna.VStatic("my-tooltip") else { fail("wrong id") }
      has_describedby = true
    }
  }
  inspect(has_describedby, content="true")
}

///|
test "tooltip_with_trigger: creates both elements" {
  let node : @luna.Node[Unit] = tooltip_with_trigger(
    "info",
    [@luna.text("?")],
    [@luna.text("More info")],
    false,
  )
  guard node is @luna.Fragment(children) else { fail("expected Fragment") }
  inspect(children.length(), content="2")
}
