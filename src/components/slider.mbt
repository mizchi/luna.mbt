///|
/// APG Slider Pattern
/// https://www.w3.org/WAI/ARIA/apg/patterns/slider/
///
/// A slider is an input where the user selects a value from within a given range.
///
/// Keyboard Interaction:
/// - Right/Up Arrow: Increase by one step
/// - Left/Down Arrow: Decrease by one step
/// - Home: Set to minimum
/// - End: Set to maximum
/// - Page Up: Increase by large step (optional)
/// - Page Down: Decrease by large step (optional)
///
/// ARIA:
/// - role="slider"
/// - aria-valuenow, aria-valuemin, aria-valuemax
/// - aria-valuetext (optional, for human-readable value)
/// - aria-orientation (default: horizontal)

///|
/// Slider orientation
pub(all) enum SliderOrientation {
  Horizontal
  Vertical
}

///|
/// Create an accessible slider.
///
/// Parameters:
/// - value: Current value
/// - min: Minimum value (default: 0)
/// - max: Maximum value (default: 100)
/// - step: Step increment (optional, for data attribute)
/// - orientation: Slider orientation
/// - aria_label: Accessible label
/// - aria_labelledby: ID of labelling element
/// - aria_valuetext: Human-readable value
/// - on_keydown: Keydown handler (for arrow key value changes)
/// - children: Visual slider content
pub fn[E] slider(
  value : Double,
  min? : Double,
  max? : Double,
  step? : Double,
  orientation? : SliderOrientation,
  aria_label? : String,
  aria_labelledby? : String,
  aria_valuetext? : String,
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let min_val = min.unwrap_or(0.0)
  let max_val = max.unwrap_or(100.0)
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("slider")),
    ("tabindex", @luna.attr_static("0")),
    ("aria-valuenow", @luna.attr_static(value.to_string())),
    ("aria-valuemin", @luna.attr_static(min_val.to_string())),
    ("aria-valuemax", @luna.attr_static(max_val.to_string())),
  ]
  if step is Some(s) {
    attrs.push(("data-step", @luna.attr_static(s.to_string())))
  }
  if orientation is Some(Vertical) {
    attrs.push(("aria-orientation", @luna.attr_static("vertical")))
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
  if on_keydown is Some(handler) {
    attrs.push(("keydown", @luna.attr_handler(handler)))
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a dynamic slider with signal-based value.
pub fn[E] slider_dyn(
  value : @signal.Signal[Double],
  min? : Double,
  max? : Double,
  orientation? : SliderOrientation,
  aria_label? : String,
  aria_valuetext_fn? : (Double) -> String,
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let min_val = min.unwrap_or(0.0)
  let max_val = max.unwrap_or(100.0)
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("slider")),
    ("tabindex", @luna.attr_static("0")),
    ("aria-valuenow", @luna.attr_dynamic(fn() { value.get().to_string() })),
    ("aria-valuemin", @luna.attr_static(min_val.to_string())),
    ("aria-valuemax", @luna.attr_static(max_val.to_string())),
  ]
  if orientation is Some(Vertical) {
    attrs.push(("aria-orientation", @luna.attr_static("vertical")))
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
  @luna.h("div", attrs, children)
}

///|
/// Create a native HTML range input.
pub fn[E] slider_native(
  name : String,
  value : Double,
  min? : Double,
  max? : Double,
  step? : Double,
  aria_label? : String,
  id? : String,
) -> @luna.Node[E] {
  let min_val = min.unwrap_or(0.0)
  let max_val = max.unwrap_or(100.0)
  let input_id = id.unwrap_or("slider-" + name)
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("type", @luna.attr_static("range")),
    ("name", @luna.attr_static(name)),
    ("id", @luna.attr_static(input_id)),
    ("value", @luna.attr_static(value.to_string())),
    ("min", @luna.attr_static(min_val.to_string())),
    ("max", @luna.attr_static(max_val.to_string())),
  ]
  if step is Some(s) {
    attrs.push(("step", @luna.attr_static(s.to_string())))
  }
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  @luna.h("input", attrs, [])
}

///|
/// Create a slider with full keyboard and mouse support.
/// Includes arrow key navigation, Home/End for min/max, PageUp/PageDown for large steps.
/// Also supports click-to-position for mouse interaction.
///
/// Parameters:
/// - value: Signal containing the current value
/// - min: Minimum value (default: 0)
/// - max: Maximum value (default: 100)
/// - step: Step increment (default: 1)
/// - large_step: Large step for PageUp/PageDown (default: step * 10)
/// - orientation: Slider orientation
/// - aria_label: Accessible label
/// - aria_valuetext_fn: Function to convert value to human-readable text
/// - children: Visual slider content
pub fn slider_interactive(
  value : @signal.Signal[Double],
  min? : Double,
  max? : Double,
  step? : Double,
  large_step? : Double,
  orientation? : SliderOrientation,
  aria_label? : String,
  aria_valuetext_fn? : (Double) -> String,
  children : Array[@luna.Node[@js.Any]],
) -> @luna.Node[@js.Any] {
  let min_val = min.unwrap_or(0.0)
  let max_val = max.unwrap_or(100.0)
  let step_val = step.unwrap_or(1.0)
  let keydown_handler = make_slider_handler(
    fn() { value.get() },
    min_val,
    max_val,
    step_val,
    fn(v) { value.set(v) },
    large_step?,
  )
  let drag_handler = make_slider_drag_handler(min_val, max_val, step_val, fn(v) {
    value.set(v)
  })
  let attrs : Array[(String, @luna.Attr[@js.Any])] = [
    ("role", @luna.attr_static("slider")),
    ("tabindex", @luna.attr_static("0")),
    ("aria-valuenow", @luna.attr_dynamic(fn() { value.get().to_string() })),
    ("aria-valuemin", @luna.attr_static(min_val.to_string())),
    ("aria-valuemax", @luna.attr_static(max_val.to_string())),
    ("keydown", @luna.attr_handler(keydown_handler)),
    ("mousedown", @luna.attr_handler(drag_handler)),
    (
      "style",
      @luna.attr_dynamic(fn() {
        let v = value.get()
        let range = max_val - min_val
        let percent = if range > 0.0 { (v - min_val) / range * 100.0 } else { 0.0 }
        "--slider-percent:" + percent.to_string()
      }),
    ),
  ]
  if orientation is Some(Vertical) {
    attrs.push(("aria-orientation", @luna.attr_static("vertical")))
  }
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  if aria_valuetext_fn is Some(fn_) {
    attrs.push(
      ("aria-valuetext", @luna.attr_dynamic(fn() { fn_(value.get()) })),
    )
  }
  @luna.h("div", attrs, children)
}
