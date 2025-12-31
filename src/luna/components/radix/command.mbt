///|
/// Radix-style Command component for Luna (Headless)
/// Command palette (cmdk-style)

///|
/// Create a headless command root
/// Outputs: <div class="radix-command">children</div>
pub fn radix_command(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-command"))], children)
}

///|
/// Create a headless command input
/// Outputs: <input class="radix-command-input" type="text" />
pub fn radix_command_input(placeholder? : String) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-command-input")),
    ("type", @luna.attr_static("text")),
  ]
  match placeholder {
    Some(p) => attrs.push(("placeholder", @luna.attr_static(p)))
    None => ()
  }
  @luna.h("input", attrs, [])
}

///|
/// Create a headless command list
/// Outputs: <div class="radix-command-list" role="listbox">children</div>
pub fn radix_command_list(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-command-list")),
      ("role", @luna.attr_static("listbox")),
    ],
    children,
  )
}

///|
/// Create a headless command empty state
/// Outputs: <div class="radix-command-empty">children</div>
pub fn radix_command_empty(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-command-empty"))],
    children,
  )
}

///|
/// Create a headless command group
/// Outputs: <div class="radix-command-group" role="group">children</div>
pub fn radix_command_group(
  heading? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-command-group")),
    ("role", @luna.attr_static("group")),
  ]
  match heading {
    Some(h) => attrs.push(("data-heading", @luna.attr_static(h)))
    None => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a headless command group heading
/// Outputs: <div class="radix-command-group-heading">children</div>
pub fn radix_command_group_heading(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-command-group-heading"))],
    children,
  )
}

///|
/// Create a headless command item
/// Outputs: <div class="radix-command-item" role="option">children</div>
pub fn radix_command_item(
  value? : String,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-command-item")),
    ("role", @luna.attr_static("option")),
  ]
  match value {
    Some(v) => attrs.push(("data-value", @luna.attr_static(v)))
    None => ()
  }
  match disabled {
    Some(true) => attrs.push(("data-disabled", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a headless command separator
/// Outputs: <div class="radix-command-separator"></div>
pub fn radix_command_separator() -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-command-separator"))], [])
}

///|
/// Create a headless command shortcut
/// Outputs: <span class="radix-command-shortcut">children</span>
pub fn radix_command_shortcut(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "span",
    [("class", @luna.attr_static("radix-command-shortcut"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the command component
fn command_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.command {
    #|  width: 100%;
    #|  max-width: 32rem;
    #|  background: white;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 8px;
    #|  overflow: hidden;
    #|  box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);
    #|}
    #|
    #|.command-input {
    #|  width: 100%;
    #|  padding: 0.75rem 1rem;
    #|  font-size: 0.875rem;
    #|  background: transparent;
    #|  border: none;
    #|  border-bottom: 1px solid #e4e4e7;
    #|  outline: none;
    #|}
    #|
    #|.command-input::placeholder {
    #|  color: #a1a1aa;
    #|}
    #|
    #|.command-list {
    #|  max-height: 300px;
    #|  overflow: auto;
    #|  padding: 0.25rem;
    #|}
    #|
    #|.command-empty {
    #|  padding: 1.5rem;
    #|  text-align: center;
    #|  font-size: 0.875rem;
    #|  color: #71717a;
    #|}
    #|
    #|.command-group {
    #|  padding: 0.25rem 0;
    #|}
    #|
    #|.command-group-heading {
    #|  padding: 0.5rem 0.75rem;
    #|  font-size: 0.75rem;
    #|  font-weight: 500;
    #|  color: #71717a;
    #|}
    #|
    #|.command-item {
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
    #|.command-item:hover:not([data-disabled]) {
    #|  background: #f4f4f5;
    #|}
    #|
    #|.command-item[data-disabled] {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
    #|
    #|.command-separator {
    #|  height: 1px;
    #|  margin: 0.25rem -0.25rem;
    #|  background: #e4e4e7;
    #|}
    #|
    #|.command-shortcut {
    #|  font-size: 0.75rem;
    #|  color: #71717a;
    #|}
  css
}

///|
/// Create a styled command with Declarative Shadow DOM
pub fn radix_command_styled(
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => command_styles()
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
  @luna.h("radix-command", [], all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a command with luna/css atomic styles
pub fn radix_command_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = command_base_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a command input with luna/css atomic styles
pub fn radix_command_input_ucss(placeholder? : String) -> @luna.Node[Unit] {
  let class_names = command_input_styles()
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("type", @luna.attr_static("text")),
  ]
  match placeholder {
    Some(p) => attrs.push(("placeholder", @luna.attr_static(p)))
    None => ()
  }
  @luna.h("input", attrs, [])
}

///|
/// Create a command list with luna/css atomic styles
pub fn radix_command_list_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = command_list_styles()
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("role", @luna.attr_static("listbox")),
    ],
    children,
  )
}

///|
/// Create a command item with luna/css atomic styles
pub fn radix_command_item_ucss(
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let mut class_names = command_item_styles()
  match disabled {
    Some(true) =>
      class_names = class_names +
        " " +
        @css.styles([("opacity", "0.5"), ("cursor", "not-allowed")])
    _ => ()
  }
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("role", @luna.attr_static("option")),
  ]
  match disabled {
    Some(true) => attrs.push(("data-disabled", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a command group heading with luna/css atomic styles
pub fn radix_command_group_heading_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = command_group_heading_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}
