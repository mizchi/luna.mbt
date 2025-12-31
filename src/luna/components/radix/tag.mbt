///|
/// Tag/Chip component for Luna (Headless)
/// Label tags with optional close button

///|
/// Tag variant enum
pub enum TagVariant {
  Default
  Primary
  Secondary
  Success
  Warning
  Error
}

///|
/// Tag size enum
pub enum TagSize {
  Sm
  Md
  Lg
}

///|
/// Create a headless tag
/// Outputs: <span class="radix-tag" data-variant="...">children</span>
pub fn radix_tag(
  variant? : TagVariant,
  size? : TagSize,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let variant_str = match variant {
    Some(Primary) => "primary"
    Some(Secondary) => "secondary"
    Some(Success) => "success"
    Some(Warning) => "warning"
    Some(Error) => "error"
    _ => "default"
  }
  let size_str = match size {
    Some(Sm) => "sm"
    Some(Lg) => "lg"
    _ => "md"
  }
  @luna.h(
    "span",
    [
      ("class", @luna.attr_static("radix-tag")),
      ("data-variant", @luna.attr_static(variant_str)),
      ("data-size", @luna.attr_static(size_str)),
    ],
    children,
  )
}

///|
/// Create a headless tag close button
/// Outputs: <button class="radix-tag-close">children</button>
pub fn radix_tag_close(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h(
    "button",
    [
      ("class", @luna.attr_static("radix-tag-close")),
      ("type", @luna.attr_static("button")),
      ("aria-label", @luna.attr_static("Remove")),
    ],
    children,
  )
}

///|
/// Create a headless tag group
/// Outputs: <div class="radix-tag-group">children</div>
pub fn radix_tag_group(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-tag-group"))], children)
}

///|
/// Create a headless tag input (for tag input fields)
/// Outputs: <div class="radix-tag-input">children</div>
pub fn radix_tag_input(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-tag-input"))], children)
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the tag component
fn tag_styles() -> String {
  let css =
    #|:host {
    #|  display: inline-block;
    #|}
    #|
    #|.tag {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  gap: 0.25rem;
    #|  font-weight: 500;
    #|  border-radius: 9999px;
    #|  white-space: nowrap;
    #|}
    #|
    #|.tag[data-size="sm"] {
    #|  padding: 0.125rem 0.5rem;
    #|  font-size: 0.75rem;
    #|}
    #|
    #|.tag[data-size="md"] {
    #|  padding: 0.25rem 0.625rem;
    #|  font-size: 0.75rem;
    #|}
    #|
    #|.tag[data-size="lg"] {
    #|  padding: 0.375rem 0.75rem;
    #|  font-size: 0.875rem;
    #|}
    #|
    #|.tag[data-variant="default"] {
    #|  background: #f4f4f5;
    #|  color: #3f3f46;
    #|}
    #|
    #|.tag[data-variant="primary"] {
    #|  background: #18181b;
    #|  color: white;
    #|}
    #|
    #|.tag[data-variant="secondary"] {
    #|  background: #e4e4e7;
    #|  color: #3f3f46;
    #|}
    #|
    #|.tag[data-variant="success"] {
    #|  background: #dcfce7;
    #|  color: #166534;
    #|}
    #|
    #|.tag[data-variant="warning"] {
    #|  background: #fef3c7;
    #|  color: #92400e;
    #|}
    #|
    #|.tag[data-variant="error"] {
    #|  background: #fee2e2;
    #|  color: #991b1b;
    #|}
    #|
    #|.tag-close {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  width: 1rem;
    #|  height: 1rem;
    #|  padding: 0;
    #|  margin-left: 0.125rem;
    #|  margin-right: -0.25rem;
    #|  background: transparent;
    #|  border: none;
    #|  border-radius: 50%;
    #|  cursor: pointer;
    #|  opacity: 0.7;
    #|  transition: opacity 0.15s ease;
    #|}
    #|
    #|.tag-close:hover {
    #|  opacity: 1;
    #|}
    #|
    #|.tag-group {
    #|  display: flex;
    #|  flex-wrap: wrap;
    #|  gap: 0.5rem;
    #|}
    #|
    #|.tag-input {
    #|  display: flex;
    #|  flex-wrap: wrap;
    #|  align-items: center;
    #|  gap: 0.5rem;
    #|  padding: 0.5rem;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|  min-height: 2.5rem;
    #|}
  css
}

///|
/// Create a styled tag with Declarative Shadow DOM
pub fn radix_tag_styled(
  variant? : TagVariant,
  size? : TagSize,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let variant_str = match variant {
    Some(Primary) => "primary"
    Some(Secondary) => "secondary"
    Some(Success) => "success"
    Some(Warning) => "warning"
    Some(Error) => "error"
    _ => "default"
  }
  let size_str = match size {
    Some(Sm) => "sm"
    Some(Lg) => "lg"
    _ => "md"
  }
  let css = match styles {
    Some(s) => s
    None => tag_styles()
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
    "radix-tag",
    [
      ("data-variant", @luna.attr_static(variant_str)),
      ("data-size", @luna.attr_static(size_str)),
    ],
    all_children,
  )
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a tag with luna/css atomic styles
pub fn radix_tag_ucss(
  variant? : TagVariant,
  size? : TagSize,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = tag_base_styles(variant, size)
  let variant_str = match variant {
    Some(Primary) => "primary"
    Some(Secondary) => "secondary"
    Some(Success) => "success"
    Some(Warning) => "warning"
    Some(Error) => "error"
    _ => "default"
  }
  let size_str = match size {
    Some(Sm) => "sm"
    Some(Lg) => "lg"
    _ => "md"
  }
  @luna.h(
    "span",
    [
      ("class", @luna.attr_static(class_names)),
      ("data-variant", @luna.attr_static(variant_str)),
      ("data-size", @luna.attr_static(size_str)),
    ],
    children,
  )
}

///|
/// Create a tag close button with luna/css atomic styles
pub fn radix_tag_close_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = tag_close_styles()
  @luna.h(
    "button",
    [
      ("class", @luna.attr_static(class_names)),
      ("type", @luna.attr_static("button")),
      ("aria-label", @luna.attr_static("Remove")),
    ],
    children,
  )
}

///|
/// Create a tag group with luna/css atomic styles
pub fn radix_tag_group_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = tag_group_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}
