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
  // Build switch with track, thumb, icon structure
  let track = @luna.h("span", [("class", @luna.attr_static("switch-track"))], [
    @luna.h("span", [("class", @luna.attr_static("switch-icon"))], [
      @luna.text("✓"),
    ]),
    @luna.h("span", [("class", @luna.attr_static("switch-thumb"))], []),
  ])
  let label = @luna.h(
    "span",
    [("class", @luna.attr_static("switch-label"))],
    children,
  )
  @luna.h("button", attrs, [track, label])
}

///|
/// Create a dynamic switch with signal-based state.
pub fn[E] switch_dyn(
  on : @resource.Signal[Bool],
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
  // Build switch with track, thumb, icon structure
  let track = @luna.h("span", [("class", @luna.attr_static("switch-track"))], [
    @luna.h("span", [("class", @luna.attr_static("switch-icon"))], [
      @luna.text("✓"),
    ]),
    @luna.h("span", [("class", @luna.attr_static("switch-thumb"))], []),
  ])
  let label = @luna.h(
    "span",
    [("class", @luna.attr_static("switch-label"))],
    children,
  )
  @luna.h("button", attrs, [track, label])
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
  // Build switch with track, thumb, icon structure
  let track = @luna.h("span", [("class", @luna.attr_static("switch-track"))], [
    @luna.h("span", [("class", @luna.attr_static("switch-icon"))], [
      @luna.text("✓"),
    ]),
    @luna.h("span", [("class", @luna.attr_static("switch-thumb"))], []),
  ])
  let label = @luna.h(
    "span",
    [("class", @luna.attr_static("switch-label"))],
    children,
  )
  @luna.h("button", attrs, [track, label])
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
  let input_id = id.unwrap_or("switch-" + name)
  let input_attrs : Array[(String, @luna.Attr[E])] = [
    ("type", @luna.attr_static("checkbox")),
    ("role", @luna.attr_static("switch")),
    ("name", @luna.attr_static(name)),
    ("id", @luna.attr_static(input_id)),
  ]
  if on {
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
/// Create a switch group.
pub fn[E] switch_group(
  aria_label? : String,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("group")),
  ]
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a keyboard handler for switch that supports Space and Enter.
///
/// APG requires:
/// - Space: Toggle switch state
/// - Enter: Toggle switch state
///
/// Parameters:
/// - on_toggle: Called when switch should toggle
pub fn make_switch_handler(on_toggle : () -> Unit) -> @luna.EventHandler[@js.Any] {
  @luna.handler(fn(e : @js.Any) {
    let key : String = e._get("key").cast()
    match key {
      " " | "Enter" => {
        let _ = e._call("preventDefault", [])
        on_toggle()
      }
      _ => ()
    }
  })
}

///|
/// Create a complete interactive switch with built-in keyboard support.
///
/// Features:
/// - Space and Enter toggle state
/// - Click toggles state
/// - Proper ARIA attributes
///
/// Parameters:
/// - on: Signal controlling switch state
/// - disabled: Whether disabled
/// - aria_label: Accessible label
/// - children: Switch label content
pub fn switch_interactive(
  on : @resource.Signal[Bool],
  disabled? : Bool,
  aria_label? : String,
  children : Array[@luna.Node[@js.Any]],
) -> @luna.Node[@js.Any] {
  let is_disabled = disabled.unwrap_or(false)
  let toggle = fn() {
    if not(is_disabled) {
      on.set(not(on.get()))
    }
  }
  let keydown_handler = make_switch_handler(toggle)
  let click_handler = @luna.handler(fn(_) { toggle() })
  let attrs : Array[(String, @luna.Attr[@js.Any])] = [
    ("role", @luna.attr_static("switch")),
    (
      "aria-checked",
      @luna.attr_dynamic(fn() { if on.get() { "true" } else { "false" } }),
    ),
    ("tabindex", @luna.attr_static("0")),
    ("keydown", @luna.attr_handler(keydown_handler)),
    ("click", @luna.attr_handler(click_handler)),
  ]
  if is_disabled {
    attrs.push(("aria-disabled", @luna.attr_static("true")))
  }
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  // Build switch with track, thumb, icon structure
  let track = @luna.h("span", [("class", @luna.attr_static("switch-track"))], [
    @luna.h("span", [("class", @luna.attr_static("switch-icon"))], [
      @luna.text("✓"),
    ]),
    @luna.h("span", [("class", @luna.attr_static("switch-thumb"))], []),
  ])
  let label = @luna.h(
    "span",
    [("class", @luna.attr_static("switch-label"))],
    children,
  )
  @luna.h("button", attrs, [track, label])
}
