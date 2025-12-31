///|
/// Radix-style ContextMenu component for Luna (Headless)
/// Right-click context menu

///|
/// Create a headless context menu root
/// Outputs: <div class="radix-context-menu">children</div>
pub fn radix_context_menu(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-context-menu"))], children)
}

///|
/// Create a headless context menu trigger
/// Outputs: <div class="radix-context-menu-trigger">children</div>
pub fn radix_context_menu_trigger(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-context-menu-trigger"))],
    children,
  )
}

///|
/// Create a headless context menu content
/// Outputs: <div class="radix-context-menu-content" role="menu">children</div>
pub fn radix_context_menu_content(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-context-menu-content")),
      ("role", @luna.attr_static("menu")),
    ],
    children,
  )
}

///|
/// Create a headless context menu item
/// Outputs: <div class="radix-context-menu-item" role="menuitem">children</div>
pub fn radix_context_menu_item(
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-context-menu-item")),
    ("role", @luna.attr_static("menuitem")),
  ]
  match disabled {
    Some(true) => attrs.push(("data-disabled", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a headless context menu checkbox item
/// Outputs: <div class="radix-context-menu-checkbox-item" role="menuitemcheckbox">children</div>
pub fn radix_context_menu_checkbox_item(
  checked? : Bool,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_checked = match checked {
    Some(true) => true
    _ => false
  }
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-context-menu-checkbox-item")),
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
/// Create a headless context menu radio group
/// Outputs: <div class="radix-context-menu-radio-group" role="group">children</div>
pub fn radix_context_menu_radio_group(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-context-menu-radio-group")),
      ("role", @luna.attr_static("group")),
    ],
    children,
  )
}

///|
/// Create a headless context menu radio item
/// Outputs: <div class="radix-context-menu-radio-item" role="menuitemradio">children</div>
pub fn radix_context_menu_radio_item(
  checked? : Bool,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_checked = match checked {
    Some(true) => true
    _ => false
  }
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-context-menu-radio-item")),
    ("role", @luna.attr_static("menuitemradio")),
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
/// Create a headless context menu separator
/// Outputs: <div class="radix-context-menu-separator" role="separator"></div>
pub fn radix_context_menu_separator() -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-context-menu-separator")),
      ("role", @luna.attr_static("separator")),
    ],
    [],
  )
}

///|
/// Create a headless context menu label
/// Outputs: <div class="radix-context-menu-label">children</div>
pub fn radix_context_menu_label(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-context-menu-label"))],
    children,
  )
}

///|
/// Create a headless context menu sub trigger
/// Outputs: <div class="radix-context-menu-sub-trigger">children</div>
pub fn radix_context_menu_sub_trigger(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-context-menu-sub-trigger"))],
    children,
  )
}

///|
/// Create a headless context menu sub content
/// Outputs: <div class="radix-context-menu-sub-content">children</div>
pub fn radix_context_menu_sub_content(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-context-menu-sub-content"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the context menu component
fn context_menu_styles() -> String {
  let css =
    #|:host {
    #|  display: contents;
    #|}
    #|
    #|.context-menu-content {
    #|  position: fixed;
    #|  z-index: 50;
    #|  min-width: 8rem;
    #|  padding: 0.25rem;
    #|  background: white;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|  box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);
    #|}
    #|
    #|.context-menu-item,
    #|.context-menu-checkbox-item,
    #|.context-menu-radio-item {
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
    #|.context-menu-item:hover:not([data-disabled]),
    #|.context-menu-checkbox-item:hover:not([data-disabled]),
    #|.context-menu-radio-item:hover:not([data-disabled]) {
    #|  background: #f4f4f5;
    #|}
    #|
    #|.context-menu-item[data-disabled],
    #|.context-menu-checkbox-item[data-disabled],
    #|.context-menu-radio-item[data-disabled] {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
    #|
    #|.context-menu-separator {
    #|  height: 1px;
    #|  margin: 0.25rem -0.25rem;
    #|  background: #e4e4e7;
    #|}
    #|
    #|.context-menu-label {
    #|  padding: 0.5rem 0.75rem;
    #|  font-size: 0.75rem;
    #|  font-weight: 600;
    #|  color: #71717a;
    #|}
    #|
    #|.context-menu-sub-trigger {
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: space-between;
    #|  padding: 0.5rem 0.75rem;
    #|  font-size: 0.875rem;
    #|  border-radius: 4px;
    #|  cursor: pointer;
    #|}
    #|
    #|.context-menu-sub-trigger:hover {
    #|  background: #f4f4f5;
    #|}
    #|
    #|.context-menu-sub-content {
    #|  position: absolute;
    #|  left: 100%;
    #|  top: 0;
    #|  min-width: 8rem;
    #|  padding: 0.25rem;
    #|  background: white;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|  box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);
    #|}
  css
}

///|
/// Create a styled context menu with Declarative Shadow DOM
pub fn radix_context_menu_styled(
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => context_menu_styles()
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
  @luna.h("radix-context-menu", [], all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a context menu content with luna/css atomic styles
pub fn radix_context_menu_content_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = context_menu_content_styles()
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
/// Create a context menu item with luna/css atomic styles
pub fn radix_context_menu_item_ucss(
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let mut class_names = context_menu_item_styles()
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
/// Create a context menu separator with luna/css atomic styles
pub fn radix_context_menu_separator_ucss() -> @luna.Node[Unit] {
  let class_names = context_menu_separator_styles()
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
/// Create a context menu label with luna/css atomic styles
pub fn radix_context_menu_label_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = context_menu_label_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}
