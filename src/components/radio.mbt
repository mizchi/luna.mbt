///|
/// APG Radio Group Pattern
/// https://www.w3.org/WAI/ARIA/apg/patterns/radio/
///
/// A radio group is a set of checkable buttons where only one can be checked at a time.
///
/// Keyboard Interaction:
/// - Tab/Shift+Tab: Move focus into/out of the group
/// - Space: Check focused radio button
/// - Right/Down Arrow: Move to next radio, check it
/// - Left/Up Arrow: Move to previous radio, check it
///
/// ARIA:
/// - radiogroup: Container role
/// - radio: Each button with aria-checked

///|
/// Radio option data
pub(all) struct RadioOption[E] {
  value : String // Option value
  label : Array[@luna.Node[E]] // Label content
  disabled : Bool // Whether disabled
}

///|
/// Create a radio option
pub fn[E] radio_option(
  value : String,
  label : Array[@luna.Node[E]],
  disabled? : Bool,
) -> RadioOption[E] {
  { value, label, disabled: disabled.unwrap_or(false) }
}

///|
/// Create a radio group container.
///
/// Parameters:
/// - aria_label: Accessible label for the group
/// - aria_labelledby: ID of labelling element
/// - children: Radio buttons (use `radio()` to create)
pub fn[E] radiogroup(
  aria_label? : String,
  aria_labelledby? : String,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("radiogroup")),
  ]
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  if aria_labelledby is Some(id) {
    attrs.push(("aria-labelledby", @luna.attr_static(id)))
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a single radio button.
///
/// Parameters:
/// - value: Radio value
/// - checked: Whether this radio is checked
/// - disabled: Whether this radio is disabled
/// - on_click: Click handler
/// - on_keydown: Keydown handler (for arrow key navigation)
/// - children: Radio label content
pub fn[E] radio(
  value : String,
  checked : Bool,
  disabled? : Bool,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("radio")),
    ("aria-checked", @luna.attr_static(if checked { "true" } else { "false" })),
    ("tabindex", @luna.attr_static(if checked { "0" } else { "-1" })),
    ("data-value", @luna.attr_static(value)),
  ]
  if disabled is Some(true) {
    attrs.push(("aria-disabled", @luna.attr_static("true")))
  }
  if on_click is Some(handler) {
    attrs.push(("click", @luna.attr_handler(handler)))
  }
  if on_keydown is Some(handler) {
    attrs.push(("keydown", @luna.attr_handler(handler)))
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a dynamic radio with signal-based checked state.
pub fn[E] radio_dyn(
  value : String,
  selected_value : @signal.Signal[String],
  disabled? : Bool,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("radio")),
    (
      "aria-checked",
      @luna.attr_dynamic(fn() {
        if selected_value.get() == value {
          "true"
        } else {
          "false"
        }
      }),
    ),
    (
      "tabindex",
      @luna.attr_dynamic(fn() {
        if selected_value.get() == value {
          "0"
        } else {
          "-1"
        }
      }),
    ),
    ("data-value", @luna.attr_static(value)),
  ]
  if disabled is Some(true) {
    attrs.push(("aria-disabled", @luna.attr_static("true")))
  }
  if on_click is Some(handler) {
    attrs.push(("click", @luna.attr_handler(handler)))
  }
  if on_keydown is Some(handler) {
    attrs.push(("keydown", @luna.attr_handler(handler)))
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a radio with computed checked state (accepts getter function).
/// Useful for derived radio states.
pub fn[E] radio_computed(
  value : String,
  checked : () -> Bool,
  disabled? : Bool,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("radio")),
    ("aria-checked", @luna.attr_dynamic(fn() { bool_to_aria(checked()) })),
    (
      "tabindex",
      @luna.attr_dynamic(fn() { if checked() { "0" } else { "-1" } }),
    ),
    ("data-value", @luna.attr_static(value)),
  ]
  if disabled is Some(true) {
    attrs.push(("aria-disabled", @luna.attr_static("true")))
  }
  if on_click is Some(handler) {
    attrs.push(("click", @luna.attr_handler(handler)))
  }
  if on_keydown is Some(handler) {
    attrs.push(("keydown", @luna.attr_handler(handler)))
  }
  @luna.h("div", attrs, children)
}

///|
/// Build a complete radio group from options.
///
/// Parameters:
/// - name: Group name (for form submission)
/// - options: Array of RadioOption
/// - selected_value: Currently selected value
/// - aria_label: Accessible label for the group
pub fn[E] radio_group(
  name : String,
  options : Array[RadioOption[E]],
  selected_value : String,
  aria_label? : String,
) -> @luna.Node[E] {
  let radios : Array[@luna.Node[E]] = []
  for option in options {
    let is_checked = option.value == selected_value
    radios.push(
      radio(option.value, is_checked, disabled=option.disabled, option.label),
    )
  }
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("radiogroup")),
    ("data-name", @luna.attr_static(name)),
  ]
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  @luna.h("div", attrs, radios)
}

///|
/// Create a native radio input with label.
/// Uses HTML native radio for better form integration.
pub fn[E] radio_native(
  name : String,
  value : String,
  checked : Bool,
  disabled? : Bool,
  id? : String,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let input_id = id.unwrap_or(name + "-" + value)
  let input_attrs : Array[(String, @luna.Attr[E])] = [
    ("type", @luna.attr_static("radio")),
    ("name", @luna.attr_static(name)),
    ("value", @luna.attr_static(value)),
    ("id", @luna.attr_static(input_id)),
  ]
  if checked {
    input_attrs.push(("checked", @luna.attr_static("")))
  }
  if disabled is Some(true) {
    input_attrs.push(("disabled", @luna.attr_static("")))
  }
  let label_attrs : Array[(String, @luna.Attr[E])] = [
    ("for", @luna.attr_static(input_id)),
  ]
  @luna.fragment([
    @luna.h("input", input_attrs, []),
    @luna.h("label", label_attrs, children),
  ])
}
