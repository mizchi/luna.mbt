///|
/// AvatarGroup component for Luna (Headless)
/// Display multiple avatars in a stacked or grid layout

///|
/// Create a headless avatar group
/// Outputs: <div class="radix-avatar-group">children</div>
pub fn radix_avatar_group(
  max? : Int,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-avatar-group")),
  ]
  match max {
    Some(m) => attrs.push(("data-max", @luna.attr_static(m.to_string())))
    None => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a headless avatar group item
/// Outputs: <div class="radix-avatar-group-item">children</div>
pub fn radix_avatar_group_item(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-avatar-group-item"))],
    children,
  )
}

///|
/// Create a headless avatar group overflow indicator
/// Outputs: <div class="radix-avatar-group-overflow">+N</div>
pub fn radix_avatar_group_overflow(count : Int) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-avatar-group-overflow"))],
    [@luna.text("+" + count.to_string())],
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the avatar group component
fn avatar_group_styles() -> String {
  let css =
    #|:host {
    #|  display: inline-flex;
    #|}
    #|
    #|.avatar-group {
    #|  display: inline-flex;
    #|  flex-direction: row-reverse;
    #|}
    #|
    #|.avatar-group-item {
    #|  position: relative;
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  width: 2.5rem;
    #|  height: 2.5rem;
    #|  border-radius: 50%;
    #|  border: 2px solid white;
    #|  background: #e4e4e7;
    #|  overflow: hidden;
    #|  margin-left: -0.75rem;
    #|}
    #|
    #|.avatar-group-item:last-child {
    #|  margin-left: 0;
    #|}
    #|
    #|.avatar-group-item img {
    #|  width: 100%;
    #|  height: 100%;
    #|  object-fit: cover;
    #|}
    #|
    #|.avatar-group-overflow {
    #|  position: relative;
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  width: 2.5rem;
    #|  height: 2.5rem;
    #|  border-radius: 50%;
    #|  border: 2px solid white;
    #|  background: #18181b;
    #|  color: white;
    #|  font-size: 0.75rem;
    #|  font-weight: 500;
    #|  margin-left: -0.75rem;
    #|}
  css
}

///|
/// Create a styled avatar group with Declarative Shadow DOM
pub fn radix_avatar_group_styled(
  max? : Int,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => avatar_group_styles()
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
  let attrs : Array[(String, @luna.Attr[Unit])] = []
  match max {
    Some(m) => attrs.push(("data-max", @luna.attr_static(m.to_string())))
    None => ()
  }
  @luna.h("radix-avatar-group", attrs, all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create an avatar group with luna/css atomic styles
pub fn radix_avatar_group_ucss(
  max? : Int,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = avatar_group_base_styles()
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
  ]
  match max {
    Some(m) => attrs.push(("data-max", @luna.attr_static(m.to_string())))
    None => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create an avatar group item with luna/css atomic styles
pub fn radix_avatar_group_item_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = avatar_group_item_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create an avatar group overflow with luna/css atomic styles
pub fn radix_avatar_group_overflow_ucss(count : Int) -> @luna.Node[Unit] {
  let class_names = avatar_group_overflow_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], [
    @luna.text("+" + count.to_string()),
  ])
}
