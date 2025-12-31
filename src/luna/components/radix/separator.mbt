///|
/// Radix-style Separator component for Luna (Headless)
/// Outputs semantic HTML with data-* attributes for external CSS styling

///|
/// Create a headless separator element
/// Outputs: <div class="radix-separator" role="separator" data-orientation="..."></div>
/// Style with external CSS using [data-orientation="..."] selectors
pub fn radix_separator(
  orientation? : Orientation,
  decorative? : Bool,
) -> @luna.Node[Unit] {
  let orient = match orientation {
    Some(o) => o
    None => Horizontal
  }
  let is_decorative = match decorative {
    Some(true) => true
    _ => false
  }
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-separator")),
    ("data-orientation", @luna.attr_static(orient.to_string())),
  ]

  // Add ARIA attributes
  if is_decorative {
    attrs.push(("data-decorative", @luna.attr_static("true")))
    attrs.push(("aria-hidden", @luna.attr_static("true")))
  } else {
    attrs.push(("role", @luna.attr_static("separator")))
    match orient {
      Vertical =>
        attrs.push(("aria-orientation", @luna.attr_static("vertical")))
      Horizontal => ()
    }
  }
  @luna.h("div", attrs, [])
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the separator component
fn separator_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.separator {
    #|  background: #e4e4e7;
    #|  flex-shrink: 0;
    #|}
    #|
    #|.separator[data-orientation="horizontal"] {
    #|  height: 1px;
    #|  width: 100%;
    #|}
    #|
    #|.separator[data-orientation="vertical"] {
    #|  height: 100%;
    #|  width: 1px;
    #|}
    #|
    #|/* Decorative separator (no semantic meaning) */
    #|.separator[data-decorative="true"] {
    #|  /* Same styling, just for accessibility distinction */
    #|}
  css
}

///|
/// Create a styled separator with Declarative Shadow DOM
/// Uses inline CSS for zero CLS (Cumulative Layout Shift)
pub fn radix_separator_styled(
  orientation? : Orientation,
  decorative? : Bool,
  styles? : String,
) -> @luna.Node[Unit] {
  let orient = match orientation {
    Some(o) => o
    None => Horizontal
  }
  let is_decorative = match decorative {
    Some(true) => true
    _ => false
  }
  let css = match styles {
    Some(s) => s
    None => separator_styles()
  }

  // Build separator attributes
  let sep_attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("separator")),
    ("data-orientation", @luna.attr_static(orient.to_string())),
  ]

  // Add ARIA attributes
  if is_decorative {
    sep_attrs.push(("data-decorative", @luna.attr_static("true")))
    sep_attrs.push(("aria-hidden", @luna.attr_static("true")))
  } else {
    sep_attrs.push(("role", @luna.attr_static("separator")))
    match orient {
      Vertical =>
        sep_attrs.push(("aria-orientation", @luna.attr_static("vertical")))
      Horizontal => ()
    }
  }

  // Build template content
  let template_children : Array[@luna.Node[Unit]] = [
    @luna.h("style", [], [@luna.text(css)]),
    @luna.h("div", sep_attrs, []),
  ]

  // Host attributes
  let host_attrs : Array[(String, @luna.Attr[Unit])] = [
    ("data-orientation", @luna.attr_static(orient.to_string())),
  ]

  // Create the DSD structure
  @luna.h("radix-separator", host_attrs, [
    @luna.h(
      "template",
      [("shadowrootmode", @luna.attr_static("open"))],
      template_children,
    ),
  ])
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a separator with luna/css atomic styles
/// Uses CSS utilities for SSR static extraction
pub fn radix_separator_ucss(
  orientation? : Orientation,
  decorative? : Bool,
) -> @luna.Node[Unit] {
  let orient = match orientation {
    Some(o) => o
    None => Horizontal
  }
  let is_decorative = match decorative {
    Some(true) => true
    _ => false
  }

  // Build class names using luna/css
  let class_names = match orient {
    Horizontal => separator_horizontal_styles()
    Vertical => separator_vertical_styles()
  }

  // Build attributes
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
  ]

  // Add ARIA attributes
  if is_decorative {
    attrs.push(("aria-hidden", @luna.attr_static("true")))
  } else {
    attrs.push(("role", @luna.attr_static("separator")))
    match orient {
      Vertical =>
        attrs.push(("aria-orientation", @luna.attr_static("vertical")))
      Horizontal => ()
    }
  }
  @luna.h("div", attrs, [])
}
