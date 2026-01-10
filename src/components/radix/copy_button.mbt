///|
/// CopyButton component for Luna (Headless)
/// Button to copy text to clipboard with feedback

///|
/// CopyButton state enum
pub enum CopyButtonState {
  Idle
  Copied
  Error
}

///|
/// Create a headless copy button
/// Outputs: <button class="radix-copy-button" data-state="...">children</button>
pub fn radix_copy_button(
  state? : CopyButtonState,
  value? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let state_str = match state {
    Some(Copied) => "copied"
    Some(Error) => "error"
    _ => "idle"
  }
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-copy-button")),
    ("type", @luna.attr_static("button")),
    ("data-state", @luna.attr_static(state_str)),
  ]
  match value {
    Some(v) => attrs.push(("data-value", @luna.attr_static(v)))
    None => ()
  }
  @luna.h("button", attrs, children)
}

///|
/// Create a headless copy button icon (idle state)
/// Outputs: <span class="radix-copy-button-icon" data-state="idle">children</span>
pub fn radix_copy_button_icon_idle(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "span",
    [
      ("class", @luna.attr_static("radix-copy-button-icon")),
      ("data-state", @luna.attr_static("idle")),
    ],
    children,
  )
}

///|
/// Create a headless copy button icon (copied state)
/// Outputs: <span class="radix-copy-button-icon" data-state="copied">children</span>
pub fn radix_copy_button_icon_copied(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "span",
    [
      ("class", @luna.attr_static("radix-copy-button-icon")),
      ("data-state", @luna.attr_static("copied")),
    ],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the copy button component
fn copy_button_styles() -> String {
  let css =
    #|:host {
    #|  display: inline-block;
    #|}
    #|
    #|.copy-button {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  width: 2rem;
    #|  height: 2rem;
    #|  padding: 0;
    #|  background: transparent;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|  cursor: pointer;
    #|  color: #71717a;
    #|  transition: all 0.15s ease;
    #|}
    #|
    #|.copy-button:hover {
    #|  background: #f4f4f5;
    #|  color: #18181b;
    #|}
    #|
    #|.copy-button[data-state="copied"] {
    #|  color: #22c55e;
    #|  border-color: #22c55e;
    #|}
    #|
    #|.copy-button[data-state="error"] {
    #|  color: #ef4444;
    #|  border-color: #ef4444;
    #|}
    #|
    #|.copy-button-icon {
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  width: 1rem;
    #|  height: 1rem;
    #|}
    #|
    #|.copy-button[data-state="idle"] .copy-button-icon[data-state="copied"],
    #|.copy-button[data-state="copied"] .copy-button-icon[data-state="idle"],
    #|.copy-button[data-state="error"] .copy-button-icon[data-state="idle"] {
    #|  display: none;
    #|}
  css
}

///|
/// Create a styled copy button with Declarative Shadow DOM
pub fn radix_copy_button_styled(
  state? : CopyButtonState,
  value? : String,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let state_str = match state {
    Some(Copied) => "copied"
    Some(Error) => "error"
    _ => "idle"
  }
  let css = match styles {
    Some(s) => s
    None => copy_button_styles()
  }
  let template_children : Array[@luna.Node[Unit]] = [
    @luna.h("style", [], [@luna.text(css)]),
    @luna.h("slot", [], []),
  ]
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
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("data-state", @luna.attr_static(state_str)),
  ]
  match value {
    Some(v) => attrs.push(("data-value", @luna.attr_static(v)))
    None => ()
  }
  @luna.h("radix-copy-button", attrs, all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a copy button with luna/css atomic styles
pub fn radix_copy_button_ucss(
  state? : CopyButtonState,
  value? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let state_str = match state {
    Some(Copied) => "copied"
    Some(Error) => "error"
    _ => "idle"
  }
  let class_names = copy_button_base_styles(state)
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("type", @luna.attr_static("button")),
    ("data-state", @luna.attr_static(state_str)),
  ]
  match value {
    Some(v) => attrs.push(("data-value", @luna.attr_static(v)))
    None => ()
  }
  @luna.h("button", attrs, children)
}

///|
/// Create a copy button icon with luna/css atomic styles
pub fn radix_copy_button_icon_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = copy_button_icon_styles()
  @luna.h("span", [("class", @luna.attr_static(class_names))], children)
}
