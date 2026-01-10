///|
/// Radix-style Checkbox component for Luna (Headless)
/// Outputs semantic HTML with data-* attributes for external CSS styling

///|
/// Checkbox state
pub(all) enum CheckboxState {
  Checked
  Unchecked
  Indeterminate
}

///|
pub fn CheckboxState::to_string(self : CheckboxState) -> String {
  match self {
    Checked => "checked"
    Unchecked => "unchecked"
    Indeterminate => "indeterminate"
  }
}

///|
/// Create a headless checkbox element
/// Outputs: <button class="radix-checkbox" role="checkbox" data-state="..." aria-checked="...">children</button>
/// Style with external CSS using [data-state="..."] selectors
pub fn radix_checkbox(
  checked? : CheckboxState,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let state = match checked {
    Some(s) => s
    None => Unchecked
  }
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-checkbox")),
    ("role", @luna.attr_static("checkbox")),
    ("data-state", @luna.attr_static(state.to_string())),
  ]

  // Add aria-checked based on state
  let aria_checked = match state {
    Checked => "true"
    Unchecked => "false"
    Indeterminate => "mixed"
  }
  attrs.push(("aria-checked", @luna.attr_static(aria_checked)))
  match disabled {
    Some(true) => {
      attrs.push(("data-disabled", @luna.attr_static("")))
      attrs.push(("disabled", @luna.attr_static("")))
      attrs.push(("aria-disabled", @luna.attr_static("true")))
    }
    _ => ()
  }
  @luna.h("button", attrs, children)
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the Radix checkbox component
fn checkbox_styles() -> String {
  let css =
    #|:host {
    #|  display: inline-flex;
    #|  align-items: center;
    #|}
    #|
    #|.checkbox-root {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  width: 1rem;
    #|  height: 1rem;
    #|  border: 1px solid #18181b;
    #|  border-radius: 2px;
    #|  background: transparent;
    #|  cursor: pointer;
    #|  transition: all 0.15s ease;
    #|  flex-shrink: 0;
    #|}
    #|
    #|/* Checked state */
    #|.checkbox-root[data-state="checked"] {
    #|  background: #18181b;
    #|  border-color: #18181b;
    #|}
    #|
    #|/* Indeterminate state */
    #|.checkbox-root[data-state="indeterminate"] {
    #|  background: #18181b;
    #|  border-color: #18181b;
    #|}
    #|
    #|/* Disabled state */
    #|.checkbox-root[data-disabled] {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
    #|
    #|/* Focus ring */
    #|.checkbox-root:focus-visible {
    #|  outline: 2px solid #2563eb;
    #|  outline-offset: 2px;
    #|}
    #|
    #|/* Indicator (checkmark) */
    #|.checkbox-indicator {
    #|  display: none;
    #|  color: white;
    #|}
    #|
    #|.checkbox-root[data-state="checked"] .checkbox-indicator,
    #|.checkbox-root[data-state="indeterminate"] .checkbox-indicator {
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|}
    #|
    #|/* Checkmark icon */
    #|.checkbox-indicator svg {
    #|  width: 0.75rem;
    #|  height: 0.75rem;
    #|}
    #|
    #|/* Label wrapper */
    #|.checkbox-wrapper {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  gap: 0.5rem;
    #|}
    #|
    #|.checkbox-label {
    #|  font-size: 0.875rem;
    #|  color: #18181b;
    #|  user-select: none;
    #|}
    #|
    #|.checkbox-wrapper:has(.checkbox-root[data-disabled]) .checkbox-label {
    #|  opacity: 0.5;
    #|}
  css
}

///|
/// Create a styled checkbox with Declarative Shadow DOM
/// Uses inline CSS for zero CLS (Cumulative Layout Shift)
pub fn radix_checkbox_styled(
  checked? : CheckboxState,
  disabled? : Bool,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let state = match checked {
    Some(s) => s
    None => Unchecked
  }
  let css = match styles {
    Some(s) => s
    None => checkbox_styles()
  }

  // Build checkbox button attributes
  let checkbox_attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("checkbox-root")),
    ("role", @luna.attr_static("checkbox")),
    ("data-state", @luna.attr_static(state.to_string())),
  ]

  // Add aria-checked based on state
  let aria_checked = match state {
    Checked => "true"
    Unchecked => "false"
    Indeterminate => "mixed"
  }
  checkbox_attrs.push(("aria-checked", @luna.attr_static(aria_checked)))
  match disabled {
    Some(true) => {
      checkbox_attrs.push(("data-disabled", @luna.attr_static("")))
      checkbox_attrs.push(("aria-disabled", @luna.attr_static("true")))
    }
    _ => ()
  }

  // Checkmark SVG icon
  let checkmark_svg = match state {
    Indeterminate =>
      // Minus icon for indeterminate
      "<svg viewBox=\"0 0 12 12\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\"><line x1=\"2\" y1=\"6\" x2=\"10\" y2=\"6\"/></svg>"
    _ =>
      // Check icon
      "<svg viewBox=\"0 0 12 12\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\"><path d=\"M2 6l3 3 5-6\"/></svg>"
  }

  // Build checkbox content
  let checkbox_content : Array[@luna.Node[Unit]] = [
    @luna.h("span", [("class", @luna.attr_static("checkbox-indicator"))], [
      @luna.raw_html(checkmark_svg),
    ]),
  ]

  // Build wrapper with label slot
  let wrapper_children : Array[@luna.Node[Unit]] = [
    @luna.h("button", checkbox_attrs, checkbox_content),
    @luna.h("label", [("class", @luna.attr_static("checkbox-label"))], [
      @luna.h("slot", [], []),
    ]),
  ]

  // Build template content
  let template_children : Array[@luna.Node[Unit]] = [
    @luna.h("style", [], [@luna.text(css)]),
    @luna.h(
      "span",
      [("class", @luna.attr_static("checkbox-wrapper"))],
      wrapper_children,
    ),
  ]

  // Create the DSD structure
  let all_children : Array[@luna.Node[Unit]] = [
    @luna.h(
      "template",
      [("shadowrootmode", @luna.attr_static("open"))],
      template_children,
    ),
  ]

  // Add light DOM children
  for child in children {
    all_children.push(child)
  }

  // Host element with data-state for external styling
  let host_attrs : Array[(String, @luna.Attr[Unit])] = [
    ("data-state", @luna.attr_static(state.to_string())),
  ]
  match disabled {
    Some(true) => host_attrs.push(("data-disabled", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("radix-checkbox", host_attrs, all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a checkbox with luna/css atomic styles
/// Uses CSS utilities for SSR static extraction
pub fn radix_checkbox_ucss(
  checked? : CheckboxState,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let state = match checked {
    Some(s) => s
    None => Unchecked
  }

  // Build class names using luna/css
  let mut class_names = checkbox_root_styles() + " " + checkbox_focus_styles()

  // Add checked styles
  match state {
    Checked | Indeterminate =>
      class_names = class_names + " " + checkbox_checked_styles()
    Unchecked => ()
  }

  // Add disabled styles if needed
  match disabled {
    Some(true) =>
      class_names = class_names +
        " " +
        @css.styles([("opacity", "0.5"), ("cursor", "not-allowed")])
    _ => ()
  }

  // Build attributes
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("role", @luna.attr_static("checkbox")),
    ("data-state", @luna.attr_static(state.to_string())),
  ]

  // Add aria-checked based on state
  let aria_checked = match state {
    Checked => "true"
    Unchecked => "false"
    Indeterminate => "mixed"
  }
  attrs.push(("aria-checked", @luna.attr_static(aria_checked)))
  match disabled {
    Some(true) => {
      attrs.push(("disabled", @luna.attr_static("")))
      attrs.push(("aria-disabled", @luna.attr_static("true")))
    }
    _ => ()
  }
  @luna.h("button", attrs, children)
}
