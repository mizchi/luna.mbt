///|
/// Radix-style Label component for Luna (Headless)
/// Outputs semantic HTML with data-* attributes for external CSS styling

///|
/// Create a headless label element
/// Outputs: <label class="radix-label" for="...">children</label>
pub fn radix_label(
  for_? : String,
  required? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-label")),
  ]

  match for_ {
    Some(f) => attrs.push(("for", @luna.attr_static(f)))
    None => ()
  }

  match required {
    Some(true) => attrs.push(("data-required", @luna.attr_static("")))
    _ => ()
  }

  @luna.h("label", attrs, children)
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the label component
fn label_styles() -> String {
  let css =
    #|:host {
    #|  display: inline-block;
    #|}
    #|
    #|.label {
    #|  font-size: 0.875rem;
    #|  font-weight: 500;
    #|  color: #18181b;
    #|  line-height: 1;
    #|  cursor: default;
    #|}
    #|
    #|.label[data-required]::after {
    #|  content: " *";
    #|  color: #dc2626;
    #|}
    #|
    #|.label[data-disabled] {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
  css
}

///|
/// Create a styled label with Declarative Shadow DOM
pub fn radix_label_styled(
  for_? : String,
  required? : Bool,
  disabled? : Bool,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => label_styles()
  }

  // Build label attributes
  let label_attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("label")),
  ]

  match for_ {
    Some(f) => label_attrs.push(("for", @luna.attr_static(f)))
    None => ()
  }

  match required {
    Some(true) => label_attrs.push(("data-required", @luna.attr_static("")))
    _ => ()
  }

  match disabled {
    Some(true) => label_attrs.push(("data-disabled", @luna.attr_static("")))
    _ => ()
  }

  // Build template content
  let template_children : Array[@luna.Node[Unit]] = [
    @luna.h("style", [], [@luna.text(css)]),
    @luna.h("label", label_attrs, [@luna.h("slot", [], [])]),
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

  // Host attributes
  let host_attrs : Array[(String, @luna.Attr[Unit])] = []
  match required {
    Some(true) => host_attrs.push(("data-required", @luna.attr_static("")))
    _ => ()
  }

  @luna.h("radix-label", host_attrs, all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a label with luna/css atomic styles
pub fn radix_label_ucss(
  for_? : String,
  required? : Bool,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let mut class_names = label_base_styles()

  match disabled {
    Some(true) => class_names = class_names + " " + label_disabled_styles()
    _ => ()
  }

  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
  ]

  match for_ {
    Some(f) => attrs.push(("for", @luna.attr_static(f)))
    None => ()
  }

  match required {
    Some(true) => attrs.push(("data-required", @luna.attr_static("")))
    _ => ()
  }

  @luna.h("label", attrs, children)
}
