///|
/// Radix-style Badge component for Luna (Headless)
/// Outputs semantic HTML with data-* attributes for external CSS styling

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
/// Create a headless badge element
/// Outputs: <span class="radix-badge" data-variant="...">children</span>
/// Style with external CSS using [data-variant="..."] selectors
pub fn radix_badge(
  variant? : BadgeVariant,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let variant_val = match variant {
    Some(v) => v
    None => Default
  }
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-badge")),
    ("data-variant", @luna.attr_static(variant_val.to_string())),
  ]
  @luna.h("span", attrs, children)
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// Default CSS styles for the badge component
fn badge_default_styles() -> String {
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
/// Create a styled badge with Declarative Shadow DOM
/// Uses inline CSS for zero CLS (Cumulative Layout Shift)
///
/// Parameters:
/// - variant: Badge style variant
/// - styles: Custom CSS to override or extend default styles
/// - children: Content inside the badge
pub fn radix_badge_styled(
  variant? : BadgeVariant,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let variant_val = match variant {
    Some(v) => v
    None => Default
  }

  // Use custom styles or default
  let css = match styles {
    Some(s) => s
    None => badge_default_styles()
  }

  // Build badge attributes
  let badge_attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("badge")),
    ("data-variant", @luna.attr_static(variant_val.to_string())),
  ]

  // Build template content
  let template_children : Array[@luna.Node[Unit]] = [
    @luna.h("style", [], [@luna.text(css)]),
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

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a badge with luna/css atomic styles
/// Uses CSS utilities for SSR static extraction
/// Call @css.generate_full_css() to get all collected CSS
pub fn radix_badge_ucss(
  variant? : BadgeVariant,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let variant_val = match variant {
    Some(v) => v
    None => Default
  }

  // Build class names using luna/css
  let class_names = badge_base_styles() +
    " " +
    badge_variant_styles(variant_val)
  @luna.h("span", [("class", @luna.attr_static(class_names))], children)
}
