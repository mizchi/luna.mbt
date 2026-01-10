///|
/// APG Dialog (Modal) Pattern
/// https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/
///
/// A dialog is a window overlaid on the primary window or another dialog.
/// Modal dialogs prevent interaction with content outside.
///
/// Keyboard Interaction:
/// - Tab: Move focus to next element inside dialog (trapped)
/// - Shift+Tab: Move focus to previous element inside dialog (trapped)
/// - Escape: Close the dialog
///
/// ARIA:
/// - role="dialog" with aria-modal="true"
/// - aria-labelledby or aria-label (required)
/// - aria-describedby (optional)

///|
/// Create a modal dialog container.
///
/// Parameters:
/// - aria_label: Accessible label for the dialog
/// - aria_labelledby: ID of the title element
/// - aria_describedby: ID of the description element
/// - open: Whether the dialog is currently open
/// - on_keydown: Keydown handler (for Escape key to close)
/// - children: Dialog content
///
/// Example:
/// ```
/// dialog(
///   aria_labelledby="dialog-title",
///   open=true,
///   [
///     h2(id="dialog-title", [text("Confirm")]),
///     p([text("Are you sure?")]),
///     button([text("Yes")]),
///     button([text("No")])
///   ]
/// )
/// ```
pub fn[E] dialog(
  aria_label? : String,
  aria_labelledby? : String,
  aria_describedby? : String,
  open : Bool,
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("dialog")),
    ("aria-modal", @luna.attr_static("true")),
  ]
  match aria_label {
    Some(label) => attrs.push(("aria-label", @luna.attr_static(label)))
    None => ()
  }
  match aria_labelledby {
    Some(id) => attrs.push(("aria-labelledby", @luna.attr_static(id)))
    None => ()
  }
  match aria_describedby {
    Some(id) => attrs.push(("aria-describedby", @luna.attr_static(id)))
    None => ()
  }
  match on_keydown {
    Some(handler) => attrs.push(("keydown", @luna.attr_handler(handler)))
    None => ()
  }
  if not(open) {
    attrs.push(("hidden", @luna.attr_static("")))
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a dynamic dialog with signal-based open state.
pub fn[E] dialog_dyn(
  aria_label? : String,
  aria_labelledby? : String,
  aria_describedby? : String,
  open : @signal.Signal[Bool],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("dialog")),
    ("aria-modal", @luna.attr_static("true")),
  ]
  match aria_label {
    Some(label) => attrs.push(("aria-label", @luna.attr_static(label)))
    None => ()
  }
  match aria_labelledby {
    Some(id) => attrs.push(("aria-labelledby", @luna.attr_static(id)))
    None => ()
  }
  match aria_describedby {
    Some(id) => attrs.push(("aria-describedby", @luna.attr_static(id)))
    None => ()
  }
  match on_keydown {
    Some(handler) => attrs.push(("keydown", @luna.attr_handler(handler)))
    None => ()
  }
  @luna.show(fn() { open.get() }, fn() { @luna.h("div", attrs, children) })
}

///|
/// Create a native HTML dialog element.
/// Uses <dialog> element for better browser support and behavior.
pub fn[E] dialog_native(
  id? : String,
  aria_labelledby? : String,
  open : Bool,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = []
  match id {
    Some(i) => attrs.push(("id", @luna.attr_static(i)))
    None => ()
  }
  match aria_labelledby {
    Some(lid) => attrs.push(("aria-labelledby", @luna.attr_static(lid)))
    None => ()
  }
  if open {
    attrs.push(("open", @luna.attr_static("")))
  }
  @luna.h("dialog", attrs, children)
}

///|
/// Create an alert dialog (interrupting dialog for important messages).
/// Uses role="alertdialog" for urgent messages that require user action.
///
/// Parameters:
/// - aria_label: Accessible label
/// - aria_labelledby: ID of title element
/// - aria_describedby: ID of description element (recommended)
/// - open: Whether the dialog is open
/// - on_keydown: Keydown handler (for Escape key to close)
/// - children: Dialog content
pub fn[E] alert_dialog(
  aria_label? : String,
  aria_labelledby? : String,
  aria_describedby? : String,
  open : Bool,
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("alertdialog")),
    ("aria-modal", @luna.attr_static("true")),
  ]
  match aria_label {
    Some(label) => attrs.push(("aria-label", @luna.attr_static(label)))
    None => ()
  }
  match aria_labelledby {
    Some(id) => attrs.push(("aria-labelledby", @luna.attr_static(id)))
    None => ()
  }
  match aria_describedby {
    Some(id) => attrs.push(("aria-describedby", @luna.attr_static(id)))
    None => ()
  }
  match on_keydown {
    Some(handler) => attrs.push(("keydown", @luna.attr_handler(handler)))
    None => ()
  }
  if not(open) {
    attrs.push(("hidden", @luna.attr_static("")))
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a dialog backdrop/overlay.
/// Used to visually obscure content behind the dialog.
pub fn[E] dialog_backdrop(
  on_click? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("data-dialog-backdrop", @luna.attr_static("")),
    ("aria-hidden", @luna.attr_static("true")),
  ]
  match on_click {
    Some(handler) => attrs.push(("click", @luna.attr_handler(handler)))
    None => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a complete dialog with backdrop.
/// Wraps dialog content with backdrop for modal behavior.
pub fn[E] modal(
  aria_label? : String,
  aria_labelledby? : String,
  open : Bool,
  on_backdrop_click? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  if not(open) {
    return @luna.fragment([])
  }
  let dialog_node = dialog(aria_label?, aria_labelledby?, true, children)
  let backdrop = match on_backdrop_click {
    Some(handler) => dialog_backdrop(on_click=handler, [])
    None => dialog_backdrop([])
  }
  @luna.fragment([backdrop, dialog_node])
}
