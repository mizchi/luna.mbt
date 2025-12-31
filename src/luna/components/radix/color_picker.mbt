///|
/// ColorPicker component for Luna (Headless)
/// Color selection input

///|
/// Create a headless color picker root
/// Outputs: <div class="radix-color-picker">children</div>
pub fn radix_color_picker(
  value? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-color-picker")),
  ]
  match value {
    Some(v) => attrs.push(("data-value", @luna.attr_static(v)))
    None => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a headless color picker trigger
/// Outputs: <button class="radix-color-picker-trigger">children</button>
pub fn radix_color_picker_trigger(
  color? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-color-picker-trigger")),
    ("type", @luna.attr_static("button")),
  ]
  match color {
    Some(c) => attrs.push(("style", @luna.attr_static("--color: " + c)))
    None => ()
  }
  @luna.h("button", attrs, children)
}

///|
/// Create a headless color picker swatch (color preview)
/// Outputs: <div class="radix-color-picker-swatch" style="background: ..."></div>
pub fn radix_color_picker_swatch(color : String) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-color-picker-swatch")),
      ("style", @luna.attr_static("background: " + color)),
    ],
    [],
  )
}

///|
/// Create a headless color picker content (popup)
/// Outputs: <div class="radix-color-picker-content">children</div>
pub fn radix_color_picker_content(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-color-picker-content"))],
    children,
  )
}

///|
/// Create a headless color picker area (gradient picker)
/// Outputs: <div class="radix-color-picker-area">children</div>
pub fn radix_color_picker_area(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-color-picker-area"))],
    children,
  )
}

///|
/// Create a headless color picker slider (hue/alpha slider)
/// Outputs: <div class="radix-color-picker-slider" data-type="..."></div>
pub fn radix_color_picker_slider(slider_type : String) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-color-picker-slider")),
      ("data-type", @luna.attr_static(slider_type)),
    ],
    [],
  )
}

///|
/// Create a headless color picker input (hex/rgb input)
/// Outputs: <input class="radix-color-picker-input" type="text" />
pub fn radix_color_picker_input(
  value? : String,
  placeholder? : String,
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-color-picker-input")),
    ("type", @luna.attr_static("text")),
  ]
  match value {
    Some(v) => attrs.push(("value", @luna.attr_static(v)))
    None => ()
  }
  match placeholder {
    Some(p) => attrs.push(("placeholder", @luna.attr_static(p)))
    None => ()
  }
  @luna.h("input", attrs, [])
}

///|
/// Create a headless color picker swatches (preset colors)
/// Outputs: <div class="radix-color-picker-swatches">children</div>
pub fn radix_color_picker_swatches(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-color-picker-swatches"))],
    children,
  )
}

///|
/// Create a headless color picker swatch button
/// Outputs: <button class="radix-color-picker-swatch-button" style="background: ..."></button>
pub fn radix_color_picker_swatch_button(color : String) -> @luna.Node[Unit] {
  @luna.h(
    "button",
    [
      ("class", @luna.attr_static("radix-color-picker-swatch-button")),
      ("type", @luna.attr_static("button")),
      ("style", @luna.attr_static("background: " + color)),
      ("data-color", @luna.attr_static(color)),
    ],
    [],
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the color picker component
fn color_picker_styles() -> String {
  let css =
    #|:host {
    #|  display: inline-block;
    #|  position: relative;
    #|}
    #|
    #|.color-picker-trigger {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  gap: 0.5rem;
    #|  padding: 0.5rem;
    #|  background: white;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|  cursor: pointer;
    #|}
    #|
    #|.color-picker-swatch {
    #|  width: 1.5rem;
    #|  height: 1.5rem;
    #|  border-radius: 4px;
    #|  border: 1px solid rgba(0,0,0,0.1);
    #|}
    #|
    #|.color-picker-content {
    #|  position: absolute;
    #|  top: 100%;
    #|  left: 0;
    #|  z-index: 50;
    #|  width: 14rem;
    #|  padding: 0.75rem;
    #|  margin-top: 0.25rem;
    #|  background: white;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 8px;
    #|  box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);
    #|}
    #|
    #|.color-picker-area {
    #|  width: 100%;
    #|  height: 8rem;
    #|  border-radius: 6px;
    #|  background: linear-gradient(to bottom, transparent, black),
    #|              linear-gradient(to right, white, transparent);
    #|  cursor: crosshair;
    #|  margin-bottom: 0.75rem;
    #|}
    #|
    #|.color-picker-slider {
    #|  width: 100%;
    #|  height: 0.75rem;
    #|  border-radius: 9999px;
    #|  margin-bottom: 0.5rem;
    #|  cursor: pointer;
    #|}
    #|
    #|.color-picker-slider[data-type="hue"] {
    #|  background: linear-gradient(to right,
    #|    hsl(0, 100%, 50%),
    #|    hsl(60, 100%, 50%),
    #|    hsl(120, 100%, 50%),
    #|    hsl(180, 100%, 50%),
    #|    hsl(240, 100%, 50%),
    #|    hsl(300, 100%, 50%),
    #|    hsl(360, 100%, 50%)
    #|  );
    #|}
    #|
    #|.color-picker-slider[data-type="alpha"] {
    #|  background: linear-gradient(to right, transparent, currentColor);
    #|}
    #|
    #|.color-picker-input {
    #|  width: 100%;
    #|  padding: 0.5rem;
    #|  font-size: 0.75rem;
    #|  font-family: monospace;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 4px;
    #|  text-transform: uppercase;
    #|}
    #|
    #|.color-picker-swatches {
    #|  display: grid;
    #|  grid-template-columns: repeat(8, 1fr);
    #|  gap: 0.25rem;
    #|  margin-top: 0.75rem;
    #|}
    #|
    #|.color-picker-swatch-button {
    #|  width: 100%;
    #|  aspect-ratio: 1;
    #|  border: none;
    #|  border-radius: 4px;
    #|  cursor: pointer;
    #|  transition: transform 0.15s ease;
    #|}
    #|
    #|.color-picker-swatch-button:hover {
    #|  transform: scale(1.1);
    #|}
  css
}

///|
/// Create a styled color picker with Declarative Shadow DOM
pub fn radix_color_picker_styled(
  value? : String,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => color_picker_styles()
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
  let attrs : Array[(String, @luna.Attr[Unit])] = []
  match value {
    Some(v) => attrs.push(("data-value", @luna.attr_static(v)))
    None => ()
  }
  @luna.h("radix-color-picker", attrs, all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a color picker trigger with luna/css atomic styles
pub fn radix_color_picker_trigger_ucss(
  color? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = color_picker_trigger_styles()
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("type", @luna.attr_static("button")),
  ]
  match color {
    Some(c) => attrs.push(("style", @luna.attr_static("--color: " + c)))
    None => ()
  }
  @luna.h("button", attrs, children)
}

///|
/// Create a color picker swatch with luna/css atomic styles
pub fn radix_color_picker_swatch_ucss(color : String) -> @luna.Node[Unit] {
  let class_names = color_picker_swatch_styles()
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("style", @luna.attr_static("background: " + color)),
    ],
    [],
  )
}

///|
/// Create a color picker content with luna/css atomic styles
pub fn radix_color_picker_content_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = color_picker_content_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}
