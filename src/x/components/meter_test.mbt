///|
test "meter: basic attributes" {
  let node : @luna.Node[Unit] = meter(75.0, aria_label="Battery level", [])
  guard node is @core.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="div")
  let mut has_role = false
  let mut has_valuenow = false
  let mut has_valuemin = false
  let mut has_valuemax = false
  for attr in el.attrs {
    if attr.0 == "role" {
      guard attr.1 is @core.VStatic("meter") else {
        fail("expected role meter")
      }
      has_role = true
    }
    if attr.0 == "aria-valuenow" {
      guard attr.1 is @core.VStatic("75") else { fail("expected valuenow 75") }
      has_valuenow = true
    }
    if attr.0 == "aria-valuemin" {
      guard attr.1 is @core.VStatic("0") else { fail("expected valuemin 0") }
      has_valuemin = true
    }
    if attr.0 == "aria-valuemax" {
      guard attr.1 is @core.VStatic("100") else {
        fail("expected valuemax 100")
      }
      has_valuemax = true
    }
  }
  inspect(has_role, content="true")
  inspect(has_valuenow, content="true")
  inspect(has_valuemin, content="true")
  inspect(has_valuemax, content="true")
}

///|
test "meter: custom range" {
  let node : @luna.Node[Unit] = meter(
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
test "meter: with aria-valuetext" {
  let node : @luna.Node[Unit] = meter(
    50.0,
    aria_label="Battery",
    aria_valuetext="50% (6 hours) remaining",
    [],
  )
  guard node is @core.Element(el) else { fail("expected Element") }
  let mut has_valuetext = false
  for attr in el.attrs {
    if attr.0 == "aria-valuetext" {
      guard attr.1 is @core.VStatic("50% (6 hours) remaining") else {
        fail("expected valuetext")
      }
      has_valuetext = true
    }
  }
  inspect(has_valuetext, content="true")
}

///|
test "meter_dyn: dynamic value" {
  let value = @resource.signal(25.0)
  let node : @luna.Node[Unit] = meter_dyn(value, aria_label="Progress", [])
  guard node is @core.Element(el) else { fail("expected Element") }
  let mut dynamic_attr : (() -> String)? = None
  for attr in el.attrs {
    if attr.0 == "aria-valuenow" {
      guard attr.1 is @core.VDynamic(getter) else { fail("expected VDynamic") }
      dynamic_attr = Some(getter)
    }
  }
  guard dynamic_attr is Some(getter) else { fail("expected valuenow attr") }
  inspect(getter(), content="25")
  value.set(75.0)
  inspect(getter(), content="75")
}

///|
test "meter_native: native meter element" {
  let node : @luna.Node[Unit] = meter_native(75.0, aria_label="Disk usage", [])
  guard node is @core.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="meter")
  let mut has_value = false
  for attr in el.attrs {
    if attr.0 == "value" {
      guard attr.1 is @core.VStatic("75") else { fail("expected value 75") }
      has_value = true
    }
  }
  inspect(has_value, content="true")
}

///|
test "meter_native: with thresholds" {
  let node : @luna.Node[Unit] = meter_native(
    50.0,
    low=25.0,
    high=75.0,
    optimum=50.0,
    aria_label="Health",
    [],
  )
  guard node is @core.Element(el) else { fail("expected Element") }
  let mut has_low = false
  let mut has_high = false
  let mut has_optimum = false
  for attr in el.attrs {
    if attr.0 == "low" {
      has_low = true
    }
    if attr.0 == "high" {
      has_high = true
    }
    if attr.0 == "optimum" {
      has_optimum = true
    }
  }
  inspect(has_low, content="true")
  inspect(has_high, content="true")
  inspect(has_optimum, content="true")
}
