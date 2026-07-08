///|
/// Native HTML Popover API mode.
pub(all) enum PopoverMode {
  /// Light-dismiss popover. This is the browser default.
  Auto
  /// Manual popover, closed explicitly by script or a target button.
  Manual
} derive(Eq, Debug)

///|
/// Native `popovertargetaction` values for controls targeting a popover.
pub(all) enum PopoverTargetAction {
  Toggle
  Show
  Hide
} derive(Eq, Debug)

///|
fn popover_mode_to_string(mode : PopoverMode) -> String {
  match mode {
    Auto => "auto"
    Manual => "manual"
  }
}

///|
fn popover_action_to_string(action : PopoverTargetAction) -> String {
  match action {
    Toggle => "toggle"
    Show => "show"
    Hide => "hide"
  }
}

///|
/// Create a zero-runtime native popover container.
///
/// The browser owns open/close behavior through the HTML Popover API. Pair this
/// with `popover_trigger` to avoid adding a client-side controller for common
/// menus, help panels, and non-modal dialogs.
pub fn[E] popover(
  id : String,
  mode? : PopoverMode,
  role? : String,
  aria_label? : String,
  aria_labelledby? : String,
  class? : String,
  children : Array[@luna.Node[E, String]],
) -> @luna.Node[E, String] {
  let attrs : Array[(String, @luna.Attr[E, String])] = [
    ("id", @luna.attr_static(id)),
    ("popover", @luna.attr_static(popover_mode_to_string(mode.unwrap_or(Auto)))),
  ]
  if role is Some(value) {
    attrs.push(("role", @luna.attr_static(value)))
  }
  if aria_label is Some(value) {
    attrs.push(("aria-label", @luna.attr_static(value)))
  }
  if aria_labelledby is Some(value) {
    attrs.push(("aria-labelledby", @luna.attr_static(value)))
  }
  if class is Some(value) {
    attrs.push(("class", @luna.attr_static(value)))
  }
  @luna.h("div", attrs) <| children
}

///|
/// Create a button that controls a native popover.
pub fn[E] popover_trigger(
  target : String,
  action? : PopoverTargetAction,
  id? : String,
  aria_label? : String,
  class? : String,
  children : Array[@luna.Node[E, String]],
) -> @luna.Node[E, String] {
  let attrs : Array[(String, @luna.Attr[E, String])] = [
    ("type", @luna.attr_static("button")),
    ("popovertarget", @luna.attr_static(target)),
  ]
  if action is Some(value) {
    attrs.push(
      (
        "popovertargetaction",
        @luna.attr_static(popover_action_to_string(value)),
      ),
    )
  }
  if id is Some(value) {
    attrs.push(("id", @luna.attr_static(value)))
  }
  if aria_label is Some(value) {
    attrs.push(("aria-label", @luna.attr_static(value)))
  }
  if class is Some(value) {
    attrs.push(("class", @luna.attr_static(value)))
  }
  @luna.h("button", attrs) <| children
}

///|
/// Create a non-modal dialog surface backed by the native Popover API.
pub fn[E] popover_dialog(
  id : String,
  mode? : PopoverMode,
  aria_label? : String,
  aria_labelledby? : String,
  class? : String,
  children : Array[@luna.Node[E, String]],
) -> @luna.Node[E, String] {
  popover(
    id,
    mode?,
    role="dialog",
    aria_label?,
    aria_labelledby?,
    class?,
    children,
  )
}
