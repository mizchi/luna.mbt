///|
test "switch: on state" {
  let node : @luna.Node[Unit, String] = switch(true, [
    @luna.text("Notifications"),
  ])
  guard node is @core.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="button")
  let mut has_role = false
  let mut has_checked = false
  for attr in el.attrs {
    if attr.0 == "role" {
      guard attr.1 is @core.VStatic("switch") else { fail("wrong role") }
      has_role = true
    }
    if attr.0 == "aria-checked" {
      guard attr.1 is @core.VStatic("true") else { fail("wrong checked") }
      has_checked = true
    }
  }
  inspect(has_role, content="true")
  inspect(has_checked, content="true")
}

///|
test "switch: off state" {
  let node : @luna.Node[Unit, String] = switch(false, [@luna.text("Dark mode")])
  guard node is @core.Element(el) else { fail("expected Element") }
  let mut checked_val = ""
  for attr in el.attrs {
    if attr.0 == "aria-checked" {
      guard attr.1 is @core.VStatic(v) else { fail("expected VStatic") }
      checked_val = v
    }
  }
  inspect(checked_val, content="false")
}

///|
test "switch_dyn: dynamic state" {
  let on = @resource.signal(false)
  let node : @luna.Node[Unit, String] = switch_dyn(on, [@luna.text("Toggle")])
  guard node is @core.Element(el) else { fail("expected Element") }
  let mut dynamic_attr : (() -> String)? = None
  for attr in el.attrs {
    if attr.0 == "aria-checked" {
      guard attr.1 is @core.VDynamic(getter) else { fail("expected VDynamic") }
      dynamic_attr = Some(getter)
    }
  }
  guard dynamic_attr is Some(getter) else { fail("expected checked attr") }
  inspect(getter(), content="false")
  on.set(true)
  inspect(getter(), content="true")
}

///|
test "switch_native: creates checkbox with role=switch" {
  let node : @luna.Node[Unit, String] = switch_native("wifi", true, [
    @luna.text("WiFi"),
  ])
  guard node is @core.Fragment(children) else { fail("expected Fragment") }
  guard children[0] is @core.Element(input) else { fail("expected input") }
  let mut has_role = false
  for attr in input.attrs {
    if attr.0 == "role" {
      guard attr.1 is @core.VStatic("switch") else { fail("wrong role") }
      has_role = true
    }
  }
  inspect(has_role, content="true")
}
