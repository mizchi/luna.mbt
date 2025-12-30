///|
/// Radix-style Switch component for Luna
/// Uses Declarative Shadow DOM with data-state attribute for styling

///|
/// CSS styles for the Radix switch component
fn switch_styles() -> String {
  let css =
    #|:host {
    #|  display: inline-flex;
    #|  align-items: center;
    #|}
    #|
    #|.switch-wrapper {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  gap: 0.5rem;
    #|}
    #|
    #|.switch-root {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  width: 2.75rem;
    #|  height: 1.5rem;
    #|  padding: 2px;
    #|  border: none;
    #|  border-radius: 9999px;
    #|  background: #e4e4e7;
    #|  cursor: pointer;
    #|  transition: background-color 0.15s ease;
    #|  flex-shrink: 0;
    #|}
    #|
    #|/* Checked state */
    #|.switch-root[data-state="checked"] {
    #|  background: #18181b;
    #|}
    #|
    #|/* Disabled state */
    #|.switch-root[data-disabled] {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
    #|
    #|/* Focus ring */
    #|.switch-root:focus-visible {
    #|  outline: 2px solid #2563eb;
    #|  outline-offset: 2px;
    #|}
    #|
    #|/* Thumb (the sliding circle) */
    #|.switch-thumb {
    #|  display: block;
    #|  width: 1.25rem;
    #|  height: 1.25rem;
    #|  background: white;
    #|  border-radius: 9999px;
    #|  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    #|  transition: transform 0.15s ease;
    #|  transform: translateX(0);
    #|}
    #|
    #|.switch-root[data-state="checked"] .switch-thumb {
    #|  transform: translateX(1.25rem);
    #|}
    #|
    #|/* Size variants */
    #|.switch-root[data-size="small"] {
    #|  width: 2rem;
    #|  height: 1rem;
    #|}
    #|.switch-root[data-size="small"] .switch-thumb {
    #|  width: 0.75rem;
    #|  height: 0.75rem;
    #|}
    #|.switch-root[data-size="small"][data-state="checked"] .switch-thumb {
    #|  transform: translateX(1rem);
    #|}
    #|
    #|.switch-root[data-size="large"] {
    #|  width: 3.5rem;
    #|  height: 2rem;
    #|}
    #|.switch-root[data-size="large"] .switch-thumb {
    #|  width: 1.75rem;
    #|  height: 1.75rem;
    #|}
    #|.switch-root[data-size="large"][data-state="checked"] .switch-thumb {
    #|  transform: translateX(1.5rem);
    #|}
    #|
    #|/* Label */
    #|.switch-label {
    #|  font-size: 0.875rem;
    #|  color: #18181b;
    #|  user-select: none;
    #|}
    #|
    #|.switch-wrapper:has(.switch-root[data-disabled]) .switch-label {
    #|  opacity: 0.5;
    #|}
  css
}

///|
/// Create a radix-switch element with Declarative Shadow DOM
/// Uses data-state attribute for styling (Radix UI pattern)
pub fn radix_switch(
  checked? : Bool,
  disabled? : Bool,
  size? : RadixSize,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_checked = match checked {
    Some(true) => true
    _ => false
  }
  let state = if is_checked { "checked" } else { "unchecked" }
  let size_val = match size {
    Some(s) => s
    None => Medium
  }

  // Build switch button attributes
  let switch_attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("switch-root")),
    ("role", @luna.attr_static("switch")),
    ("data-state", @luna.attr_static(state)),
    ("data-size", @luna.attr_static(size_val.to_string())),
    (
      "aria-checked",
      @luna.attr_static(if is_checked { "true" } else { "false" }),
    ),
  ]
  match disabled {
    Some(true) => {
      switch_attrs.push(("data-disabled", @luna.attr_static("")))
      switch_attrs.push(("aria-disabled", @luna.attr_static("true")))
    }
    _ => ()
  }

  // Build switch content (thumb)
  let switch_content : Array[@luna.Node[Unit]] = [
    @luna.h("span", [("class", @luna.attr_static("switch-thumb"))], []),
  ]

  // Build wrapper with label slot
  let wrapper_children : Array[@luna.Node[Unit]] = [
    @luna.h("button", switch_attrs, switch_content),
    @luna.h("label", [("class", @luna.attr_static("switch-label"))], [
      @luna.h("slot", [], []),
    ]),
  ]

  // Build template content
  let template_children : Array[@luna.Node[Unit]] = [
    @luna.h("style", [], [@luna.text(switch_styles())]),
    @luna.h(
      "span",
      [("class", @luna.attr_static("switch-wrapper"))],
      wrapper_children,
    ),
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

  // Host element with data-state for external styling
  let host_attrs : Array[(String, @luna.Attr[Unit])] = [
    ("data-state", @luna.attr_static(state)),
  ]
  match disabled {
    Some(true) => host_attrs.push(("data-disabled", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("radix-switch", host_attrs, all_children)
}
