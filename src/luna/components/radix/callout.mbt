///|
/// Callout component for Luna (Headless)
/// Highlighted information box with icon

///|
/// Callout variant enum
pub enum CalloutVariant {
  Default
  Info
  Success
  Warning
  Error
}

///|
/// Create a headless callout root
/// Outputs: <div class="radix-callout" data-variant="...">children</div>
pub fn radix_callout(
  variant? : CalloutVariant,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let variant_str = match variant {
    Some(Info) => "info"
    Some(Success) => "success"
    Some(Warning) => "warning"
    Some(Error) => "error"
    _ => "default"
  }
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-callout")),
      ("role", @luna.attr_static("alert")),
      ("data-variant", @luna.attr_static(variant_str)),
    ],
    children,
  )
}

///|
/// Create a headless callout icon
/// Outputs: <div class="radix-callout-icon">children</div>
pub fn radix_callout_icon(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-callout-icon"))], children)
}

///|
/// Create a headless callout content
/// Outputs: <div class="radix-callout-content">children</div>
pub fn radix_callout_content(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-callout-content"))],
    children,
  )
}

///|
/// Create a headless callout title
/// Outputs: <div class="radix-callout-title">children</div>
pub fn radix_callout_title(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-callout-title"))],
    children,
  )
}

///|
/// Create a headless callout description
/// Outputs: <div class="radix-callout-description">children</div>
pub fn radix_callout_description(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-callout-description"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the callout component
fn callout_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.callout {
    #|  display: flex;
    #|  gap: 0.75rem;
    #|  padding: 1rem;
    #|  border-radius: 8px;
    #|  border: 1px solid;
    #|}
    #|
    #|.callout[data-variant="default"] {
    #|  background: #f4f4f5;
    #|  border-color: #e4e4e7;
    #|}
    #|
    #|.callout[data-variant="info"] {
    #|  background: #eff6ff;
    #|  border-color: #bfdbfe;
    #|}
    #|
    #|.callout[data-variant="success"] {
    #|  background: #f0fdf4;
    #|  border-color: #bbf7d0;
    #|}
    #|
    #|.callout[data-variant="warning"] {
    #|  background: #fffbeb;
    #|  border-color: #fde68a;
    #|}
    #|
    #|.callout[data-variant="error"] {
    #|  background: #fef2f2;
    #|  border-color: #fecaca;
    #|}
    #|
    #|.callout-icon {
    #|  flex-shrink: 0;
    #|  width: 1.25rem;
    #|  height: 1.25rem;
    #|  margin-top: 0.125rem;
    #|}
    #|
    #|.callout[data-variant="default"] .callout-icon {
    #|  color: #71717a;
    #|}
    #|
    #|.callout[data-variant="info"] .callout-icon {
    #|  color: #3b82f6;
    #|}
    #|
    #|.callout[data-variant="success"] .callout-icon {
    #|  color: #22c55e;
    #|}
    #|
    #|.callout[data-variant="warning"] .callout-icon {
    #|  color: #f59e0b;
    #|}
    #|
    #|.callout[data-variant="error"] .callout-icon {
    #|  color: #ef4444;
    #|}
    #|
    #|.callout-content {
    #|  flex: 1;
    #|  min-width: 0;
    #|}
    #|
    #|.callout-title {
    #|  font-size: 0.875rem;
    #|  font-weight: 600;
    #|  color: #18181b;
    #|  margin-bottom: 0.25rem;
    #|}
    #|
    #|.callout-description {
    #|  font-size: 0.875rem;
    #|  color: #52525b;
    #|  line-height: 1.5;
    #|}
  css
}

///|
/// Create a styled callout with Declarative Shadow DOM
pub fn radix_callout_styled(
  variant? : CalloutVariant,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let variant_str = match variant {
    Some(Info) => "info"
    Some(Success) => "success"
    Some(Warning) => "warning"
    Some(Error) => "error"
    _ => "default"
  }
  let css = match styles {
    Some(s) => s
    None => callout_styles()
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
  @luna.h(
    "radix-callout",
    [
      ("role", @luna.attr_static("alert")),
      ("data-variant", @luna.attr_static(variant_str)),
    ],
    all_children,
  )
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a callout with luna/css atomic styles
pub fn radix_callout_ucss(
  variant? : CalloutVariant,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let variant_str = match variant {
    Some(Info) => "info"
    Some(Success) => "success"
    Some(Warning) => "warning"
    Some(Error) => "error"
    _ => "default"
  }
  let class_names = callout_base_styles(variant)
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("role", @luna.attr_static("alert")),
      ("data-variant", @luna.attr_static(variant_str)),
    ],
    children,
  )
}

///|
/// Create a callout icon with luna/css atomic styles
pub fn radix_callout_icon_ucss(
  variant? : CalloutVariant,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = callout_icon_styles(variant)
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a callout content with luna/css atomic styles
pub fn radix_callout_content_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = callout_content_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a callout title with luna/css atomic styles
pub fn radix_callout_title_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = callout_title_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a callout description with luna/css atomic styles
pub fn radix_callout_description_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = callout_description_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}
