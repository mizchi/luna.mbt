///|
/// Radix-style Resizable component for Luna (Headless)
/// Resizable panels

///|
/// Resizable direction
pub(all) enum ResizableDirection {
  Horizontal
  Vertical
}

///|
pub fn ResizableDirection::to_string(self : ResizableDirection) -> String {
  match self {
    Horizontal => "horizontal"
    Vertical => "vertical"
  }
}

///|
/// Create a headless resizable panel group
/// Outputs: <div class="radix-resizable-panel-group" data-direction="...">children</div>
pub fn radix_resizable_panel_group(
  direction? : ResizableDirection,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let dir = match direction {
    Some(d) => d
    None => Horizontal
  }
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-resizable-panel-group")),
      ("data-direction", @luna.attr_static(dir.to_string())),
    ],
    children,
  )
}

///|
/// Create a headless resizable panel
/// Outputs: <div class="radix-resizable-panel" data-default-size="...">children</div>
pub fn radix_resizable_panel(
  default_size? : Int,
  min_size? : Int,
  max_size? : Int,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-resizable-panel")),
  ]
  match default_size {
    Some(s) =>
      attrs.push(("data-default-size", @luna.attr_static(s.to_string())))
    None => ()
  }
  match min_size {
    Some(s) => attrs.push(("data-min-size", @luna.attr_static(s.to_string())))
    None => ()
  }
  match max_size {
    Some(s) => attrs.push(("data-max-size", @luna.attr_static(s.to_string())))
    None => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a headless resizable handle
/// Outputs: <div class="radix-resizable-handle" data-direction="..."></div>
pub fn radix_resizable_handle(
  direction? : ResizableDirection,
) -> @luna.Node[Unit] {
  let dir = match direction {
    Some(d) => d
    None => Horizontal
  }
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-resizable-handle")),
      ("data-direction", @luna.attr_static(dir.to_string())),
    ],
    [],
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the resizable component
fn resizable_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.resizable-panel-group {
    #|  display: flex;
    #|  width: 100%;
    #|  height: 100%;
    #|}
    #|
    #|.resizable-panel-group[data-direction="horizontal"] {
    #|  flex-direction: row;
    #|}
    #|
    #|.resizable-panel-group[data-direction="vertical"] {
    #|  flex-direction: column;
    #|}
    #|
    #|.resizable-panel {
    #|  flex: 1;
    #|  overflow: auto;
    #|}
    #|
    #|.resizable-handle {
    #|  flex: 0 0 auto;
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  background: #e4e4e7;
    #|  transition: background 0.15s ease;
    #|}
    #|
    #|.resizable-handle:hover {
    #|  background: #d4d4d8;
    #|}
    #|
    #|.resizable-handle[data-direction="horizontal"] {
    #|  width: 4px;
    #|  cursor: col-resize;
    #|}
    #|
    #|.resizable-handle[data-direction="vertical"] {
    #|  height: 4px;
    #|  cursor: row-resize;
    #|}
  css
}

///|
/// Create a styled resizable panel group with Declarative Shadow DOM
pub fn radix_resizable_panel_group_styled(
  direction? : ResizableDirection,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let dir = match direction {
    Some(d) => d
    None => Horizontal
  }
  let css = match styles {
    Some(s) => s
    None => resizable_styles()
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
    "radix-resizable-panel-group",
    [("data-direction", @luna.attr_static(dir.to_string()))],
    all_children,
  )
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a resizable panel group with luna/css atomic styles
pub fn radix_resizable_panel_group_ucss(
  direction? : ResizableDirection,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let dir = match direction {
    Some(d) => d
    None => Horizontal
  }
  let class_names = resizable_panel_group_styles(dir)
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("data-direction", @luna.attr_static(dir.to_string())),
    ],
    children,
  )
}

///|
/// Create a resizable panel with luna/css atomic styles
pub fn radix_resizable_panel_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = resizable_panel_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a resizable handle with luna/css atomic styles
pub fn radix_resizable_handle_ucss(
  direction? : ResizableDirection,
) -> @luna.Node[Unit] {
  let dir = match direction {
    Some(d) => d
    None => Horizontal
  }
  let class_names = resizable_handle_styles(dir)
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("data-direction", @luna.attr_static(dir.to_string())),
    ],
    [],
  )
}
