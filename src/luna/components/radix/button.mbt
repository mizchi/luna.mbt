///|
/// Radix-style Button component for Luna
/// Uses Declarative Shadow DOM with data-* attributes for styling

///|
/// CSS styles for the Radix button component
/// Uses data-* attribute selectors like Radix UI
fn button_styles() -> String {
  let css =
    #|:host {
    #|  display: inline-block;
    #|}
    #|
    #|.button {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  gap: 0.5em;
    #|  border: none;
    #|  border-radius: 4px;
    #|  cursor: pointer;
    #|  font-family: inherit;
    #|  font-weight: 500;
    #|  padding: 0.5em 1em;
    #|  font-size: 0.875rem;
    #|  transition: all 0.15s ease;
    #|  background: #18181b;
    #|  color: white;
    #|}
    #|
    #|/* Size variants via data-size */
    #|.button[data-size="small"] { padding: 0.25em 0.5em; font-size: 0.75rem; }
    #|.button[data-size="medium"] { padding: 0.5em 1em; font-size: 0.875rem; }
    #|.button[data-size="large"] { padding: 0.75em 1.5em; font-size: 1rem; }
    #|
    #|/* Variant styles via data-variant */
    #|.button[data-variant="default"] {
    #|  background: #18181b;
    #|  color: #fafafa;
    #|}
    #|.button[data-variant="default"]:hover:not([data-disabled]) {
    #|  background: #27272a;
    #|}
    #|
    #|.button[data-variant="destructive"] {
    #|  background: #dc2626;
    #|  color: white;
    #|}
    #|.button[data-variant="destructive"]:hover:not([data-disabled]) {
    #|  background: #b91c1c;
    #|}
    #|
    #|.button[data-variant="outline"] {
    #|  background: transparent;
    #|  border: 1px solid #e4e4e7;
    #|  color: #18181b;
    #|}
    #|.button[data-variant="outline"]:hover:not([data-disabled]) {
    #|  background: #f4f4f5;
    #|}
    #|
    #|.button[data-variant="secondary"] {
    #|  background: #f4f4f5;
    #|  color: #18181b;
    #|}
    #|.button[data-variant="secondary"]:hover:not([data-disabled]) {
    #|  background: #e4e4e7;
    #|}
    #|
    #|.button[data-variant="ghost"] {
    #|  background: transparent;
    #|  color: #18181b;
    #|}
    #|.button[data-variant="ghost"]:hover:not([data-disabled]) {
    #|  background: #f4f4f5;
    #|}
    #|
    #|.button[data-variant="link"] {
    #|  background: transparent;
    #|  color: #2563eb;
    #|  text-decoration: underline;
    #|  text-underline-offset: 4px;
    #|}
    #|.button[data-variant="link"]:hover:not([data-disabled]) {
    #|  color: #1d4ed8;
    #|}
    #|
    #|/* Disabled state */
    #|.button[data-disabled] {
    #|  opacity: 0.5;
    #|  pointer-events: none;
    #|  cursor: not-allowed;
    #|}
    #|
    #|/* Focus ring */
    #|.button:focus-visible {
    #|  outline: 2px solid #2563eb;
    #|  outline-offset: 2px;
    #|}
  css
}

///|
/// Button variant types (Radix/shadcn style)
pub(all) enum RadixButtonVariant {
  Default
  Destructive
  Outline
  Secondary
  Ghost
  Link
}

///|
pub fn RadixButtonVariant::to_string(self : RadixButtonVariant) -> String {
  match self {
    Default => "default"
    Destructive => "destructive"
    Outline => "outline"
    Secondary => "secondary"
    Ghost => "ghost"
    Link => "link"
  }
}

///|
/// Size types
pub(all) enum RadixSize {
  Small
  Medium
  Large
}

///|
pub fn RadixSize::to_string(self : RadixSize) -> String {
  match self {
    Small => "small"
    Medium => "medium"
    Large => "large"
  }
}

///|
/// Create a radix-button element with Declarative Shadow DOM
/// Uses data-* attributes for styling (Radix UI pattern)
pub fn radix_button(
  variant? : RadixButtonVariant,
  size? : RadixSize,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let variant_val = match variant {
    Some(v) => v
    None => Default
  }
  let size_val = match size {
    Some(s) => s
    None => Medium
  }

  // Build button attributes with data-* for styling
  let button_attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("button")),
    ("data-variant", @luna.attr_static(variant_val.to_string())),
    ("data-size", @luna.attr_static(size_val.to_string())),
  ]
  match disabled {
    Some(true) => button_attrs.push(("data-disabled", @luna.attr_static("")))
    _ => ()
  }

  // Build the shadow DOM template content
  let template_children : Array[@luna.Node[Unit]] = [
    @luna.h("style", [], [@luna.text(button_styles())]),
    @luna.h("button", button_attrs, [@luna.h("slot", [], [])]),
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
  @luna.h("radix-button", [], all_children)
}
