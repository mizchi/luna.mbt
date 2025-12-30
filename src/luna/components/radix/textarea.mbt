///|
/// Radix-style Textarea component for Luna
/// Uses Declarative Shadow DOM with data-* attributes for styling

///|
/// CSS styles for the textarea component
fn textarea_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.textarea-wrapper {
    #|  display: flex;
    #|  flex-direction: column;
    #|  gap: 0.375rem;
    #|}
    #|
    #|.textarea-label {
    #|  font-size: 0.875rem;
    #|  font-weight: 500;
    #|  color: #18181b;
    #|}
    #|
    #|.textarea {
    #|  display: block;
    #|  width: 100%;
    #|  min-height: 5rem;
    #|  box-sizing: border-box;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|  font-family: inherit;
    #|  font-size: 0.875rem;
    #|  line-height: 1.5;
    #|  padding: 0.5rem 0.75rem;
    #|  resize: vertical;
    #|  transition: all 0.15s ease;
    #|  background: white;
    #|}
    #|
    #|.textarea:focus {
    #|  outline: none;
    #|  border-color: #18181b;
    #|  box-shadow: 0 0 0 1px #18181b;
    #|}
    #|
    #|/* Disabled state */
    #|.textarea[data-disabled] {
    #|  background: #f4f4f5;
    #|  color: #a1a1aa;
    #|  cursor: not-allowed;
    #|  opacity: 0.5;
    #|  resize: none;
    #|}
    #|
    #|.textarea[readonly] {
    #|  background: #fafafa;
    #|}
    #|
    #|.textarea::placeholder {
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
/// Create a radix-textarea element with Declarative Shadow DOM
pub fn radix_textarea(
  label? : String,
  placeholder? : String,
  value? : String,
  rows? : Int,
  disabled? : Bool,
  readonly_? : Bool,
  required? : Bool,
  help_text? : String,
  minlength? : Int,
  maxlength? : Int,
) -> @luna.Node[Unit] {
  // Build textarea attributes
  let textarea_attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("textarea")),
  ]
  match placeholder {
    Some(p) => textarea_attrs.push(("placeholder", @luna.attr_static(p)))
    None => ()
  }
  match rows {
    Some(r) => textarea_attrs.push(("rows", @luna.attr_static(r.to_string())))
    None => ()
  }
  match disabled {
    Some(true) => {
      textarea_attrs.push(("data-disabled", @luna.attr_static("")))
      textarea_attrs.push(("disabled", @luna.attr_static("")))
    }
    _ => ()
  }
  match readonly_ {
    Some(true) => textarea_attrs.push(("readonly", @luna.attr_static("")))
    _ => ()
  }
  match required {
    Some(true) => textarea_attrs.push(("required", @luna.attr_static("")))
    _ => ()
  }
  match minlength {
    Some(n) =>
      textarea_attrs.push(("minlength", @luna.attr_static(n.to_string())))
    None => ()
  }
  match maxlength {
    Some(n) =>
      textarea_attrs.push(("maxlength", @luna.attr_static(n.to_string())))
    None => ()
  }

  // Build wrapper content
  let wrapper_children : Array[@luna.Node[Unit]] = []

  // Add label if provided
  match label {
    Some(l) =>
      wrapper_children.push(
        @luna.h("label", [("class", @luna.attr_static("textarea-label"))], [
          @luna.text(l),
        ]),
      )
    None => ()
  }

  // Add textarea element with optional default value
  let textarea_content : Array[@luna.Node[Unit]] = match value {
    Some(v) => [@luna.text(v)]
    None => []
  }
  wrapper_children.push(@luna.h("textarea", textarea_attrs, textarea_content))

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
    @luna.h("style", [], [@luna.text(textarea_styles())]),
    @luna.h(
      "div",
      [("class", @luna.attr_static("textarea-wrapper"))],
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
  @luna.h("radix-textarea", host_attrs, [
    @luna.h(
      "template",
      [("shadowrootmode", @luna.attr_static("open"))],
      template_children,
    ),
  ])
}
