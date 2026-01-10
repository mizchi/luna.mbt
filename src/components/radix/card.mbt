///|
/// Radix-style Card component for Luna (Headless)
/// Outputs semantic HTML with data-* attributes for external CSS styling

///|
/// Create a headless card container
/// Outputs: <div class="radix-card" data-variant="...">children</div>
/// Style with external CSS
pub fn radix_card(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-card"))], children)
}

///|
/// Create a headless card header
/// Outputs: <div class="radix-card-header">children</div>
pub fn radix_card_header(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-card-header"))], children)
}

///|
/// Create a headless card title
/// Outputs: <h3 class="radix-card-title">children</h3>
pub fn radix_card_title(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h("h3", [("class", @luna.attr_static("radix-card-title"))], children)
}

///|
/// Create a headless card description
/// Outputs: <p class="radix-card-description">children</p>
pub fn radix_card_description(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "p",
    [("class", @luna.attr_static("radix-card-description"))],
    children,
  )
}

///|
/// Create a headless card content
/// Outputs: <div class="radix-card-content">children</div>
pub fn radix_card_content(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-card-content"))], children)
}

///|
/// Create a headless card footer
/// Outputs: <div class="radix-card-footer">children</div>
pub fn radix_card_footer(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-card-footer"))], children)
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the card component
fn card_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.card {
    #|  background: white;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 8px;
    #|  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    #|  overflow: hidden;
    #|}
    #|
    #|.card-header {
    #|  display: flex;
    #|  flex-direction: column;
    #|  gap: 0.375rem;
    #|  padding: 1.5rem;
    #|}
    #|
    #|.card-title {
    #|  margin: 0;
    #|  font-size: 1.25rem;
    #|  font-weight: 600;
    #|  line-height: 1.2;
    #|  color: #18181b;
    #|}
    #|
    #|.card-description {
    #|  margin: 0;
    #|  font-size: 0.875rem;
    #|  color: #71717a;
    #|  line-height: 1.5;
    #|}
    #|
    #|.card-content {
    #|  padding: 0 1.5rem 1.5rem;
    #|}
    #|
    #|.card-footer {
    #|  display: flex;
    #|  align-items: center;
    #|  gap: 0.5rem;
    #|  padding: 1.5rem;
    #|  border-top: 1px solid #e4e4e7;
    #|}
  css
}

///|
/// Create a styled card with Declarative Shadow DOM
pub fn radix_card_styled(
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => card_styles()
  }

  // Build template content
  let template_children : Array[@luna.Node[Unit]] = [
    @luna.h("style", [], [@luna.text(css)]),
    @luna.h("div", [("class", @luna.attr_static("card"))], [
      @luna.h("slot", [], []),
    ]),
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
  @luna.h("radix-card", [], all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a card with luna/css atomic styles
pub fn radix_card_ucss(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  let class_names = card_base_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a card header with luna/css atomic styles
pub fn radix_card_header_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = card_header_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a card title with luna/css atomic styles
pub fn radix_card_title_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = card_title_styles()
  @luna.h("h3", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a card description with luna/css atomic styles
pub fn radix_card_description_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = card_description_styles()
  @luna.h("p", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a card content with luna/css atomic styles
pub fn radix_card_content_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = card_content_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a card footer with luna/css atomic styles
pub fn radix_card_footer_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = card_footer_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}
