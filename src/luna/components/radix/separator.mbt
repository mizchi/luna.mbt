///|
/// Radix-style Separator component for Luna
/// Uses Declarative Shadow DOM with data-orientation attribute

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
/// Create a radix-separator element with Declarative Shadow DOM
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
    @luna.h("style", [], [@luna.text(separator_styles())]),
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
