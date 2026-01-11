///|
test "radiogroup: role" {
  let node : @luna.Node[Unit] = radiogroup(aria_label="Options", [])
  guard node is @luna.Element(el) else { fail("expected Element") }
  guard el.attrs[0] is ("role", @luna.VStatic("radiogroup")) else {
    fail("expected role=radiogroup")
  }
}

///|
test "radio: checked state" {
  let node : @luna.Node[Unit] = radio(
    "option1",
    true,
    [@luna.text("Option 1")],
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  let mut has_checked = false
  let mut has_tabindex = false
  for attr in el.attrs {
    if attr.0 == "aria-checked" {
      guard attr.1 is @luna.VStatic("true") else { fail("wrong checked") }
      has_checked = true
    }
    if attr.0 == "tabindex" {
      guard attr.1 is @luna.VStatic("0") else { fail("wrong tabindex") }
      has_tabindex = true
    }
  }
  inspect(has_checked, content="true")
  inspect(has_tabindex, content="true")
}

///|
test "radio: unchecked state" {
  let node : @luna.Node[Unit] = radio(
    "option2",
    false,
    [@luna.text("Option 2")],
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  let mut checked_val = ""
  let mut tabindex_val = ""
  for attr in el.attrs {
    if attr.0 == "aria-checked" {
      guard attr.1 is @luna.VStatic(v) else { fail("expected VStatic") }
      checked_val = v
    }
    if attr.0 == "tabindex" {
      guard attr.1 is @luna.VStatic(v) else { fail("expected VStatic") }
      tabindex_val = v
    }
  }
  inspect(checked_val, content="false")
  inspect(tabindex_val, content="-1")
}

///|
test "radio_dyn: dynamic checked" {
  let selected = @signal.signal("opt1")
  let node : @luna.Node[Unit] = radio_dyn(
    "opt1",
    selected,
    [@luna.text("Opt 1")],
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  let mut dynamic_checked : (() -> String)? = None
  for attr in el.attrs {
    if attr.0 == "aria-checked" {
      guard attr.1 is @luna.VDynamic(getter) else { fail("expected VDynamic") }
      dynamic_checked = Some(getter)
    }
  }
  guard dynamic_checked is Some(getter) else { fail("expected checked attr") }
  inspect(getter(), content="true")
  selected.set("opt2")
  inspect(getter(), content="false")
}

///|
test "radio_group: builds structure" {
  let options : Array[RadioOption[Unit]] = [
    radio_option("a", [@luna.text("A")]),
    radio_option("b", [@luna.text("B")]),
  ]
  let node : @luna.Node[Unit] = radio_group(
    "choice",
    options,
    "a",
    aria_label="Choose",
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.children.length(), content="2")
}

///|
test "radio_native: creates input and label" {
  let node : @luna.Node[Unit] = radio_native(
    "color",
    "red",
    true,
    [@luna.text("Red")],
  )
  guard node is @luna.Fragment(children) else { fail("expected Fragment") }
  inspect(children.length(), content="2")
  guard children[0] is @luna.Element(input) && input.tag == "input" else {
    fail("expected input")
  }
  guard children[1] is @luna.Element(label) && label.tag == "label" else {
    fail("expected label")
  }
}
