///|
/// Radix-style Input component for Luna (Headless)
/// Outputs semantic HTML with data-* attributes for external CSS styling

///|
/// Input type variants
pub(all) enum InputType {
  Text
  Email
  Password
  Number
  Tel
  Url
  Search
  Date
}

///|
pub fn InputType::to_string(self : InputType) -> String {
  match self {
    Text => "text"
    Email => "email"
    Password => "password"
    Number => "number"
    Tel => "tel"
    Url => "url"
    Search => "search"
    Date => "date"
  }
}

///|
/// Create a headless input element
/// Outputs: <input class="radix-input" type="..." data-size="..." .../>
/// Style with external CSS using [data-size="..."] selectors
pub fn radix_input(
  type_? : InputType,
  label? : String,
  placeholder? : String,
  value? : String,
  size? : RadixSize,
  disabled? : Bool,
  readonly_? : Bool,
  required? : Bool,
  help_text? : String,
  minlength? : Int,
  maxlength? : Int,
  pattern? : String,
) -> @luna.Node[Unit] {
  let type_val = match type_ {
    Some(t) => t
    None => Text
  }
  let size_val = match size {
    Some(s) => s
    None => Medium
  }
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-input")),
    ("type", @luna.attr_static(type_val.to_string())),
    ("data-size", @luna.attr_static(size_val.to_string())),
  ]
  match placeholder {
    Some(p) => attrs.push(("placeholder", @luna.attr_static(p)))
    None => ()
  }
  match value {
    Some(v) => attrs.push(("value", @luna.attr_static(v)))
    None => ()
  }
  match disabled {
    Some(true) => {
      attrs.push(("data-disabled", @luna.attr_static("")))
      attrs.push(("disabled", @luna.attr_static("")))
    }
    _ => ()
  }
  match readonly_ {
    Some(true) => attrs.push(("readonly", @luna.attr_static("")))
    _ => ()
  }
  match required {
    Some(true) => attrs.push(("required", @luna.attr_static("")))
    _ => ()
  }
  match minlength {
    Some(n) => attrs.push(("minlength", @luna.attr_static(n.to_string())))
    None => ()
  }
  match maxlength {
    Some(n) => attrs.push(("maxlength", @luna.attr_static(n.to_string())))
    None => ()
  }
  match pattern {
    Some(p) => attrs.push(("pattern", @luna.attr_static(p)))
    None => ()
  }

  // For headless, we just output input. Label/help_text are ignored in headless mode.
  // Users should wrap with their own label structure.
  let _ = label
  let _ = help_text
  @luna.h("input", attrs, [])
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the input component
fn input_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.input-wrapper {
    #|  display: flex;
    #|  flex-direction: column;
    #|  gap: 0.375rem;
    #|}
    #|
    #|.input-label {
    #|  font-size: 0.875rem;
    #|  font-weight: 500;
    #|  color: #18181b;
    #|}
    #|
    #|.input {
    #|  display: flex;
    #|  width: 100%;
    #|  box-sizing: border-box;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|  font-family: inherit;
    #|  transition: all 0.15s ease;
    #|  background: white;
    #|}
    #|
    #|.input:focus {
    #|  outline: none;
    #|  border-color: #18181b;
    #|  box-shadow: 0 0 0 1px #18181b;
    #|}
    #|
    #|/* Sizes via data-size */
    #|.input[data-size="small"] { height: 2rem; padding: 0 0.5rem; font-size: 0.875rem; }
    #|.input[data-size="medium"] { height: 2.5rem; padding: 0 0.75rem; font-size: 0.875rem; }
    #|.input[data-size="large"] { height: 3rem; padding: 0 1rem; font-size: 1rem; }
    #|
    #|/* Disabled state */
    #|.input[data-disabled] {
    #|  background: #f4f4f5;
    #|  color: #a1a1aa;
    #|  cursor: not-allowed;
    #|  opacity: 0.5;
    #|}
    #|
    #|.input[readonly] {
    #|  background: #fafafa;
    #|}
    #|
    #|.input::placeholder {
    #|  color: #a1a1aa;
    #|}
    #|
    #|.help-text {
    #|  font-size: 0.75rem;
    #|  color: #71717a;
    #|}
  css
}

///|
/// Create a styled input with Declarative Shadow DOM
/// Uses inline CSS for zero CLS (Cumulative Layout Shift)
pub fn radix_input_styled(
  type_? : InputType,
  label? : String,
  placeholder? : String,
  value? : String,
  size? : RadixSize,
  disabled? : Bool,
  readonly_? : Bool,
  required? : Bool,
  help_text? : String,
  minlength? : Int,
  maxlength? : Int,
  pattern? : String,
  styles? : String,
) -> @luna.Node[Unit] {
  let type_val = match type_ {
    Some(t) => t
    None => Text
  }
  let size_val = match size {
    Some(s) => s
    None => Medium
  }
  let css = match styles {
    Some(s) => s
    None => input_styles()
  }

  // Build input attributes with data-* for styling
  let input_attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("input")),
    ("type", @luna.attr_static(type_val.to_string())),
    ("data-size", @luna.attr_static(size_val.to_string())),
  ]
  match placeholder {
    Some(p) => input_attrs.push(("placeholder", @luna.attr_static(p)))
    None => ()
  }
  match value {
    Some(v) => input_attrs.push(("value", @luna.attr_static(v)))
    None => ()
  }
  match disabled {
    Some(true) => {
      input_attrs.push(("data-disabled", @luna.attr_static("")))
      input_attrs.push(("disabled", @luna.attr_static("")))
    }
    _ => ()
  }
  match readonly_ {
    Some(true) => input_attrs.push(("readonly", @luna.attr_static("")))
    _ => ()
  }
  match required {
    Some(true) => input_attrs.push(("required", @luna.attr_static("")))
    _ => ()
  }
  match minlength {
    Some(n) => input_attrs.push(("minlength", @luna.attr_static(n.to_string())))
    None => ()
  }
  match maxlength {
    Some(n) => input_attrs.push(("maxlength", @luna.attr_static(n.to_string())))
    None => ()
  }
  match pattern {
    Some(p) => input_attrs.push(("pattern", @luna.attr_static(p)))
    None => ()
  }

  // Build wrapper content
  let wrapper_children : Array[@luna.Node[Unit]] = []

  // Add label if provided
  match label {
    Some(l) =>
      wrapper_children.push(
        @luna.h("label", [("class", @luna.attr_static("input-label"))], [
          @luna.text(l),
        ]),
      )
    None => ()
  }

  // Add input element
  wrapper_children.push(@luna.h("input", input_attrs, []))

  // Add help text if provided
  match help_text {
    Some(h) =>
      wrapper_children.push(
        @luna.h("span", [("class", @luna.attr_static("help-text"))], [
          @luna.text(h),
        ]),
      )
    None => ()
  }

  // Build template content
  let template_children : Array[@luna.Node[Unit]] = [
    @luna.h("style", [], [@luna.text(css)]),
    @luna.h(
      "div",
      [("class", @luna.attr_static("input-wrapper"))],
      wrapper_children,
    ),
  ]

  // Host attributes
  let host_attrs : Array[(String, @luna.Attr[Unit])] = []
  match disabled {
    Some(true) => host_attrs.push(("data-disabled", @luna.attr_static("")))
    _ => ()
  }

  // Create the DSD structure
  @luna.h("radix-input", host_attrs, [
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
/// Create an input with luna/css atomic styles
/// Uses CSS utilities for SSR static extraction
pub fn radix_input_ucss(
  type_? : InputType,
  placeholder? : String,
  value? : String,
  size? : RadixSize,
  disabled? : Bool,
  readonly_? : Bool,
  required? : Bool,
) -> @luna.Node[Unit] {
  let type_val = match type_ {
    Some(t) => t
    None => Text
  }
  let size_val = match size {
    Some(s) => s
    None => Medium
  }

  // Build class names using luna/css
  let mut class_names = input_base_styles() +
    " " +
    input_size_styles(size_val) +
    " " +
    input_focus_styles()

  // Add disabled styles if needed
  match disabled {
    Some(true) => class_names = class_names + " " + input_disabled_styles()
    _ => ()
  }

  // Build attributes
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("type", @luna.attr_static(type_val.to_string())),
  ]
  match placeholder {
    Some(p) => attrs.push(("placeholder", @luna.attr_static(p)))
    None => ()
  }
  match value {
    Some(v) => attrs.push(("value", @luna.attr_static(v)))
    None => ()
  }
  match disabled {
    Some(true) => attrs.push(("disabled", @luna.attr_static("")))
    _ => ()
  }
  match readonly_ {
    Some(true) => attrs.push(("readonly", @luna.attr_static("")))
    _ => ()
  }
  match required {
    Some(true) => attrs.push(("required", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("input", attrs, [])
}
