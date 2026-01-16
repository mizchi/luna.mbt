///|
/// APG Disclosure Pattern
/// https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/
///
/// A disclosure is a widget that enables content to be collapsed or expanded.
/// It has a button and a content section controlled by the button.
///
/// Keyboard Interaction:
/// - Enter: Toggle visibility
/// - Space: Toggle visibility
///
/// ARIA:
/// - Button with aria-expanded and aria-controls
/// - No special role needed for content

///|
/// Create a disclosure button.
///
/// Parameters:
/// - id: Button ID
/// - expanded: Whether content is visible
/// - controls: ID of controlled content element
/// - on_click: Click handler
/// - on_keydown: Keydown handler (for Enter/Space toggle)
/// - children: Button content
pub fn[E] disclosure_button(
  id? : String,
  expanded : Bool,
  controls : String,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("type", @luna.attr_static("button")),
    (
      "aria-expanded",
      @luna.attr_static(if expanded { "true" } else { "false" }),
    ),
    ("aria-controls", @luna.attr_static(controls)),
  ]
  if id is Some(i) {
    attrs.push(("id", @luna.attr_static(i)))
  }
  if on_click is Some(handler) {
    attrs.push(("click", @luna.attr_handler(handler)))
  }
  if on_keydown is Some(handler) {
    attrs.push(("keydown", @luna.attr_handler(handler)))
  }
  @luna.h("button", attrs, children)
}

///|
/// Create a dynamic disclosure button with signal-based state.
pub fn[E] disclosure_button_dyn(
  id? : String,
  expanded : @resource.Signal[Bool],
  controls : String,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("type", @luna.attr_static("button")),
    (
      "aria-expanded",
      @luna.attr_dynamic(fn() { if expanded.get() { "true" } else { "false" } }),
    ),
    ("aria-controls", @luna.attr_static(controls)),
  ]
  if id is Some(i) {
    attrs.push(("id", @luna.attr_static(i)))
  }
  if on_click is Some(handler) {
    attrs.push(("click", @luna.attr_handler(handler)))
  }
  if on_keydown is Some(handler) {
    attrs.push(("keydown", @luna.attr_handler(handler)))
  }
  @luna.h("button", attrs, children)
}

///|
/// Create a disclosure button with computed state (accepts getter function).
/// Useful for derived disclosure states.
pub fn[E] disclosure_button_computed(
  id? : String,
  expanded : () -> Bool,
  controls : String,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("type", @luna.attr_static("button")),
    ("aria-expanded", @luna.attr_dynamic(fn() { bool_to_aria(expanded()) })),
    ("aria-controls", @luna.attr_static(controls)),
  ]
  if id is Some(i) {
    attrs.push(("id", @luna.attr_static(i)))
  }
  if on_click is Some(handler) {
    attrs.push(("click", @luna.attr_handler(handler)))
  }
  if on_keydown is Some(handler) {
    attrs.push(("keydown", @luna.attr_handler(handler)))
  }
  @luna.h("button", attrs, children)
}

///|
/// Create disclosure content panel.
///
/// Parameters:
/// - id: Content ID (referenced by button's aria-controls)
/// - hidden: Whether content is hidden
/// - children: Content
pub fn[E] disclosure_content(
  id : String,
  hidden : Bool,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [("id", @luna.attr_static(id))]
  if hidden {
    attrs.push(("hidden", @luna.attr_static("")))
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a dynamic disclosure content with signal-based visibility.
pub fn[E] disclosure_content_dyn(
  id : String,
  visible : @resource.Signal[Bool],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [("id", @luna.attr_static(id))]
  @luna.show(fn() { visible.get() }, fn() { @luna.h("div", attrs, children) })
}

///|
/// Create disclosure content with computed visibility (accepts getter function).
pub fn[E] disclosure_content_computed(
  id : String,
  visible : () -> Bool,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [("id", @luna.attr_static(id))]
  @luna.show(visible, fn() { @luna.h("div", attrs, children) })
}

///|
/// Create a complete disclosure component.
///
/// Parameters:
/// - id: Base ID for the disclosure
/// - expanded: Whether expanded
/// - button_content: Content for the button
/// - panel_content: Content for the panel
pub fn[E] disclosure(
  id : String,
  expanded : Bool,
  button_content : Array[@luna.Node[E]],
  panel_content : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let button_id = id + "-button"
  let content_id = id + "-content"
  @luna.fragment([
    disclosure_button(id=button_id, expanded, content_id, button_content),
    disclosure_content(content_id, not(expanded), panel_content),
  ])
}

///|
/// Create a dynamic disclosure component with signal-based state.
/// This is the recommended way to create disclosures with reactive state.
///
/// Parameters:
/// - id: Base ID for the disclosure
/// - expanded: Signal containing the expanded state
/// - button_content: Content for the button
/// - panel_content: Content for the panel
pub fn[E] disclosure_dyn(
  id : String,
  expanded : @resource.Signal[Bool],
  button_content : Array[@luna.Node[E]],
  panel_content : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let button_id = id + "-button"
  let content_id = id + "-content"
  @luna.fragment([
    disclosure_button_computed(
      id=button_id,
      fn() { expanded.get() },
      content_id,
      on_click=@luna.handler(fn(_) { expanded.set(not(expanded.get())) }),
      button_content,
    ),
    disclosure_content_computed(
      content_id,
      fn() { expanded.get() },
      panel_content,
    ),
  ])
}
