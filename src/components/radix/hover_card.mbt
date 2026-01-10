///|
/// Radix-style HoverCard component for Luna (Headless)
/// Card shown on hover

///|
/// Create a headless hover card root
/// Outputs: <div class="radix-hover-card">children</div>
pub fn radix_hover_card(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-hover-card"))], children)
}

///|
/// Create a headless hover card trigger
/// Outputs: <span class="radix-hover-card-trigger">children</span>
pub fn radix_hover_card_trigger(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "span",
    [("class", @luna.attr_static("radix-hover-card-trigger"))],
    children,
  )
}

///|
/// Create a headless hover card content
/// Outputs: <div class="radix-hover-card-content" data-side="...">children</div>
pub fn radix_hover_card_content(
  side? : TooltipSide,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let side_val = match side {
    Some(s) => s
    None => Bottom
  }
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-hover-card-content")),
      ("data-side", @luna.attr_static(side_val.to_string())),
    ],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the hover card component
fn hover_card_styles() -> String {
  let css =
    #|:host {
    #|  display: inline-block;
    #|  position: relative;
    #|}
    #|
    #|.hover-card-trigger {
    #|  cursor: pointer;
    #|}
    #|
    #|.hover-card-content {
    #|  position: absolute;
    #|  z-index: 50;
    #|  min-width: 16rem;
    #|  padding: 1rem;
    #|  background: white;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 8px;
    #|  box-shadow: 0 10px 15px -3px rgba(0,0,0,0.1);
    #|}
    #|
    #|.hover-card-content[data-side="top"] {
    #|  bottom: 100%;
    #|  left: 50%;
    #|  transform: translateX(-50%);
    #|  margin-bottom: 0.5rem;
    #|}
    #|
    #|.hover-card-content[data-side="bottom"] {
    #|  top: 100%;
    #|  left: 50%;
    #|  transform: translateX(-50%);
    #|  margin-top: 0.5rem;
    #|}
    #|
    #|.hover-card-content[data-side="left"] {
    #|  right: 100%;
    #|  top: 50%;
    #|  transform: translateY(-50%);
    #|  margin-right: 0.5rem;
    #|}
    #|
    #|.hover-card-content[data-side="right"] {
    #|  left: 100%;
    #|  top: 50%;
    #|  transform: translateY(-50%);
    #|  margin-left: 0.5rem;
    #|}
  css
}

///|
/// Create a styled hover card with Declarative Shadow DOM
pub fn radix_hover_card_styled(
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => hover_card_styles()
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
  @luna.h("radix-hover-card", [], all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a hover card with luna/css atomic styles
pub fn radix_hover_card_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = hover_card_base_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a hover card trigger with luna/css atomic styles
pub fn radix_hover_card_trigger_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = hover_card_trigger_styles()
  @luna.h("span", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a hover card content with luna/css atomic styles
pub fn radix_hover_card_content_ucss(
  side? : TooltipSide,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let side_val = match side {
    Some(s) => s
    None => Bottom
  }
  let class_names = hover_card_content_styles() +
    " " +
    hover_card_side_styles(side_val)
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("data-side", @luna.attr_static(side_val.to_string())),
    ],
    children,
  )
}
