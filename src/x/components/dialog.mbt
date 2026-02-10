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
  children : Array[@luna.Node[E, String]],
) -> @luna.Node[E, String] {
  let attrs : Array[(String, @luna.Attr[E, String])] = [
    ("role", @luna.attr_static("dialog")),
    ("aria-modal", @luna.attr_static("true")),
    ("tabindex", @luna.attr_static("-1")), // Allow focus for keyboard events
  ]
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  if aria_labelledby is Some(id) {
    attrs.push(("aria-labelledby", @luna.attr_static(id)))
  }
  if aria_describedby is Some(id) {
    attrs.push(("aria-describedby", @luna.attr_static(id)))
  }
  if on_keydown is Some(handler) {
    attrs.push(("keydown", @luna.attr_handler(handler)))
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
  open : @resource.Signal[Bool],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E, String]],
) -> @luna.Node[E, String] {
  let attrs : Array[(String, @luna.Attr[E, String])] = [
    ("role", @luna.attr_static("dialog")),
    ("aria-modal", @luna.attr_static("true")),
    ("tabindex", @luna.attr_static("-1")), // Allow focus for keyboard events
  ]
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  if aria_labelledby is Some(id) {
    attrs.push(("aria-labelledby", @luna.attr_static(id)))
  }
  if aria_describedby is Some(id) {
    attrs.push(("aria-describedby", @luna.attr_static(id)))
  }
  if on_keydown is Some(handler) {
    attrs.push(("keydown", @luna.attr_handler(handler)))
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
  children : Array[@luna.Node[E, String]],
) -> @luna.Node[E, String] {
  let attrs : Array[(String, @luna.Attr[E, String])] = []
  if id is Some(i) {
    attrs.push(("id", @luna.attr_static(i)))
  }
  if aria_labelledby is Some(lid) {
    attrs.push(("aria-labelledby", @luna.attr_static(lid)))
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
  children : Array[@luna.Node[E, String]],
) -> @luna.Node[E, String] {
  let attrs : Array[(String, @luna.Attr[E, String])] = [
    ("role", @luna.attr_static("alertdialog")),
    ("aria-modal", @luna.attr_static("true")),
  ]
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  if aria_labelledby is Some(id) {
    attrs.push(("aria-labelledby", @luna.attr_static(id)))
  }
  if aria_describedby is Some(id) {
    attrs.push(("aria-describedby", @luna.attr_static(id)))
  }
  if on_keydown is Some(handler) {
    attrs.push(("keydown", @luna.attr_handler(handler)))
  }
  if not(open) {
    attrs.push(("hidden", @luna.attr_static("")))
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a dynamic alert dialog with signal-based open state.
pub fn[E] alert_dialog_dyn(
  aria_label? : String,
  aria_labelledby? : String,
  aria_describedby? : String,
  open : @resource.Signal[Bool],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E, String]],
) -> @luna.Node[E, String] {
  let attrs : Array[(String, @luna.Attr[E, String])] = [
    ("role", @luna.attr_static("alertdialog")),
    ("aria-modal", @luna.attr_static("true")),
  ]
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  if aria_labelledby is Some(id) {
    attrs.push(("aria-labelledby", @luna.attr_static(id)))
  }
  if aria_describedby is Some(id) {
    attrs.push(("aria-describedby", @luna.attr_static(id)))
  }
  if on_keydown is Some(handler) {
    attrs.push(("keydown", @luna.attr_handler(handler)))
  }
  @luna.show(fn() { open.get() }, fn() { @luna.h("div", attrs, children) })
}

///|
/// Create a confirmation dialog (common Alert Dialog use case).
/// Returns a fragment with backdrop and dialog.
///
/// Parameters:
/// - id: Base ID for the dialog
/// - title: Dialog title
/// - message: Confirmation message
/// - confirm_label: Label for confirm button (default: "OK")
/// - cancel_label: Label for cancel button (default: "Cancel")
/// - open: Signal controlling visibility
/// - on_confirm: Called when user confirms
/// - on_cancel: Called when user cancels
pub fn confirm_dialog(
  id : String,
  title : String,
  message : String,
  confirm_label? : String,
  cancel_label? : String,
  open : @resource.Signal[Bool],
  on_confirm : () -> Unit,
  on_cancel : () -> Unit,
) -> @luna.Node[@js.Any, String] {
  let confirm_text = confirm_label.unwrap_or("OK")
  let cancel_text = cancel_label.unwrap_or("Cancel")
  let title_id = id + "-title"
  let message_id = id + "-message"
  let close = fn() { open.set(false) }
  @luna.show(fn() { open.get() }, fn() {
    @luna.fragment([
      // Backdrop - does not close on click for alert dialogs
      @luna.h(
        "div",
        [
          ("class", @luna.attr_static("dialog-backdrop")),
          ("aria-hidden", @luna.attr_static("true")),
        ],
        [],
      ),
      // Alert Dialog
      @luna.h(
        "div",
        [
          ("role", @luna.attr_static("alertdialog")),
          ("aria-modal", @luna.attr_static("true")),
          ("aria-labelledby", @luna.attr_static(title_id)),
          ("aria-describedby", @luna.attr_static(message_id)),
          ("class", @luna.attr_static("alert-dialog")),
        ],
        [
          @luna.h("h2", [("id", @luna.attr_static(title_id))], [
            @luna.text(title),
          ]),
          @luna.h("p", [("id", @luna.attr_static(message_id))], [
            @luna.text(message),
          ]),
          @luna.h("div", [("class", @luna.attr_static("dialog-actions"))], [
            // Cancel button (should be focused first for safety)
            @luna.h(
              "button",
              [
                ("type", @luna.attr_static("button")),
                ("class", @luna.attr_static("dialog-cancel")),
                (
                  "click",
                  @luna.attr_handler(
                    @luna.handler(fn(_) {
                      close()
                      on_cancel()
                    }),
                  ),
                ),
              ],
              [@luna.text(cancel_text)],
            ),
            // Confirm button
            @luna.h(
              "button",
              [
                ("type", @luna.attr_static("button")),
                ("class", @luna.attr_static("dialog-confirm")),
                (
                  "click",
                  @luna.attr_handler(
                    @luna.handler(fn(_) {
                      close()
                      on_confirm()
                    }),
                  ),
                ),
              ],
              [@luna.text(confirm_text)],
            ),
          ]),
        ],
      ),
    ])
  })
}

///|
/// Create a dialog backdrop/overlay.
/// Used to visually obscure content behind the dialog.
pub fn[E] dialog_backdrop(
  on_click? : @luna.EventHandler[E],
  children : Array[@luna.Node[E, String]],
) -> @luna.Node[E, String] {
  let attrs : Array[(String, @luna.Attr[E, String])] = [
    ("data-dialog-backdrop", @luna.attr_static("")),
    ("aria-hidden", @luna.attr_static("true")),
  ]
  if on_click is Some(handler) {
    attrs.push(("click", @luna.attr_handler(handler)))
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
  children : Array[@luna.Node[E, String]],
) -> @luna.Node[E, String] {
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

// =============================================================================
// Focus Management Utilities
// =============================================================================

///|
/// Selector for focusable elements within a dialog.
let focusable_selector : String = "button, [href], input, select, textarea, [tabindex]:not([tabindex=\"-1\"])"

///|
/// Get all focusable elements within a dialog.
/// Returns a JavaScript NodeList.
fn get_focusable_elements(dialog_id : String) -> @js.Any {
  let doc = @js.global_this()._get("document")
  let dialog = doc._call("getElementById", [@js.any(dialog_id)])
  dialog._call("querySelectorAll", [@js.any(focusable_selector)])
}

///|
/// Focus the first focusable element inside the dialog.
/// Call this when the dialog opens.
pub fn focus_first_in_dialog(dialog_id : String) -> Unit {
  let elements = get_focusable_elements(dialog_id)
  let length : Int = elements._get("length").cast()
  if length > 0 {
    let first = elements._call("item", [@js.any(0)])
    let _ = first._call("focus", [])
  }
}

///|
/// Focus the dialog container itself.
/// Useful when there are no focusable elements inside.
pub fn focus_dialog(dialog_id : String) -> Unit {
  let doc = @js.global_this()._get("document")
  let dialog = doc._call("getElementById", [@js.any(dialog_id)])
  let _ = dialog._call("focus", [])
}

///|
/// Store the currently focused element for later restoration.
/// Call this before opening the dialog.
pub fn store_active_element() -> @js.Any {
  let doc = @js.global_this()._get("document")
  doc._get("activeElement")
}

///|
/// Restore focus to a previously stored element.
/// Call this when the dialog closes.
pub fn restore_focus(element : @js.Any) -> Unit {
  let _ = element._call("focus", [])
}

///|
/// Create a keydown handler for dialog with focus trap and Escape support.
///
/// Parameters:
/// - dialog_id: ID of the dialog element
/// - on_close: Callback when Escape is pressed
///
/// Handles:
/// - Escape: Calls on_close
/// - Tab: Moves focus to next element, wrapping at end
/// - Shift+Tab: Moves focus to previous element, wrapping at start
pub fn make_dialog_keydown_handler(
  dialog_id : String,
  on_close : () -> Unit,
) -> @luna.EventHandler[@js.Any] {
  @luna.handler(fn(e : @js.Any) {
    let key : String = e._get("key").cast()
    match key {
      "Escape" => {
        let _ = e._call("preventDefault", [])
        on_close()
      }
      "Tab" => {
        let elements = get_focusable_elements(dialog_id)
        let length : Int = elements._get("length").cast()
        if length == 0 {
          let _ = e._call("preventDefault", [])
          return
        }
        let shift_key : Bool = e._get("shiftKey").cast()
        let doc = @js.global_this()._get("document")
        let active = doc._get("activeElement")
        let first = elements._call("item", [@js.any(0)])
        let last = elements._call("item", [@js.any(length - 1)])
        if shift_key {
          // Shift+Tab: wrap from first to last
          if @js.any(active) == @js.any(first) {
            let _ = e._call("preventDefault", [])
            let _ = last._call("focus", [])
          }
          // Tab: wrap from last to first
        } else if @js.any(active) == @js.any(last) {
          let _ = e._call("preventDefault", [])
          let _ = first._call("focus", [])
        }
      }
      _ => ()
    }
  })
}

///|
/// Create a complete interactive modal dialog with focus management.
///
/// Features:
/// - Focus trap (Tab/Shift+Tab cycles within dialog)
/// - Escape key closes dialog
/// - Focus moves to first element on open
/// - Focus returns to trigger on close
///
/// Parameters:
/// - id: Dialog element ID
/// - aria_label: Accessible label
/// - aria_labelledby: ID of title element
/// - open: Signal controlling visibility
/// - on_close: Called when dialog should close
/// - trigger_ref: Reference to store trigger element for focus restoration
/// - children: Dialog content
pub fn dialog_interactive(
  id : String,
  aria_label? : String,
  aria_labelledby? : String,
  aria_describedby? : String,
  open : @resource.Signal[Bool],
  on_close : () -> Unit,
  children : Array[@luna.Node[@js.Any, String]],
) -> @luna.Node[@js.Any, String] {
  // Store trigger element when showing
  let trigger_ref : Ref[@js.Any] = { val: @js.null() }
  let close_and_restore = fn() {
    open.set(false)
    on_close()
    // Restore focus to trigger
    restore_focus(trigger_ref.val)
  }
  let keydown_handler = make_dialog_keydown_handler(id, close_and_restore)
  @luna.show(fn() { open.get() }, fn() {
    // Store current focus before showing dialog
    trigger_ref.val = store_active_element()
    // Focus first element after render (use setTimeout for next tick)
    let window = @js.global_this()
    let _ = window._call("setTimeout", [
      @js.any(fn() { focus_first_in_dialog(id) }),
      @js.any(0),
    ])
    @luna.fragment([
      // Backdrop
      @luna.h(
        "div",
        [
          ("class", @luna.attr_static("dialog-backdrop")),
          ("aria-hidden", @luna.attr_static("true")),
          (
            "click",
            @luna.attr_handler(@luna.handler(fn(_) { close_and_restore() })),
          ),
        ],
        [],
      ),
      // Dialog
      @luna.h(
        "div",
        [
          ("id", @luna.attr_static(id)),
          ("role", @luna.attr_static("dialog")),
          ("aria-modal", @luna.attr_static("true")),
          ("tabindex", @luna.attr_static("-1")),
          ("aria-label", @luna.attr_static(aria_label.unwrap_or(""))),
          ("aria-labelledby", @luna.attr_static(aria_labelledby.unwrap_or(""))),
          (
            "aria-describedby",
            @luna.attr_static(aria_describedby.unwrap_or("")),
          ),
          ("keydown", @luna.attr_handler(keydown_handler)),
        ],
        children,
      ),
    ])
  })
}
