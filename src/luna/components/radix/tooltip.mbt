///|
/// Radix-style Tooltip component for Luna (Headless)
/// Outputs semantic HTML with data-* attributes for external CSS styling

///|
/// Tooltip side (position relative to trigger)
pub(all) enum TooltipSide {
  Top
  Right
  Bottom
  Left
}

///|
pub fn TooltipSide::to_string(self : TooltipSide) -> String {
  match self {
    Top => "top"
    Right => "right"
    Bottom => "bottom"
    Left => "left"
  }
}

///|
/// Create a headless tooltip root
/// Outputs: <div class="radix-tooltip">children</div>
pub fn radix_tooltip(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-tooltip"))], children)
}

///|
/// Create a headless tooltip trigger
/// Outputs: <button class="radix-tooltip-trigger">children</button>
pub fn radix_tooltip_trigger(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "button",
    [("class", @luna.attr_static("radix-tooltip-trigger"))],
    children,
  )
}

///|
/// Create a headless tooltip content
/// Outputs: <div class="radix-tooltip-content" role="tooltip" data-side="...">children</div>
pub fn radix_tooltip_content(
  side? : TooltipSide,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let side_val = match side {
    Some(s) => s
    None => Top
  }
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-tooltip-content")),
      ("role", @luna.attr_static("tooltip")),
      ("data-side", @luna.attr_static(side_val.to_string())),
    ],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the tooltip component
fn tooltip_styles() -> String {
  let css =
    #|:host {
    #|  display: inline-block;
    #|  position: relative;
    #|}
    #|
    #|.tooltip-trigger {
    #|  background: transparent;
    #|  border: none;
    #|  cursor: pointer;
    #|}
    #|
    #|.tooltip-content {
    #|  position: absolute;
    #|  z-index: 50;
    #|  padding: 0.375rem 0.75rem;
    #|  font-size: 0.75rem;
    #|  background: #18181b;
    #|  color: white;
    #|  border-radius: 4px;
    #|  white-space: nowrap;
    #|  pointer-events: none;
    #|}
    #|
    #|.tooltip-content[data-side="top"] {
    #|  bottom: 100%;
    #|  left: 50%;
    #|  transform: translateX(-50%);
    #|  margin-bottom: 0.5rem;
    #|}
    #|
    #|.tooltip-content[data-side="bottom"] {
    #|  top: 100%;
    #|  left: 50%;
    #|  transform: translateX(-50%);
    #|  margin-top: 0.5rem;
    #|}
    #|
    #|.tooltip-content[data-side="left"] {
    #|  right: 100%;
    #|  top: 50%;
    #|  transform: translateY(-50%);
    #|  margin-right: 0.5rem;
    #|}
    #|
    #|.tooltip-content[data-side="right"] {
    #|  left: 100%;
    #|  top: 50%;
    #|  transform: translateY(-50%);
    #|  margin-left: 0.5rem;
    #|}
  css
}

///|
/// Create a styled tooltip with Declarative Shadow DOM
pub fn radix_tooltip_styled(
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => tooltip_styles()
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
  @luna.h("radix-tooltip", [], all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a tooltip with luna/css atomic styles
pub fn radix_tooltip_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = tooltip_base_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a tooltip trigger with luna/css atomic styles
pub fn radix_tooltip_trigger_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = tooltip_trigger_styles()
  @luna.h("button", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a tooltip content with luna/css atomic styles
pub fn radix_tooltip_content_ucss(
  side? : TooltipSide,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let side_val = match side {
    Some(s) => s
    None => Top
  }
  let class_names = tooltip_content_styles() +
    " " +
    tooltip_side_styles(side_val)
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("role", @luna.attr_static("tooltip")),
    ],
    children,
  )
}
