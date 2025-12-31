///|
/// Radix-style Sheet (Side Panel/Drawer) component for Luna (Headless)
/// Outputs semantic HTML with data-* attributes for external CSS styling

///|
/// Sheet side (position)
pub(all) enum SheetSide {
  Top
  Right
  Bottom
  Left
}

///|
pub fn SheetSide::to_string(self : SheetSide) -> String {
  match self {
    Top => "top"
    Right => "right"
    Bottom => "bottom"
    Left => "left"
  }
}

///|
/// Create a headless sheet root
/// Outputs: <div class="radix-sheet" data-state="...">children</div>
pub fn radix_sheet(
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
      ("class", @luna.attr_static("radix-sheet")),
      ("data-state", @luna.attr_static(state)),
    ],
    children,
  )
}

///|
/// Create a headless sheet trigger
/// Outputs: <button class="radix-sheet-trigger">children</button>
pub fn radix_sheet_trigger(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "button",
    [("class", @luna.attr_static("radix-sheet-trigger"))],
    children,
  )
}

///|
/// Create a headless sheet overlay
/// Outputs: <div class="radix-sheet-overlay"></div>
pub fn radix_sheet_overlay() -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-sheet-overlay"))], [])
}

///|
/// Create a headless sheet content
/// Outputs: <div class="radix-sheet-content" data-side="..." role="dialog">children</div>
pub fn radix_sheet_content(
  side? : SheetSide,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let side_val = match side {
    Some(s) => s
    None => Right
  }

  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-sheet-content")),
      ("data-side", @luna.attr_static(side_val.to_string())),
      ("role", @luna.attr_static("dialog")),
      ("aria-modal", @luna.attr_static("true")),
    ],
    children,
  )
}

///|
/// Create a headless sheet header
/// Outputs: <div class="radix-sheet-header">children</div>
pub fn radix_sheet_header(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-sheet-header"))],
    children,
  )
}

///|
/// Create a headless sheet title
/// Outputs: <h2 class="radix-sheet-title">children</h2>
pub fn radix_sheet_title(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h("h2", [("class", @luna.attr_static("radix-sheet-title"))], children)
}

///|
/// Create a headless sheet description
/// Outputs: <p class="radix-sheet-description">children</p>
pub fn radix_sheet_description(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "p",
    [("class", @luna.attr_static("radix-sheet-description"))],
    children,
  )
}

///|
/// Create a headless sheet footer
/// Outputs: <div class="radix-sheet-footer">children</div>
pub fn radix_sheet_footer(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-sheet-footer"))],
    children,
  )
}

///|
/// Create a headless sheet close button
/// Outputs: <button class="radix-sheet-close">children</button>
pub fn radix_sheet_close(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "button",
    [("class", @luna.attr_static("radix-sheet-close"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the sheet component
fn sheet_styles() -> String {
  let css =
    #|:host {
    #|  display: contents;
    #|}
    #|
    #|.sheet-overlay {
    #|  position: fixed;
    #|  inset: 0;
    #|  background: rgba(0,0,0,0.5);
    #|  z-index: 50;
    #|}
    #|
    #|.sheet-content {
    #|  position: fixed;
    #|  z-index: 51;
    #|  background: white;
    #|  box-shadow: -4px 0 6px -1px rgba(0,0,0,0.1);
    #|  padding: 1.5rem;
    #|  overflow: auto;
    #|}
    #|
    #|.sheet-content[data-side="right"] {
    #|  top: 0;
    #|  right: 0;
    #|  height: 100%;
    #|  width: 75%;
    #|  max-width: 400px;
    #|}
    #|
    #|.sheet-content[data-side="left"] {
    #|  top: 0;
    #|  left: 0;
    #|  height: 100%;
    #|  width: 75%;
    #|  max-width: 400px;
    #|}
    #|
    #|.sheet-content[data-side="top"] {
    #|  top: 0;
    #|  left: 0;
    #|  right: 0;
    #|  height: auto;
    #|  max-height: 75%;
    #|}
    #|
    #|.sheet-content[data-side="bottom"] {
    #|  bottom: 0;
    #|  left: 0;
    #|  right: 0;
    #|  height: auto;
    #|  max-height: 75%;
    #|}
    #|
    #|.sheet-header {
    #|  display: flex;
    #|  flex-direction: column;
    #|  gap: 0.25rem;
    #|  margin-bottom: 1rem;
    #|}
    #|
    #|.sheet-title {
    #|  margin: 0;
    #|  font-size: 1.125rem;
    #|  font-weight: 600;
    #|  color: #18181b;
    #|}
    #|
    #|.sheet-description {
    #|  margin: 0;
    #|  font-size: 0.875rem;
    #|  color: #71717a;
    #|}
    #|
    #|.sheet-footer {
    #|  display: flex;
    #|  justify-content: flex-end;
    #|  gap: 0.5rem;
    #|  margin-top: 1.5rem;
    #|}
    #|
    #|.sheet-close {
    #|  position: absolute;
    #|  top: 1rem;
    #|  right: 1rem;
    #|  padding: 0.25rem;
    #|  background: transparent;
    #|  border: none;
    #|  cursor: pointer;
    #|  opacity: 0.7;
    #|  transition: opacity 0.15s;
    #|}
    #|
    #|.sheet-close:hover {
    #|  opacity: 1;
    #|}
  css
}

///|
/// Create a styled sheet with Declarative Shadow DOM
pub fn radix_sheet_styled(
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
    None => sheet_styles()
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
    "radix-sheet",
    [("data-state", @luna.attr_static(state))],
    all_children,
  )
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a sheet overlay with luna/css atomic styles
pub fn radix_sheet_overlay_ucss() -> @luna.Node[Unit] {
  let class_names = sheet_overlay_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], [])
}

///|
/// Create a sheet content with luna/css atomic styles
pub fn radix_sheet_content_ucss(
  side? : SheetSide,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let side_val = match side {
    Some(s) => s
    None => Right
  }

  let class_names = sheet_content_styles() + " " + sheet_side_styles(side_val)
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("role", @luna.attr_static("dialog")),
      ("aria-modal", @luna.attr_static("true")),
    ],
    children,
  )
}

///|
/// Create a sheet header with luna/css atomic styles
pub fn radix_sheet_header_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = sheet_header_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a sheet title with luna/css atomic styles
pub fn radix_sheet_title_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = sheet_title_styles()
  @luna.h("h2", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a sheet description with luna/css atomic styles
pub fn radix_sheet_description_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = sheet_description_styles()
  @luna.h("p", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a sheet footer with luna/css atomic styles
pub fn radix_sheet_footer_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = sheet_footer_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}
