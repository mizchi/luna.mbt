///|
/// Radix-style DropdownMenu component for Luna (Headless)
/// Outputs semantic HTML with data-* attributes for external CSS styling

///|
/// Create a headless dropdown menu root
/// Outputs: <div class="radix-dropdown-menu" data-state="...">children</div>
pub fn radix_dropdown_menu(
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
      ("class", @luna.attr_static("radix-dropdown-menu")),
      ("data-state", @luna.attr_static(state)),
    ],
    children,
  )
}

///|
/// Create a headless dropdown menu trigger
/// Outputs: <button class="radix-dropdown-menu-trigger">children</button>
pub fn radix_dropdown_menu_trigger(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "button",
    [
      ("class", @luna.attr_static("radix-dropdown-menu-trigger")),
      ("aria-haspopup", @luna.attr_static("menu")),
    ],
    children,
  )
}

///|
/// Create a headless dropdown menu content
/// Outputs: <div class="radix-dropdown-menu-content" role="menu">children</div>
pub fn radix_dropdown_menu_content(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-dropdown-menu-content")),
      ("role", @luna.attr_static("menu")),
    ],
    children,
  )
}

///|
/// Create a headless dropdown menu item
/// Outputs: <div class="radix-dropdown-menu-item" role="menuitem">children</div>
pub fn radix_dropdown_menu_item(
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-dropdown-menu-item")),
    ("role", @luna.attr_static("menuitem")),
  ]

  match disabled {
    Some(true) => attrs.push(("data-disabled", @luna.attr_static("")))
    _ => ()
  }

  @luna.h("div", attrs, children)
}

///|
/// Create a headless dropdown menu separator
/// Outputs: <div class="radix-dropdown-menu-separator" role="separator"></div>
pub fn radix_dropdown_menu_separator() -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-dropdown-menu-separator")),
      ("role", @luna.attr_static("separator")),
    ],
    [],
  )
}

///|
/// Create a headless dropdown menu label
/// Outputs: <div class="radix-dropdown-menu-label">children</div>
pub fn radix_dropdown_menu_label(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-dropdown-menu-label"))],
    children,
  )
}

///|
/// Create a headless dropdown menu group
/// Outputs: <div class="radix-dropdown-menu-group" role="group">children</div>
pub fn radix_dropdown_menu_group(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-dropdown-menu-group")),
      ("role", @luna.attr_static("group")),
    ],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the dropdown menu component
fn dropdown_menu_styles() -> String {
  let css =
    #|:host {
    #|  display: inline-block;
    #|  position: relative;
    #|}
    #|
    #|.dropdown-trigger {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  gap: 0.25rem;
    #|  background: transparent;
    #|  border: none;
    #|  cursor: pointer;
    #|}
    #|
    #|.dropdown-content {
    #|  position: absolute;
    #|  top: 100%;
    #|  left: 0;
    #|  z-index: 50;
    #|  min-width: 8rem;
    #|  padding: 0.25rem;
    #|  background: white;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|  box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);
    #|}
    #|
    #|.dropdown-item {
    #|  display: flex;
    #|  align-items: center;
    #|  gap: 0.5rem;
    #|  padding: 0.5rem 0.75rem;
    #|  font-size: 0.875rem;
    #|  border-radius: 4px;
    #|  cursor: pointer;
    #|  transition: background 0.15s ease;
    #|}
    #|
    #|.dropdown-item:hover:not([data-disabled]) {
    #|  background: #f4f4f5;
    #|}
    #|
    #|.dropdown-item[data-disabled] {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
    #|
    #|.dropdown-separator {
    #|  height: 1px;
    #|  margin: 0.25rem -0.25rem;
    #|  background: #e4e4e7;
    #|}
    #|
    #|.dropdown-label {
    #|  padding: 0.5rem 0.75rem;
    #|  font-size: 0.75rem;
    #|  font-weight: 600;
    #|  color: #71717a;
    #|}
  css
}

///|
/// Create a styled dropdown menu with Declarative Shadow DOM
pub fn radix_dropdown_menu_styled(
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
    None => dropdown_menu_styles()
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
    "radix-dropdown-menu",
    [("data-state", @luna.attr_static(state))],
    all_children,
  )
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a dropdown menu with luna/css atomic styles
pub fn radix_dropdown_menu_ucss(
  open? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_open = match open {
    Some(true) => true
    _ => false
  }
  let state = if is_open { "open" } else { "closed" }

  let class_names = dropdown_menu_base_styles()
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
/// Create a dropdown menu trigger with luna/css atomic styles
pub fn radix_dropdown_menu_trigger_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = dropdown_menu_trigger_styles()
  @luna.h(
    "button",
    [
      ("class", @luna.attr_static(class_names)),
      ("aria-haspopup", @luna.attr_static("menu")),
    ],
    children,
  )
}

///|
/// Create a dropdown menu content with luna/css atomic styles
pub fn radix_dropdown_menu_content_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = dropdown_menu_content_styles()
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("role", @luna.attr_static("menu")),
    ],
    children,
  )
}

///|
/// Create a dropdown menu item with luna/css atomic styles
pub fn radix_dropdown_menu_item_ucss(
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let mut class_names = dropdown_menu_item_styles()

  match disabled {
    Some(true) =>
      class_names = class_names +
        " " +
        @css.styles([("opacity", "0.5"), ("cursor", "not-allowed")])
    _ => ()
  }

  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("role", @luna.attr_static("menuitem")),
  ]

  match disabled {
    Some(true) => attrs.push(("data-disabled", @luna.attr_static("")))
    _ => ()
  }

  @luna.h("div", attrs, children)
}

///|
/// Create a dropdown menu separator with luna/css atomic styles
pub fn radix_dropdown_menu_separator_ucss() -> @luna.Node[Unit] {
  let class_names = dropdown_menu_separator_styles()
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("role", @luna.attr_static("separator")),
    ],
    [],
  )
}

///|
/// Create a dropdown menu label with luna/css atomic styles
pub fn radix_dropdown_menu_label_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = dropdown_menu_label_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}
