///|
/// Radix-style Avatar component for Luna (Headless)
/// Outputs semantic HTML with data-* attributes for external CSS styling

///|
/// Avatar size variants
pub(all) enum AvatarSize {
  Small // 32px
  Medium // 40px
  Large // 48px
  XLarge // 64px
}

///|
pub fn AvatarSize::to_string(self : AvatarSize) -> String {
  match self {
    Small => "small"
    Medium => "medium"
    Large => "large"
    XLarge => "xlarge"
  }
}

///|
/// Create a headless avatar container
/// Outputs: <span class="radix-avatar" data-size="...">children</span>
pub fn radix_avatar(
  size? : AvatarSize,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let size_val = match size {
    Some(s) => s
    None => Medium
  }

  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-avatar")),
    ("data-size", @luna.attr_static(size_val.to_string())),
  ]

  @luna.h("span", attrs, children)
}

///|
/// Create a headless avatar image
/// Outputs: <img class="radix-avatar-image" src="..." alt="..."/>
pub fn radix_avatar_image(
  src : String,
  alt? : String,
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-avatar-image")),
    ("src", @luna.attr_static(src)),
  ]

  match alt {
    Some(a) => attrs.push(("alt", @luna.attr_static(a)))
    None => ()
  }

  @luna.h("img", attrs, [])
}

///|
/// Create a headless avatar fallback
/// Outputs: <span class="radix-avatar-fallback">children</span>
pub fn radix_avatar_fallback(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "span",
    [("class", @luna.attr_static("radix-avatar-fallback"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the avatar component
fn avatar_styles() -> String {
  let css =
    #|:host {
    #|  display: inline-block;
    #|}
    #|
    #|.avatar {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  border-radius: 50%;
    #|  overflow: hidden;
    #|  background: #e4e4e7;
    #|  vertical-align: middle;
    #|  user-select: none;
    #|}
    #|
    #|/* Sizes */
    #|.avatar[data-size="small"] { width: 2rem; height: 2rem; font-size: 0.75rem; }
    #|.avatar[data-size="medium"] { width: 2.5rem; height: 2.5rem; font-size: 0.875rem; }
    #|.avatar[data-size="large"] { width: 3rem; height: 3rem; font-size: 1rem; }
    #|.avatar[data-size="xlarge"] { width: 4rem; height: 4rem; font-size: 1.25rem; }
    #|
    #|.avatar-image {
    #|  width: 100%;
    #|  height: 100%;
    #|  object-fit: cover;
    #|}
    #|
    #|.avatar-fallback {
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  width: 100%;
    #|  height: 100%;
    #|  font-weight: 500;
    #|  color: #71717a;
    #|  text-transform: uppercase;
    #|}
  css
}

///|
/// Create a styled avatar with Declarative Shadow DOM
pub fn radix_avatar_styled(
  size? : AvatarSize,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let size_val = match size {
    Some(s) => s
    None => Medium
  }

  let css = match styles {
    Some(s) => s
    None => avatar_styles()
  }

  // Build avatar attributes
  let avatar_attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("avatar")),
    ("data-size", @luna.attr_static(size_val.to_string())),
  ]

  // Build template content
  let template_children : Array[@luna.Node[Unit]] = [
    @luna.h("style", [], [@luna.text(css)]),
    @luna.h("span", avatar_attrs, [@luna.h("slot", [], [])]),
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
    "radix-avatar",
    [("data-size", @luna.attr_static(size_val.to_string()))],
    all_children,
  )
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create an avatar with luna/css atomic styles
pub fn radix_avatar_ucss(
  size? : AvatarSize,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let size_val = match size {
    Some(s) => s
    None => Medium
  }

  let class_names = avatar_base_styles() + " " + avatar_size_styles(size_val)
  @luna.h("span", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create an avatar image with luna/css atomic styles
pub fn radix_avatar_image_ucss(src : String, alt? : String) -> @luna.Node[Unit] {
  let class_names = avatar_image_styles()

  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("src", @luna.attr_static(src)),
  ]

  match alt {
    Some(a) => attrs.push(("alt", @luna.attr_static(a)))
    None => ()
  }

  @luna.h("img", attrs, [])
}

///|
/// Create an avatar fallback with luna/css atomic styles
pub fn radix_avatar_fallback_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = avatar_fallback_styles()
  @luna.h("span", [("class", @luna.attr_static(class_names))], children)
}
