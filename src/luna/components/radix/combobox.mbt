///|
/// Radix-style Combobox component for Luna (Headless)
/// Searchable select/autocomplete

///|
/// Create a headless combobox root
/// Outputs: <div class="radix-combobox" data-state="...">children</div>
pub fn radix_combobox(
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
      ("class", @luna.attr_static("radix-combobox")),
      ("data-state", @luna.attr_static(state)),
    ],
    children,
  )
}

///|
/// Create a headless combobox trigger
/// Outputs: <button class="radix-combobox-trigger">children</button>
pub fn radix_combobox_trigger(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "button",
    [
      ("class", @luna.attr_static("radix-combobox-trigger")),
      ("role", @luna.attr_static("combobox")),
      ("aria-haspopup", @luna.attr_static("listbox")),
    ],
    children,
  )
}

///|
/// Create a headless combobox input
/// Outputs: <input class="radix-combobox-input" type="text" />
pub fn radix_combobox_input(
  placeholder? : String,
  value? : String,
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-combobox-input")),
    ("type", @luna.attr_static("text")),
    ("role", @luna.attr_static("combobox")),
    ("aria-autocomplete", @luna.attr_static("list")),
  ]
  match placeholder {
    Some(p) => attrs.push(("placeholder", @luna.attr_static(p)))
    None => ()
  }
  match value {
    Some(v) => attrs.push(("value", @luna.attr_static(v)))
    None => ()
  }
  @luna.h("input", attrs, [])
}

///|
/// Create a headless combobox content
/// Outputs: <div class="radix-combobox-content" role="listbox">children</div>
pub fn radix_combobox_content(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-combobox-content")),
      ("role", @luna.attr_static("listbox")),
    ],
    children,
  )
}

///|
/// Create a headless combobox item
/// Outputs: <div class="radix-combobox-item" role="option">children</div>
pub fn radix_combobox_item(
  value : String,
  selected? : Bool,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_selected = match selected {
    Some(true) => true
    _ => false
  }
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-combobox-item")),
    ("role", @luna.attr_static("option")),
    ("data-value", @luna.attr_static(value)),
    (
      "aria-selected",
      @luna.attr_static(if is_selected { "true" } else { "false" }),
    ),
  ]
  if is_selected {
    attrs.push(("data-selected", @luna.attr_static("")))
  }
  match disabled {
    Some(true) => attrs.push(("data-disabled", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a headless combobox empty state
/// Outputs: <div class="radix-combobox-empty">children</div>
pub fn radix_combobox_empty(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-combobox-empty"))],
    children,
  )
}

///|
/// Create a headless combobox group
/// Outputs: <div class="radix-combobox-group" role="group">children</div>
pub fn radix_combobox_group(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-combobox-group")),
      ("role", @luna.attr_static("group")),
    ],
    children,
  )
}

///|
/// Create a headless combobox group label
/// Outputs: <div class="radix-combobox-group-label">children</div>
pub fn radix_combobox_group_label(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-combobox-group-label"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the combobox component
fn combobox_styles() -> String {
  let css =
    #|:host {
    #|  display: inline-block;
    #|  position: relative;
    #|}
    #|
    #|.combobox-trigger {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  justify-content: space-between;
    #|  min-width: 12rem;
    #|  padding: 0.5rem 0.75rem;
    #|  font-size: 0.875rem;
    #|  background: white;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|  cursor: pointer;
    #|  transition: border-color 0.15s ease;
    #|}
    #|
    #|.combobox-trigger:hover {
    #|  border-color: #a1a1aa;
    #|}
    #|
    #|.combobox-input {
    #|  width: 100%;
    #|  padding: 0.5rem 0.75rem;
    #|  font-size: 0.875rem;
    #|  background: white;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|  outline: none;
    #|  transition: border-color 0.15s ease;
    #|}
    #|
    #|.combobox-input:focus {
    #|  border-color: #18181b;
    #|}
    #|
    #|.combobox-content {
    #|  position: absolute;
    #|  top: 100%;
    #|  left: 0;
    #|  z-index: 50;
    #|  width: 100%;
    #|  min-width: 12rem;
    #|  max-height: 300px;
    #|  overflow: auto;
    #|  padding: 0.25rem;
    #|  margin-top: 0.25rem;
    #|  background: white;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|  box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);
    #|}
    #|
    #|.combobox-item {
    #|  display: flex;
    #|  align-items: center;
    #|  padding: 0.5rem 0.75rem;
    #|  font-size: 0.875rem;
    #|  border-radius: 4px;
    #|  cursor: pointer;
    #|  transition: background 0.15s ease;
    #|}
    #|
    #|.combobox-item:hover:not([data-disabled]) {
    #|  background: #f4f4f5;
    #|}
    #|
    #|.combobox-item[data-selected] {
    #|  background: #f4f4f5;
    #|  font-weight: 500;
    #|}
    #|
    #|.combobox-item[data-disabled] {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
    #|
    #|.combobox-empty {
    #|  padding: 1rem;
    #|  text-align: center;
    #|  font-size: 0.875rem;
    #|  color: #71717a;
    #|}
    #|
    #|.combobox-group-label {
    #|  padding: 0.5rem 0.75rem;
    #|  font-size: 0.75rem;
    #|  font-weight: 500;
    #|  color: #71717a;
    #|}
  css
}

///|
/// Create a styled combobox with Declarative Shadow DOM
pub fn radix_combobox_styled(
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
    None => combobox_styles()
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
    "radix-combobox",
    [("data-state", @luna.attr_static(state))],
    all_children,
  )
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a combobox with luna/css atomic styles
pub fn radix_combobox_ucss(
  open? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_open = match open {
    Some(true) => true
    _ => false
  }
  let state = if is_open { "open" } else { "closed" }
  let class_names = combobox_base_styles()
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
/// Create a combobox trigger with luna/css atomic styles
pub fn radix_combobox_trigger_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = combobox_trigger_styles()
  @luna.h(
    "button",
    [
      ("class", @luna.attr_static(class_names)),
      ("role", @luna.attr_static("combobox")),
    ],
    children,
  )
}

///|
/// Create a combobox input with luna/css atomic styles
pub fn radix_combobox_input_ucss(placeholder? : String) -> @luna.Node[Unit] {
  let class_names = combobox_input_styles()
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
/// Create a combobox content with luna/css atomic styles
pub fn radix_combobox_content_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = combobox_content_styles()
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
/// Create a combobox item with luna/css atomic styles
pub fn radix_combobox_item_ucss(
  value : String,
  selected? : Bool,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_selected = match selected {
    Some(true) => true
    _ => false
  }
  let mut class_names = combobox_item_styles()
  if is_selected {
    class_names = class_names +
      " " +
      @css.styles([("background", "#f4f4f5"), ("font-weight", "500")])
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
    ("role", @luna.attr_static("option")),
    ("data-value", @luna.attr_static(value)),
  ]
  if is_selected {
    attrs.push(("data-selected", @luna.attr_static("")))
  }
  match disabled {
    Some(true) => attrs.push(("data-disabled", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("div", attrs, children)
}
