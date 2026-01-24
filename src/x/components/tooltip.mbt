///|
/// APG Tooltip Pattern
/// https://www.w3.org/WAI/ARIA/apg/patterns/tooltip/
///
/// A tooltip is a popup that displays information related to an element
/// when it receives focus or mouse hover.
///
/// Important:
/// - Tooltip does NOT receive focus
/// - Appears on focus/hover, dismissed on Escape or blur/mouseout
/// - For focusable content, use non-modal dialog instead
///
/// Keyboard Interaction:
/// - Escape: Dismiss the tooltip
///
/// ARIA:
/// - role="tooltip" on the tooltip element
/// - aria-describedby on the trigger referencing the tooltip

///|
/// Create a tooltip element.
///
/// Parameters:
/// - id: Tooltip ID (required, used for aria-describedby on trigger)
/// - children: Tooltip content
pub fn[E] tooltip(
  id : String,
  children : Array[@luna.Node[E, String]],
) -> @luna.Node[E, String] {
  @luna.h(
    "div",
    [("role", @luna.attr_static("tooltip")), ("id", @luna.attr_static(id))],
    children,
  )
}

///|
/// Create a tooltip that can be shown/hidden.
///
/// Parameters:
/// - id: Tooltip ID
/// - visible: Whether tooltip is visible
/// - children: Tooltip content
pub fn[E] tooltip_popup(
  id : String,
  visible : Bool,
  children : Array[@luna.Node[E, String]],
) -> @luna.Node[E, String] {
  let attrs : Array[(String, @luna.Attr[E, String])] = [
    ("role", @luna.attr_static("tooltip")),
    ("id", @luna.attr_static(id)),
  ]
  if not(visible) {
    attrs.push(("hidden", @luna.attr_static("")))
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a dynamic tooltip with signal-based visibility.
pub fn[E] tooltip_dyn(
  id : String,
  visible : @resource.Signal[Bool],
  children : Array[@luna.Node[E, String]],
) -> @luna.Node[E, String] {
  let attrs : Array[(String, @luna.Attr[E, String])] = [
    ("role", @luna.attr_static("tooltip")),
    ("id", @luna.attr_static(id)),
  ]
  @luna.show(fn() { visible.get() }, fn() { @luna.h("div", attrs, children) })
}

///|
/// Create a trigger element that references a tooltip.
/// Adds aria-describedby to the trigger.
///
/// Parameters:
/// - tooltip_id: ID of the tooltip element
/// - tag: HTML tag for the trigger (default: "button")
/// - children: Trigger content
pub fn[E] tooltip_trigger(
  tooltip_id : String,
  tag? : String,
  children : Array[@luna.Node[E, String]],
) -> @luna.Node[E, String] {
  let element_tag = tag.unwrap_or("button")
  let attrs : Array[(String, @luna.Attr[E, String])] = [
    ("aria-describedby", @luna.attr_static(tooltip_id)),
  ]
  if element_tag == "button" {
    attrs.push(("type", @luna.attr_static("button")))
  }
  @luna.h(element_tag, attrs, children)
}

///|
/// Create a complete tooltip with trigger.
///
/// Parameters:
/// - id: Base ID for the tooltip
/// - trigger_content: Content for the trigger element
/// - tooltip_content: Content for the tooltip
/// - visible: Whether tooltip is visible
pub fn[E] tooltip_with_trigger(
  id : String,
  trigger_content : Array[@luna.Node[E, String]],
  tooltip_content : Array[@luna.Node[E, String]],
  visible : Bool,
) -> @luna.Node[E, String] {
  let tooltip_id = id + "-tooltip"
  @luna.fragment([
    tooltip_trigger(tooltip_id, trigger_content),
    tooltip_popup(tooltip_id, visible, tooltip_content),
  ])
}

// =============================================================================
// Interactive Tooltip with Keyboard Support
// =============================================================================

///|
/// Create a keydown handler for tooltip that supports Escape key.
///
/// APG keyboard support:
/// - Escape: Close the tooltip
///
/// Parameters:
/// - on_close: Called when Escape is pressed
pub fn make_tooltip_keydown_handler(
  on_close : () -> Unit,
) -> @luna.EventHandler[@js.Any] {
  @luna.handler(fn(e : @js.Any) {
    let key : String = e._get("key").cast()
    if key == "Escape" {
      on_close()
    }
  })
}

///|
/// Create a complete interactive tooltip with focus/hover behavior.
///
/// Features:
/// - Shows on focus/mouseenter
/// - Hides on blur/mouseleave
/// - Escape key closes tooltip
/// - Proper aria-describedby management
///
/// Parameters:
/// - id: Base ID
/// - trigger_tag: Tag for trigger element (default: "button")
/// - trigger_content: Content for trigger
/// - tooltip_content: Content for tooltip
pub fn tooltip_interactive(
  id : String,
  trigger_tag? : String,
  trigger_content : Array[@luna.Node[@js.Any, String]],
  tooltip_content : Array[@luna.Node[@js.Any, String]],
) -> @luna.Node[@js.Any, String] {
  let visible = @resource.signal(false)
  let tooltip_id = id + "-tooltip"
  let element_tag = trigger_tag.unwrap_or("button")
  let show = fn() { visible.set(true) }
  let hide = fn() { visible.set(false) }
  let keydown_handler = make_tooltip_keydown_handler(hide)
  // Build trigger attrs
  let trigger_attrs : Array[(String, @luna.Attr[@js.Any, String])] = [
    ("id", @luna.attr_static(id)),
    (
      "aria-describedby",
      @luna.attr_dynamic(fn() { if visible.get() { tooltip_id } else { "" } }),
    ),
    ("focus", @luna.attr_handler(@luna.handler(fn(_) { show() }))),
    ("blur", @luna.attr_handler(@luna.handler(fn(_) { hide() }))),
    ("mouseenter", @luna.attr_handler(@luna.handler(fn(_) { show() }))),
    ("mouseleave", @luna.attr_handler(@luna.handler(fn(_) { hide() }))),
    ("keydown", @luna.attr_handler(keydown_handler)),
  ]
  if element_tag == "button" {
    trigger_attrs.push(("type", @luna.attr_static("button")))
  }
  // Build tooltip attrs
  let tooltip_attrs : Array[(String, @luna.Attr[@js.Any, String])] = [
    ("role", @luna.attr_static("tooltip")),
    ("id", @luna.attr_static(tooltip_id)),
  ]
  @luna.fragment([
    @luna.h(element_tag, trigger_attrs, trigger_content),
    @luna.show(fn() { visible.get() }, fn() {
      @luna.h("div", tooltip_attrs, tooltip_content)
    }),
  ])
}
