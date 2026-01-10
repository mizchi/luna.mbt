///|
/// DateRangePicker component for Luna (Headless)
/// Date range selection with dual calendar view

///|
/// Create a headless date range picker root
/// Outputs: <div class="radix-date-range-picker">children</div>
pub fn radix_date_range_picker(
  open? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-date-range-picker")),
  ]
  match open {
    Some(true) => attrs.push(("data-open", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a headless date range picker trigger
/// Outputs: <button class="radix-date-range-picker-trigger">children</button>
pub fn radix_date_range_picker_trigger(
  start_date? : String,
  end_date? : String,
  placeholder? : String,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-date-range-picker-trigger")),
    ("type", @luna.attr_static("button")),
  ]
  match start_date {
    Some(d) => attrs.push(("data-start", @luna.attr_static(d)))
    None => ()
  }
  match end_date {
    Some(d) => attrs.push(("data-end", @luna.attr_static(d)))
    None => ()
  }
  match placeholder {
    Some(p) => attrs.push(("data-placeholder", @luna.attr_static(p)))
    None => ()
  }
  match disabled {
    Some(true) => {
      attrs.push(("disabled", @luna.attr_static("")))
      attrs.push(("data-disabled", @luna.attr_static("")))
    }
    _ => ()
  }
  @luna.h("button", attrs, children)
}

///|
/// Create a headless date range picker content
/// Outputs: <div class="radix-date-range-picker-content">children</div>
pub fn radix_date_range_picker_content(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-date-range-picker-content"))],
    children,
  )
}

///|
/// Create a headless date range picker calendars container
/// Outputs: <div class="radix-date-range-picker-calendars">children</div>
pub fn radix_date_range_picker_calendars(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-date-range-picker-calendars"))],
    children,
  )
}

///|
/// Create a headless date range picker presets
/// Outputs: <div class="radix-date-range-picker-presets">children</div>
pub fn radix_date_range_picker_presets(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-date-range-picker-presets"))],
    children,
  )
}

///|
/// Create a headless date range picker preset button
/// Outputs: <button class="radix-date-range-picker-preset">label</button>
pub fn radix_date_range_picker_preset(
  label : String,
  start_date : String,
  end_date : String,
) -> @luna.Node[Unit] {
  @luna.h(
    "button",
    [
      ("class", @luna.attr_static("radix-date-range-picker-preset")),
      ("type", @luna.attr_static("button")),
      ("data-start", @luna.attr_static(start_date)),
      ("data-end", @luna.attr_static(end_date)),
    ],
    [@luna.text(label)],
  )
}

///|
/// Create a headless date range display
/// Outputs: <span class="radix-date-range-picker-display">children</span>
pub fn radix_date_range_picker_display(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "span",
    [("class", @luna.attr_static("radix-date-range-picker-display"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the date range picker component
fn date_range_picker_styles() -> String {
  let css =
    #|:host {
    #|  display: inline-block;
    #|  position: relative;
    #|}
    #|
    #|.date-range-picker {
    #|  position: relative;
    #|}
    #|
    #|.date-range-picker-trigger {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  gap: 0.5rem;
    #|  padding: 0.5rem 0.75rem;
    #|  background: white;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|  font-size: 0.875rem;
    #|  cursor: pointer;
    #|  min-width: 16rem;
    #|  transition: border-color 0.15s ease;
    #|}
    #|
    #|.date-range-picker-trigger:hover:not(:disabled) {
    #|  border-color: #a1a1aa;
    #|}
    #|
    #|.date-range-picker-trigger:disabled {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
    #|
    #|.date-range-picker-content {
    #|  position: absolute;
    #|  top: 100%;
    #|  left: 0;
    #|  z-index: 50;
    #|  display: flex;
    #|  gap: 1rem;
    #|  margin-top: 0.25rem;
    #|  padding: 1rem;
    #|  background: white;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 8px;
    #|  box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);
    #|}
    #|
    #|.date-range-picker:not([data-open]) .date-range-picker-content {
    #|  display: none;
    #|}
    #|
    #|.date-range-picker-calendars {
    #|  display: flex;
    #|  gap: 1rem;
    #|}
    #|
    #|.date-range-picker-presets {
    #|  display: flex;
    #|  flex-direction: column;
    #|  gap: 0.25rem;
    #|  padding-left: 1rem;
    #|  border-left: 1px solid #e4e4e7;
    #|}
    #|
    #|.date-range-picker-preset {
    #|  padding: 0.5rem 0.75rem;
    #|  background: transparent;
    #|  border: none;
    #|  border-radius: 4px;
    #|  font-size: 0.875rem;
    #|  text-align: left;
    #|  cursor: pointer;
    #|  transition: background 0.15s ease;
    #|}
    #|
    #|.date-range-picker-preset:hover {
    #|  background: #f4f4f5;
    #|}
    #|
    #|.date-range-picker-display {
    #|  color: #18181b;
    #|}
    #|
    #|.date-range-picker-trigger:not([data-start]) .date-range-picker-display {
    #|  color: #a1a1aa;
    #|}
  css
}

///|
/// Create a styled date range picker with Declarative Shadow DOM
pub fn radix_date_range_picker_styled(
  open? : Bool,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => date_range_picker_styles()
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
  match open {
    Some(true) => attrs.push(("data-open", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("radix-date-range-picker", attrs, all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a date range picker with luna/css atomic styles
pub fn radix_date_range_picker_ucss(
  open? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = date_range_picker_base_styles()
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
  ]
  match open {
    Some(true) => attrs.push(("data-open", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a date range picker trigger with luna/css atomic styles
pub fn radix_date_range_picker_trigger_ucss(
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = date_range_picker_trigger_styles()
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("type", @luna.attr_static("button")),
  ]
  match disabled {
    Some(true) => attrs.push(("disabled", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("button", attrs, children)
}

///|
/// Create a date range picker content with luna/css atomic styles
pub fn radix_date_range_picker_content_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = date_range_picker_content_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}
