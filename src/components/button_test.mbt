///|
test "button: basic attributes" {
  let node : @luna.Node[Unit] = button([@luna.text("Click me")])
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="button")
  guard el.attrs[0] is ("type", @luna.VStatic("button")) else {
    fail("expected type=button")
  }
}

///|
test "button: submit type" {
  let node : @luna.Node[Unit] = button(type_=Submit, [@luna.text("Submit")])
  guard node is @luna.Element(el) else { fail("expected Element") }
  guard el.attrs[0] is ("type", @luna.VStatic("submit")) else {
    fail("expected type=submit")
  }
}

///|
test "button: disabled state" {
  let node : @luna.Node[Unit] = button(
    disabled=true,
    [@luna.text("Disabled")],
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  let mut has_disabled = false
  let mut has_aria_disabled = false
  for attr in el.attrs {
    if attr.0 == "disabled" {
      has_disabled = true
    }
    if attr.0 == "aria-disabled" {
      guard attr.1 is @luna.VStatic("true") else {
        fail("expected aria-disabled true")
      }
      has_aria_disabled = true
    }
  }
  inspect(has_disabled, content="true")
  inspect(has_aria_disabled, content="true")
}

///|
test "button: aria-label for icon button" {
  let node : @luna.Node[Unit] = button(
    aria_label="Close dialog",
    [@luna.text("×")],
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  let mut has_aria_label = false
  for attr in el.attrs {
    if attr.0 == "aria-label" {
      guard attr.1 is @luna.VStatic("Close dialog") else {
        fail("expected aria-label value")
      }
      has_aria_label = true
    }
  }
  inspect(has_aria_label, content="true")
}

///|
test "toggle_button: pressed state" {
  let node : @luna.Node[Unit] = toggle_button(
    Pressed,
    [@luna.text("Mute")],
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  let mut has_aria_pressed = false
  for attr in el.attrs {
    if attr.0 == "aria-pressed" {
      guard attr.1 is @luna.VStatic("true") else {
        fail("expected aria-pressed true")
      }
      has_aria_pressed = true
    }
  }
  inspect(has_aria_pressed, content="true")
}

///|
test "toggle_button: not pressed state" {
  let node : @luna.Node[Unit] = toggle_button(
    NotPressed,
    [@luna.text("Mute")],
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  let mut has_aria_pressed = false
  for attr in el.attrs {
    if attr.0 == "aria-pressed" {
      guard attr.1 is @luna.VStatic("false") else {
        fail("expected aria-pressed false")
      }
      has_aria_pressed = true
    }
  }
  inspect(has_aria_pressed, content="true")
}

///|
test "toggle_button_dyn: dynamic pressed state" {
  let pressed = @signal.signal(false)
  let node : @luna.Node[Unit] = toggle_button_dyn(
    pressed,
    [@luna.text("Bold")],
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  let mut dynamic_attr : (() -> String)? = None
  for attr in el.attrs {
    if attr.0 == "aria-pressed" {
      guard attr.1 is @luna.VDynamic(getter) else { fail("expected VDynamic") }
      dynamic_attr = Some(getter)
    }
  }
  guard dynamic_attr is Some(getter) else {
    fail("expected aria-pressed attribute")
  }
  inspect(getter(), content="false")
  pressed.set(true)
  inspect(getter(), content="true")
}

///|
test "menu_button: popup attributes" {
  let node : @luna.Node[Unit] = menu_button(
    Menu,
    false,
    controls="dropdown",
    [@luna.text("Options")],
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  let mut has_haspopup = false
  let mut has_expanded = false
  let mut has_controls = false
  for attr in el.attrs {
    if attr.0 == "aria-haspopup" {
      guard attr.1 is @luna.VStatic("menu") else {
        fail("expected aria-haspopup menu")
      }
      has_haspopup = true
    }
    if attr.0 == "aria-expanded" {
      guard attr.1 is @luna.VStatic("false") else {
        fail("expected aria-expanded false")
      }
      has_expanded = true
    }
    if attr.0 == "aria-controls" {
      guard attr.1 is @luna.VStatic("dropdown") else {
        fail("expected aria-controls dropdown")
      }
      has_controls = true
    }
  }
  inspect(has_haspopup, content="true")
  inspect(has_expanded, content="true")
  inspect(has_controls, content="true")
}

///|
test "menu_button_dyn: dynamic expanded state" {
  let expanded = @signal.signal(false)
  let node : @luna.Node[Unit] = menu_button_dyn(
    Dialog,
    expanded,
    [@luna.text("Open")],
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  let mut dynamic_attr : (() -> String)? = None
  for attr in el.attrs {
    if attr.0 == "aria-expanded" {
      guard attr.1 is @luna.VDynamic(getter) else { fail("expected VDynamic") }
      dynamic_attr = Some(getter)
    }
  }
  guard dynamic_attr is Some(getter) else {
    fail("expected aria-expanded attribute")
  }
  inspect(getter(), content="false")
  expanded.set(true)
  inspect(getter(), content="true")
}
