///|
/// Headless Checkbox Component
///
/// Provides accessibility (ARIA) and behavior without DOM structure or styling.
///
/// APG Reference: https://www.w3.org/WAI/ARIA/apg/patterns/checkbox/

///|
/// Checkbox props
pub(all) struct CheckboxProps {
  attrs : Array[(String, @luna.Attr[@js.Any])]
  toggle : () -> Unit
  is_checked : Bool
}

///|
/// Create a headless checkbox with signal-based state.
pub fn use_checkbox(
  checked : @signal.Signal[Bool],
  disabled? : Bool = false,
  indeterminate? : Bool = false,
  aria_label? : String,
) -> CheckboxProps {
  let is_checked = checked.get()
  let aria_attrs = checkbox_aria(is_checked, disabled, indeterminate)
  let attrs : Array[(String, @luna.Attr[@js.Any])] = aria_attrs.map(fn(pair) {
    (pair.0, @luna.attr_static(pair.1))
  })

  // Dynamic aria-checked
  attrs.push(
    (
      "aria-checked",
      @luna.attr_dynamic(fn() {
        if indeterminate {
          "mixed"
        } else if checked.get() {
          "true"
        } else {
          "false"
        }
      }),
    ),
  )
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  let toggle = fn() { if not(disabled) { checked.set(not(checked.get())) } }
  attrs.push(("click", @luna.attr_handler(@luna.handler(fn(_) { toggle() }))))
  attrs.push(
    (
      "keydown",
      @luna.attr_handler(
        @luna.handler(fn(evt) {
          let key = get_event_key(evt)
          if is_toggle_key(key) {
            prevent_default(evt)
            toggle()
          }
        }),
      ),
    ),
  )
  { attrs, toggle, is_checked }
}

///|
/// Checkbox attrs only (static version).
pub fn[E] checkbox_attrs(
  checked : Bool,
  disabled? : Bool = false,
  indeterminate? : Bool = false,
  aria_label? : String,
) -> Array[(String, @luna.Attr[E])] {
  let aria_attrs = checkbox_aria(checked, disabled, indeterminate)
  let attrs : Array[(String, @luna.Attr[E])] = aria_attrs.map(fn(pair) {
    (pair.0, @luna.attr_static(pair.1))
  })
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  attrs
}
