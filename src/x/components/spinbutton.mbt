///|
/// APG Spinbutton Pattern
/// https://www.w3.org/WAI/ARIA/apg/patterns/spinbutton/
///
/// A spinbutton is an input widget that restricts its value to a set
/// or range of discrete values. Unlike slider, it supports text input.
///
/// Keyboard Interaction:
/// - Up Arrow: Increase value by step
/// - Down Arrow: Decrease value by step
/// - Home: Set to minimum (if defined)
/// - End: Set to maximum (if defined)
/// - PageUp: Increase by large step
/// - PageDown: Decrease by large step
///
/// Note: Left/Right arrows are not used (reserved for text editing)
///
/// ARIA:
/// - role="spinbutton"
/// - aria-valuenow (required)
/// - aria-valuemin, aria-valuemax (when bounds exist)
/// - aria-valuetext (optional, for human-readable value)

///|
/// Create a basic spinbutton.
///
/// Parameters:
/// - value: Current numeric value
/// - min: Minimum value (optional)
/// - max: Maximum value (optional)
/// - step: Step increment (default: 1)
/// - aria_label: Accessible label
/// - aria_labelledby: ID of labelling element
/// - aria_valuetext: Human-readable value text
/// - disabled: Whether the spinbutton is disabled
/// - is_readonly: Whether the spinbutton is read-only
/// - on_keydown: Keydown handler
/// - on_input: Input handler for text changes
pub fn[E] spinbutton(
  value : Double,
  min? : Double,
  max? : Double,
  step? : Double,
  aria_label? : String,
  aria_labelledby? : String,
  aria_valuetext? : String,
  disabled? : Bool,
  is_readonly? : Bool,
  on_keydown? : @luna.EventHandler[E],
  on_input? : @luna.EventHandler[E],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("spinbutton")),
    ("tabindex", @luna.attr_static("0")),
    ("aria-valuenow", @luna.attr_static(value.to_string())),
    ("inputmode", @luna.attr_static("numeric")),
  ]
  if min is Some(m) {
    attrs.push(("aria-valuemin", @luna.attr_static(m.to_string())))
  }
  if max is Some(m) {
    attrs.push(("aria-valuemax", @luna.attr_static(m.to_string())))
  }
  if step is Some(s) {
    attrs.push(("data-step", @luna.attr_static(s.to_string())))
  }
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  if aria_labelledby is Some(id) {
    attrs.push(("aria-labelledby", @luna.attr_static(id)))
  }
  if aria_valuetext is Some(text) {
    attrs.push(("aria-valuetext", @luna.attr_static(text)))
  }
  if disabled is Some(true) {
    attrs.push(("aria-disabled", @luna.attr_static("true")))
  }
  if is_readonly is Some(true) {
    attrs.push(("aria-readonly", @luna.attr_static("true")))
  }
  if on_keydown is Some(handler) {
    attrs.push(("keydown", @luna.attr_handler(handler)))
  }
  if on_input is Some(handler) {
    attrs.push(("input", @luna.attr_handler(handler)))
  }
  // Using input element for text editing support
  @luna.h("input", attrs, [])
}

///|
/// Create a dynamic spinbutton with signal-based value.
pub fn[E] spinbutton_dyn(
  value : @resource.Signal[Double],
  min? : Double,
  max? : Double,
  aria_label? : String,
  aria_valuetext_fn? : (Double) -> String,
  on_keydown? : @luna.EventHandler[E],
  on_input? : @luna.EventHandler[E],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("spinbutton")),
    ("tabindex", @luna.attr_static("0")),
    ("aria-valuenow", @luna.attr_dynamic(fn() { value.get().to_string() })),
    ("inputmode", @luna.attr_static("numeric")),
    ("value", @luna.attr_dynamic(fn() { value.get().to_string() })),
  ]
  if min is Some(m) {
    attrs.push(("aria-valuemin", @luna.attr_static(m.to_string())))
  }
  if max is Some(m) {
    attrs.push(("aria-valuemax", @luna.attr_static(m.to_string())))
  }
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  if aria_valuetext_fn is Some(fn_) {
    attrs.push(
      ("aria-valuetext", @luna.attr_dynamic(fn() { fn_(value.get()) })),
    )
  }
  if on_keydown is Some(handler) {
    attrs.push(("keydown", @luna.attr_handler(handler)))
  }
  if on_input is Some(handler) {
    attrs.push(("input", @luna.attr_handler(handler)))
  }
  @luna.h("input", attrs, [])
}

///|
/// Create a spinbutton keyboard handler.
/// Handles Up/Down arrows, Home/End, PageUp/PageDown.
pub fn make_spinbutton_handler(
  current_value : () -> Double,
  min : Double?,
  max : Double?,
  step : Double,
  on_change : (Double) -> Unit,
  large_step? : Double,
) -> @luna.EventHandler[@js.Any] {
  let big_step = large_step.unwrap_or(step * 10.0)
  @luna.handler(fn(e : @js.Any) {
    let key : String = e._get("key").cast()
    let curr = current_value()
    let new_val : Double? = match key {
      "ArrowUp" => {
        let v = curr + step
        match max {
          Some(m) => Some(if v > m { m } else { v })
          None => Some(v)
        }
      }
      "ArrowDown" => {
        let v = curr - step
        match min {
          Some(m) => Some(if v < m { m } else { v })
          None => Some(v)
        }
      }
      "PageUp" => {
        let v = curr + big_step
        match max {
          Some(m) => Some(if v > m { m } else { v })
          None => Some(v)
        }
      }
      "PageDown" => {
        let v = curr - big_step
        match min {
          Some(m) => Some(if v < m { m } else { v })
          None => Some(v)
        }
      }
      "Home" =>
        match min {
          Some(m) => Some(m)
          None => None
        }
      "End" =>
        match max {
          Some(m) => Some(m)
          None => None
        }
      _ => None
    }
    if new_val is Some(v) {
      if v != curr {
        let _ = e._call("preventDefault", [])
        on_change(v)
      }
    }
  })
}

///|
/// Create a spinbutton input handler for text input.
/// Validates and clamps input to min/max bounds.
pub fn make_spinbutton_input_handler(
  min : Double?,
  max : Double?,
  on_change : (Double) -> Unit,
  fallback_value : () -> Double,
) -> @luna.EventHandler[@js.Any] {
  @luna.handler(fn(e : @js.Any) {
    let target = e._get("target")
    let input_str : String = target._get("value").cast()
    // Try to parse the input using JavaScript's parseFloat
    let v : Double = @js.global_this()
      ._call("parseFloat", [@js.any(input_str)])
      .cast()
    // Check if it's a valid number (not NaN)
    let is_nan : Bool = @js.global_this()._call("isNaN", [@js.any(v)]).cast()
    if is_nan {
      // Invalid input - restore previous value
      let prev = fallback_value()
      let _ = target._call("setAttribute", [
        @js.any("value"),
        @js.any(prev.to_string()),
      ])

    } else {
      // Clamp to bounds
      let clamped = match (min, max) {
        (Some(mi), Some(ma)) =>
          if v < mi {
            mi
          } else if v > ma {
            ma
          } else {
            v
          }
        (Some(mi), None) => if v < mi { mi } else { v }
        (None, Some(ma)) => if v > ma { ma } else { v }
        (None, None) => v
      }
      on_change(clamped)
    }
  })
}

///|
/// Create a complete interactive spinbutton with increment/decrement buttons.
///
/// Parameters:
/// - value: Signal containing the current value
/// - min: Minimum value
/// - max: Maximum value
/// - step: Step increment (default: 1)
/// - large_step: Large step for PageUp/PageDown (default: step * 10)
/// - aria_label: Accessible label
/// - aria_valuetext_fn: Function to convert value to human-readable text
pub fn spinbutton_interactive(
  value : @resource.Signal[Double],
  min? : Double,
  max? : Double,
  step? : Double,
  large_step? : Double,
  aria_label? : String,
  aria_valuetext_fn? : (Double) -> String,
) -> @luna.Node[@js.Any] {
  let step_val = step.unwrap_or(1.0)
  let clamp = fn(v : Double) -> Double {
    let v1 = match min {
      Some(m) => if v < m { m } else { v }
      None => v
    }
    match max {
      Some(m) => if v1 > m { m } else { v1 }
      None => v1
    }
  }
  let keydown_handler = make_spinbutton_handler(
    fn() { value.get() },
    min,
    max,
    step_val,
    fn(v) { value.set(v) },
    large_step?,
  )
  let input_handler = make_spinbutton_input_handler(
    min,
    max,
    fn(v) { value.set(v) },
    fn() { value.get() },
  )
  let decrement = fn() {
    let v = value.get() - step_val
    value.set(clamp(v))
  }
  let increment = fn() {
    let v = value.get() + step_val
    value.set(clamp(v))
  }
  // Build the input element
  let input_attrs : Array[(String, @luna.Attr[@js.Any])] = [
    ("type", @luna.attr_static("text")),
    ("role", @luna.attr_static("spinbutton")),
    ("inputmode", @luna.attr_static("numeric")),
    ("aria-valuenow", @luna.attr_dynamic(fn() { value.get().to_string() })),
    ("value", @luna.attr_dynamic(fn() { value.get().to_string() })),
    ("keydown", @luna.attr_handler(keydown_handler)),
    ("change", @luna.attr_handler(input_handler)),
  ]
  if min is Some(m) {
    input_attrs.push(("aria-valuemin", @luna.attr_static(m.to_string())))
  }
  if max is Some(m) {
    input_attrs.push(("aria-valuemax", @luna.attr_static(m.to_string())))
  }
  if aria_label is Some(label) {
    input_attrs.push(("aria-label", @luna.attr_static(label)))
  }
  if aria_valuetext_fn is Some(fn_) {
    input_attrs.push(
      ("aria-valuetext", @luna.attr_dynamic(fn() { fn_(value.get()) })),
    )
  }
  @luna.h("div", [("class", @luna.attr_static("spinbutton-container"))], [
    @luna.h(
      "button",
      [
        ("type", @luna.attr_static("button")),
        ("class", @luna.attr_static("spinbutton-decrement")),
        ("aria-label", @luna.attr_static("Decrease")),
        ("tabindex", @luna.attr_static("-1")),
        ("click", @luna.attr_handler(@luna.handler(fn(_) { decrement() }))),
      ],
      [@luna.text("-")],
    ),
    @luna.h("input", input_attrs, []),
    @luna.h(
      "button",
      [
        ("type", @luna.attr_static("button")),
        ("class", @luna.attr_static("spinbutton-increment")),
        ("aria-label", @luna.attr_static("Increase")),
        ("tabindex", @luna.attr_static("-1")),
        ("click", @luna.attr_handler(@luna.handler(fn(_) { increment() }))),
      ],
      [@luna.text("+")],
    ),
  ])
}

///|
/// Create a native HTML number input.
/// This is the simplest option when custom styling is not needed.
pub fn[E] spinbutton_native(
  name : String,
  value : Double,
  min? : Double,
  max? : Double,
  step? : Double,
  aria_label? : String,
  id? : String,
) -> @luna.Node[E] {
  let input_id = id.unwrap_or("spinbutton-" + name)
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("type", @luna.attr_static("number")),
    ("name", @luna.attr_static(name)),
    ("id", @luna.attr_static(input_id)),
    ("value", @luna.attr_static(value.to_string())),
  ]
  if min is Some(m) {
    attrs.push(("min", @luna.attr_static(m.to_string())))
  }
  if max is Some(m) {
    attrs.push(("max", @luna.attr_static(m.to_string())))
  }
  if step is Some(s) {
    attrs.push(("step", @luna.attr_static(s.to_string())))
  }
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  @luna.h("input", attrs, [])
}
