///|
/// Radix-style Menubar component for Luna (Headless)
/// Horizontal menu bar with dropdown menus

///|
/// Create a headless menubar root
/// Outputs: <div class="radix-menubar" role="menubar">children</div>
pub fn radix_menubar(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-menubar")),
      ("role", @luna.attr_static("menubar")),
    ],
    children,
  )
}

///|
/// Create a headless menubar menu
/// Outputs: <div class="radix-menubar-menu">children</div>
pub fn radix_menubar_menu(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-menubar-menu"))],
    children,
  )
}

///|
/// Create a headless menubar trigger
/// Outputs: <button class="radix-menubar-trigger">children</button>
pub fn radix_menubar_trigger(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "button",
    [
      ("class", @luna.attr_static("radix-menubar-trigger")),
      ("role", @luna.attr_static("menuitem")),
    ],
    children,
  )
}

///|
/// Create a headless menubar content
/// Outputs: <div class="radix-menubar-content" role="menu">children</div>
pub fn radix_menubar_content(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-menubar-content")),
      ("role", @luna.attr_static("menu")),
    ],
    children,
  )
}

///|
/// Create a headless menubar item
/// Outputs: <div class="radix-menubar-item" role="menuitem">children</div>
pub fn radix_menubar_item(
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-menubar-item")),
    ("role", @luna.attr_static("menuitem")),
  ]

  match disabled {
    Some(true) => attrs.push(("data-disabled", @luna.attr_static("")))
    _ => ()
  }

  @luna.h("div", attrs, children)
}

///|
/// Create a headless menubar separator
/// Outputs: <div class="radix-menubar-separator" role="separator"></div>
pub fn radix_menubar_separator() -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-menubar-separator")),
      ("role", @luna.attr_static("separator")),
    ],
    [],
  )
}

///|
/// Create a headless menubar checkbox item
/// Outputs: <div class="radix-menubar-checkbox-item" role="menuitemcheckbox">children</div>
pub fn radix_menubar_checkbox_item(
  checked? : Bool,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_checked = match checked {
    Some(true) => true
    _ => false
  }

  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-menubar-checkbox-item")),
    ("role", @luna.attr_static("menuitemcheckbox")),
    (
      "aria-checked",
      @luna.attr_static(if is_checked { "true" } else { "false" }),
    ),
  ]

  if is_checked {
    attrs.push(("data-state", @luna.attr_static("checked")))
  }

  match disabled {
    Some(true) => attrs.push(("data-disabled", @luna.attr_static("")))
    _ => ()
  }

  @luna.h("div", attrs, children)
}

///|
/// Create a headless menubar shortcut
/// Outputs: <span class="radix-menubar-shortcut">children</span>
pub fn radix_menubar_shortcut(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "span",
    [("class", @luna.attr_static("radix-menubar-shortcut"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the menubar component
fn menubar_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.menubar {
    #|  display: flex;
    #|  align-items: center;
    #|  gap: 0.25rem;
    #|  padding: 0.25rem;
    #|  background: white;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|}
    #|
    #|.menubar-menu {
    #|  position: relative;
    #|}
    #|
    #|.menubar-trigger {
    #|  display: inline-flex;
    #|  align-items: center;
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
    #|.menubar-trigger:hover {
    #|  background: #f4f4f5;
    #|}
    #|
    #|.menubar-content {
    #|  position: absolute;
    #|  top: 100%;
    #|  left: 0;
    #|  z-index: 50;
    #|  min-width: 12rem;
    #|  padding: 0.25rem;
    #|  background: white;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|  box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);
    #|}
    #|
    #|.menubar-item {
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: space-between;
    #|  padding: 0.5rem 0.75rem;
    #|  font-size: 0.875rem;
    #|  border-radius: 4px;
    #|  cursor: pointer;
    #|  transition: background 0.15s ease;
    #|}
    #|
    #|.menubar-item:hover:not([data-disabled]) {
    #|  background: #f4f4f5;
    #|}
    #|
    #|.menubar-item[data-disabled] {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
    #|
    #|.menubar-separator {
    #|  height: 1px;
    #|  margin: 0.25rem -0.25rem;
    #|  background: #e4e4e7;
    #|}
    #|
    #|.menubar-shortcut {
    #|  margin-left: auto;
    #|  font-size: 0.75rem;
    #|  color: #71717a;
    #|}
  css
}

///|
/// Create a styled menubar with Declarative Shadow DOM
pub fn radix_menubar_styled(
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => menubar_styles()
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

  @luna.h("radix-menubar", [], all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a menubar with luna/css atomic styles
pub fn radix_menubar_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = menubar_base_styles()
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("role", @luna.attr_static("menubar")),
    ],
    children,
  )
}

///|
/// Create a menubar trigger with luna/css atomic styles
pub fn radix_menubar_trigger_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = menubar_trigger_styles()
  @luna.h("button", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a menubar content with luna/css atomic styles
pub fn radix_menubar_content_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = menubar_content_styles()
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
/// Create a menubar item with luna/css atomic styles
pub fn radix_menubar_item_ucss(
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let mut class_names = menubar_item_styles()

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
/// Create a menubar separator with luna/css atomic styles
pub fn radix_menubar_separator_ucss() -> @luna.Node[Unit] {
  let class_names = menubar_separator_styles()
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
/// Create a menubar shortcut with luna/css atomic styles
pub fn radix_menubar_shortcut_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = menubar_shortcut_styles()
  @luna.h("span", [("class", @luna.attr_static(class_names))], children)
}
