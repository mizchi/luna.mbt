///|
/// Default Styled Switch Component
///
/// Provides a complete switch with default DOM structure and BEM class names.
/// Use with the default theme CSS or override with your own styles.
///
/// Class names (BEM):
/// - .switch          - Root element
/// - .switch__track   - The track/background
/// - .switch__thumb   - The sliding thumb
/// - .switch__label   - Label text
///
/// Data attributes for styling:
/// - [data-state="on"|"off"]
/// - [data-disabled]

///|
/// Slots for the switch component
pub(all) struct SwitchSlots {
  root : String
  track : String
  thumb : String
  label : String
}

///|
/// Default BEM class names for switch
pub fn switch_slots() -> SwitchSlots {
  {
    root: "switch",
    track: "switch__track",
    thumb: "switch__thumb",
    label: "switch__label",
  }
}

///|
/// Create a styled switch with signal-based state.
///
/// Example:
/// ```moonbit
/// let enabled = @resource.signal(true)
/// switch(enabled, aria_label="Enable notifications", [@luna.text("Notifications")])
/// ```
pub fn switch(
  on : @resource.Signal[Bool],
  disabled? : Bool = false,
  aria_label? : String,
  aria_labelledby? : String,
  class? : String,
  children : Array[@luna.Node[@js.Any]],
) -> @luna.Node[@js.Any] {
  let slots = switch_slots()
  let props = @headless.use_switch(on, disabled~, aria_label?, aria_labelledby?)

  // Build root class with optional extra class
  let root_class = match class {
    Some(c) => slots.root + " " + c
    None => slots.root
  }

  // Data attributes for CSS state selectors
  let data_attrs : Array[(String, @luna.Attr[@js.Any])] = [
    (
      "data-state",
      @luna.attr_dynamic(fn() { if on.get() { "on" } else { "off" } }),
    ),
  ]
  if disabled {
    data_attrs.push(("data-disabled", @luna.attr_static("")))
  }
  @luna.h(
    "button",
    props.attrs + [("class", @luna.attr_static(root_class))] + data_attrs,
    [
      // Track with thumb
      @luna.h("span", [("class", @luna.attr_static(slots.track))], [
        @luna.h("span", [("class", @luna.attr_static(slots.thumb))], []),
      ]),
      // Label
      @luna.h("span", [("class", @luna.attr_static(slots.label))], children),
    ],
  )
}

///|
/// Create a styled switch with static state (non-reactive).
///
/// Useful for server-side rendering or when state is managed externally.
pub fn switch_static(
  on : Bool,
  disabled? : Bool = false,
  aria_label? : String,
  aria_labelledby? : String,
  on_click? : @luna.EventHandler[@js.Any],
  class? : String,
  children : Array[@luna.Node[@js.Any]],
) -> @luna.Node[@js.Any] {
  let slots = switch_slots()
  let attrs : Array[(String, @luna.Attr[@js.Any])] = @headless.switch_attrs(
    on,
    disabled~,
    aria_label?,
    aria_labelledby?,
  )

  // Build root class
  let root_class = match class {
    Some(c) => slots.root + " " + c
    None => slots.root
  }

  // Data attributes
  let data_attrs : Array[(String, @luna.Attr[@js.Any])] = [
    ("data-state", @luna.attr_static(if on { "on" } else { "off" })),
  ]
  if disabled {
    data_attrs.push(("data-disabled", @luna.attr_static("")))
  }

  // Optional click handler
  let handler_attrs : Array[(String, @luna.Attr[@js.Any])] = match on_click {
    Some(handler) => [("click", @luna.attr_handler(handler))]
    None => []
  }
  @luna.h(
    "button",
    attrs +
    [("class", @luna.attr_static(root_class))] +
    data_attrs +
    handler_attrs,
    [
      @luna.h("span", [("class", @luna.attr_static(slots.track))], [
        @luna.h("span", [("class", @luna.attr_static(slots.thumb))], []),
      ]),
      @luna.h("span", [("class", @luna.attr_static(slots.label))], children),
    ],
  )
}

///|
/// Switch group container
pub fn switch_group(
  aria_label? : String,
  class? : String,
  children : Array[@luna.Node[@js.Any]],
) -> @luna.Node[@js.Any] {
  let attrs : Array[(String, @luna.Attr[@js.Any])] = [
    ("role", @luna.attr_static("group")),
  ]
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  let group_class = match class {
    Some(c) => "switch-group " + c
    None => "switch-group"
  }
  attrs.push(("class", @luna.attr_static(group_class)))
  @luna.h("div", attrs, children)
}

///|
/// Get the CSS for the default switch theme.
///
/// This can be used to extract CSS at build time or inject at runtime.
pub fn switch_css() -> String {
  let css =
    #|/* Switch - Default Theme */
    #|.switch {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  gap: 0.75rem;
    #|  padding: 0;
    #|  border: none;
    #|  background: transparent;
    #|  cursor: pointer;
    #|  font-weight: 500;
    #|  font-size: 0.875rem;
    #|  color: var(--foreground);
    #|}
    #|
    #|.switch:focus-visible {
    #|  outline: 2px solid var(--accent);
    #|  outline-offset: 2px;
    #|  border-radius: 4px;
    #|}
    #|
    #|.switch[data-disabled] {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
    #|
    #|.switch__track {
    #|  position: relative;
    #|  display: inline-flex;
    #|  align-items: center;
    #|  width: 3rem;
    #|  height: 1.5rem;
    #|  border-radius: 9999px;
    #|  background: var(--muted-foreground);
    #|  border: 2px solid var(--muted-foreground);
    #|  transition: background-color 0.2s, border-color 0.2s;
    #|}
    #|
    #|.switch[data-state="on"] .switch__track {
    #|  background: var(--accent);
    #|  border-color: var(--accent);
    #|}
    #|
    #|.switch__thumb {
    #|  position: absolute;
    #|  left: 2px;
    #|  width: 1.125rem;
    #|  height: 1.125rem;
    #|  border-radius: 50%;
    #|  background: var(--background);
    #|  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.2);
    #|  transition: transform 0.2s;
    #|}
    #|
    #|.switch[data-state="on"] .switch__thumb {
    #|  transform: translateX(1.5rem);
    #|}
    #|
    #|.switch__label {
    #|  user-select: none;
    #|}
    #|
    #|.switch-group {
    #|  display: flex;
    #|  flex-direction: column;
    #|  gap: 0.75rem;
    #|}
  css
}
