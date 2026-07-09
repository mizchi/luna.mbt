///|
test "popover: uses native popover attribute" {
  let node : @luna.Node[Unit, String] = popover("menu-popover", [
    @luna.text("Menu"),
  ])
  guard node is @core.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="div")
  let mut has_id = false
  let mut has_popover = false
  for attr in el.attrs {
    if attr.0 == "id" {
      guard attr.1 is @core.VStatic("menu-popover") else { fail("wrong id") }
      has_id = true
    }
    if attr.0 == "popover" {
      guard attr.1 is @core.VStatic("auto") else { fail("wrong popover mode") }
      has_popover = true
    }
  }
  inspect(has_id, content="true")
  inspect(has_popover, content="true")
}

///|
test "popover: supports manual mode and dialog role" {
  let node : @luna.Node[Unit, String] = popover(
    "confirm-popover",
    mode=Manual,
    role="dialog",
    aria_labelledby="confirm-title",
    [],
  )
  guard node is @core.Element(el) else { fail("expected Element") }
  let mut has_manual = false
  let mut has_role = false
  let mut has_labelledby = false
  for attr in el.attrs {
    if attr.0 == "popover" {
      guard attr.1 is @core.VStatic("manual") else {
        fail("wrong popover mode")
      }
      has_manual = true
    }
    if attr.0 == "role" {
      guard attr.1 is @core.VStatic("dialog") else { fail("wrong role") }
      has_role = true
    }
    if attr.0 == "aria-labelledby" {
      guard attr.1 is @core.VStatic("confirm-title") else {
        fail("wrong labelledby")
      }
      has_labelledby = true
    }
  }
  inspect(has_manual, content="true")
  inspect(has_role, content="true")
  inspect(has_labelledby, content="true")
}

///|
test "popover_trigger: targets popover without client runtime" {
  let node : @luna.Node[Unit, String] = popover_trigger(
    "menu-popover",
    action=Toggle,
    [@luna.text("Open menu")],
  )
  guard node is @core.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="button")
  let mut has_type = false
  let mut has_target = false
  let mut has_action = false
  for attr in el.attrs {
    if attr.0 == "type" {
      guard attr.1 is @core.VStatic("button") else { fail("wrong type") }
      has_type = true
    }
    if attr.0 == "popovertarget" {
      guard attr.1 is @core.VStatic("menu-popover") else {
        fail("wrong target")
      }
      has_target = true
    }
    if attr.0 == "popovertargetaction" {
      guard attr.1 is @core.VStatic("toggle") else {
        fail("wrong target action")
      }
      has_action = true
    }
  }
  inspect(has_type, content="true")
  inspect(has_target, content="true")
  inspect(has_action, content="true")
}
