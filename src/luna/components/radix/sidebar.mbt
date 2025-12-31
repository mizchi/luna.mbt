///|
/// Radix-style Sidebar component for Luna (Headless)
/// Collapsible sidebar navigation

///|
/// Sidebar variant enum
pub enum SidebarVariant {
  Sidebar
  Floating
  Inset
}

///|
/// Sidebar side enum
pub enum SidebarSide {
  Left
  Right
}

///|
/// Create a headless sidebar provider
/// Outputs: <div class="radix-sidebar-provider" data-state="...">children</div>
pub fn radix_sidebar_provider(
  open? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_open = match open {
    Some(o) => o
    None => true
  }
  let state = if is_open { "expanded" } else { "collapsed" }
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-sidebar-provider")),
      ("data-state", @luna.attr_static(state)),
    ],
    children,
  )
}

///|
/// Create a headless sidebar
/// Outputs: <aside class="radix-sidebar" data-side="..." data-variant="...">children</aside>
pub fn radix_sidebar(
  side? : SidebarSide,
  variant? : SidebarVariant,
  collapsible? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let side_str = match side {
    Some(Right) => "right"
    _ => "left"
  }
  let variant_str = match variant {
    Some(Floating) => "floating"
    Some(Inset) => "inset"
    _ => "sidebar"
  }
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-sidebar")),
    ("data-side", @luna.attr_static(side_str)),
    ("data-variant", @luna.attr_static(variant_str)),
  ]
  match collapsible {
    Some(true) => attrs.push(("data-collapsible", @luna.attr_static("true")))
    _ => ()
  }
  @luna.h("aside", attrs, children)
}

///|
/// Create a headless sidebar trigger
/// Outputs: <button class="radix-sidebar-trigger">children</button>
pub fn radix_sidebar_trigger(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "button",
    [("class", @luna.attr_static("radix-sidebar-trigger"))],
    children,
  )
}

///|
/// Create a headless sidebar rail (thin hover area for expanding)
/// Outputs: <button class="radix-sidebar-rail"></button>
pub fn radix_sidebar_rail() -> @luna.Node[Unit] {
  @luna.h("button", [("class", @luna.attr_static("radix-sidebar-rail"))], [])
}

///|
/// Create a headless sidebar inset
/// Outputs: <main class="radix-sidebar-inset">children</main>
pub fn radix_sidebar_inset(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "main",
    [("class", @luna.attr_static("radix-sidebar-inset"))],
    children,
  )
}

///|
/// Create a headless sidebar header
/// Outputs: <div class="radix-sidebar-header">children</div>
pub fn radix_sidebar_header(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-sidebar-header"))],
    children,
  )
}

///|
/// Create a headless sidebar footer
/// Outputs: <div class="radix-sidebar-footer">children</div>
pub fn radix_sidebar_footer(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-sidebar-footer"))],
    children,
  )
}

///|
/// Create a headless sidebar content
/// Outputs: <div class="radix-sidebar-content">children</div>
pub fn radix_sidebar_content(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-sidebar-content"))],
    children,
  )
}

///|
/// Create a headless sidebar group
/// Outputs: <div class="radix-sidebar-group">children</div>
pub fn radix_sidebar_group(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-sidebar-group"))],
    children,
  )
}

///|
/// Create a headless sidebar group label
/// Outputs: <div class="radix-sidebar-group-label">children</div>
pub fn radix_sidebar_group_label(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-sidebar-group-label"))],
    children,
  )
}

///|
/// Create a headless sidebar group content
/// Outputs: <div class="radix-sidebar-group-content">children</div>
pub fn radix_sidebar_group_content(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-sidebar-group-content"))],
    children,
  )
}

///|
/// Create a headless sidebar menu
/// Outputs: <ul class="radix-sidebar-menu">children</ul>
pub fn radix_sidebar_menu(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h("ul", [("class", @luna.attr_static("radix-sidebar-menu"))], children)
}

///|
/// Create a headless sidebar menu item
/// Outputs: <li class="radix-sidebar-menu-item">children</li>
pub fn radix_sidebar_menu_item(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "li",
    [("class", @luna.attr_static("radix-sidebar-menu-item"))],
    children,
  )
}

///|
/// Create a headless sidebar menu button
/// Outputs: <button class="radix-sidebar-menu-button" data-active="...">children</button>
pub fn radix_sidebar_menu_button(
  active? : Bool,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-sidebar-menu-button")),
  ]
  match active {
    Some(true) => attrs.push(("data-active", @luna.attr_static("")))
    _ => ()
  }
  match disabled {
    Some(true) => {
      attrs.push(("data-disabled", @luna.attr_static("")))
      attrs.push(("disabled", @luna.attr_static("")))
    }
    _ => ()
  }
  @luna.h("button", attrs, children)
}

///|
/// Create a headless sidebar menu sub
/// Outputs: <ul class="radix-sidebar-menu-sub">children</ul>
pub fn radix_sidebar_menu_sub(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "ul",
    [("class", @luna.attr_static("radix-sidebar-menu-sub"))],
    children,
  )
}

///|
/// Create a headless sidebar menu sub item
/// Outputs: <li class="radix-sidebar-menu-sub-item">children</li>
pub fn radix_sidebar_menu_sub_item(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "li",
    [("class", @luna.attr_static("radix-sidebar-menu-sub-item"))],
    children,
  )
}

///|
/// Create a headless sidebar menu sub button
/// Outputs: <a class="radix-sidebar-menu-sub-button">children</a>
pub fn radix_sidebar_menu_sub_button(
  href? : String,
  active? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-sidebar-menu-sub-button")),
  ]
  match href {
    Some(h) => attrs.push(("href", @luna.attr_static(h)))
    None => ()
  }
  match active {
    Some(true) => attrs.push(("data-active", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("a", attrs, children)
}

///|
/// Create a headless sidebar separator
/// Outputs: <div class="radix-sidebar-separator"></div>
pub fn radix_sidebar_separator() -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-sidebar-separator"))], [])
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the sidebar component
fn sidebar_styles() -> String {
  let css =
    #|:host {
    #|  display: contents;
    #|}
    #|
    #|.sidebar-provider {
    #|  display: flex;
    #|  min-height: 100vh;
    #|  width: 100%;
    #|}
    #|
    #|.sidebar {
    #|  display: flex;
    #|  flex-direction: column;
    #|  width: 16rem;
    #|  background: white;
    #|  border-right: 1px solid #e4e4e7;
    #|  transition: width 0.2s ease, transform 0.2s ease;
    #|}
    #|
    #|.sidebar[data-side="right"] {
    #|  border-right: none;
    #|  border-left: 1px solid #e4e4e7;
    #|  order: 1;
    #|}
    #|
    #|.sidebar[data-variant="floating"] {
    #|  margin: 1rem;
    #|  border-radius: 8px;
    #|  border: 1px solid #e4e4e7;
    #|  box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);
    #|}
    #|
    #|.sidebar[data-variant="inset"] {
    #|  background: #f4f4f5;
    #|}
    #|
    #|[data-state="collapsed"] .sidebar {
    #|  width: 3rem;
    #|}
    #|
    #|.sidebar-trigger {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  width: 2rem;
    #|  height: 2rem;
    #|  background: transparent;
    #|  border: none;
    #|  cursor: pointer;
    #|  color: #71717a;
    #|}
    #|
    #|.sidebar-trigger:hover {
    #|  color: #18181b;
    #|}
    #|
    #|.sidebar-rail {
    #|  position: absolute;
    #|  top: 0;
    #|  bottom: 0;
    #|  width: 4px;
    #|  background: transparent;
    #|  border: none;
    #|  cursor: ew-resize;
    #|}
    #|
    #|.sidebar[data-side="left"] .sidebar-rail {
    #|  right: -2px;
    #|}
    #|
    #|.sidebar[data-side="right"] .sidebar-rail {
    #|  left: -2px;
    #|}
    #|
    #|.sidebar-rail:hover {
    #|  background: #e4e4e7;
    #|}
    #|
    #|.sidebar-inset {
    #|  flex: 1;
    #|  min-width: 0;
    #|}
    #|
    #|.sidebar-header {
    #|  padding: 1rem;
    #|  border-bottom: 1px solid #e4e4e7;
    #|}
    #|
    #|.sidebar-footer {
    #|  padding: 1rem;
    #|  border-top: 1px solid #e4e4e7;
    #|  margin-top: auto;
    #|}
    #|
    #|.sidebar-content {
    #|  flex: 1;
    #|  overflow: auto;
    #|  padding: 0.5rem;
    #|}
    #|
    #|.sidebar-group {
    #|  padding: 0.5rem 0;
    #|}
    #|
    #|.sidebar-group-label {
    #|  padding: 0.5rem 0.75rem;
    #|  font-size: 0.75rem;
    #|  font-weight: 500;
    #|  color: #71717a;
    #|  text-transform: uppercase;
    #|  letter-spacing: 0.05em;
    #|}
    #|
    #|.sidebar-menu {
    #|  list-style: none;
    #|  margin: 0;
    #|  padding: 0;
    #|}
    #|
    #|.sidebar-menu-item {
    #|  margin: 0.125rem 0;
    #|}
    #|
    #|.sidebar-menu-button {
    #|  display: flex;
    #|  align-items: center;
    #|  gap: 0.5rem;
    #|  width: 100%;
    #|  padding: 0.5rem 0.75rem;
    #|  font-size: 0.875rem;
    #|  background: transparent;
    #|  border: none;
    #|  border-radius: 6px;
    #|  cursor: pointer;
    #|  text-align: left;
    #|  color: #18181b;
    #|  transition: background 0.15s ease;
    #|}
    #|
    #|.sidebar-menu-button:hover {
    #|  background: #f4f4f5;
    #|}
    #|
    #|.sidebar-menu-button[data-active] {
    #|  background: #f4f4f5;
    #|  font-weight: 500;
    #|}
    #|
    #|.sidebar-menu-button[data-disabled] {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
    #|
    #|.sidebar-menu-sub {
    #|  list-style: none;
    #|  margin: 0;
    #|  padding: 0 0 0 1.5rem;
    #|  border-left: 1px solid #e4e4e7;
    #|  margin-left: 0.875rem;
    #|}
    #|
    #|.sidebar-menu-sub-button {
    #|  display: block;
    #|  padding: 0.375rem 0.75rem;
    #|  font-size: 0.875rem;
    #|  color: #71717a;
    #|  text-decoration: none;
    #|  border-radius: 4px;
    #|  transition: color 0.15s ease, background 0.15s ease;
    #|}
    #|
    #|.sidebar-menu-sub-button:hover {
    #|  color: #18181b;
    #|  background: #f4f4f5;
    #|}
    #|
    #|.sidebar-menu-sub-button[data-active] {
    #|  color: #18181b;
    #|  font-weight: 500;
    #|}
    #|
    #|.sidebar-separator {
    #|  height: 1px;
    #|  margin: 0.5rem 0;
    #|  background: #e4e4e7;
    #|}
  css
}

///|
/// Create a styled sidebar with Declarative Shadow DOM
pub fn radix_sidebar_styled(
  side? : SidebarSide,
  variant? : SidebarVariant,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let side_str = match side {
    Some(Right) => "right"
    _ => "left"
  }
  let variant_str = match variant {
    Some(Floating) => "floating"
    Some(Inset) => "inset"
    _ => "sidebar"
  }
  let css = match styles {
    Some(s) => s
    None => sidebar_styles()
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
    "radix-sidebar",
    [
      ("data-side", @luna.attr_static(side_str)),
      ("data-variant", @luna.attr_static(variant_str)),
    ],
    all_children,
  )
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a sidebar provider with luna/css atomic styles
pub fn radix_sidebar_provider_ucss(
  open? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_open = match open {
    Some(o) => o
    None => true
  }
  let state = if is_open { "expanded" } else { "collapsed" }
  let class_names = sidebar_provider_styles()
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("data-state", @luna.attr_static(state)),
    ],
    children,
  )
}

///|
/// Create a sidebar with luna/css atomic styles
pub fn radix_sidebar_ucss(
  side? : SidebarSide,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let side_str = match side {
    Some(Right) => "right"
    _ => "left"
  }
  let class_names = sidebar_base_styles()
  @luna.h(
    "aside",
    [
      ("class", @luna.attr_static(class_names)),
      ("data-side", @luna.attr_static(side_str)),
    ],
    children,
  )
}

///|
/// Create a sidebar header with luna/css atomic styles
pub fn radix_sidebar_header_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = sidebar_header_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a sidebar content with luna/css atomic styles
pub fn radix_sidebar_content_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = sidebar_content_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a sidebar footer with luna/css atomic styles
pub fn radix_sidebar_footer_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = sidebar_footer_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a sidebar group label with luna/css atomic styles
pub fn radix_sidebar_group_label_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = sidebar_group_label_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a sidebar menu button with luna/css atomic styles
pub fn radix_sidebar_menu_button_ucss(
  active? : Bool,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let mut class_names = sidebar_menu_button_styles()
  match active {
    Some(true) =>
      class_names = class_names +
        " " +
        @css.styles([("background", "#f4f4f5"), ("font-weight", "500")])
    _ => ()
  }
  match disabled {
    Some(true) =>
      class_names = class_names +
        " " +
        @css.styles([("opacity", "0.5"), ("cursor", "not-allowed")])
    _ => ()
  }
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
  ]
  match active {
    Some(true) => attrs.push(("data-active", @luna.attr_static("")))
    _ => ()
  }
  match disabled {
    Some(true) => {
      attrs.push(("data-disabled", @luna.attr_static("")))
      attrs.push(("disabled", @luna.attr_static("")))
    }
    _ => ()
  }
  @luna.h("button", attrs, children)
}
