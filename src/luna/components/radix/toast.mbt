///|
/// Radix-style Toast component for Luna (Headless)
/// Outputs semantic HTML with data-* attributes for external CSS styling

///|
/// Toast variant
pub(all) enum ToastVariant {
  Default
  Destructive
  Success
}

///|
pub fn ToastVariant::to_string(self : ToastVariant) -> String {
  match self {
    Default => "default"
    Destructive => "destructive"
    Success => "success"
  }
}

///|
/// Create a headless toast provider (container for toasts)
/// Outputs: <div class="radix-toast-provider">children</div>
pub fn radix_toast_provider(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-toast-provider"))],
    children,
  )
}

///|
/// Create a headless toast viewport (where toasts appear)
/// Outputs: <div class="radix-toast-viewport">children</div>
pub fn radix_toast_viewport(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-toast-viewport")),
      ("role", @luna.attr_static("region")),
      ("aria-live", @luna.attr_static("polite")),
    ],
    children,
  )
}

///|
/// Create a headless toast
/// Outputs: <div class="radix-toast" data-variant="..." data-state="...">children</div>
pub fn radix_toast(
  variant? : ToastVariant,
  open? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let variant_val = match variant {
    Some(v) => v
    None => Default
  }
  let is_open = match open {
    Some(true) => true
    _ => false
  }
  let state = if is_open { "open" } else { "closed" }
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-toast")),
      ("role", @luna.attr_static("alert")),
      ("data-variant", @luna.attr_static(variant_val.to_string())),
      ("data-state", @luna.attr_static(state)),
    ],
    children,
  )
}

///|
/// Create a headless toast title
/// Outputs: <div class="radix-toast-title">children</div>
pub fn radix_toast_title(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-toast-title"))], children)
}

///|
/// Create a headless toast description
/// Outputs: <div class="radix-toast-description">children</div>
pub fn radix_toast_description(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-toast-description"))],
    children,
  )
}

///|
/// Create a headless toast action button
/// Outputs: <button class="radix-toast-action">children</button>
pub fn radix_toast_action(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "button",
    [("class", @luna.attr_static("radix-toast-action"))],
    children,
  )
}

///|
/// Create a headless toast close button
/// Outputs: <button class="radix-toast-close">children</button>
pub fn radix_toast_close(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "button",
    [("class", @luna.attr_static("radix-toast-close"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the toast component
fn toast_styles() -> String {
  let css =
    #|:host {
    #|  display: contents;
    #|}
    #|
    #|.toast-viewport {
    #|  position: fixed;
    #|  bottom: 0;
    #|  right: 0;
    #|  display: flex;
    #|  flex-direction: column;
    #|  gap: 0.5rem;
    #|  padding: 1rem;
    #|  max-height: 100vh;
    #|  width: 100%;
    #|  max-width: 420px;
    #|  z-index: 100;
    #|}
    #|
    #|.toast {
    #|  display: flex;
    #|  align-items: flex-start;
    #|  gap: 0.75rem;
    #|  padding: 1rem;
    #|  background: white;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 8px;
    #|  box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);
    #|}
    #|
    #|.toast[data-variant="destructive"] {
    #|  background: #fef2f2;
    #|  border-color: #fecaca;
    #|  color: #991b1b;
    #|}
    #|
    #|.toast[data-variant="success"] {
    #|  background: #f0fdf4;
    #|  border-color: #bbf7d0;
    #|  color: #166534;
    #|}
    #|
    #|.toast-title {
    #|  font-weight: 600;
    #|  font-size: 0.875rem;
    #|}
    #|
    #|.toast-description {
    #|  font-size: 0.875rem;
    #|  color: #71717a;
    #|}
    #|
    #|.toast[data-variant="destructive"] .toast-description {
    #|  color: #b91c1c;
    #|}
    #|
    #|.toast[data-variant="success"] .toast-description {
    #|  color: #15803d;
    #|}
    #|
    #|.toast-action {
    #|  padding: 0.25rem 0.75rem;
    #|  font-size: 0.75rem;
    #|  font-weight: 500;
    #|  background: transparent;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 4px;
    #|  cursor: pointer;
    #|  transition: background 0.15s ease;
    #|}
    #|
    #|.toast-action:hover {
    #|  background: #f4f4f5;
    #|}
    #|
    #|.toast-close {
    #|  padding: 0.25rem;
    #|  background: transparent;
    #|  border: none;
    #|  cursor: pointer;
    #|  opacity: 0.7;
    #|  transition: opacity 0.15s;
    #|}
    #|
    #|.toast-close:hover {
    #|  opacity: 1;
    #|}
  css
}

///|
/// Create a styled toast with Declarative Shadow DOM
pub fn radix_toast_styled(
  variant? : ToastVariant,
  open? : Bool,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let variant_val = match variant {
    Some(v) => v
    None => Default
  }
  let is_open = match open {
    Some(true) => true
    _ => false
  }
  let state = if is_open { "open" } else { "closed" }
  let css = match styles {
    Some(s) => s
    None => toast_styles()
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
    "radix-toast",
    [
      ("data-variant", @luna.attr_static(variant_val.to_string())),
      ("data-state", @luna.attr_static(state)),
    ],
    all_children,
  )
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a toast viewport with luna/css atomic styles
pub fn radix_toast_viewport_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = toast_viewport_styles()
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("role", @luna.attr_static("region")),
      ("aria-live", @luna.attr_static("polite")),
    ],
    children,
  )
}

///|
/// Create a toast with luna/css atomic styles
pub fn radix_toast_ucss(
  variant? : ToastVariant,
  open? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let variant_val = match variant {
    Some(v) => v
    None => Default
  }
  let is_open = match open {
    Some(true) => true
    _ => false
  }
  let state = if is_open { "open" } else { "closed" }
  let class_names = toast_base_styles() +
    " " +
    toast_variant_styles(variant_val)
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("role", @luna.attr_static("alert")),
      ("data-state", @luna.attr_static(state)),
    ],
    children,
  )
}

///|
/// Create a toast title with luna/css atomic styles
pub fn radix_toast_title_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = toast_title_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a toast description with luna/css atomic styles
pub fn radix_toast_description_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = toast_description_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a toast action with luna/css atomic styles
pub fn radix_toast_action_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = toast_action_styles()
  @luna.h("button", [("class", @luna.attr_static(class_names))], children)
}
