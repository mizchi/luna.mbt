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
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
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
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
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
  visible : @signal.Signal[Bool],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
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
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let element_tag = match tag {
    Some(t) => t
    None => "button"
  }
  let attrs : Array[(String, @luna.Attr[E])] = [
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
  trigger_content : Array[@luna.Node[E]],
  tooltip_content : Array[@luna.Node[E]],
  visible : Bool,
) -> @luna.Node[E] {
  let tooltip_id = id + "-tooltip"
  @luna.fragment([
    tooltip_trigger(tooltip_id, trigger_content),
    tooltip_popup(tooltip_id, visible, tooltip_content),
  ])
}
