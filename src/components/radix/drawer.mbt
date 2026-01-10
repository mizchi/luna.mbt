///|
/// Radix-style Drawer component for Luna (Headless)
/// Bottom/side sliding panel with handle (mobile-friendly sheet)

///|
/// Create a headless drawer root
/// Outputs: <div class="radix-drawer" data-state="...">children</div>
pub fn radix_drawer(
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
      ("class", @luna.attr_static("radix-drawer")),
      ("data-state", @luna.attr_static(state)),
    ],
    children,
  )
}

///|
/// Create a headless drawer trigger
/// Outputs: <button class="radix-drawer-trigger">children</button>
pub fn radix_drawer_trigger(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "button",
    [("class", @luna.attr_static("radix-drawer-trigger"))],
    children,
  )
}

///|
/// Create a headless drawer portal
/// Outputs: <div class="radix-drawer-portal">children</div>
pub fn radix_drawer_portal(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-drawer-portal"))],
    children,
  )
}

///|
/// Create a headless drawer overlay
/// Outputs: <div class="radix-drawer-overlay"></div>
pub fn radix_drawer_overlay() -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-drawer-overlay"))], [])
}

///|
/// Drawer direction enum
pub enum DrawerDirection {
  Top
  Right
  Bottom
  Left
}

///|
/// Create a headless drawer content
/// Outputs: <div class="radix-drawer-content" data-direction="...">children</div>
pub fn radix_drawer_content(
  direction? : DrawerDirection,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let dir = match direction {
    Some(Top) => "top"
    Some(Right) => "right"
    Some(Left) => "left"
    _ => "bottom"
  }
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-drawer-content")),
      ("data-direction", @luna.attr_static(dir)),
    ],
    children,
  )
}

///|
/// Create a headless drawer handle (drag indicator)
/// Outputs: <div class="radix-drawer-handle"><div class="radix-drawer-handle-bar"></div></div>
pub fn radix_drawer_handle() -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-drawer-handle"))], [
    @luna.h("div", [("class", @luna.attr_static("radix-drawer-handle-bar"))], []),
  ])
}

///|
/// Create a headless drawer header
/// Outputs: <div class="radix-drawer-header">children</div>
pub fn radix_drawer_header(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-drawer-header"))],
    children,
  )
}

///|
/// Create a headless drawer title
/// Outputs: <h2 class="radix-drawer-title">children</h2>
pub fn radix_drawer_title(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h("h2", [("class", @luna.attr_static("radix-drawer-title"))], children)
}

///|
/// Create a headless drawer description
/// Outputs: <p class="radix-drawer-description">children</p>
pub fn radix_drawer_description(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "p",
    [("class", @luna.attr_static("radix-drawer-description"))],
    children,
  )
}

///|
/// Create a headless drawer footer
/// Outputs: <div class="radix-drawer-footer">children</div>
pub fn radix_drawer_footer(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-drawer-footer"))],
    children,
  )
}

///|
/// Create a headless drawer close button
/// Outputs: <button class="radix-drawer-close">children</button>
pub fn radix_drawer_close(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "button",
    [("class", @luna.attr_static("radix-drawer-close"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the drawer component
fn drawer_styles() -> String {
  let css =
    #|:host {
    #|  display: contents;
    #|}
    #|
    #|.drawer-overlay {
    #|  position: fixed;
    #|  inset: 0;
    #|  z-index: 50;
    #|  background: rgba(0, 0, 0, 0.8);
    #|}
    #|
    #|.drawer-content {
    #|  position: fixed;
    #|  z-index: 50;
    #|  display: flex;
    #|  flex-direction: column;
    #|  background: white;
    #|}
    #|
    #|.drawer-content[data-direction="bottom"] {
    #|  inset: auto 0 0 0;
    #|  border-top-left-radius: 10px;
    #|  border-top-right-radius: 10px;
    #|  max-height: 96vh;
    #|}
    #|
    #|.drawer-content[data-direction="top"] {
    #|  inset: 0 0 auto 0;
    #|  border-bottom-left-radius: 10px;
    #|  border-bottom-right-radius: 10px;
    #|  max-height: 96vh;
    #|}
    #|
    #|.drawer-content[data-direction="left"] {
    #|  inset: 0 auto 0 0;
    #|  width: 75%;
    #|  max-width: 400px;
    #|  height: 100%;
    #|}
    #|
    #|.drawer-content[data-direction="right"] {
    #|  inset: 0 0 0 auto;
    #|  width: 75%;
    #|  max-width: 400px;
    #|  height: 100%;
    #|}
    #|
    #|.drawer-handle {
    #|  display: flex;
    #|  justify-content: center;
    #|  padding: 0.5rem 0;
    #|}
    #|
    #|.drawer-handle-bar {
    #|  width: 3rem;
    #|  height: 0.25rem;
    #|  background: #d4d4d8;
    #|  border-radius: 9999px;
    #|}
    #|
    #|.drawer-header {
    #|  padding: 1rem;
    #|  text-align: center;
    #|}
    #|
    #|.drawer-title {
    #|  font-size: 1.125rem;
    #|  font-weight: 600;
    #|  line-height: 1;
    #|  margin: 0;
    #|}
    #|
    #|.drawer-description {
    #|  font-size: 0.875rem;
    #|  color: #71717a;
    #|  margin: 0.25rem 0 0 0;
    #|}
    #|
    #|.drawer-footer {
    #|  display: flex;
    #|  flex-direction: column;
    #|  gap: 0.5rem;
    #|  padding: 1rem;
    #|  margin-top: auto;
    #|}
    #|
    #|.drawer-close {
    #|  position: absolute;
    #|  top: 1rem;
    #|  right: 1rem;
    #|  width: 1.5rem;
    #|  height: 1.5rem;
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  background: transparent;
    #|  border: none;
    #|  cursor: pointer;
    #|  color: #71717a;
    #|}
    #|
    #|.drawer-close:hover {
    #|  color: #18181b;
    #|}
  css
}

///|
/// Create a styled drawer with Declarative Shadow DOM
pub fn radix_drawer_styled(
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
    None => drawer_styles()
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
    "radix-drawer",
    [("data-state", @luna.attr_static(state))],
    all_children,
  )
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a drawer with luna/css atomic styles
pub fn radix_drawer_ucss(
  open? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_open = match open {
    Some(true) => true
    _ => false
  }
  let state = if is_open { "open" } else { "closed" }
  @luna.h("div", [("data-state", @luna.attr_static(state))], children)
}

///|
/// Create a drawer overlay with luna/css atomic styles
pub fn radix_drawer_overlay_ucss() -> @luna.Node[Unit] {
  let class_names = drawer_overlay_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], [])
}

///|
/// Create a drawer content with luna/css atomic styles
pub fn radix_drawer_content_ucss(
  direction? : DrawerDirection,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let dir = match direction {
    Some(Top) => "top"
    Some(Right) => "right"
    Some(Left) => "left"
    _ => "bottom"
  }
  let class_names = drawer_content_styles()
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("data-direction", @luna.attr_static(dir)),
    ],
    children,
  )
}

///|
/// Create a drawer handle with luna/css atomic styles
pub fn radix_drawer_handle_ucss() -> @luna.Node[Unit] {
  let handle_class = drawer_handle_styles()
  let bar_class = drawer_handle_bar_styles()
  @luna.h("div", [("class", @luna.attr_static(handle_class))], [
    @luna.h("div", [("class", @luna.attr_static(bar_class))], []),
  ])
}

///|
/// Create a drawer header with luna/css atomic styles
pub fn radix_drawer_header_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = drawer_header_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a drawer title with luna/css atomic styles
pub fn radix_drawer_title_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = drawer_title_styles()
  @luna.h("h2", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a drawer footer with luna/css atomic styles
pub fn radix_drawer_footer_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = drawer_footer_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}
