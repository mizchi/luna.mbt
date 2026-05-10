///|
test "slider: role and value attributes" {
  let node : @luna.Node[Unit, String] = slider(50.0, aria_label="Volume", [])
  guard node is @core.Element(el) else { fail("expected Element") }
  let mut has_role = false
  let mut has_valuenow = false
  let mut has_valuemin = false
  let mut has_valuemax = false
  for attr in el.attrs {
    if attr.0 == "role" {
      guard attr.1 is @core.VStatic("slider") else { fail("wrong role") }
      has_role = true
    }
    if attr.0 == "aria-valuenow" {
      guard attr.1 is @core.VStatic("50") else { fail("wrong valuenow") }
      has_valuenow = true
    }
    if attr.0 == "aria-valuemin" {
      guard attr.1 is @core.VStatic("0") else { fail("wrong valuemin") }
      has_valuemin = true
    }
    if attr.0 == "aria-valuemax" {
      guard attr.1 is @core.VStatic("100") else { fail("wrong valuemax") }
      has_valuemax = true
    }
  }
  inspect(has_role, content="true")
  inspect(has_valuenow, content="true")
  inspect(has_valuemin, content="true")
  inspect(has_valuemax, content="true")
}

///|
test "slider: custom range" {
  let node : @luna.Node[Unit, String] = slider(
    5.0,
    min=0.0,
    max=10.0,
    aria_label="Rating",
    [],
  )
  guard node is @core.Element(el) else { fail("expected Element") }
  let mut min_val = ""
  let mut max_val = ""
  for attr in el.attrs {
    if attr.0 == "aria-valuemin" {
      guard attr.1 is @core.VStatic(v) else { fail("expected VStatic") }
      min_val = v
    }
    if attr.0 == "aria-valuemax" {
      guard attr.1 is @core.VStatic(v) else { fail("expected VStatic") }
      max_val = v
    }
  }
  inspect(min_val, content="0")
  inspect(max_val, content="10")
}

///|
test "slider: vertical orientation" {
  let node : @luna.Node[Unit, String] = slider(
    50.0,
    orientation=Vertical,
    aria_label="Height",
    [],
  )
  guard node is @core.Element(el) else { fail("expected Element") }
  let mut has_orientation = false
  for attr in el.attrs {
    if attr.0 == "aria-orientation" {
      guard attr.1 is @core.VStatic("vertical") else { fail("wrong orient") }
      has_orientation = true
    }
  }
  inspect(has_orientation, content="true")
}

///|
test "slider_native: creates range input" {
  let node : @luna.Node[Unit, String] = slider_native(
    "volume",
    50.0,
    aria_label="Volume",
  )
  guard node is @core.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="input")
  let mut has_type = false
  for attr in el.attrs {
    if attr.0 == "type" {
      guard attr.1 is @core.VStatic("range") else { fail("wrong type") }
      has_type = true
    }
  }
  inspect(has_type, content="true")
}
