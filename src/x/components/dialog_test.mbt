///|
test "dialog: role and aria-modal" {
  let node : @luna.Node[Unit, String] = dialog(aria_label="Confirm", true, [
    @luna.text("Content"),
  ])
  guard node is @core.Element(el) else { fail("expected Element") }
  let mut has_role = false
  let mut has_modal = false
  for attr in el.attrs {
    if attr.0 == "role" {
      guard attr.1 is @core.VStatic("dialog") else { fail("wrong role") }
      has_role = true
    }
    if attr.0 == "aria-modal" {
      guard attr.1 is @core.VStatic("true") else { fail("wrong modal") }
      has_modal = true
    }
  }
  inspect(has_role, content="true")
  inspect(has_modal, content="true")
}

///|
test "dialog: hidden when closed" {
  let node : @luna.Node[Unit, String] = dialog(aria_label="Test", false, [])
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
test "dialog: aria-labelledby" {
  let node : @luna.Node[Unit, String] = dialog(
    aria_labelledby="title-id",
    true,
    [],
  )
  guard node is @core.Element(el) else { fail("expected Element") }
  let mut has_labelledby = false
  for attr in el.attrs {
    if attr.0 == "aria-labelledby" {
      guard attr.1 is @core.VStatic("title-id") else { fail("wrong id") }
      has_labelledby = true
    }
  }
  inspect(has_labelledby, content="true")
}

///|
test "dialog_native: uses dialog element" {
  let node : @luna.Node[Unit, String] = dialog_native(id="my-dialog", true, [
    @luna.text("Native"),
  ])
  guard node is @core.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="dialog")
}

///|
test "alert_dialog: role alertdialog" {
  let node : @luna.Node[Unit, String] = alert_dialog(
    aria_label="Warning",
    true,
    [],
  )
  guard node is @core.Element(el) else { fail("expected Element") }
  let mut has_role = false
  for attr in el.attrs {
    if attr.0 == "role" {
      guard attr.1 is @core.VStatic("alertdialog") else { fail("wrong role") }
      has_role = true
    }
  }
  inspect(has_role, content="true")
}

///|
test "modal: creates backdrop and dialog" {
  let node : @luna.Node[Unit, String] = modal(aria_label="Modal", true, [
    @luna.text("Body"),
  ])
  guard node is @core.Fragment(children) else { fail("expected Fragment") }
  inspect(children.length(), content="2")
  // First is backdrop
  guard children[0] is @core.Element(backdrop) else {
    fail("expected backdrop")
  }
  let mut is_backdrop = false
  for attr in backdrop.attrs {
    if attr.0 == "data-dialog-backdrop" {
      is_backdrop = true
    }
  }
  inspect(is_backdrop, content="true")
  // Second is dialog
  guard children[1] is @core.Element(dlg) else { fail("expected dialog") }
  let mut is_dialog = false
  for attr in dlg.attrs {
    if attr.0 == "role" {
      guard attr.1 is @core.VStatic("dialog") else { fail("wrong role") }
      is_dialog = true
    }
  }
  inspect(is_dialog, content="true")
}

///|
test "modal: empty when closed" {
  let node : @luna.Node[Unit, String] = modal(aria_label="Test", false, [])
  guard node is @core.Fragment(children) else { fail("expected Fragment") }
  inspect(children.length(), content="0")
}
