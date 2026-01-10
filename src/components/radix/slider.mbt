///|
/// Radix-style Slider component for Luna (Headless)
/// Outputs semantic HTML with data-* attributes for external CSS styling

///|
/// Slider orientation
pub(all) enum SliderOrientation {
  Horizontal
  Vertical
}

///|
pub fn SliderOrientation::to_string(self : SliderOrientation) -> String {
  match self {
    Horizontal => "horizontal"
    Vertical => "vertical"
  }
}

///|
/// Create a headless slider root
/// Outputs: <div class="radix-slider" role="slider" ...>children</div>
pub fn radix_slider(
  value? : Int,
  min? : Int,
  max? : Int,
  step? : Int,
  orientation? : SliderOrientation,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let min_val = match min {
    Some(m) => m
    None => 0
  }
  let max_val = match max {
    Some(m) => m
    None => 100
  }
  let val = match value {
    Some(v) => v
    None => min_val
  }
  let step_val = match step {
    Some(s) => s
    None => 1
  }
  let orient = match orientation {
    Some(o) => o
    None => Horizontal
  }
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-slider")),
    ("role", @luna.attr_static("slider")),
    ("aria-valuemin", @luna.attr_static(min_val.to_string())),
    ("aria-valuemax", @luna.attr_static(max_val.to_string())),
    ("aria-valuenow", @luna.attr_static(val.to_string())),
    ("data-orientation", @luna.attr_static(orient.to_string())),
    ("data-step", @luna.attr_static(step_val.to_string())),
  ]
  match disabled {
    Some(true) => attrs.push(("data-disabled", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a headless slider track
/// Outputs: <div class="radix-slider-track">children</div>
pub fn radix_slider_track(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-slider-track"))], children)
}

///|
/// Create a headless slider range (filled portion)
/// Outputs: <div class="radix-slider-range"></div>
pub fn radix_slider_range(value? : Int, max? : Int) -> @luna.Node[Unit] {
  let max_val = match max {
    Some(m) => m
    None => 100
  }
  let val = match value {
    Some(v) => v
    None => 0
  }
  let percentage = if max_val > 0 { val * 100 / max_val } else { 0 }
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-slider-range")),
      ("style", @luna.attr_static("width: " + percentage.to_string() + "%")),
    ],
    [],
  )
}

///|
/// Create a headless slider thumb
/// Outputs: <div class="radix-slider-thumb"></div>
pub fn radix_slider_thumb(value? : Int, max? : Int) -> @luna.Node[Unit] {
  let max_val = match max {
    Some(m) => m
    None => 100
  }
  let val = match value {
    Some(v) => v
    None => 0
  }
  let percentage = if max_val > 0 { val * 100 / max_val } else { 0 }
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-slider-thumb")),
      ("style", @luna.attr_static("left: " + percentage.to_string() + "%")),
      ("tabindex", @luna.attr_static("0")),
    ],
    [],
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the slider component
fn slider_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.slider {
    #|  position: relative;
    #|  display: flex;
    #|  align-items: center;
    #|  width: 100%;
    #|  touch-action: none;
    #|  user-select: none;
    #|}
    #|
    #|.slider[data-orientation="vertical"] {
    #|  flex-direction: column;
    #|  width: auto;
    #|  height: 100%;
    #|}
    #|
    #|.slider[data-disabled] {
    #|  opacity: 0.5;
    #|  pointer-events: none;
    #|}
    #|
    #|.slider-track {
    #|  position: relative;
    #|  flex-grow: 1;
    #|  height: 8px;
    #|  background: #e4e4e7;
    #|  border-radius: 9999px;
    #|  overflow: hidden;
    #|}
    #|
    #|.slider[data-orientation="vertical"] .slider-track {
    #|  width: 8px;
    #|  height: 100%;
    #|}
    #|
    #|.slider-range {
    #|  position: absolute;
    #|  height: 100%;
    #|  background: #18181b;
    #|  border-radius: 9999px;
    #|}
    #|
    #|.slider[data-orientation="vertical"] .slider-range {
    #|  width: 100%;
    #|  bottom: 0;
    #|}
    #|
    #|.slider-thumb {
    #|  position: absolute;
    #|  top: 50%;
    #|  width: 20px;
    #|  height: 20px;
    #|  background: white;
    #|  border: 2px solid #18181b;
    #|  border-radius: 50%;
    #|  transform: translate(-50%, -50%);
    #|  cursor: grab;
    #|  transition: box-shadow 0.15s ease;
    #|}
    #|
    #|.slider-thumb:focus {
    #|  outline: none;
    #|  box-shadow: 0 0 0 3px rgba(24,24,27,0.2);
    #|}
    #|
    #|.slider-thumb:active {
    #|  cursor: grabbing;
    #|}
  css
}

///|
/// Create a styled slider with Declarative Shadow DOM
pub fn radix_slider_styled(
  value? : Int,
  min? : Int,
  max? : Int,
  orientation? : SliderOrientation,
  disabled? : Bool,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let min_val = match min {
    Some(m) => m
    None => 0
  }
  let max_val = match max {
    Some(m) => m
    None => 100
  }
  let val = match value {
    Some(v) => v
    None => min_val
  }
  let orient = match orientation {
    Some(o) => o
    None => Horizontal
  }
  let css = match styles {
    Some(s) => s
    None => slider_styles()
  }
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("aria-valuemin", @luna.attr_static(min_val.to_string())),
    ("aria-valuemax", @luna.attr_static(max_val.to_string())),
    ("aria-valuenow", @luna.attr_static(val.to_string())),
    ("data-orientation", @luna.attr_static(orient.to_string())),
  ]
  match disabled {
    Some(true) => attrs.push(("data-disabled", @luna.attr_static("")))
    _ => ()
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
  @luna.h("radix-slider", attrs, all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a slider with luna/css atomic styles
pub fn radix_slider_ucss(
  value? : Int,
  min? : Int,
  max? : Int,
  orientation? : SliderOrientation,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let min_val = match min {
    Some(m) => m
    None => 0
  }
  let max_val = match max {
    Some(m) => m
    None => 100
  }
  let val = match value {
    Some(v) => v
    None => min_val
  }
  let orient = match orientation {
    Some(o) => o
    None => Horizontal
  }
  let mut class_names = slider_base_styles()
  class_names = class_names + " " + slider_orientation_styles(orient)
  match disabled {
    Some(true) =>
      class_names = class_names +
        " " +
        @css.styles([("opacity", "0.5"), ("pointer-events", "none")])
    _ => ()
  }
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("role", @luna.attr_static("slider")),
    ("aria-valuemin", @luna.attr_static(min_val.to_string())),
    ("aria-valuemax", @luna.attr_static(max_val.to_string())),
    ("aria-valuenow", @luna.attr_static(val.to_string())),
    ("data-orientation", @luna.attr_static(orient.to_string())),
  ]
  match disabled {
    Some(true) => attrs.push(("data-disabled", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a slider track with luna/css atomic styles
pub fn radix_slider_track_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = slider_track_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a slider range with luna/css atomic styles
pub fn radix_slider_range_ucss(value? : Int, max? : Int) -> @luna.Node[Unit] {
  let max_val = match max {
    Some(m) => m
    None => 100
  }
  let val = match value {
    Some(v) => v
    None => 0
  }
  let percentage = if max_val > 0 { val * 100 / max_val } else { 0 }
  let class_names = slider_range_styles()
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("style", @luna.attr_static("width: " + percentage.to_string() + "%")),
    ],
    [],
  )
}

///|
/// Create a slider thumb with luna/css atomic styles
pub fn radix_slider_thumb_ucss(value? : Int, max? : Int) -> @luna.Node[Unit] {
  let max_val = match max {
    Some(m) => m
    None => 100
  }
  let val = match value {
    Some(v) => v
    None => 0
  }
  let percentage = if max_val > 0 { val * 100 / max_val } else { 0 }
  let class_names = slider_thumb_styles()
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("style", @luna.attr_static("left: " + percentage.to_string() + "%")),
      ("tabindex", @luna.attr_static("0")),
    ],
    [],
  )
}
