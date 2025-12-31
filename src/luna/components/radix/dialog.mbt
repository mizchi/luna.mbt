///|
/// Radix-style Dialog component for Luna (Headless)
/// Outputs semantic HTML with data-* attributes for external CSS styling

///|
/// Create a headless dialog root
/// Outputs: <div class="radix-dialog" data-state="...">children</div>
pub fn radix_dialog(
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
      ("class", @luna.attr_static("radix-dialog")),
      ("data-state", @luna.attr_static(state)),
    ],
    children,
  )
}

///|
/// Create a headless dialog trigger
/// Outputs: <button class="radix-dialog-trigger">children</button>
pub fn radix_dialog_trigger(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "button",
    [("class", @luna.attr_static("radix-dialog-trigger"))],
    children,
  )
}

///|
/// Create a headless dialog overlay
/// Outputs: <div class="radix-dialog-overlay"></div>
pub fn radix_dialog_overlay() -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-dialog-overlay"))], [])
}

///|
/// Create a headless dialog content
/// Outputs: <div class="radix-dialog-content" role="dialog">children</div>
pub fn radix_dialog_content(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-dialog-content")),
      ("role", @luna.attr_static("dialog")),
      ("aria-modal", @luna.attr_static("true")),
    ],
    children,
  )
}

///|
/// Create a headless dialog header
/// Outputs: <div class="radix-dialog-header">children</div>
pub fn radix_dialog_header(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-dialog-header"))],
    children,
  )
}

///|
/// Create a headless dialog title
/// Outputs: <h2 class="radix-dialog-title">children</h2>
pub fn radix_dialog_title(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h("h2", [("class", @luna.attr_static("radix-dialog-title"))], children)
}

///|
/// Create a headless dialog description
/// Outputs: <p class="radix-dialog-description">children</p>
pub fn radix_dialog_description(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "p",
    [("class", @luna.attr_static("radix-dialog-description"))],
    children,
  )
}

///|
/// Create a headless dialog footer
/// Outputs: <div class="radix-dialog-footer">children</div>
pub fn radix_dialog_footer(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-dialog-footer"))],
    children,
  )
}

///|
/// Create a headless dialog close button
/// Outputs: <button class="radix-dialog-close">children</button>
pub fn radix_dialog_close(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "button",
    [("class", @luna.attr_static("radix-dialog-close"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the dialog component
fn dialog_styles() -> String {
  let css =
    #|:host {
    #|  display: contents;
    #|}
    #|
    #|.dialog-overlay {
    #|  position: fixed;
    #|  inset: 0;
    #|  background: rgba(0,0,0,0.5);
    #|  z-index: 50;
    #|}
    #|
    #|.dialog-content {
    #|  position: fixed;
    #|  left: 50%;
    #|  top: 50%;
    #|  transform: translate(-50%, -50%);
    #|  max-width: 32rem;
    #|  width: 100%;
    #|  max-height: 85vh;
    #|  background: white;
    #|  border-radius: 8px;
    #|  box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25);
    #|  z-index: 51;
    #|  padding: 1.5rem;
    #|  overflow: auto;
    #|}
    #|
    #|.dialog-header {
    #|  display: flex;
    #|  flex-direction: column;
    #|  gap: 0.25rem;
    #|  margin-bottom: 1rem;
    #|}
    #|
    #|.dialog-title {
    #|  margin: 0;
    #|  font-size: 1.125rem;
    #|  font-weight: 600;
    #|  color: #18181b;
    #|}
    #|
    #|.dialog-description {
    #|  margin: 0;
    #|  font-size: 0.875rem;
    #|  color: #71717a;
    #|}
    #|
    #|.dialog-footer {
    #|  display: flex;
    #|  justify-content: flex-end;
    #|  gap: 0.5rem;
    #|  margin-top: 1.5rem;
    #|}
    #|
    #|.dialog-close {
    #|  position: absolute;
    #|  top: 1rem;
    #|  right: 1rem;
    #|  padding: 0.25rem;
    #|  background: transparent;
    #|  border: none;
    #|  cursor: pointer;
    #|  opacity: 0.7;
    #|  transition: opacity 0.15s;
    #|}
    #|
    #|.dialog-close:hover {
    #|  opacity: 1;
    #|}
  css
}

///|
/// Create a styled dialog with Declarative Shadow DOM
pub fn radix_dialog_styled(
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
    None => dialog_styles()
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
    "radix-dialog",
    [("data-state", @luna.attr_static(state))],
    all_children,
  )
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a dialog overlay with luna/css atomic styles
pub fn radix_dialog_overlay_ucss() -> @luna.Node[Unit] {
  let class_names = dialog_overlay_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], [])
}

///|
/// Create a dialog content with luna/css atomic styles
pub fn radix_dialog_content_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = dialog_content_styles()
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("role", @luna.attr_static("dialog")),
      ("aria-modal", @luna.attr_static("true")),
    ],
    children,
  )
}

///|
/// Create a dialog header with luna/css atomic styles
pub fn radix_dialog_header_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = dialog_header_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a dialog title with luna/css atomic styles
pub fn radix_dialog_title_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = dialog_title_styles()
  @luna.h("h2", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a dialog description with luna/css atomic styles
pub fn radix_dialog_description_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = dialog_description_styles()
  @luna.h("p", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a dialog footer with luna/css atomic styles
pub fn radix_dialog_footer_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = dialog_footer_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}
