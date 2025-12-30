///|
/// Radix-style Badge component for Luna
/// Uses Declarative Shadow DOM with data-variant attribute for styling

///|
/// Badge variant types
pub(all) enum BadgeVariant {
  Default
  Secondary
  Destructive
  Outline
}

///|
pub fn BadgeVariant::to_string(self : BadgeVariant) -> String {
  match self {
    Default => "default"
    Secondary => "secondary"
    Destructive => "destructive"
    Outline => "outline"
  }
}

///|
/// CSS styles for the badge component
fn badge_styles() -> String {
  let css =
    #|:host {
    #|  display: inline-block;
    #|}
    #|
    #|.badge {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  border-radius: 9999px;
    #|  font-size: 0.75rem;
    #|  font-weight: 500;
    #|  line-height: 1;
    #|  padding: 0.25rem 0.625rem;
    #|  transition: all 0.15s ease;
    #|}
    #|
    #|/* Variants */
    #|.badge[data-variant="default"] {
    #|  background: #18181b;
    #|  color: #fafafa;
    #|}
    #|
    #|.badge[data-variant="secondary"] {
    #|  background: #f4f4f5;
    #|  color: #18181b;
    #|}
    #|
    #|.badge[data-variant="destructive"] {
    #|  background: #dc2626;
    #|  color: white;
    #|}
    #|
    #|.badge[data-variant="outline"] {
    #|  background: transparent;
    #|  border: 1px solid #e4e4e7;
    #|  color: #18181b;
    #|}
  css
}

///|
/// Create a radix-badge element with Declarative Shadow DOM
pub fn radix_badge(
  variant? : BadgeVariant,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let variant_val = match variant {
    Some(v) => v
    None => Default
  }

  // Build badge attributes
  let badge_attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("badge")),
    ("data-variant", @luna.attr_static(variant_val.to_string())),
  ]

  // Build template content
  let template_children : Array[@luna.Node[Unit]] = [
    @luna.h("style", [], [@luna.text(badge_styles())]),
    @luna.h("span", badge_attrs, [@luna.h("slot", [], [])]),
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
  @luna.h("radix-badge", [], all_children)
}
