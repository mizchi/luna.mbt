///|
test "checkbox: checked state" {
  let node : @luna.Node[Unit] = checkbox(Checked, [@luna.text("Accept")])
  guard node is @luna.Element(el) else { fail("expected Element") }
  let mut has_role = false
  let mut has_checked = false
  for attr in el.attrs {
    if attr.0 == "role" {
      guard attr.1 is @luna.VStatic("checkbox") else { fail("wrong role") }
      has_role = true
    }
    if attr.0 == "aria-checked" {
      guard attr.1 is @luna.VStatic("true") else { fail("wrong checked") }
      has_checked = true
    }
  }
  inspect(has_role, content="true")
  inspect(has_checked, content="true")
}

///|
test "checkbox: unchecked state" {
  let node : @luna.Node[Unit] = checkbox(Unchecked, [@luna.text("Terms")])
  guard node is @luna.Element(el) else { fail("expected Element") }
  let mut checked_val = ""
  for attr in el.attrs {
    if attr.0 == "aria-checked" {
      guard attr.1 is @luna.VStatic(v) else { fail("expected VStatic") }
      checked_val = v
    }
  }
  inspect(checked_val, content="false")
}

///|
test "checkbox: mixed state (tri-state)" {
  let node : @luna.Node[Unit] = checkbox(Mixed, [@luna.text("All")])
  guard node is @luna.Element(el) else { fail("expected Element") }
  let mut checked_val = ""
  for attr in el.attrs {
    if attr.0 == "aria-checked" {
      guard attr.1 is @luna.VStatic(v) else { fail("expected VStatic") }
      checked_val = v
    }
  }
  inspect(checked_val, content="mixed")
}

///|
test "checkbox_native: creates input and label" {
  let node : @luna.Node[Unit] = checkbox_native("agree", true, [
    @luna.text("I agree"),
  ])
  guard node is @luna.Fragment(children) else { fail("expected Fragment") }
  inspect(children.length(), content="2")
}

///|
test "checkbox_group: role group" {
  let node : @luna.Node[Unit] = checkbox_group(aria_label="Options", [])
  guard node is @luna.Element(el) else { fail("expected Element") }
  guard el.attrs[0] is ("role", @luna.VStatic("group")) else {
    fail("expected role=group")
  }
}
