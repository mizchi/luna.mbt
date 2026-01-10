///|
/// Radix-style Popover component for Luna (Headless)
/// Outputs semantic HTML with data-* attributes for external CSS styling

///|
/// Create a headless popover root
/// Outputs: <div class="radix-popover" data-state="...">children</div>
pub fn radix_popover(
  open? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_open = match open {
    Some(true) => true
    _ => false
  }
  let state = if is_open { "open" } else { "closed" }
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-popover")),
      ("data-state", @luna.attr_static(state)),
    ],
    children,
  )
}

///|
/// Create a headless popover trigger
/// Outputs: <button class="radix-popover-trigger">children</button>
pub fn radix_popover_trigger(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "button",
    [("class", @luna.attr_static("radix-popover-trigger"))],
    children,
  )
}

///|
/// Create a headless popover content
/// Outputs: <div class="radix-popover-content" data-side="...">children</div>
pub fn radix_popover_content(
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
      ("class", @luna.attr_static("radix-popover-content")),
      ("data-side", @luna.attr_static(side_val.to_string())),
    ],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the popover component
fn popover_styles() -> String {
  let css =
    #|:host {
    #|  display: inline-block;
    #|  position: relative;
    #|}
    #|
    #|.popover-trigger {
    #|  background: transparent;
    #|  border: none;
    #|  cursor: pointer;
    #|}
    #|
    #|.popover-content {
    #|  position: absolute;
    #|  z-index: 50;
    #|  min-width: 12rem;
    #|  padding: 1rem;
    #|  background: white;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 8px;
    #|  box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);
    #|}
    #|
    #|.popover-content[data-side="top"] {
    #|  bottom: 100%;
    #|  left: 50%;
    #|  transform: translateX(-50%);
    #|  margin-bottom: 0.5rem;
    #|}
    #|
    #|.popover-content[data-side="bottom"] {
    #|  top: 100%;
    #|  left: 50%;
    #|  transform: translateX(-50%);
    #|  margin-top: 0.5rem;
    #|}
    #|
    #|.popover-content[data-side="left"] {
    #|  right: 100%;
    #|  top: 50%;
    #|  transform: translateY(-50%);
    #|  margin-right: 0.5rem;
    #|}
    #|
    #|.popover-content[data-side="right"] {
    #|  left: 100%;
    #|  top: 50%;
    #|  transform: translateY(-50%);
    #|  margin-left: 0.5rem;
    #|}
  css
}

///|
/// Create a styled popover with Declarative Shadow DOM
pub fn radix_popover_styled(
  open? : Bool,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_open = match open {
    Some(true) => true
    _ => false
  }
  let state = if is_open { "open" } else { "closed" }
  let css = match styles {
    Some(s) => s
    None => popover_styles()
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
  @luna.h(
    "radix-popover",
    [("data-state", @luna.attr_static(state))],
    all_children,
  )
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a popover with luna/css atomic styles
pub fn radix_popover_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = popover_base_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a popover trigger with luna/css atomic styles
pub fn radix_popover_trigger_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = popover_trigger_styles()
  @luna.h("button", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a popover content with luna/css atomic styles
pub fn radix_popover_content_ucss(
  side? : TooltipSide,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let side_val = match side {
    Some(s) => s
    None => Bottom
  }
  let class_names = popover_content_styles() +
    " " +
    popover_side_styles(side_val)
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}
