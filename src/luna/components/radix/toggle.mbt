///|
/// Radix-style Toggle component for Luna
/// Uses Declarative Shadow DOM with data-state attribute for styling

///|
/// CSS styles for the toggle component
fn toggle_styles() -> String {
  let css =
    #|:host {
    #|  display: inline-block;
    #|}
    #|
    #|.toggle {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|  background: transparent;
    #|  color: #71717a;
    #|  cursor: pointer;
    #|  font-family: inherit;
    #|  font-weight: 500;
    #|  transition: all 0.15s ease;
    #|}
    #|
    #|/* Sizes */
    #|.toggle[data-size="small"] { height: 2rem; width: 2rem; font-size: 0.75rem; }
    #|.toggle[data-size="medium"] { height: 2.5rem; width: 2.5rem; font-size: 0.875rem; }
    #|.toggle[data-size="large"] { height: 3rem; width: 3rem; font-size: 1rem; }
    #|
    #|/* Pressed state */
    #|.toggle[data-state="on"] {
    #|  background: #f4f4f5;
    #|  color: #18181b;
    #|  border-color: #18181b;
    #|}
    #|
    #|/* Hover */
    #|.toggle:hover:not([data-disabled]) {
    #|  background: #f4f4f5;
    #|}
    #|
    #|.toggle[data-state="on"]:hover:not([data-disabled]) {
    #|  background: #e4e4e7;
    #|}
    #|
    #|/* Disabled state */
    #|.toggle[data-disabled] {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
    #|
    #|/* Focus ring */
    #|.toggle:focus-visible {
    #|  outline: 2px solid #2563eb;
    #|  outline-offset: 2px;
    #|}
  css
}

///|
/// Create a radix-toggle element with Declarative Shadow DOM
/// Toggle is like a button that can be pressed/unpressed
pub fn radix_toggle(
  pressed? : Bool,
  disabled? : Bool,
  size? : RadixSize,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_pressed = match pressed {
    Some(true) => true
    _ => false
  }
  let state = if is_pressed { "on" } else { "off" }
  let size_val = match size {
    Some(s) => s
    None => Medium
  }

  // Build toggle attributes
  let toggle_attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("toggle")),
    ("type", @luna.attr_static("button")),
    ("data-state", @luna.attr_static(state)),
    ("data-size", @luna.attr_static(size_val.to_string())),
    (
      "aria-pressed",
      @luna.attr_static(if is_pressed { "true" } else { "false" }),
    ),
  ]
  match disabled {
    Some(true) => {
      toggle_attrs.push(("data-disabled", @luna.attr_static("")))
      toggle_attrs.push(("disabled", @luna.attr_static("")))
    }
    _ => ()
  }

  // Build template content
  let template_children : Array[@luna.Node[Unit]] = [
    @luna.h("style", [], [@luna.text(toggle_styles())]),
    @luna.h("button", toggle_attrs, [@luna.h("slot", [], [])]),
  ]

  // Create the DSD structure
  let all_children : Array[@luna.Node[Unit]] = [
    @luna.h(
      "template",
      [("shadowrootmode", @luna.attr_static("open"))],
      template_children,
    ),
  ]

  // Add light DOM children
  for child in children {
    all_children.push(child)
  }

  // Host attributes
  let host_attrs : Array[(String, @luna.Attr[Unit])] = [
    ("data-state", @luna.attr_static(state)),
  ]
  match disabled {
    Some(true) => host_attrs.push(("data-disabled", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("radix-toggle", host_attrs, all_children)
}
