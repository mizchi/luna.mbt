///|
/// APG Switch Pattern
/// https://www.w3.org/WAI/ARIA/apg/patterns/switch/
///
/// A switch is an input widget for binary "on" or "off" values.
/// Similar to checkbox but semantically different (on/off vs checked/unchecked).
///
/// Important: The label should NOT change when state changes.
///
/// Keyboard Interaction:
/// - Space: Toggle the switch state
/// - Enter: Toggle the switch state (optional)
///
/// ARIA:
/// - role="switch"
/// - aria-checked: "true" (on) / "false" (off)

///|
/// Create an accessible switch.
///
/// Parameters:
/// - on: Whether the switch is on
/// - disabled: Whether disabled
/// - aria_label: Accessible label (should NOT change with state)
/// - aria_labelledby: ID of labelling element
/// - on_click: Click handler
/// - on_keydown: Keydown handler (for Space/Enter toggle)
/// - children: Switch label content
pub fn[E] switch(
  on : Bool,
  disabled? : Bool,
  aria_label? : String,
  aria_labelledby? : String,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("switch")),
    ("aria-checked", @luna.attr_static(if on { "true" } else { "false" })),
    ("tabindex", @luna.attr_static("0")),
  ]
  match disabled {
    Some(true) => attrs.push(("aria-disabled", @luna.attr_static("true")))
    _ => ()
  }
  match aria_label {
    Some(label) => attrs.push(("aria-label", @luna.attr_static(label)))
    None => ()
  }
  match aria_labelledby {
    Some(id) => attrs.push(("aria-labelledby", @luna.attr_static(id)))
    None => ()
  }
  match on_click {
    Some(handler) => attrs.push(("click", @luna.attr_handler(handler)))
    None => ()
  }
  match on_keydown {
    Some(handler) => attrs.push(("keydown", @luna.attr_handler(handler)))
    None => ()
  }
  @luna.h("button", attrs, children)
}

///|
/// Create a dynamic switch with signal-based state.
pub fn[E] switch_dyn(
  on : @signal.Signal[Bool],
  disabled? : Bool,
  aria_label? : String,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("switch")),
    (
      "aria-checked",
      @luna.attr_dynamic(fn() { if on.get() { "true" } else { "false" } }),
    ),
    ("tabindex", @luna.attr_static("0")),
  ]
  match disabled {
    Some(true) => attrs.push(("aria-disabled", @luna.attr_static("true")))
    _ => ()
  }
  match aria_label {
    Some(label) => attrs.push(("aria-label", @luna.attr_static(label)))
    None => ()
  }
  match on_click {
    Some(handler) => attrs.push(("click", @luna.attr_handler(handler)))
    None => ()
  }
  match on_keydown {
    Some(handler) => attrs.push(("keydown", @luna.attr_handler(handler)))
    None => ()
  }
  @luna.h("button", attrs, children)
}

///|
/// Create a switch with computed state (accepts getter function).
/// Useful for derived switch states.
pub fn[E] switch_computed(
  on : () -> Bool,
  disabled? : Bool,
  aria_label? : String,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("switch")),
    ("aria-checked", @luna.attr_dynamic(fn() { bool_to_aria(on()) })),
    ("tabindex", @luna.attr_static("0")),
  ]
  match disabled {
    Some(true) => attrs.push(("aria-disabled", @luna.attr_static("true")))
    _ => ()
  }
  match aria_label {
    Some(label) => attrs.push(("aria-label", @luna.attr_static(label)))
    None => ()
  }
  match on_click {
    Some(handler) => attrs.push(("click", @luna.attr_handler(handler)))
    None => ()
  }
  match on_keydown {
    Some(handler) => attrs.push(("keydown", @luna.attr_handler(handler)))
    None => ()
  }
  @luna.h("button", attrs, children)
}

///|
/// Create a switch using native checkbox with role="switch".
pub fn[E] switch_native(
  name : String,
  on : Bool,
  disabled? : Bool,
  id? : String,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let input_id = match id {
    Some(i) => i
    None => "switch-" + name
  }
  let input_attrs : Array[(String, @luna.Attr[E])] = [
    ("type", @luna.attr_static("checkbox")),
    ("role", @luna.attr_static("switch")),
    ("name", @luna.attr_static(name)),
    ("id", @luna.attr_static(input_id)),
  ]
  if on {
    input_attrs.push(("checked", @luna.attr_static("")))
  }
  match disabled {
    Some(true) => input_attrs.push(("disabled", @luna.attr_static("")))
    _ => ()
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
/// Create a switch group.
pub fn[E] switch_group(
  aria_label? : String,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("group")),
  ]
  match aria_label {
    Some(label) => attrs.push(("aria-label", @luna.attr_static(label)))
    None => ()
  }
  @luna.h("div", attrs, children)
}
