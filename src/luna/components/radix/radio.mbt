///|
/// Radix-style Radio Group component for Luna (Headless)
/// Outputs semantic HTML with data-* attributes for external CSS styling

///|
/// Radio option
pub(all) struct RadioOption {
  value : String
  label : String
  disabled : Bool
}

///|
/// Create a RadioOption
pub fn radio_option(
  value : String,
  label : String,
  disabled? : Bool,
) -> RadioOption {
  { value, label, disabled: disabled.unwrap_or(false) }
}

///|
/// Orientation for radio group
pub(all) enum Orientation {
  Vertical
  Horizontal
}

///|
pub fn Orientation::to_string(self : Orientation) -> String {
  match self {
    Vertical => "vertical"
    Horizontal => "horizontal"
  }
}

///|
/// Build a single headless radio item
fn build_radio_item_headless(
  name : String,
  opt : RadioOption,
  selected_value : String?,
  group_disabled : Bool,
  group_required : Bool,
) -> @luna.Node[Unit] {
  let input_attrs : Array[(String, @luna.Attr[Unit])] = [
    ("type", @luna.attr_static("radio")),
    ("class", @luna.attr_static("radix-radio")),
    ("name", @luna.attr_static(name)),
    ("value", @luna.attr_static(opt.value)),
  ]

  // Check if this option is selected
  match selected_value {
    Some(v) =>
      if v == opt.value {
        input_attrs.push(("checked", @luna.attr_static("")))
      }
    None => ()
  }

  // Handle disabled state
  if opt.disabled || group_disabled {
    input_attrs.push(("disabled", @luna.attr_static("")))
  }
  if group_required {
    input_attrs.push(("required", @luna.attr_static("")))
  }

  @luna.h("label", [("class", @luna.attr_static("radix-radio-item"))], [
    @luna.h("input", input_attrs, []),
    @luna.h("span", [("class", @luna.attr_static("radix-radio-label"))], [
      @luna.text(opt.label),
    ]),
  ])
}

///|
/// Create a headless radio group
/// Outputs: <div class="radix-radio-group" role="radiogroup" data-orientation="...">items</div>
/// Style with external CSS
pub fn radix_radio_group(
  name : String,
  options : Array[RadioOption],
  label? : String,
  value? : String,
  orientation? : Orientation,
  disabled? : Bool,
  required? : Bool,
) -> @luna.Node[Unit] {
  let orient = match orientation {
    Some(o) => o
    None => Vertical
  }
  let group_disabled = match disabled {
    Some(true) => true
    _ => false
  }
  let group_required = match required {
    Some(true) => true
    _ => false
  }

  // Build radio items using map
  let items : Array[@luna.Node[Unit]] = options.map(fn(opt) {
    build_radio_item_headless(name, opt, value, group_disabled, group_required)
  })

  // Build attrs
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-radio-group")),
    ("role", @luna.attr_static("radiogroup")),
    ("data-orientation", @luna.attr_static(orient.to_string())),
  ]

  if group_disabled {
    attrs.push(("data-disabled", @luna.attr_static("")))
  }

  // For headless, label is ignored
  let _ = label

  @luna.h("div", attrs, items)
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the radio group component
fn radio_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.radio-group {
    #|  display: flex;
    #|  flex-direction: column;
    #|  gap: 0.5rem;
    #|}
    #|
    #|.radio-group[data-orientation="horizontal"] {
    #|  flex-direction: row;
    #|  flex-wrap: wrap;
    #|  gap: 1rem;
    #|}
    #|
    #|.radio-group-label {
    #|  font-size: 0.875rem;
    #|  font-weight: 500;
    #|  color: #18181b;
    #|  margin-bottom: 0.25rem;
    #|}
    #|
    #|.radio-item {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  gap: 0.5rem;
    #|  cursor: pointer;
    #|}
    #|
    #|.radio-item:has(input:disabled) {
    #|  cursor: not-allowed;
    #|  opacity: 0.5;
    #|}
    #|
    #|.radio-control {
    #|  appearance: none;
    #|  -webkit-appearance: none;
    #|  width: 1rem;
    #|  height: 1rem;
    #|  border: 1px solid #18181b;
    #|  border-radius: 50%;
    #|  cursor: inherit;
    #|  transition: all 0.15s ease;
    #|  position: relative;
    #|  background: white;
    #|  flex-shrink: 0;
    #|}
    #|
    #|.radio-control:checked {
    #|  border-color: #18181b;
    #|}
    #|
    #|.radio-control:checked::after {
    #|  content: "";
    #|  position: absolute;
    #|  top: 50%;
    #|  left: 50%;
    #|  transform: translate(-50%, -50%);
    #|  width: 0.5rem;
    #|  height: 0.5rem;
    #|  background: #18181b;
    #|  border-radius: 50%;
    #|}
    #|
    #|.radio-control:focus-visible {
    #|  outline: 2px solid #2563eb;
    #|  outline-offset: 2px;
    #|}
    #|
    #|.radio-label {
    #|  font-size: 0.875rem;
    #|  color: #18181b;
    #|  user-select: none;
    #|}
  css
}

///|
/// Build a single styled radio item
fn build_radio_item_styled(
  name : String,
  opt : RadioOption,
  selected_value : String?,
  group_disabled : Bool,
  group_required : Bool,
) -> @luna.Node[Unit] {
  let input_attrs : Array[(String, @luna.Attr[Unit])] = [
    ("type", @luna.attr_static("radio")),
    ("class", @luna.attr_static("radio-control")),
    ("name", @luna.attr_static(name)),
    ("value", @luna.attr_static(opt.value)),
  ]

  // Check if this option is selected
  match selected_value {
    Some(v) =>
      if v == opt.value {
        input_attrs.push(("checked", @luna.attr_static("")))
      }
    None => ()
  }

  // Handle disabled state
  if opt.disabled || group_disabled {
    input_attrs.push(("disabled", @luna.attr_static("")))
  }
  if group_required {
    input_attrs.push(("required", @luna.attr_static("")))
  }
  @luna.h("label", [("class", @luna.attr_static("radio-item"))], [
    @luna.h("input", input_attrs, []),
    @luna.h("span", [("class", @luna.attr_static("radio-label"))], [
      @luna.text(opt.label),
    ]),
  ])
}

///|
/// Create a styled radio group with Declarative Shadow DOM
/// Uses inline CSS for zero CLS (Cumulative Layout Shift)
pub fn radix_radio_group_styled(
  name : String,
  options : Array[RadioOption],
  label? : String,
  value? : String,
  orientation? : Orientation,
  disabled? : Bool,
  required? : Bool,
  styles? : String,
) -> @luna.Node[Unit] {
  let orient = match orientation {
    Some(o) => o
    None => Vertical
  }
  let group_disabled = match disabled {
    Some(true) => true
    _ => false
  }
  let group_required = match required {
    Some(true) => true
    _ => false
  }

  let css = match styles {
    Some(s) => s
    None => radio_styles()
  }

  // Build radio group attributes
  let group_attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radio-group")),
    ("role", @luna.attr_static("radiogroup")),
    ("data-orientation", @luna.attr_static(orient.to_string())),
  ]

  // Build radio items using map
  let items : Array[@luna.Node[Unit]] = options.map(fn(opt) {
    build_radio_item_styled(name, opt, value, group_disabled, group_required)
  })

  // Build wrapper content
  let wrapper_children : Array[@luna.Node[Unit]] = []

  // Add group label if provided
  match label {
    Some(l) =>
      wrapper_children.push(
        @luna.h("div", [("class", @luna.attr_static("radio-group-label"))], [
          @luna.text(l),
        ]),
      )
    None => ()
  }

  // Add radio group
  wrapper_children.push(@luna.h("div", group_attrs, items))

  // Build template content
  let template_children : Array[@luna.Node[Unit]] = [
    @luna.h("style", [], [@luna.text(css)]),
    @luna.fragment(wrapper_children),
  ]

  // Host attributes
  let host_attrs : Array[(String, @luna.Attr[Unit])] = [
    ("data-orientation", @luna.attr_static(orient.to_string())),
  ]
  if group_disabled {
    host_attrs.push(("data-disabled", @luna.attr_static("")))
  }

  // Create the DSD structure
  @luna.h("radix-radio-group", host_attrs, [
    @luna.h(
      "template",
      [("shadowrootmode", @luna.attr_static("open"))],
      template_children,
    ),
  ])
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Build a single radio item with luna/css styles
fn build_radio_item_ucss(
  name : String,
  opt : RadioOption,
  selected_value : String?,
  group_disabled : Bool,
  group_required : Bool,
) -> @luna.Node[Unit] {
  // Build input class names
  let input_class = radio_control_styles() + " " + radio_control_focus_styles()

  let input_attrs : Array[(String, @luna.Attr[Unit])] = [
    ("type", @luna.attr_static("radio")),
    ("class", @luna.attr_static(input_class)),
    ("name", @luna.attr_static(name)),
    ("value", @luna.attr_static(opt.value)),
  ]

  // Check if this option is selected
  match selected_value {
    Some(v) =>
      if v == opt.value {
        input_attrs.push(("checked", @luna.attr_static("")))
      }
    None => ()
  }

  // Handle disabled state
  if opt.disabled || group_disabled {
    input_attrs.push(("disabled", @luna.attr_static("")))
  }
  if group_required {
    input_attrs.push(("required", @luna.attr_static("")))
  }

  let label_class = radio_label_styles()

  @luna.h("label", [("class", @luna.attr_static(radio_item_styles()))], [
    @luna.h("input", input_attrs, []),
    @luna.h("span", [("class", @luna.attr_static(label_class))], [
      @luna.text(opt.label),
    ]),
  ])
}

///|
/// Create a radio group with luna/css atomic styles
/// Uses CSS utilities for SSR static extraction
pub fn radix_radio_group_ucss(
  name : String,
  options : Array[RadioOption],
  value? : String,
  orientation? : Orientation,
  disabled? : Bool,
  required? : Bool,
) -> @luna.Node[Unit] {
  let orient = match orientation {
    Some(o) => o
    None => Vertical
  }
  let group_disabled = match disabled {
    Some(true) => true
    _ => false
  }
  let group_required = match required {
    Some(true) => true
    _ => false
  }

  // Build class names using luna/css
  let mut class_names = radio_group_base_styles()
  match orient {
    Horizontal =>
      class_names = class_names + " " + radio_group_horizontal_styles()
    Vertical => ()
  }

  // Build radio items using map
  let items : Array[@luna.Node[Unit]] = options.map(fn(opt) {
    build_radio_item_ucss(name, opt, value, group_disabled, group_required)
  })

  // Build attrs
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("role", @luna.attr_static("radiogroup")),
  ]

  @luna.h("div", attrs, items)
}
