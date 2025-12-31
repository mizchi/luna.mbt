///|
/// Radix-style DatePicker component for Luna (Headless)
/// Date picker input with calendar popup

///|
/// Create a headless date picker root
/// Outputs: <div class="radix-date-picker">children</div>
pub fn radix_date_picker(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-date-picker"))], children)
}

///|
/// Create a headless date picker trigger
/// Outputs: <button class="radix-date-picker-trigger">children</button>
pub fn radix_date_picker_trigger(
  placeholder? : String,
  value? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-date-picker-trigger")),
  ]

  match placeholder {
    Some(p) => attrs.push(("data-placeholder", @luna.attr_static(p)))
    None => ()
  }

  match value {
    Some(v) => attrs.push(("data-value", @luna.attr_static(v)))
    None => ()
  }

  @luna.h("button", attrs, children)
}

///|
/// Create a headless date picker content (calendar popup)
/// Outputs: <div class="radix-date-picker-content">children</div>
pub fn radix_date_picker_content(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-date-picker-content"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the date picker component
fn date_picker_styles() -> String {
  let css =
    #|:host {
    #|  display: inline-block;
    #|  position: relative;
    #|}
    #|
    #|.date-picker-trigger {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  gap: 0.5rem;
    #|  padding: 0.5rem 0.75rem;
    #|  font-size: 0.875rem;
    #|  background: white;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|  cursor: pointer;
    #|  transition: border-color 0.15s ease;
    #|}
    #|
    #|.date-picker-trigger:hover {
    #|  border-color: #a1a1aa;
    #|}
    #|
    #|.date-picker-trigger:focus {
    #|  outline: 2px solid #2563eb;
    #|  outline-offset: 2px;
    #|}
    #|
    #|.date-picker-content {
    #|  position: absolute;
    #|  top: 100%;
    #|  left: 0;
    #|  z-index: 50;
    #|  margin-top: 0.25rem;
    #|}
  css
}

///|
/// Create a styled date picker with Declarative Shadow DOM
pub fn radix_date_picker_styled(
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => date_picker_styles()
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

  @luna.h("radix-date-picker", [], all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a date picker with luna/css atomic styles
pub fn radix_date_picker_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = date_picker_base_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a date picker trigger with luna/css atomic styles
pub fn radix_date_picker_trigger_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = date_picker_trigger_styles()
  @luna.h("button", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a date picker content with luna/css atomic styles
pub fn radix_date_picker_content_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = date_picker_content_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}
