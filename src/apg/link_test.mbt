///|
test "link: basic attributes" {
  let node : @luna.Node[Unit] = @apg.link(
    "https://example.com",
    [@luna.text("Example")],
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="a")
  guard el.attrs[0] is ("href", @luna.VStatic("https://example.com")) else {
    fail("expected href attribute")
  }
}

///|
test "link: with target blank" {
  let node : @luna.Node[Unit] = @apg.link(
    "/page",
    target=Blank,
    [@luna.text("New Tab")],
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  let mut has_target = false
  for attr in el.attrs {
    if attr.0 == "target" {
      guard attr.1 is @luna.VStatic("_blank") else {
        fail("expected _blank target")
      }
      has_target = true
    }
  }
  inspect(has_target, content="true")
}

///|
test "link: with aria-label for icon-only" {
  let node : @luna.Node[Unit] = @apg.link(
    "/home",
    aria_label="Go to home page",
    [@luna.text("🏠")],
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  let mut has_aria_label = false
  for attr in el.attrs {
    if attr.0 == "aria-label" {
      guard attr.1 is @luna.VStatic("Go to home page") else {
        fail("expected aria-label value")
      }
      has_aria_label = true
    }
  }
  inspect(has_aria_label, content="true")
}

///|
test "link: disabled state" {
  let node : @luna.Node[Unit] = @apg.link(
    "/action",
    disabled=true,
    [@luna.text("Disabled")],
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  let mut has_aria_disabled = false
  let mut has_tabindex = false
  for attr in el.attrs {
    if attr.0 == "aria-disabled" {
      guard attr.1 is @luna.VStatic("true") else {
        fail("expected aria-disabled true")
      }
      has_aria_disabled = true
    }
    if attr.0 == "tabindex" {
      guard attr.1 is @luna.VStatic("-1") else { fail("expected tabindex -1") }
      has_tabindex = true
    }
  }
  inspect(has_aria_disabled, content="true")
  inspect(has_tabindex, content="true")
}

///|
test "link_button: role and tabindex" {
  let handler = @luna.handler(fn(_x : Unit) { () })
  let node : @luna.Node[Unit] = @apg.link_button(
    handler,
    [@luna.text("Click")],
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="span")
  let mut has_role = false
  let mut has_tabindex = false
  for attr in el.attrs {
    if attr.0 == "role" {
      guard attr.1 is @luna.VStatic("link") else { fail("expected role link") }
      has_role = true
    }
    if attr.0 == "tabindex" {
      guard attr.1 is @luna.VStatic("0") else { fail("expected tabindex 0") }
      has_tabindex = true
    }
  }
  inspect(has_role, content="true")
  inspect(has_tabindex, content="true")
}
