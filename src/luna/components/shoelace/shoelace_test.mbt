///|
/// Tests for Shoelace components
/// Verifies SSR output matches the JS implementation

///|
test "sl_button - basic" {
  let node = sl_button([@luna.text("Click me")])
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="sl-button")
  inspect(el.children.length(), content="1")
}

///|
test "sl_button - with variant" {
  let node : @luna.Node[Unit] = sl_button(variant=Primary, [])
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="sl-button")
  // Check variant attribute
  let has_variant = el.attrs.iter().any(fn(attr) {
    let (name, value) = attr
    name == "variant" && value is @luna.VStatic("primary")
  })
  inspect(has_variant, content="true")
}

///|
test "sl_button - with all options" {
  let node = sl_button(
    variant=Success,
    size=Large,
    disabled=true,
    loading=true,
    outline=true,
    pill=true,
    [@luna.text("Submit")],
  )
  guard node is @luna.Element(el) else { fail("expected Element") }

  // Check all attributes are present
  let attr_names : Array[String] = el.attrs.map(fn(attr) { attr.0 })
  inspect(attr_names.contains("variant"), content="true")
  inspect(attr_names.contains("size"), content="true")
  inspect(attr_names.contains("disabled"), content="true")
  inspect(attr_names.contains("loading"), content="true")
  inspect(attr_names.contains("outline"), content="true")
  inspect(attr_names.contains("pill"), content="true")
}

///|
test "sl_button - href renders as link" {
  let node : @luna.Node[Unit] = sl_button(href="https://example.com", target="_blank", [])
  guard node is @luna.Element(el) else { fail("expected Element") }

  let attr_names : Array[String] = el.attrs.map(fn(attr) { attr.0 })
  inspect(attr_names.contains("href"), content="true")
  inspect(attr_names.contains("target"), content="true")
}

///|
test "sl_input - basic" {
  let node = sl_input(label="Username", placeholder="Enter username")
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="sl-input")

  let attr_names : Array[String] = el.attrs.map(fn(attr) { attr.0 })
  inspect(attr_names.contains("type"), content="true")
  inspect(attr_names.contains("label"), content="true")
  inspect(attr_names.contains("placeholder"), content="true")
}

///|
test "sl_input - password with toggle" {
  let node = sl_input(type_=Password, password_toggle=true)
  guard node is @luna.Element(el) else { fail("expected Element") }

  let attr_names : Array[String] = el.attrs.map(fn(attr) { attr.0 })
  inspect(attr_names.contains("password-toggle"), content="true")

  // Check type is password
  let type_attr = el.attrs.iter().find_first(fn(attr) { attr.0 == "type" })
  guard type_attr is Some((_, @luna.VStatic(v))) else {
    fail("expected type attribute")
  }
  inspect(v, content="password")
}

///|
test "sl_input - with validation" {
  let node = sl_input(required=true, minlength=3, maxlength=20, pattern="[A-Za-z]+")
  guard node is @luna.Element(el) else { fail("expected Element") }

  let attr_names : Array[String] = el.attrs.map(fn(attr) { attr.0 })
  inspect(attr_names.contains("required"), content="true")
  inspect(attr_names.contains("minlength"), content="true")
  inspect(attr_names.contains("maxlength"), content="true")
  inspect(attr_names.contains("pattern"), content="true")
}

///|
test "sl_checkbox - basic" {
  let node = sl_checkbox([@luna.text("Accept terms")])
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="sl-checkbox")
  inspect(el.children.length(), content="1")
}

///|
test "sl_checkbox - checked" {
  let node : @luna.Node[Unit] = sl_checkbox(checked=true, [])
  guard node is @luna.Element(el) else { fail("expected Element") }

  let attr_names : Array[String] = el.attrs.map(fn(attr) { attr.0 })
  inspect(attr_names.contains("checked"), content="true")
}

///|
test "sl_checkbox - indeterminate" {
  let node : @luna.Node[Unit] = sl_checkbox(indeterminate=true, [])
  guard node is @luna.Element(el) else { fail("expected Element") }

  let attr_names : Array[String] = el.attrs.map(fn(attr) { attr.0 })
  inspect(attr_names.contains("indeterminate"), content="true")
}

///|
test "sl_switch - basic" {
  let node = sl_switch([@luna.text("Enable")])
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="sl-switch")
  inspect(el.children.length(), content="1")
}

///|
test "sl_switch - checked" {
  let node : @luna.Node[Unit] = sl_switch(checked=true, [])
  guard node is @luna.Element(el) else { fail("expected Element") }

  let attr_names : Array[String] = el.attrs.map(fn(attr) { attr.0 })
  inspect(attr_names.contains("checked"), content="true")
}

///|
test "sl_switch - with size" {
  let node : @luna.Node[Unit] = sl_switch(size=Small, [])
  guard node is @luna.Element(el) else { fail("expected Element") }

  let size_attr = el.attrs.iter().find_first(fn(attr) { attr.0 == "size" })
  guard size_attr is Some((_, @luna.VStatic(v))) else {
    fail("expected size attribute")
  }
  inspect(v, content="small")
}
