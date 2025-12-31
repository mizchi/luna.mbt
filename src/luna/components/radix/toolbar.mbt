///|
/// Radix-style Toolbar component for Luna (Headless)
/// Toolbar with buttons, toggles, and separators

///|
/// Create a headless toolbar root
/// Outputs: <div class="radix-toolbar" role="toolbar">children</div>
pub fn radix_toolbar(
  orientation? : Orientation,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let orient = match orientation {
    Some(o) => o
    None => Horizontal
  }
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-toolbar")),
      ("role", @luna.attr_static("toolbar")),
      ("data-orientation", @luna.attr_static(orient.to_string())),
    ],
    children,
  )
}

///|
/// Create a headless toolbar button
/// Outputs: <button class="radix-toolbar-button">children</button>
pub fn radix_toolbar_button(
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-toolbar-button")),
  ]
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
/// Create a headless toolbar separator
/// Outputs: <div class="radix-toolbar-separator" role="separator"></div>
pub fn radix_toolbar_separator() -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-toolbar-separator")),
      ("role", @luna.attr_static("separator")),
    ],
    [],
  )
}

///|
/// Create a headless toolbar link
/// Outputs: <a class="radix-toolbar-link" href="...">children</a>
pub fn radix_toolbar_link(
  href : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "a",
    [
      ("class", @luna.attr_static("radix-toolbar-link")),
      ("href", @luna.attr_static(href)),
    ],
    children,
  )
}

///|
/// Create a headless toolbar toggle group
/// Outputs: <div class="radix-toolbar-toggle-group" role="group">children</div>
pub fn radix_toolbar_toggle_group(
  type_? : ToggleGroupType,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let type_val = match type_ {
    Some(t) => t
    None => Single
  }
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-toolbar-toggle-group")),
      ("role", @luna.attr_static("group")),
      ("data-type", @luna.attr_static(type_val.to_string())),
    ],
    children,
  )
}

///|
/// Create a headless toolbar toggle item
/// Outputs: <button class="radix-toolbar-toggle-item" data-state="...">children</button>
pub fn radix_toolbar_toggle_item(
  value : String,
  pressed? : Bool,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_pressed = match pressed {
    Some(true) => true
    _ => false
  }
  let state = if is_pressed { "on" } else { "off" }
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-toolbar-toggle-item")),
    ("data-state", @luna.attr_static(state)),
    ("data-value", @luna.attr_static(value)),
    (
      "aria-pressed",
      @luna.attr_static(if is_pressed { "true" } else { "false" }),
    ),
  ]
  match disabled {
    Some(true) => {
      attrs.push(("data-disabled", @luna.attr_static("")))
      attrs.push(("disabled", @luna.attr_static("")))
    }
    _ => ()
  }
  @luna.h("button", attrs, children)
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the toolbar component
fn toolbar_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.toolbar {
    #|  display: flex;
    #|  align-items: center;
    #|  gap: 0.25rem;
    #|  padding: 0.25rem;
    #|  background: white;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|}
    #|
    #|.toolbar[data-orientation="vertical"] {
    #|  flex-direction: column;
    #|}
    #|
    #|.toolbar-button {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  padding: 0.5rem;
    #|  font-size: 0.875rem;
    #|  background: transparent;
    #|  border: none;
    #|  border-radius: 4px;
    #|  cursor: pointer;
    #|  transition: background 0.15s ease;
    #|}
    #|
    #|.toolbar-button:hover:not([data-disabled]) {
    #|  background: #f4f4f5;
    #|}
    #|
    #|.toolbar-button[data-disabled] {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
    #|
    #|.toolbar-separator {
    #|  width: 1px;
    #|  height: 1rem;
    #|  background: #e4e4e7;
    #|  margin: 0 0.25rem;
    #|}
    #|
    #|.toolbar[data-orientation="vertical"] .toolbar-separator {
    #|  width: 100%;
    #|  height: 1px;
    #|  margin: 0.25rem 0;
    #|}
    #|
    #|.toolbar-link {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  padding: 0.5rem;
    #|  font-size: 0.875rem;
    #|  text-decoration: none;
    #|  color: #18181b;
    #|  border-radius: 4px;
    #|}
    #|
    #|.toolbar-link:hover {
    #|  background: #f4f4f5;
    #|}
    #|
    #|.toolbar-toggle-group {
    #|  display: inline-flex;
    #|  align-items: center;
    #|}
    #|
    #|.toolbar-toggle-item {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  padding: 0.5rem;
    #|  font-size: 0.875rem;
    #|  background: transparent;
    #|  border: none;
    #|  border-radius: 4px;
    #|  cursor: pointer;
    #|  transition: background 0.15s ease;
    #|}
    #|
    #|.toolbar-toggle-item:hover:not([data-disabled]) {
    #|  background: #f4f4f5;
    #|}
    #|
    #|.toolbar-toggle-item[data-state="on"] {
    #|  background: #18181b;
    #|  color: white;
    #|}
    #|
    #|.toolbar-toggle-item[data-disabled] {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
  css
}

///|
/// Create a styled toolbar with Declarative Shadow DOM
pub fn radix_toolbar_styled(
  orientation? : Orientation,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let orient = match orientation {
    Some(o) => o
    None => Horizontal
  }
  let css = match styles {
    Some(s) => s
    None => toolbar_styles()
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
    "radix-toolbar",
    [("data-orientation", @luna.attr_static(orient.to_string()))],
    all_children,
  )
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a toolbar with luna/css atomic styles
pub fn radix_toolbar_ucss(
  orientation? : Orientation,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let orient = match orientation {
    Some(o) => o
    None => Horizontal
  }
  let class_names = toolbar_base_styles() +
    " " +
    toolbar_orientation_styles(orient)
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("role", @luna.attr_static("toolbar")),
      ("data-orientation", @luna.attr_static(orient.to_string())),
    ],
    children,
  )
}

///|
/// Create a toolbar button with luna/css atomic styles
pub fn radix_toolbar_button_ucss(
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let mut class_names = toolbar_button_styles()
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
/// Create a toolbar separator with luna/css atomic styles
pub fn radix_toolbar_separator_ucss() -> @luna.Node[Unit] {
  let class_names = toolbar_separator_styles()
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
/// Create a toolbar toggle item with luna/css atomic styles
pub fn radix_toolbar_toggle_item_ucss(
  value : String,
  pressed? : Bool,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_pressed = match pressed {
    Some(true) => true
    _ => false
  }
  let state = if is_pressed { "on" } else { "off" }
  let mut class_names = toolbar_toggle_item_styles()
  if is_pressed {
    class_names = class_names +
      " " +
      @css.styles([("background", "#18181b"), ("color", "white")])
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
    ("data-state", @luna.attr_static(state)),
    ("data-value", @luna.attr_static(value)),
    (
      "aria-pressed",
      @luna.attr_static(if is_pressed { "true" } else { "false" }),
    ),
  ]
  match disabled {
    Some(true) => {
      attrs.push(("data-disabled", @luna.attr_static("")))
      attrs.push(("disabled", @luna.attr_static("")))
    }
    _ => ()
  }
  @luna.h("button", attrs, children)
}
