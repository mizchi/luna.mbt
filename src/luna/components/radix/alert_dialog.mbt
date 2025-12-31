///|
/// Radix-style AlertDialog component for Luna (Headless)
/// A modal dialog for confirmations with cancel/confirm actions

///|
/// Create a headless alert dialog root
/// Outputs: <div class="radix-alert-dialog" data-state="...">children</div>
pub fn radix_alert_dialog(
  open? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_open = match open {
    Some(true) => true
    _ => false
  }
  let state = if is_open { "open" } else { "closed" }

  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-alert-dialog")),
      ("data-state", @luna.attr_static(state)),
    ],
    children,
  )
}

///|
/// Create a headless alert dialog trigger
/// Outputs: <button class="radix-alert-dialog-trigger">children</button>
pub fn radix_alert_dialog_trigger(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "button",
    [("class", @luna.attr_static("radix-alert-dialog-trigger"))],
    children,
  )
}

///|
/// Create a headless alert dialog overlay
/// Outputs: <div class="radix-alert-dialog-overlay"></div>
pub fn radix_alert_dialog_overlay() -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-alert-dialog-overlay"))],
    [],
  )
}

///|
/// Create a headless alert dialog content
/// Outputs: <div class="radix-alert-dialog-content" role="alertdialog">children</div>
pub fn radix_alert_dialog_content(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-alert-dialog-content")),
      ("role", @luna.attr_static("alertdialog")),
      ("aria-modal", @luna.attr_static("true")),
    ],
    children,
  )
}

///|
/// Create a headless alert dialog header
/// Outputs: <div class="radix-alert-dialog-header">children</div>
pub fn radix_alert_dialog_header(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-alert-dialog-header"))],
    children,
  )
}

///|
/// Create a headless alert dialog title
/// Outputs: <h2 class="radix-alert-dialog-title">children</h2>
pub fn radix_alert_dialog_title(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "h2",
    [("class", @luna.attr_static("radix-alert-dialog-title"))],
    children,
  )
}

///|
/// Create a headless alert dialog description
/// Outputs: <p class="radix-alert-dialog-description">children</p>
pub fn radix_alert_dialog_description(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "p",
    [("class", @luna.attr_static("radix-alert-dialog-description"))],
    children,
  )
}

///|
/// Create a headless alert dialog footer
/// Outputs: <div class="radix-alert-dialog-footer">children</div>
pub fn radix_alert_dialog_footer(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-alert-dialog-footer"))],
    children,
  )
}

///|
/// Create a headless alert dialog cancel button
/// Outputs: <button class="radix-alert-dialog-cancel">children</button>
pub fn radix_alert_dialog_cancel(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "button",
    [("class", @luna.attr_static("radix-alert-dialog-cancel"))],
    children,
  )
}

///|
/// Create a headless alert dialog action button
/// Outputs: <button class="radix-alert-dialog-action">children</button>
pub fn radix_alert_dialog_action(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "button",
    [("class", @luna.attr_static("radix-alert-dialog-action"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the alert dialog component
fn alert_dialog_styles() -> String {
  let css =
    #|:host {
    #|  display: contents;
    #|}
    #|
    #|.alert-dialog-overlay {
    #|  position: fixed;
    #|  inset: 0;
    #|  background: rgba(0,0,0,0.5);
    #|  z-index: 50;
    #|}
    #|
    #|.alert-dialog-content {
    #|  position: fixed;
    #|  left: 50%;
    #|  top: 50%;
    #|  transform: translate(-50%, -50%);
    #|  max-width: 32rem;
    #|  width: 100%;
    #|  background: white;
    #|  border-radius: 8px;
    #|  box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25);
    #|  z-index: 51;
    #|  padding: 1.5rem;
    #|}
    #|
    #|.alert-dialog-header {
    #|  display: flex;
    #|  flex-direction: column;
    #|  gap: 0.5rem;
    #|  text-align: center;
    #|}
    #|
    #|.alert-dialog-title {
    #|  margin: 0;
    #|  font-size: 1.125rem;
    #|  font-weight: 600;
    #|  color: #18181b;
    #|}
    #|
    #|.alert-dialog-description {
    #|  margin: 0;
    #|  font-size: 0.875rem;
    #|  color: #71717a;
    #|}
    #|
    #|.alert-dialog-footer {
    #|  display: flex;
    #|  justify-content: center;
    #|  gap: 0.5rem;
    #|  margin-top: 1.5rem;
    #|}
    #|
    #|.alert-dialog-cancel {
    #|  padding: 0.5rem 1rem;
    #|  font-size: 0.875rem;
    #|  font-weight: 500;
    #|  background: white;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|  cursor: pointer;
    #|  transition: background 0.15s ease;
    #|}
    #|
    #|.alert-dialog-cancel:hover {
    #|  background: #f4f4f5;
    #|}
    #|
    #|.alert-dialog-action {
    #|  padding: 0.5rem 1rem;
    #|  font-size: 0.875rem;
    #|  font-weight: 500;
    #|  color: white;
    #|  background: #dc2626;
    #|  border: none;
    #|  border-radius: 6px;
    #|  cursor: pointer;
    #|  transition: background 0.15s ease;
    #|}
    #|
    #|.alert-dialog-action:hover {
    #|  background: #b91c1c;
    #|}
  css
}

///|
/// Create a styled alert dialog with Declarative Shadow DOM
pub fn radix_alert_dialog_styled(
  open? : Bool,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_open = match open {
    Some(true) => true
    _ => false
  }
  let state = if is_open { "open" } else { "closed" }

  let css = match styles {
    Some(s) => s
    None => alert_dialog_styles()
  }

  // Build template content
  let template_children : Array[@luna.Node[Unit]] = [
    @luna.h("style", [], [@luna.text(css)]),
    @luna.h("slot", [], []),
  ]

  // Create DSD structure
  let all_children : Array[@luna.Node[Unit]] = [
    @luna.h(
      "template",
      [("shadowrootmode", @luna.attr_static("open"))],
      template_children,
    ),
  ]

  for child in children {
    all_children.push(child)
  }

  @luna.h(
    "radix-alert-dialog",
    [("data-state", @luna.attr_static(state))],
    all_children,
  )
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create an alert dialog overlay with luna/css atomic styles
pub fn radix_alert_dialog_overlay_ucss() -> @luna.Node[Unit] {
  let class_names = alert_dialog_overlay_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], [])
}

///|
/// Create an alert dialog content with luna/css atomic styles
pub fn radix_alert_dialog_content_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = alert_dialog_content_styles()
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("role", @luna.attr_static("alertdialog")),
      ("aria-modal", @luna.attr_static("true")),
    ],
    children,
  )
}

///|
/// Create an alert dialog header with luna/css atomic styles
pub fn radix_alert_dialog_header_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = alert_dialog_header_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create an alert dialog title with luna/css atomic styles
pub fn radix_alert_dialog_title_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = alert_dialog_title_styles()
  @luna.h("h2", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create an alert dialog description with luna/css atomic styles
pub fn radix_alert_dialog_description_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = alert_dialog_description_styles()
  @luna.h("p", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create an alert dialog footer with luna/css atomic styles
pub fn radix_alert_dialog_footer_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = alert_dialog_footer_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create an alert dialog cancel button with luna/css atomic styles
pub fn radix_alert_dialog_cancel_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = alert_dialog_cancel_styles()
  @luna.h("button", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create an alert dialog action button with luna/css atomic styles
pub fn radix_alert_dialog_action_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = alert_dialog_action_styles()
  @luna.h("button", [("class", @luna.attr_static(class_names))], children)
}
