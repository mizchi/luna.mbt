///|
/// RangeSlider component for Luna (Headless)
/// Dual-handle slider for selecting a range

///|
/// Create a headless range slider root
/// Outputs: <div class="radix-range-slider" role="group">children</div>
pub fn radix_range_slider(
  min? : String,
  max? : String,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-range-slider")),
    ("role", @luna.attr_static("group")),
  ]
  match min {
    Some(m) => attrs.push(("data-min", @luna.attr_static(m)))
    None => ()
  }
  match max {
    Some(m) => attrs.push(("data-max", @luna.attr_static(m)))
    None => ()
  }
  match disabled {
    Some(true) => attrs.push(("data-disabled", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a headless range slider track
/// Outputs: <div class="radix-range-slider-track">children</div>
pub fn radix_range_slider_track(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-range-slider-track"))],
    children,
  )
}

///|
/// Create a headless range slider range (filled area between handles)
/// Outputs: <div class="radix-range-slider-range" style="left: ...%; width: ...%"></div>
pub fn radix_range_slider_range(
  start_percent : Int,
  end_percent : Int,
) -> @luna.Node[Unit] {
  let width = end_percent - start_percent
  let style = "left: " +
    start_percent.to_string() +
    "%; width: " +
    width.to_string() +
    "%"
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-range-slider-range")),
      ("style", @luna.attr_static(style)),
    ],
    [],
  )
}

///|
/// Create a headless range slider thumb
/// Outputs: <div class="radix-range-slider-thumb" role="slider" style="left: ...%">children</div>
pub fn radix_range_slider_thumb(
  position_percent : Int,
  value? : String,
  min? : String,
  max? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let style = "left: " + position_percent.to_string() + "%"
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-range-slider-thumb")),
    ("role", @luna.attr_static("slider")),
    ("tabindex", @luna.attr_static("0")),
    ("style", @luna.attr_static(style)),
  ]
  match value {
    Some(v) => attrs.push(("aria-valuenow", @luna.attr_static(v)))
    None => ()
  }
  match min {
    Some(m) => attrs.push(("aria-valuemin", @luna.attr_static(m)))
    None => ()
  }
  match max {
    Some(m) => attrs.push(("aria-valuemax", @luna.attr_static(m)))
    None => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a headless range slider value display
/// Outputs: <div class="radix-range-slider-values">children</div>
pub fn radix_range_slider_values(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-range-slider-values"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the range slider component
fn range_slider_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.range-slider {
    #|  position: relative;
    #|  display: flex;
    #|  align-items: center;
    #|  width: 100%;
    #|  height: 1.25rem;
    #|}
    #|
    #|.range-slider[data-disabled] {
    #|  opacity: 0.5;
    #|  pointer-events: none;
    #|}
    #|
    #|.range-slider-track {
    #|  position: relative;
    #|  flex: 1;
    #|  height: 0.25rem;
    #|  background: #e4e4e7;
    #|  border-radius: 9999px;
    #|}
    #|
    #|.range-slider-range {
    #|  position: absolute;
    #|  height: 100%;
    #|  background: #18181b;
    #|  border-radius: 9999px;
    #|}
    #|
    #|.range-slider-thumb {
    #|  position: absolute;
    #|  top: 50%;
    #|  width: 1.25rem;
    #|  height: 1.25rem;
    #|  background: white;
    #|  border: 2px solid #18181b;
    #|  border-radius: 50%;
    #|  transform: translate(-50%, -50%);
    #|  cursor: grab;
    #|  transition: box-shadow 0.15s ease;
    #|}
    #|
    #|.range-slider-thumb:hover {
    #|  box-shadow: 0 0 0 4px rgba(24, 24, 27, 0.1);
    #|}
    #|
    #|.range-slider-thumb:focus {
    #|  outline: none;
    #|  box-shadow: 0 0 0 4px rgba(24, 24, 27, 0.2);
    #|}
    #|
    #|.range-slider-thumb:active {
    #|  cursor: grabbing;
    #|}
    #|
    #|.range-slider-values {
    #|  display: flex;
    #|  justify-content: space-between;
    #|  margin-top: 0.5rem;
    #|  font-size: 0.75rem;
    #|  color: #71717a;
    #|}
  css
}

///|
/// Create a styled range slider with Declarative Shadow DOM
pub fn radix_range_slider_styled(
  min? : String,
  max? : String,
  disabled? : Bool,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => range_slider_styles()
  }
  let template_children : Array[@luna.Node[Unit]] = [
    @luna.h("style", [], [@luna.text(css)]),
    @luna.h("slot", [], []),
  ]
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
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("role", @luna.attr_static("group")),
  ]
  match min {
    Some(m) => attrs.push(("data-min", @luna.attr_static(m)))
    None => ()
  }
  match max {
    Some(m) => attrs.push(("data-max", @luna.attr_static(m)))
    None => ()
  }
  match disabled {
    Some(true) => attrs.push(("data-disabled", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("radix-range-slider", attrs, all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a range slider with luna/css atomic styles
pub fn radix_range_slider_ucss(
  min? : String,
  max? : String,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = range_slider_base_styles()
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("role", @luna.attr_static("group")),
  ]
  match min {
    Some(m) => attrs.push(("data-min", @luna.attr_static(m)))
    None => ()
  }
  match max {
    Some(m) => attrs.push(("data-max", @luna.attr_static(m)))
    None => ()
  }
  match disabled {
    Some(true) => attrs.push(("data-disabled", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a range slider track with luna/css atomic styles
pub fn radix_range_slider_track_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = range_slider_track_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a range slider thumb with luna/css atomic styles
pub fn radix_range_slider_thumb_ucss(
  position_percent : Int,
  value? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let base_styles = range_slider_thumb_styles()
  let style = "left: " + position_percent.to_string() + "%"
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(base_styles)),
    ("role", @luna.attr_static("slider")),
    ("tabindex", @luna.attr_static("0")),
    ("style", @luna.attr_static(style)),
  ]
  match value {
    Some(v) => attrs.push(("aria-valuenow", @luna.attr_static(v)))
    None => ()
  }
  @luna.h("div", attrs, children)
}
