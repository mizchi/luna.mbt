///|
/// APG Meter Pattern
/// https://www.w3.org/WAI/ARIA/apg/patterns/meter/
///
/// A meter is a graphical display of a numeric value that varies within a defined range.
/// Examples: battery percentage, fuel level, disk usage
///
/// Note: Do NOT use meter for:
/// - Values without meaningful maximum (use other representations)
/// - Progress/loading indicators (use progressbar role instead)
///
/// ARIA Roles, States, and Properties:
/// - role="meter"
/// - aria-valuenow: Current value (required)
/// - aria-valuemin: Minimum value (required)
/// - aria-valuemax: Maximum value (required)
/// - aria-valuetext: Human-readable value description (optional)
/// - aria-label/aria-labelledby: Accessible name (required)

///|
/// Create an accessible meter element.
///
/// Parameters:
/// - value: Current value (aria-valuenow)
/// - min: Minimum value (aria-valuemin), default 0
/// - max: Maximum value (aria-valuemax), default 100
/// - aria_label: Accessible label (required if no aria_labelledby)
/// - aria_labelledby: ID of labelling element
/// - aria_valuetext: Human-readable value (e.g., "50% (6 hours) remaining")
/// - children: Visual representation of the meter
///
/// Example:
/// ```
/// meter(75.0, aria_label="Battery level", [])
/// meter(50.0, aria_valuetext="50% (6 hours) remaining", aria_label="Battery", [])
/// ```
pub fn[E] meter(
  value : Double,
  min? : Double,
  max? : Double,
  aria_label? : String,
  aria_labelledby? : String,
  aria_valuetext? : String,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let min_val = match min {
    Some(v) => v
    None => 0.0
  }
  let max_val = match max {
    Some(v) => v
    None => 100.0
  }
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("meter")),
    ("aria-valuenow", @luna.attr_static(value.to_string())),
    ("aria-valuemin", @luna.attr_static(min_val.to_string())),
    ("aria-valuemax", @luna.attr_static(max_val.to_string())),
  ]
  match aria_label {
    Some(label) => attrs.push(("aria-label", @luna.attr_static(label)))
    None => ()
  }
  match aria_labelledby {
    Some(id) => attrs.push(("aria-labelledby", @luna.attr_static(id)))
    None => ()
  }
  match aria_valuetext {
    Some(text) => attrs.push(("aria-valuetext", @luna.attr_static(text)))
    None => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a dynamic meter with signal-based value.
/// Automatically updates aria-valuenow when the signal changes.
///
/// Parameters:
/// - value: Signal containing current value
/// - min: Minimum value (default 0)
/// - max: Maximum value (default 100)
/// - aria_label: Accessible label
/// - aria_valuetext_fn: Function to generate aria-valuetext from current value
/// - children: Visual representation
pub fn[E] meter_dyn(
  value : @signal.Signal[Double],
  min? : Double,
  max? : Double,
  aria_label? : String,
  aria_valuetext_fn? : (Double) -> String,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let min_val = match min {
    Some(v) => v
    None => 0.0
  }
  let max_val = match max {
    Some(v) => v
    None => 100.0
  }
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("meter")),
    ("aria-valuenow", @luna.attr_dynamic(fn() { value.get().to_string() })),
    ("aria-valuemin", @luna.attr_static(min_val.to_string())),
    ("aria-valuemax", @luna.attr_static(max_val.to_string())),
  ]
  match aria_label {
    Some(label) => attrs.push(("aria-label", @luna.attr_static(label)))
    None => ()
  }
  match aria_valuetext_fn {
    Some(fn_) =>
      attrs.push(
        ("aria-valuetext", @luna.attr_dynamic(fn() { fn_(value.get()) })),
      )
    None => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a meter using the native HTML <meter> element.
/// Native meter has better browser support but limited styling options.
///
/// Parameters:
/// - value: Current value
/// - min: Minimum value (default 0)
/// - max: Maximum value (default 100)
/// - low: Low threshold (values below are considered low)
/// - high: High threshold (values above are considered high)
/// - optimum: Optimal value
/// - aria_label: Accessible label
/// - children: Fallback content for browsers without meter support
pub fn[E] meter_native(
  value : Double,
  min? : Double,
  max? : Double,
  low? : Double,
  high? : Double,
  optimum? : Double,
  aria_label? : String,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let min_val = match min {
    Some(v) => v
    None => 0.0
  }
  let max_val = match max {
    Some(v) => v
    None => 100.0
  }
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("value", @luna.attr_static(value.to_string())),
    ("min", @luna.attr_static(min_val.to_string())),
    ("max", @luna.attr_static(max_val.to_string())),
  ]
  match low {
    Some(v) => attrs.push(("low", @luna.attr_static(v.to_string())))
    None => ()
  }
  match high {
    Some(v) => attrs.push(("high", @luna.attr_static(v.to_string())))
    None => ()
  }
  match optimum {
    Some(v) => attrs.push(("optimum", @luna.attr_static(v.to_string())))
    None => ()
  }
  match aria_label {
    Some(label) => attrs.push(("aria-label", @luna.attr_static(label)))
    None => ()
  }
  @luna.h("meter", attrs, children)
}
