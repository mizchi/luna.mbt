///|
/// Styled Spinbutton Component (APG Pattern)
///
/// Based on APG: https://www.w3.org/WAI/ARIA/apg/patterns/spinbutton/
///
/// Class names:
/// - .spinbutton           - Root wrapper
/// - .spinbutton__label    - Optional label
/// - .spinbutton__controls - Button + input container
/// - .spinbutton__button   - Increment/decrement buttons
/// - .spinbutton__input    - Value input field
///
/// States via data attributes:
/// - [data-disabled] on .spinbutton when disabled

///|
pub(all) struct SpinbuttonSlots {
  root : String
  label : String
  controls : String
  button : String
  decrement : String
  increment : String
  input : String
}

///|
pub fn spinbutton_slots() -> SpinbuttonSlots {
  {
    root: "spinbutton",
    label: "spinbutton__label",
    controls: "spinbutton__controls",
    button: "spinbutton__button",
    decrement: "spinbutton__decrement",
    increment: "spinbutton__increment",
    input: "spinbutton__input",
  }
}

///|
/// Create a styled spinbutton with signal-based value.
pub fn spinbutton(
  value : @resource.Signal[Double],
  min? : Double,
  max? : Double,
  step? : Double = 1.0,
  large_step? : Double,
  disabled? : Bool = false,
  aria_label? : String,
  aria_valuetext_fn? : (Double) -> String,
  label? : String,
  class? : String,
) -> @luna.Node[@js.Any] {
  let slots = spinbutton_slots()
  let big_step = large_step.unwrap_or(step * 10.0)
  let root_class = match class {
    Some(c) => slots.root + " " + c
    None => slots.root
  }
  let root_attrs : Array[(String, @luna.Attr[@js.Any])] = [
    ("class", @luna.attr_static(root_class)),
  ]
  if disabled {
    root_attrs.push(("data-disabled", @luna.attr_static("")))
  }

  // Clamp function
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

  // Handlers
  let decrement = fn() {
    if not(disabled) {
      let v = value.get() - step
      value.set(clamp(v))
    }
  }
  let increment = fn() {
    if not(disabled) {
      let v = value.get() + step
      value.set(clamp(v))
    }
  }

  // Keydown handler
  let keydown_handler = @luna.handler(fn(e : @js.Any) {
    if disabled {
      return
    }
    let key : String = e._get("key").cast()
    let curr = value.get()
    let new_val : Double? = match key {
      "ArrowUp" => Some(clamp(curr + step))
      "ArrowDown" => Some(clamp(curr - step))
      "PageUp" => Some(clamp(curr + big_step))
      "PageDown" => Some(clamp(curr - big_step))
      "Home" => min
      "End" => max
      _ => None
    }
    if new_val is Some(v) {
      if v != curr {
        let _ = e._call("preventDefault", [])
        value.set(v)
      }
    }
  })

  // Input change handler
  let change_handler = @luna.handler(fn(e : @js.Any) {
    if disabled {
      return
    }
    let target = e._get("target")
    let input_str : String = target._get("value").cast()
    let v : Double = @js.global_this()
      ._call("parseFloat", [@js.any(input_str)])
      .cast()
    let is_nan : Bool = @js.global_this()._call("isNaN", [@js.any(v)]).cast()
    if not(is_nan) {
      value.set(clamp(v))
    }
  })

  // Input element
  let input_attrs : Array[(String, @luna.Attr[@js.Any])] = [
    ("type", @luna.attr_static("text")),
    ("role", @luna.attr_static("spinbutton")),
    ("inputmode", @luna.attr_static("numeric")),
    ("class", @luna.attr_static(slots.input)),
    ("aria-valuenow", @luna.attr_dynamic(fn() { value.get().to_string() })),
    ("value", @luna.attr_dynamic(fn() { value.get().to_string() })),
    ("keydown", @luna.attr_handler(keydown_handler)),
    ("change", @luna.attr_handler(change_handler)),
  ]
  if min is Some(m) {
    input_attrs.push(("aria-valuemin", @luna.attr_static(m.to_string())))
  }
  if max is Some(m) {
    input_attrs.push(("aria-valuemax", @luna.attr_static(m.to_string())))
  }
  if aria_label is Some(l) {
    input_attrs.push(("aria-label", @luna.attr_static(l)))
  }
  if aria_valuetext_fn is Some(fn_) {
    input_attrs.push(
      ("aria-valuetext", @luna.attr_dynamic(fn() { fn_(value.get()) })),
    )
  }
  if disabled {
    input_attrs.push(("disabled", @luna.attr_static("")))
  }

  // Buttons
  let dec_attrs : Array[(String, @luna.Attr[@js.Any])] = [
    ("type", @luna.attr_static("button")),
    ("class", @luna.attr_static(slots.button + " " + slots.decrement)),
    ("aria-label", @luna.attr_static("Decrease")),
    ("tabindex", @luna.attr_static("-1")),
    ("click", @luna.attr_handler(@luna.handler(fn(_) { decrement() }))),
  ]
  if disabled {
    dec_attrs.push(("disabled", @luna.attr_static("")))
  }
  let dec_btn = @luna.h("button", dec_attrs, [@luna.text("-")])
  let inc_attrs : Array[(String, @luna.Attr[@js.Any])] = [
    ("type", @luna.attr_static("button")),
    ("class", @luna.attr_static(slots.button + " " + slots.increment)),
    ("aria-label", @luna.attr_static("Increase")),
    ("tabindex", @luna.attr_static("-1")),
    ("click", @luna.attr_handler(@luna.handler(fn(_) { increment() }))),
  ]
  if disabled {
    inc_attrs.push(("disabled", @luna.attr_static("")))
  }
  let inc_btn = @luna.h("button", inc_attrs, [@luna.text("+")])

  // Controls wrapper
  let controls = @luna.h(
    "div",
    [("class", @luna.attr_static(slots.controls))],
    [dec_btn, @luna.h("input", input_attrs, []), inc_btn],
  )

  // Build root
  let children : Array[@luna.Node[@js.Any]] = []
  if label is Some(l) {
    children.push(
      @luna.h("label", [("class", @luna.attr_static(slots.label))], [
        @luna.text(l),
      ]),
    )
  }
  children.push(controls)
  @luna.h("div", root_attrs, children)
}

///|
/// Get the CSS for the spinbutton component.
pub fn spinbutton_css() -> String {
  let css =
    #|/* Spinbutton - APG Pattern */
    #|.spinbutton {
    #|  display: inline-flex;
    #|  flex-direction: column;
    #|  gap: 0.5rem;
    #|}
    #|
    #|/* Label */
    #|.spinbutton__label {
    #|  font-weight: 500;
    #|  font-size: 0.875rem;
    #|  color: var(--foreground);
    #|}
    #|
    #|/* Controls container */
    #|.spinbutton__controls {
    #|  display: inline-flex;
    #|  align-items: stretch;
    #|  border: 1px solid var(--border);
    #|  border-radius: 0.375rem;
    #|  overflow: hidden;
    #|  background: var(--background);
    #|}
    #|
    #|/* Focus ring on controls when input focused */
    #|.spinbutton__controls:has(.spinbutton__input:focus-visible) {
    #|  outline: 2px solid var(--accent);
    #|  outline-offset: 2px;
    #|}
    #|
    #|/* Input field */
    #|.spinbutton__input {
    #|  width: 4rem;
    #|  padding: 0.5rem 0.75rem;
    #|  font-size: 0.875rem;
    #|  font-variant-numeric: tabular-nums;
    #|  text-align: center;
    #|  color: var(--foreground);
    #|  background: transparent;
    #|  border: none;
    #|  outline: none;
    #|}
    #|
    #|.spinbutton__input::placeholder {
    #|  color: var(--muted-foreground);
    #|}
    #|
    #|/* Buttons */
    #|.spinbutton__button {
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  width: 2rem;
    #|  padding: 0;
    #|  font-size: 1rem;
    #|  font-weight: 500;
    #|  color: var(--foreground);
    #|  background: var(--muted);
    #|  border: none;
    #|  cursor: pointer;
    #|  transition: background-color 0.15s ease-out, color 0.15s ease-out;
    #|}
    #|
    #|.spinbutton__button:hover:not(:disabled) {
    #|  background: var(--border);
    #|}
    #|
    #|.spinbutton__button:active:not(:disabled) {
    #|  background: var(--muted-foreground);
    #|}
    #|
    #|/* Button borders */
    #|.spinbutton__decrement {
    #|  border-right: 1px solid var(--border);
    #|}
    #|
    #|.spinbutton__increment {
    #|  border-left: 1px solid var(--border);
    #|}
    #|
    #|/* Disabled state */
    #|.spinbutton[data-disabled] {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
    #|
    #|.spinbutton[data-disabled] .spinbutton__input {
    #|  cursor: not-allowed;
    #|}
    #|
    #|.spinbutton[data-disabled] .spinbutton__button {
    #|  cursor: not-allowed;
    #|  pointer-events: none;
    #|}
    #|
    #|/* Reduced motion */
    #|@media (prefers-reduced-motion: reduce) {
    #|  .spinbutton__button {
    #|    transition: none;
    #|  }
    #|}
  css
}
