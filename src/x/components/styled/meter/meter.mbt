///|
/// Styled Meter Component (Native HTML meter element)
///
/// Uses the native <meter> element with <label> for accessibility.
///
/// Class names (BEM):
/// - .meter           - Root container
/// - .meter__label    - Label element
/// - .meter__element  - The native meter element
/// - .meter__value    - Value text display

///|
/// Slots for the meter component
pub(all) struct MeterSlots {
  root : String
  label : String
  element : String
  value : String
}

///|
/// Default BEM class names for meter
pub fn meter_slots() -> MeterSlots {
  {
    root: "meter",
    label: "meter__label",
    element: "meter__element",
    value: "meter__value",
  }
}

///|
/// Create a styled meter component using native HTML meter element.
///
/// Parameters:
/// - id: Meter ID (used for label association)
/// - value: Current value
/// - min: Minimum value (default 0)
/// - max: Maximum value (default 100)
/// - low: Low threshold
/// - high: High threshold
/// - optimum: Optimal value
/// - label: Label text
/// - value_text: Value text displayed on the right
/// - class: Additional CSS class
pub fn meter(
  id : String,
  value : Double,
  min? : Double,
  max? : Double,
  low? : Double,
  high? : Double,
  optimum? : Double,
  label? : String,
  value_text? : String,
  class? : String,
) -> @luna.Node[@js.Any] {
  let slots = meter_slots()
  let min_val = min.unwrap_or(0.0)
  let max_val = max.unwrap_or(100.0)
  let root_class = match class {
    Some(c) => slots.root + " " + c
    None => slots.root
  }

  // Build children
  let children : Array[@luna.Node[@js.Any]] = []

  // Label
  match label {
    Some(l) =>
      children.push(
        @luna.h(
          "label",
          [
            ("for", @luna.attr_static(id)),
            ("class", @luna.attr_static(slots.label)),
          ],
          [@luna.text(l)],
        ),
      )
    None => ()
  }

  // Native meter element
  let meter_attrs : Array[(String, @luna.Attr[@js.Any])] = [
    ("id", @luna.attr_static(id)),
    ("class", @luna.attr_static(slots.element)),
    ("value", @luna.attr_static(value.to_string())),
    ("min", @luna.attr_static(min_val.to_string())),
    ("max", @luna.attr_static(max_val.to_string())),
  ]
  match low {
    Some(v) => meter_attrs.push(("low", @luna.attr_static(v.to_string())))
    None => ()
  }
  match high {
    Some(v) => meter_attrs.push(("high", @luna.attr_static(v.to_string())))
    None => ()
  }
  match optimum {
    Some(v) => meter_attrs.push(("optimum", @luna.attr_static(v.to_string())))
    None => ()
  }

  // Fallback text inside meter
  let fallback = match value_text {
    Some(vt) => vt
    None => value.to_string()
  }
  children.push(@luna.h("meter", meter_attrs, [@luna.text(fallback)]))

  // Value text
  match value_text {
    Some(vt) =>
      children.push(
        @luna.h("span", [("class", @luna.attr_static(slots.value))], [
          @luna.text(vt),
        ]),
      )
    None => ()
  }
  @luna.h("div", [("class", @luna.attr_static(root_class))], children)
}

///|
/// Get the CSS for the styled meter.
pub fn meter_css() -> String {
  let css =
    #|/* Meter - Default Theme */
    #|.meter {
    #|  display: flex;
    #|  align-items: center;
    #|  gap: 1rem;
    #|  padding: 0.75rem 0;
    #|}
    #|
    #|.meter__label {
    #|  flex-shrink: 0;
    #|  min-width: 7rem;
    #|  font-size: 0.875rem;
    #|  font-weight: 500;
    #|  color: var(--foreground);
    #|}
    #|
    #|.meter__element {
    #|  flex: 1;
    #|  height: 0.5rem;
    #|  appearance: none;
    #|  -webkit-appearance: none;
    #|  border: none;
    #|  border-radius: 9999px;
    #|  background: var(--muted);
    #|  overflow: hidden;
    #|}
    #|
    #|/* WebKit (Chrome, Safari) */
    #|.meter__element::-webkit-meter-bar {
    #|  background: var(--muted);
    #|  border-radius: 9999px;
    #|  border: none;
    #|}
    #|
    #|.meter__element::-webkit-meter-optimum-value {
    #|  background: var(--foreground);
    #|  border-radius: 9999px;
    #|}
    #|
    #|.meter__element::-webkit-meter-suboptimum-value {
    #|  background: var(--warning);
    #|  border-radius: 9999px;
    #|}
    #|
    #|.meter__element::-webkit-meter-even-less-good-value {
    #|  background: var(--destructive);
    #|  border-radius: 9999px;
    #|}
    #|
    #|/* Firefox */
    #|.meter__element::-moz-meter-bar {
    #|  background: var(--foreground);
    #|  border-radius: 9999px;
    #|}
    #|
    #|.meter__value {
    #|  flex-shrink: 0;
    #|  min-width: 4rem;
    #|  text-align: right;
    #|  font-size: 0.875rem;
    #|  color: var(--muted-foreground);
    #|}
  css
}
