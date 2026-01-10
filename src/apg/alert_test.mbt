///|
test "alert: basic role" {
  let node : @luna.Node[Unit] = @apg.alert([@luna.text("Message")])
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="div")
  guard el.attrs[0] is ("role", @luna.VStatic("alert")) else {
    fail("expected role=alert")
  }
}

///|
test "alert: with type" {
  let node : @luna.Node[Unit] = @apg.alert(
    type_=Error,
    [@luna.text("Error!")],
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  let mut has_type = false
  for attr in el.attrs {
    if attr.0 == "data-type" {
      guard attr.1 is @luna.VStatic("error") else { fail("wrong type") }
      has_type = true
    }
  }
  inspect(has_type, content="true")
}

///|
test "alert_live: aria-live and atomic" {
  let node : @luna.Node[Unit] = @apg.alert_live([@luna.text("Update")])
  guard node is @luna.Element(el) else { fail("expected Element") }
  let mut has_live = false
  let mut has_atomic = false
  for attr in el.attrs {
    if attr.0 == "aria-live" {
      guard attr.1 is @luna.VStatic("assertive") else { fail("wrong live") }
      has_live = true
    }
    if attr.0 == "aria-atomic" {
      guard attr.1 is @luna.VStatic("true") else { fail("wrong atomic") }
      has_atomic = true
    }
  }
  inspect(has_live, content="true")
  inspect(has_atomic, content="true")
}

///|
test "status: role status" {
  let node : @luna.Node[Unit] = @apg.status([@luna.text("Status")])
  guard node is @luna.Element(el) else { fail("expected Element") }
  guard el.attrs[0] is ("role", @luna.VStatic("status")) else {
    fail("expected role=status")
  }
}
