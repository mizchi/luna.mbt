///|
/// TimePicker component for Luna (Headless)
/// Time selection input

///|
/// TimePicker format enum
pub enum TimePickerFormat {
  H12
  H24
}

///|
/// Create a headless time picker root
/// Outputs: <div class="radix-time-picker">children</div>
pub fn radix_time_picker(
  open? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-time-picker")),
  ]
  match open {
    Some(true) => attrs.push(("data-open", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a headless time picker trigger
/// Outputs: <button class="radix-time-picker-trigger">children</button>
pub fn radix_time_picker_trigger(
  value? : String,
  placeholder? : String,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-time-picker-trigger")),
    ("type", @luna.attr_static("button")),
  ]
  match value {
    Some(v) => attrs.push(("data-value", @luna.attr_static(v)))
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
/// Create a headless time picker content
/// Outputs: <div class="radix-time-picker-content">children</div>
pub fn radix_time_picker_content(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-time-picker-content"))],
    children,
  )
}

///|
/// Create a headless time picker column (hours/minutes/seconds/period)
/// Outputs: <div class="radix-time-picker-column" data-type="...">children</div>
pub fn radix_time_picker_column(
  column_type : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-time-picker-column")),
      ("data-type", @luna.attr_static(column_type)),
      ("role", @luna.attr_static("listbox")),
    ],
    children,
  )
}

///|
/// Create a headless time picker option
/// Outputs: <div class="radix-time-picker-option" role="option">value</div>
pub fn radix_time_picker_option(
  value : String,
  selected? : Bool,
  disabled? : Bool,
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-time-picker-option")),
    ("role", @luna.attr_static("option")),
    ("data-value", @luna.attr_static(value)),
  ]
  match selected {
    Some(true) => {
      attrs.push(("aria-selected", @luna.attr_static("true")))
      attrs.push(("data-selected", @luna.attr_static("")))
    }
    _ => ()
  }
  match disabled {
    Some(true) => attrs.push(("data-disabled", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("div", attrs, [@luna.text(value)])
}

///|
/// Create a headless time picker separator
/// Outputs: <span class="radix-time-picker-separator">:</span>
pub fn radix_time_picker_separator() -> @luna.Node[Unit] {
  @luna.h(
    "span",
    [("class", @luna.attr_static("radix-time-picker-separator"))],
    [@luna.text(":")],
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the time picker component
fn time_picker_styles() -> String {
  let css =
    #|:host {
    #|  display: inline-block;
    #|  position: relative;
    #|}
    #|
    #|.time-picker {
    #|  position: relative;
    #|}
    #|
    #|.time-picker-trigger {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  gap: 0.5rem;
    #|  padding: 0.5rem 0.75rem;
    #|  background: white;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|  font-size: 0.875rem;
    #|  cursor: pointer;
    #|  min-width: 8rem;
    #|  transition: border-color 0.15s ease;
    #|}
    #|
    #|.time-picker-trigger:hover:not(:disabled) {
    #|  border-color: #a1a1aa;
    #|}
    #|
    #|.time-picker-trigger:disabled {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
    #|
    #|.time-picker-content {
    #|  position: absolute;
    #|  top: 100%;
    #|  left: 0;
    #|  z-index: 50;
    #|  display: flex;
    #|  gap: 0.25rem;
    #|  margin-top: 0.25rem;
    #|  padding: 0.5rem;
    #|  background: white;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 8px;
    #|  box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);
    #|}
    #|
    #|.time-picker:not([data-open]) .time-picker-content {
    #|  display: none;
    #|}
    #|
    #|.time-picker-column {
    #|  display: flex;
    #|  flex-direction: column;
    #|  max-height: 12rem;
    #|  overflow-y: auto;
    #|  padding: 0.25rem;
    #|}
    #|
    #|.time-picker-option {
    #|  padding: 0.375rem 0.75rem;
    #|  font-size: 0.875rem;
    #|  border-radius: 4px;
    #|  cursor: pointer;
    #|  text-align: center;
    #|  transition: background 0.15s ease;
    #|}
    #|
    #|.time-picker-option:hover:not([data-disabled]) {
    #|  background: #f4f4f5;
    #|}
    #|
    #|.time-picker-option[data-selected] {
    #|  background: #18181b;
    #|  color: white;
    #|}
    #|
    #|.time-picker-option[data-disabled] {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
    #|
    #|.time-picker-separator {
    #|  display: flex;
    #|  align-items: center;
    #|  color: #71717a;
    #|  font-weight: 500;
    #|}
  css
}

///|
/// Create a styled time picker with Declarative Shadow DOM
pub fn radix_time_picker_styled(
  open? : Bool,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => time_picker_styles()
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
  @luna.h("radix-time-picker", attrs, all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a time picker with luna/css atomic styles
pub fn radix_time_picker_ucss(
  open? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = time_picker_base_styles()
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
/// Create a time picker trigger with luna/css atomic styles
pub fn radix_time_picker_trigger_ucss(
  value? : String,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = time_picker_trigger_styles()
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("type", @luna.attr_static("button")),
  ]
  match value {
    Some(v) => attrs.push(("data-value", @luna.attr_static(v)))
    None => ()
  }
  match disabled {
    Some(true) => attrs.push(("disabled", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("button", attrs, children)
}

///|
/// Create a time picker content with luna/css atomic styles
pub fn radix_time_picker_content_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = time_picker_content_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a time picker option with luna/css atomic styles
pub fn radix_time_picker_option_ucss(
  value : String,
  selected? : Bool,
) -> @luna.Node[Unit] {
  let class_names = time_picker_option_styles(selected)
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("role", @luna.attr_static("option")),
    ("data-value", @luna.attr_static(value)),
  ]
  match selected {
    Some(true) => attrs.push(("aria-selected", @luna.attr_static("true")))
    _ => ()
  }
  @luna.h("div", attrs, [@luna.text(value)])
}
