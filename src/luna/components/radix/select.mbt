///|
/// Radix-style Select component for Luna
/// Uses Declarative Shadow DOM with data-* attributes for styling

///|
/// Select option
pub(all) struct SelectOption {
  value : String
  label : String
  disabled : Bool
}

///|
/// Create a SelectOption
pub fn select_option(
  value : String,
  label : String,
  disabled? : Bool,
) -> SelectOption {
  { value, label, disabled: disabled.unwrap_or(false) }
}

///|
/// CSS styles for the select component
fn select_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.select-wrapper {
    #|  display: flex;
    #|  flex-direction: column;
    #|  gap: 0.375rem;
    #|}
    #|
    #|.select-label {
    #|  font-size: 0.875rem;
    #|  font-weight: 500;
    #|  color: #18181b;
    #|}
    #|
    #|.select {
    #|  display: flex;
    #|  width: 100%;
    #|  height: 2.5rem;
    #|  box-sizing: border-box;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|  font-family: inherit;
    #|  font-size: 0.875rem;
    #|  padding: 0 0.75rem;
    #|  background: white;
    #|  cursor: pointer;
    #|  transition: all 0.15s ease;
    #|  appearance: none;
    #|  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 12 12'%3E%3Cpath fill='%2371717a' d='M2.5 4.5L6 8l3.5-3.5'/%3E%3C/svg%3E");
    #|  background-repeat: no-repeat;
    #|  background-position: right 0.75rem center;
    #|  padding-right: 2rem;
    #|}
    #|
    #|.select:focus {
    #|  outline: none;
    #|  border-color: #18181b;
    #|  box-shadow: 0 0 0 1px #18181b;
    #|}
    #|
    #|/* Sizes via data-size */
    #|.select[data-size="small"] { height: 2rem; font-size: 0.75rem; padding: 0 0.5rem; padding-right: 1.75rem; }
    #|.select[data-size="medium"] { height: 2.5rem; font-size: 0.875rem; }
    #|.select[data-size="large"] { height: 3rem; font-size: 1rem; padding: 0 1rem; padding-right: 2.25rem; }
    #|
    #|/* Disabled state */
    #|.select[data-disabled] {
    #|  background: #f4f4f5;
    #|  color: #a1a1aa;
    #|  cursor: not-allowed;
    #|  opacity: 0.5;
    #|}
    #|
    #|.help-text {
    #|  font-size: 0.75rem;
    #|  color: #71717a;
    #|}
  css
}

///|
/// Create a radix-select element with Declarative Shadow DOM
pub fn radix_select(
  options : Array[SelectOption],
  label? : String,
  placeholder? : String,
  value? : String,
  size? : RadixSize,
  disabled? : Bool,
  required? : Bool,
  help_text? : String,
) -> @luna.Node[Unit] {
  let size_val = match size {
    Some(s) => s
    None => Medium
  }

  // Build select attributes
  let select_attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("select")),
    ("data-size", @luna.attr_static(size_val.to_string())),
  ]
  match disabled {
    Some(true) => {
      select_attrs.push(("data-disabled", @luna.attr_static("")))
      select_attrs.push(("disabled", @luna.attr_static("")))
    }
    _ => ()
  }
  match required {
    Some(true) => select_attrs.push(("required", @luna.attr_static("")))
    _ => ()
  }

  // Build options
  let option_nodes : Array[@luna.Node[Unit]] = []

  // Add placeholder option if provided
  match placeholder {
    Some(p) =>
      option_nodes.push(
        @luna.h(
          "option",
          [
            ("value", @luna.attr_static("")),
            ("disabled", @luna.attr_static("")),
            ("selected", @luna.attr_static("")),
          ],
          [@luna.text(p)],
        ),
      )
    None => ()
  }

  // Add options
  for opt in options {
    let opt_attrs : Array[(String, @luna.Attr[Unit])] = [
      ("value", @luna.attr_static(opt.value)),
    ]
    if opt.disabled {
      opt_attrs.push(("disabled", @luna.attr_static("")))
    }
    match value {
      Some(v) =>
        if v == opt.value {
          opt_attrs.push(("selected", @luna.attr_static("")))
        }
      None => ()
    }
    option_nodes.push(@luna.h("option", opt_attrs, [@luna.text(opt.label)]))
  }

  // Build wrapper content
  let wrapper_children : Array[@luna.Node[Unit]] = []

  // Add label if provided
  match label {
    Some(l) =>
      wrapper_children.push(
        @luna.h("label", [("class", @luna.attr_static("select-label"))], [
          @luna.text(l),
        ]),
      )
    None => ()
  }

  // Add select element
  wrapper_children.push(@luna.h("select", select_attrs, option_nodes))

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
    @luna.h("style", [], [@luna.text(select_styles())]),
    @luna.h(
      "div",
      [("class", @luna.attr_static("select-wrapper"))],
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
  @luna.h("radix-select", host_attrs, [
    @luna.h(
      "template",
      [("shadowrootmode", @luna.attr_static("open"))],
      template_children,
    ),
  ])
}
