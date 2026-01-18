///|
/// Headless Switch Component
///
/// Provides accessibility (ARIA) and behavior without DOM structure or styling.
/// Use this with your own CSS framework (Tailwind, CSS Modules, etc.)
///
/// APG Reference: https://www.w3.org/WAI/ARIA/apg/patterns/switch/

///|
/// Switch state and handlers (Web-specific, uses @js.Any for events)
pub(all) struct SwitchProps {
  /// ARIA and accessibility attributes
  attrs : Array[(String, @luna.Attr[@js.Any])]
  /// Toggle the switch state
  toggle : () -> Unit
  /// Current on/off state
  is_on : Bool
}

///|
/// Create a headless switch with signal-based state.
///
/// Returns props that can be spread onto any element.
///
/// Example with Tailwind:
/// ```moonbit
/// let on = @resource.signal(false)
/// let props = use_switch(on)
///
/// @luna.h("button",
///   props.attrs + [
///     ("class", @luna.attr_static("relative inline-flex h-6 w-11 rounded-full")),
///   ],
///   [/* your thumb element */]
/// )
/// ```
pub fn use_switch(
  on : @resource.Signal[Bool],
  disabled? : Bool,
  aria_label? : String,
  aria_labelledby? : String,
) -> SwitchProps {
  let is_disabled = disabled.unwrap_or(false)
  let is_on = on.get()

  // Build ARIA attributes with dynamic aria-checked for reactivity
  let attrs : Array[(String, @luna.Attr[@js.Any])] = [
    ("role", @luna.attr_static("switch")),
    (
      "aria-checked",
      @luna.attr_dynamic(fn() { if on.get() { "true" } else { "false" } }),
    ),
    ("tabindex", @luna.attr_static(if is_disabled { "-1" } else { "0" })),
  ]
  if is_disabled {
    attrs.push(("aria-disabled", @luna.attr_static("true")))
  }
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  if aria_labelledby is Some(id) {
    attrs.push(("aria-labelledby", @luna.attr_static(id)))
  }

  // Toggle function
  let toggle = fn() { if not(is_disabled) { on.set(not(on.get())) } }

  // Add click handler
  attrs.push(("click", @luna.attr_handler(@luna.handler(fn(_) { toggle() }))))

  // Add keydown handler for Space/Enter
  attrs.push(
    (
      "keydown",
      @luna.attr_handler(
        @luna.handler(fn(evt) {
          let key = get_event_key(evt)
          if @aria.is_toggle_key(key) {
            prevent_default(evt)
            toggle()
          }
        }),
      ),
    ),
  )
  { attrs, toggle, is_on }
}

///|
/// Create a headless switch with computed state (getter function).
///
/// Useful when the state is derived from other signals.
pub fn use_switch_computed(
  get_on : () -> Bool,
  set_on : (Bool) -> Unit,
  disabled? : Bool,
  aria_label? : String,
  aria_labelledby? : String,
) -> SwitchProps {
  let is_disabled = disabled.unwrap_or(false)
  let is_on = get_on()

  // Build ARIA attributes with dynamic aria-checked
  let attrs : Array[(String, @luna.Attr[@js.Any])] = [
    ("role", @luna.attr_static("switch")),
    (
      "aria-checked",
      @luna.attr_dynamic(fn() { if get_on() { "true" } else { "false" } }),
    ),
    ("tabindex", @luna.attr_static(if is_disabled { "-1" } else { "0" })),
  ]
  if is_disabled {
    attrs.push(("aria-disabled", @luna.attr_static("true")))
  }
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  if aria_labelledby is Some(id) {
    attrs.push(("aria-labelledby", @luna.attr_static(id)))
  }

  // Toggle function
  let toggle = fn() { if not(is_disabled) { set_on(not(get_on())) } }

  // Add handlers
  attrs.push(("click", @luna.attr_handler(@luna.handler(fn(_) { toggle() }))))
  attrs.push(
    (
      "keydown",
      @luna.attr_handler(
        @luna.handler(fn(evt) {
          let key = get_event_key(evt)
          if @aria.is_toggle_key(key) {
            prevent_default(evt)
            toggle()
          }
        }),
      ),
    ),
  )
  { attrs, toggle, is_on }
}

///|
/// Simple switch ARIA attributes only (no handlers).
///
/// Use when you want to attach your own event handlers.
/// Generic version that works with any event type.
pub fn[E] switch_attrs(
  on : Bool,
  disabled? : Bool,
  aria_label? : String,
  aria_labelledby? : String,
) -> Array[(String, @luna.Attr[E])] {
  let is_disabled = disabled.unwrap_or(false)
  let aria_attrs = @aria.switch_aria(on, is_disabled)
  if aria_label is Some(label) {
    aria_attrs.push(("aria-label", label))
  }
  if aria_labelledby is Some(id) {
    aria_attrs.push(("aria-labelledby", id))
  }
  aria_attrs.map(fn(pair) { (pair.0, @luna.attr_static(pair.1)) })
}

///|
/// Dynamic switch ARIA attributes (reactive aria-checked).
/// Generic version that works with any event type.
pub fn[E] switch_attrs_dyn(
  on : @resource.Signal[Bool],
  disabled? : Bool,
  aria_label? : String,
  aria_labelledby? : String,
) -> Array[(String, @luna.Attr[E])] {
  let is_disabled = disabled.unwrap_or(false)
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("switch")),
    (
      "aria-checked",
      @luna.attr_dynamic(fn() { if on.get() { "true" } else { "false" } }),
    ),
    ("tabindex", @luna.attr_static(if is_disabled { "-1" } else { "0" })),
  ]
  if is_disabled {
    attrs.push(("aria-disabled", @luna.attr_static("true")))
  }
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  if aria_labelledby is Some(id) {
    attrs.push(("aria-labelledby", @luna.attr_static(id)))
  }
  attrs
}

///|
/// Create a toggle handler for Space/Enter keys.
/// Web-specific version.
pub fn make_switch_keydown_handler(
  toggle : () -> Unit,
) -> @luna.EventHandler[@js.Any] {
  @luna.handler(fn(evt) {
    let key = get_event_key(evt)
    if @aria.is_toggle_key(key) {
      prevent_default(evt)
      toggle()
    }
  })
}
