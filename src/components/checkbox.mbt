///|
/// APG Checkbox Pattern
/// https://www.w3.org/WAI/ARIA/apg/patterns/checkbox/
///
/// Checkbox supports two types:
/// - Dual-state: checked / not checked
/// - Tri-state: checked / not checked / partially checked (mixed)
///
/// Keyboard Interaction:
/// - Space: Toggle the checkbox state
///
/// ARIA:
/// - role="checkbox"
/// - aria-checked: "true" / "false" / "mixed"

///|
/// Checkbox state
pub(all) enum CheckboxState {
  Checked // aria-checked="true"
  Unchecked // aria-checked="false"
  Mixed // aria-checked="mixed" (tri-state)
}

///|
fn CheckboxState::to_aria(self : CheckboxState) -> String {
  match self {
    Checked => "true"
    Unchecked => "false"
    Mixed => "mixed"
  }
}

///|
/// Create an accessible checkbox.
///
/// Parameters:
/// - checked: Checkbox state
/// - disabled: Whether disabled
/// - aria_label: Accessible label
/// - aria_labelledby: ID of labelling element
/// - on_click: Click handler
/// - on_keydown: Keydown handler (for Space key toggle)
/// - children: Checkbox label content
pub fn[E] checkbox(
  checked : CheckboxState,
  disabled? : Bool,
  aria_label? : String,
  aria_labelledby? : String,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("checkbox")),
    ("aria-checked", @luna.attr_static(checked.to_aria())),
    ("tabindex", @luna.attr_static("0")),
  ]
  if disabled is Some(true) {
    attrs.push(("aria-disabled", @luna.attr_static("true")))
  }
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  if aria_labelledby is Some(id) {
    attrs.push(("aria-labelledby", @luna.attr_static(id)))
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
/// Create a dynamic checkbox with signal-based state.
pub fn[E] checkbox_dyn(
  checked : @signal.Signal[CheckboxState],
  disabled? : Bool,
  aria_label? : String,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("checkbox")),
    ("aria-checked", @luna.attr_dynamic(fn() { checked.get().to_aria() })),
    ("tabindex", @luna.attr_static("0")),
  ]
  if disabled is Some(true) {
    attrs.push(("aria-disabled", @luna.attr_static("true")))
  }
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
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
/// Create a checkbox with computed state (accepts getter function).
/// Useful for derived checkbox states.
pub fn[E] checkbox_computed(
  checked : () -> CheckboxState,
  disabled? : Bool,
  aria_label? : String,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("checkbox")),
    ("aria-checked", @luna.attr_dynamic(fn() { checked().to_aria() })),
    ("tabindex", @luna.attr_static("0")),
  ]
  if disabled is Some(true) {
    attrs.push(("aria-disabled", @luna.attr_static("true")))
  }
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
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
/// Create a native HTML checkbox input with label.
pub fn[E] checkbox_native(
  name : String,
  checked : Bool,
  disabled? : Bool,
  id? : String,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let input_id = id.unwrap_or("checkbox-" + name)
  let input_attrs : Array[(String, @luna.Attr[E])] = [
    ("type", @luna.attr_static("checkbox")),
    ("name", @luna.attr_static(name)),
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

///|
/// Create a checkbox group with role="group".
pub fn[E] checkbox_group(
  aria_label? : String,
  aria_labelledby? : String,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("group")),
  ]
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  if aria_labelledby is Some(id) {
    attrs.push(("aria-labelledby", @luna.attr_static(id)))
  }
  @luna.h("div", attrs, children)
}
