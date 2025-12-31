///|
/// Radix-style ScrollArea component for Luna (Headless)
/// Custom scrollbar styling

///|
/// Scrollbar orientation
pub(all) enum ScrollOrientation {
  Horizontal
  Vertical
  Both
}

///|
pub fn ScrollOrientation::to_string(self : ScrollOrientation) -> String {
  match self {
    Horizontal => "horizontal"
    Vertical => "vertical"
    Both => "both"
  }
}

///|
/// Create a headless scroll area root
/// Outputs: <div class="radix-scroll-area">children</div>
pub fn radix_scroll_area(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-scroll-area"))], children)
}

///|
/// Create a headless scroll area viewport
/// Outputs: <div class="radix-scroll-area-viewport">children</div>
pub fn radix_scroll_area_viewport(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-scroll-area-viewport"))],
    children,
  )
}

///|
/// Create a headless scroll area scrollbar
/// Outputs: <div class="radix-scroll-area-scrollbar" data-orientation="...">children</div>
pub fn radix_scroll_area_scrollbar(
  orientation? : ScrollOrientation,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let orient = match orientation {
    Some(o) => o
    None => Vertical
  }
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-scroll-area-scrollbar")),
      ("data-orientation", @luna.attr_static(orient.to_string())),
    ],
    children,
  )
}

///|
/// Create a headless scroll area thumb
/// Outputs: <div class="radix-scroll-area-thumb"></div>
pub fn radix_scroll_area_thumb() -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-scroll-area-thumb"))], [])
}

///|
/// Create a headless scroll area corner
/// Outputs: <div class="radix-scroll-area-corner"></div>
pub fn radix_scroll_area_corner() -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-scroll-area-corner"))], [])
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the scroll area component
fn scroll_area_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.scroll-area {
    #|  position: relative;
    #|  overflow: hidden;
    #|}
    #|
    #|.scroll-area-viewport {
    #|  width: 100%;
    #|  height: 100%;
    #|  overflow: auto;
    #|  scrollbar-width: none;
    #|  -ms-overflow-style: none;
    #|}
    #|
    #|.scroll-area-viewport::-webkit-scrollbar {
    #|  display: none;
    #|}
    #|
    #|.scroll-area-scrollbar {
    #|  display: flex;
    #|  touch-action: none;
    #|  user-select: none;
    #|  padding: 2px;
    #|}
    #|
    #|.scroll-area-scrollbar[data-orientation="vertical"] {
    #|  position: absolute;
    #|  top: 0;
    #|  right: 0;
    #|  height: 100%;
    #|  width: 10px;
    #|  flex-direction: column;
    #|}
    #|
    #|.scroll-area-scrollbar[data-orientation="horizontal"] {
    #|  position: absolute;
    #|  bottom: 0;
    #|  left: 0;
    #|  width: 100%;
    #|  height: 10px;
    #|  flex-direction: row;
    #|}
    #|
    #|.scroll-area-thumb {
    #|  flex: 1;
    #|  background: rgba(0,0,0,0.3);
    #|  border-radius: 9999px;
    #|  transition: background 0.15s ease;
    #|}
    #|
    #|.scroll-area-thumb:hover {
    #|  background: rgba(0,0,0,0.5);
    #|}
    #|
    #|.scroll-area-corner {
    #|  background: transparent;
    #|}
  css
}

///|
/// Create a styled scroll area with Declarative Shadow DOM
pub fn radix_scroll_area_styled(
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => scroll_area_styles()
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
  @luna.h("radix-scroll-area", [], all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a scroll area with luna/css atomic styles
pub fn radix_scroll_area_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = scroll_area_base_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a scroll area viewport with luna/css atomic styles
pub fn radix_scroll_area_viewport_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = scroll_area_viewport_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a scroll area scrollbar with luna/css atomic styles
pub fn radix_scroll_area_scrollbar_ucss(
  orientation? : ScrollOrientation,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let orient = match orientation {
    Some(o) => o
    None => Vertical
  }
  let class_names = scroll_area_scrollbar_styles(orient)
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("data-orientation", @luna.attr_static(orient.to_string())),
    ],
    children,
  )
}

///|
/// Create a scroll area thumb with luna/css atomic styles
pub fn radix_scroll_area_thumb_ucss() -> @luna.Node[Unit] {
  let class_names = scroll_area_thumb_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], [])
}
