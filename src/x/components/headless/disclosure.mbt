///|
/// Headless Disclosure Component
///
/// Provides accessibility (ARIA) and behavior without styling.
///
/// APG Reference: https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/

///|
/// Props returned by use_disclosure for the trigger button.
pub(all) struct DisclosureTriggerProps {
  attrs : Array[(String, @luna.Attr[@js.Any, String])]
  toggle : () -> Unit
  is_expanded : Bool
}

///|
/// Props returned by use_disclosure for the panel.
pub(all) struct DisclosurePanelProps {
  attrs : Array[(String, @luna.Attr[@js.Any, String])]
  is_expanded : Bool
}

///|
/// Create headless disclosure trigger props.
///
/// Parameters:
/// - button_id: ID for the trigger button
/// - panel_id: ID for the controlled panel
/// - expanded: Signal containing the expanded state
pub fn use_disclosure_trigger(
  button_id : String,
  panel_id : String,
  expanded : @resource.Signal[Bool],
) -> DisclosureTriggerProps {
  let toggle = fn() { expanded.set(not(expanded.get())) }
  let attrs : Array[(String, @luna.Attr[@js.Any, String])] = [
    ("type", @luna.attr_static("button")),
    ("id", @luna.attr_static(button_id)),
    (
      "aria-expanded",
      @luna.attr_dynamic(fn() { if expanded.get() { "true" } else { "false" } }),
    ),
    ("aria-controls", @luna.attr_static(panel_id)),
    ("click", @luna.attr_handler(@luna.handler(fn(_) { toggle() }))),
  ]
  { attrs, toggle, is_expanded: expanded.get() }
}

///|
/// Create headless disclosure panel props.
///
/// Parameters:
/// - panel_id: ID for the panel
/// - button_id: ID of the controlling button
/// - expanded: Signal containing the expanded state
pub fn use_disclosure_panel(
  panel_id : String,
  button_id : String,
  expanded : @resource.Signal[Bool],
) -> DisclosurePanelProps {
  let attrs : Array[(String, @luna.Attr[@js.Any, String])] = [
    ("id", @luna.attr_static(panel_id)),
    ("aria-labelledby", @luna.attr_static(button_id)),
    (
      "aria-hidden",
      @luna.attr_dynamic(fn() { if expanded.get() { "false" } else { "true" } }),
    ),
  ]
  { attrs, is_expanded: expanded.get() }
}

///|
/// Get static ARIA attributes for disclosure trigger.
pub fn[E] disclosure_trigger_attrs(
  button_id : String,
  panel_id : String,
  is_expanded : Bool,
) -> Array[(String, @luna.Attr[E, String])] {
  [
    ("type", @luna.attr_static("button")),
    ("id", @luna.attr_static(button_id)),
    (
      "aria-expanded",
      @luna.attr_static(if is_expanded { "true" } else { "false" }),
    ),
    ("aria-controls", @luna.attr_static(panel_id)),
  ]
}

///|
/// Get static ARIA attributes for disclosure panel.
pub fn[E] disclosure_panel_attrs(
  panel_id : String,
  button_id : String,
  is_expanded : Bool,
) -> Array[(String, @luna.Attr[E, String])] {
  [
    ("id", @luna.attr_static(panel_id)),
    ("aria-labelledby", @luna.attr_static(button_id)),
    (
      "aria-hidden",
      @luna.attr_static(if is_expanded { "false" } else { "true" }),
    ),
  ]
}
