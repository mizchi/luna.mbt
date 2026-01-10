///|
/// Radix-style ToggleGroup component for Luna (Headless)
/// Group of toggle buttons where only one or multiple can be active

///|
/// Toggle group type
pub(all) enum ToggleGroupType {
  Single
  Multiple
}

///|
pub fn ToggleGroupType::to_string(self : ToggleGroupType) -> String {
  match self {
    Single => "single"
    Multiple => "multiple"
  }
}

///|
/// Create a headless toggle group root
/// Outputs: <div class="radix-toggle-group" role="group" data-type="...">children</div>
pub fn radix_toggle_group(
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
      ("class", @luna.attr_static("radix-toggle-group")),
      ("role", @luna.attr_static("group")),
      ("data-type", @luna.attr_static(type_val.to_string())),
    ],
    children,
  )
}

///|
/// Create a headless toggle group item
/// Outputs: <button class="radix-toggle-group-item" data-state="..." aria-pressed="...">children</button>
pub fn radix_toggle_group_item(
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
    ("class", @luna.attr_static("radix-toggle-group-item")),
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
/// CSS styles for the toggle group component
fn toggle_group_styles() -> String {
  let css =
    #|:host {
    #|  display: inline-flex;
    #|}
    #|
    #|.toggle-group {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|  overflow: hidden;
    #|}
    #|
    #|.toggle-group-item {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  padding: 0.5rem 0.75rem;
    #|  font-size: 0.875rem;
    #|  font-weight: 500;
    #|  background: transparent;
    #|  border: none;
    #|  border-right: 1px solid #e4e4e7;
    #|  cursor: pointer;
    #|  transition: background 0.15s ease;
    #|}
    #|
    #|.toggle-group-item:last-child {
    #|  border-right: none;
    #|}
    #|
    #|.toggle-group-item:hover:not([data-disabled]) {
    #|  background: #f4f4f5;
    #|}
    #|
    #|.toggle-group-item[data-state="on"] {
    #|  background: #18181b;
    #|  color: white;
    #|}
    #|
    #|.toggle-group-item[data-disabled] {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
  css
}

///|
/// Create a styled toggle group with Declarative Shadow DOM
pub fn radix_toggle_group_styled(
  type_? : ToggleGroupType,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let type_val = match type_ {
    Some(t) => t
    None => Single
  }
  let css = match styles {
    Some(s) => s
    None => toggle_group_styles()
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
    "radix-toggle-group",
    [("data-type", @luna.attr_static(type_val.to_string()))],
    all_children,
  )
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a toggle group with luna/css atomic styles
pub fn radix_toggle_group_ucss(
  type_? : ToggleGroupType,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let type_val = match type_ {
    Some(t) => t
    None => Single
  }
  let class_names = toggle_group_base_styles()
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("role", @luna.attr_static("group")),
      ("data-type", @luna.attr_static(type_val.to_string())),
    ],
    children,
  )
}

///|
/// Create a toggle group item with luna/css atomic styles
pub fn radix_toggle_group_item_ucss(
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
  let mut class_names = toggle_group_item_styles()
  if is_pressed {
    class_names = class_names + " " + toggle_group_item_active_styles()
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
