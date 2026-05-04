///|
test "disclosure_button: expanded state" {
  let node : @luna.Node[Unit, String] = disclosure_button(true, "content-1", [
    @luna.text("Show more"),
  ])
  guard node is @core.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="button")
  let mut has_expanded = false
  let mut has_controls = false
  for attr in el.attrs {
    if attr.0 == "aria-expanded" {
      guard attr.1 is @core.VStatic("true") else { fail("wrong expanded") }
      has_expanded = true
    }
    if attr.0 == "aria-controls" {
      guard attr.1 is @core.VStatic("content-1") else { fail("wrong controls") }
      has_controls = true
    }
  }
  inspect(has_expanded, content="true")
  inspect(has_controls, content="true")
}

///|
test "disclosure_button: collapsed state" {
  let node : @luna.Node[Unit, String] = disclosure_button(false, "content-2", [
    @luna.text("Show"),
  ])
  guard node is @core.Element(el) else { fail("expected Element") }
  let mut expanded_val = ""
  for attr in el.attrs {
    if attr.0 == "aria-expanded" {
      guard attr.1 is @core.VStatic(v) else { fail("expected VStatic") }
      expanded_val = v
    }
  }
  inspect(expanded_val, content="false")
}

///|
test "disclosure_content: hidden when collapsed" {
  let node : @luna.Node[Unit, String] = disclosure_content("panel", true, [
    @luna.text("Hidden content"),
  ])
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
test "disclosure: creates complete structure" {
  let node : @luna.Node[Unit, String] = disclosure(
    "faq-1",
    true,
    [@luna.text("Question?")],
    [@luna.text("Answer.")],
  )
  guard node is @core.Fragment(children) else { fail("expected Fragment") }
  inspect(children.length(), content="2")
}

///|
test "disclosure_button_dyn: dynamic expanded" {
  let expanded = @resource.signal(false)
  let node : @luna.Node[Unit, String] = disclosure_button_dyn(
    expanded,
    "panel",
    [@luna.text("Toggle")],
  )
  guard node is @core.Element(el) else { fail("expected Element") }
  let mut dynamic_attr : (() -> String)? = None
  for attr in el.attrs {
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
