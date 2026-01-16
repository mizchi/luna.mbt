///|
/// APG Button Pattern
/// https://www.w3.org/WAI/ARIA/apg/patterns/button/
///
/// A button is a widget that enables users to trigger an action or event.
/// Uses native <button> element for best accessibility.
///
/// Keyboard Interaction:
/// - Space: Activates the button
/// - Enter: Activates the button
///
/// ARIA Roles, States, and Properties:
/// - role="button" (implicit for <button>)
/// - aria-pressed: For toggle buttons (true/false)
/// - aria-disabled: When action is unavailable
/// - aria-label/aria-labelledby: Accessible name
/// - aria-describedby: Description of button's function
/// - aria-haspopup: For menu buttons

///|
/// Button type variants
pub(all) enum ButtonType {
  Button // Default button
  Submit // Form submit button
  Reset // Form reset button
}

///|
fn ButtonType::to_string(self : ButtonType) -> String {
  match self {
    Button => "button"
    Submit => "submit"
    Reset => "reset"
  }
}

///|
/// Create an accessible button using native <button> element.
///
/// Parameters:
/// - type_: Button type (default: Button)
/// - disabled: Whether the button is disabled
/// - aria_label: Accessible label (optional, for icon-only buttons)
/// - aria_describedby: ID of element describing the button
/// - on_click: Click handler
/// - on_keydown: Keydown handler (for custom keyboard interactions)
/// - children: Child nodes (button content)
///
/// Example:
/// ```
/// button([@luna.text("Save")])
/// button(disabled=true, [@luna.text("Disabled")])
/// ```
pub fn[E] button(
  type_? : ButtonType,
  disabled? : Bool,
  aria_label? : String,
  aria_describedby? : String,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("type", @luna.attr_static(type_.unwrap_or(Button).to_string())),
  ]
  if disabled is Some(true) {
    attrs.push(("disabled", @luna.attr_static("")))
    attrs.push(("aria-disabled", @luna.attr_static("true")))
  }
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  if aria_describedby is Some(id) {
    attrs.push(("aria-describedby", @luna.attr_static(id)))
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
/// Toggle button state
pub(all) enum ToggleState {
  Pressed // aria-pressed="true"
  NotPressed // aria-pressed="false"
}

///|
fn ToggleState::to_aria(self : ToggleState) -> String {
  match self {
    Pressed => "true"
    NotPressed => "false"
  }
}

///|
/// Create an accessible toggle button.
/// Toggle buttons have aria-pressed state.
///
/// Parameters:
/// - pressed: Current toggle state
/// - disabled: Whether the button is disabled
/// - aria_label: Accessible label
/// - on_click: Click handler (should toggle the state)
/// - on_keydown: Keydown handler (for custom keyboard interactions)
/// - children: Child nodes (button content - should NOT change based on state)
///
/// Note: The label should remain constant. Use aria-pressed to convey state.
///
/// Example:
/// ```
/// toggle_button(Pressed, [@luna.text("Mute")])
/// ```
pub fn[E] toggle_button(
  pressed : ToggleState,
  disabled? : Bool,
  aria_label? : String,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("type", @luna.attr_static("button")),
    ("aria-pressed", @luna.attr_static(pressed.to_aria())),
  ]
  if disabled is Some(true) {
    attrs.push(("disabled", @luna.attr_static("")))
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
  @luna.h("button", attrs, children)
}

///|
/// Dynamic toggle button with signal-based pressed state.
/// Uses dynamic aria-pressed attribute.
pub fn[E] toggle_button_dyn(
  pressed : @resource.Signal[Bool],
  disabled? : Bool,
  aria_label? : String,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("type", @luna.attr_static("button")),
    (
      "aria-pressed",
      @luna.attr_dynamic(fn() { if pressed.get() { "true" } else { "false" } }),
    ),
  ]
  if disabled is Some(true) {
    attrs.push(("disabled", @luna.attr_static("")))
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
  @luna.h("button", attrs, children)
}

///|
/// Menu button popup type
pub(all) enum PopupType {
  Menu // aria-haspopup="menu"
  Listbox // aria-haspopup="listbox"
  Tree // aria-haspopup="tree"
  Grid // aria-haspopup="grid"
  Dialog // aria-haspopup="dialog"
}

///|
fn PopupType::to_aria(self : PopupType) -> String {
  match self {
    Menu => "menu"
    Listbox => "listbox"
    Tree => "tree"
    Grid => "grid"
    Dialog => "dialog"
  }
}

///|
/// Create a menu button (button that opens a popup).
///
/// Parameters:
/// - popup_type: Type of popup this button controls
/// - expanded: Whether the popup is currently open
/// - controls: ID of the popup element
/// - aria_label: Accessible label
/// - on_click: Click handler
/// - on_keydown: Keydown handler (for arrow key navigation, Escape, etc.)
/// - children: Child nodes
///
/// Example:
/// ```
/// menu_button(Menu, false, controls="dropdown", [@luna.text("Options")])
/// ```
pub fn[E] menu_button(
  popup_type : PopupType,
  expanded : Bool,
  controls? : String,
  aria_label? : String,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("type", @luna.attr_static("button")),
    ("aria-haspopup", @luna.attr_static(popup_type.to_aria())),
    (
      "aria-expanded",
      @luna.attr_static(if expanded { "true" } else { "false" }),
    ),
  ]
  if controls is Some(id) {
    attrs.push(("aria-controls", @luna.attr_static(id)))
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
  @luna.h("button", attrs, children)
}

///|
/// Dynamic menu button with signal-based expanded state.
pub fn[E] menu_button_dyn(
  popup_type : PopupType,
  expanded : @resource.Signal[Bool],
  controls? : String,
  aria_label? : String,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("type", @luna.attr_static("button")),
    ("aria-haspopup", @luna.attr_static(popup_type.to_aria())),
    (
      "aria-expanded",
      @luna.attr_dynamic(fn() { if expanded.get() { "true" } else { "false" } }),
    ),
  ]
  if controls is Some(id) {
    attrs.push(("aria-controls", @luna.attr_static(id)))
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
  @luna.h("button", attrs, children)
}
