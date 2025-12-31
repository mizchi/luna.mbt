///|
/// Radix-style NavigationMenu component for Luna (Headless)
/// Navigation menu with submenus

///|
/// Create a headless navigation menu root
/// Outputs: <nav class="radix-navigation-menu">children</nav>
pub fn radix_navigation_menu(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "nav",
    [("class", @luna.attr_static("radix-navigation-menu"))],
    children,
  )
}

///|
/// Create a headless navigation menu list
/// Outputs: <ul class="radix-navigation-menu-list">children</ul>
pub fn radix_navigation_menu_list(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "ul",
    [("class", @luna.attr_static("radix-navigation-menu-list"))],
    children,
  )
}

///|
/// Create a headless navigation menu item
/// Outputs: <li class="radix-navigation-menu-item">children</li>
pub fn radix_navigation_menu_item(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "li",
    [("class", @luna.attr_static("radix-navigation-menu-item"))],
    children,
  )
}

///|
/// Create a headless navigation menu trigger
/// Outputs: <button class="radix-navigation-menu-trigger">children</button>
pub fn radix_navigation_menu_trigger(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "button",
    [("class", @luna.attr_static("radix-navigation-menu-trigger"))],
    children,
  )
}

///|
/// Create a headless navigation menu content
/// Outputs: <div class="radix-navigation-menu-content">children</div>
pub fn radix_navigation_menu_content(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-navigation-menu-content"))],
    children,
  )
}

///|
/// Create a headless navigation menu link
/// Outputs: <a class="radix-navigation-menu-link" href="...">children</a>
pub fn radix_navigation_menu_link(
  href : String,
  active? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-navigation-menu-link")),
    ("href", @luna.attr_static(href)),
  ]

  match active {
    Some(true) => attrs.push(("data-active", @luna.attr_static("")))
    _ => ()
  }

  @luna.h("a", attrs, children)
}

///|
/// Create a headless navigation menu indicator
/// Outputs: <div class="radix-navigation-menu-indicator"></div>
pub fn radix_navigation_menu_indicator() -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-navigation-menu-indicator"))],
    [],
  )
}

///|
/// Create a headless navigation menu viewport
/// Outputs: <div class="radix-navigation-menu-viewport">children</div>
pub fn radix_navigation_menu_viewport(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-navigation-menu-viewport"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the navigation menu component
fn navigation_menu_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.navigation-menu {
    #|  position: relative;
    #|  z-index: 10;
    #|}
    #|
    #|.navigation-menu-list {
    #|  display: flex;
    #|  align-items: center;
    #|  gap: 0.25rem;
    #|  list-style: none;
    #|  margin: 0;
    #|  padding: 0;
    #|}
    #|
    #|.navigation-menu-item {
    #|  position: relative;
    #|}
    #|
    #|.navigation-menu-trigger {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  gap: 0.25rem;
    #|  padding: 0.5rem 0.75rem;
    #|  font-size: 0.875rem;
    #|  font-weight: 500;
    #|  background: transparent;
    #|  border: none;
    #|  border-radius: 4px;
    #|  cursor: pointer;
    #|  transition: background 0.15s ease;
    #|}
    #|
    #|.navigation-menu-trigger:hover {
    #|  background: #f4f4f5;
    #|}
    #|
    #|.navigation-menu-content {
    #|  position: absolute;
    #|  top: 100%;
    #|  left: 0;
    #|  min-width: 12rem;
    #|  padding: 0.5rem;
    #|  background: white;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|  box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);
    #|}
    #|
    #|.navigation-menu-link {
    #|  display: block;
    #|  padding: 0.5rem 0.75rem;
    #|  font-size: 0.875rem;
    #|  text-decoration: none;
    #|  color: #18181b;
    #|  border-radius: 4px;
    #|  transition: background 0.15s ease;
    #|}
    #|
    #|.navigation-menu-link:hover {
    #|  background: #f4f4f5;
    #|}
    #|
    #|.navigation-menu-link[data-active] {
    #|  background: #f4f4f5;
    #|  font-weight: 500;
    #|}
    #|
    #|.navigation-menu-indicator {
    #|  position: absolute;
    #|  bottom: 0;
    #|  left: 0;
    #|  height: 2px;
    #|  background: #18181b;
    #|  transition: transform 0.2s ease, width 0.2s ease;
    #|}
    #|
    #|.navigation-menu-viewport {
    #|  position: absolute;
    #|  top: 100%;
    #|  left: 0;
    #|  width: 100%;
    #|}
  css
}

///|
/// Create a styled navigation menu with Declarative Shadow DOM
pub fn radix_navigation_menu_styled(
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => navigation_menu_styles()
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

  @luna.h("radix-navigation-menu", [], all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a navigation menu with luna/css atomic styles
pub fn radix_navigation_menu_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = navigation_menu_base_styles()
  @luna.h("nav", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a navigation menu list with luna/css atomic styles
pub fn radix_navigation_menu_list_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = navigation_menu_list_styles()
  @luna.h("ul", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a navigation menu trigger with luna/css atomic styles
pub fn radix_navigation_menu_trigger_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = navigation_menu_trigger_styles()
  @luna.h("button", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a navigation menu content with luna/css atomic styles
pub fn radix_navigation_menu_content_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = navigation_menu_content_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a navigation menu link with luna/css atomic styles
pub fn radix_navigation_menu_link_ucss(
  href : String,
  active? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let mut class_names = navigation_menu_link_styles()

  match active {
    Some(true) =>
      class_names = class_names +
        " " +
        @css.styles([("background", "#f4f4f5"), ("font-weight", "500")])
    _ => ()
  }

  @luna.h(
    "a",
    [
      ("class", @luna.attr_static(class_names)),
      ("href", @luna.attr_static(href)),
    ],
    children,
  )
}
