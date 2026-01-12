///|
/// Styled Checkbox Component (APG Pattern)
///
/// Uses native checkbox input with custom styling.
/// Based on APG: https://www.w3.org/WAI/ARIA/apg/patterns/checkbox/
///
/// Class names:
/// - .checkbox           - Root wrapper
/// - .checkbox__input    - Hidden native input
/// - .checkbox__control  - Visual checkbox box
/// - .checkbox__icon     - Check/indeterminate icon
/// - .checkbox__label    - Label text
///
/// States handled via :checked, :indeterminate, :disabled pseudo-classes

///|
pub(all) struct CheckboxSlots {
  root : String
  input : String
  control : String
  icon : String
  label : String
}

///|
pub fn checkbox_slots() -> CheckboxSlots {
  {
    root: "checkbox",
    input: "checkbox__input",
    control: "checkbox__control",
    icon: "checkbox__icon",
    label: "checkbox__label",
  }
}

///|
/// Checkbox state enum
pub(all) enum CheckboxState {
  Checked
  Unchecked
  Indeterminate
}

///|
/// Create a styled checkbox with signal-based state.
pub fn checkbox(
  checked : @signal.Signal[Bool],
  disabled~ : Bool = false,
  indeterminate~ : Bool = false,
  id? : String,
  name? : String,
  class? : String,
  children : Array[@luna.Node[@js.Any]],
) -> @luna.Node[@js.Any] {
  let slots = checkbox_slots()
  let random = @js.global_this()._get("Math")._call("random", []).to_string()
  let input_id = id.unwrap_or("checkbox-" + random)
  let input_name = name.unwrap_or(input_id)

  let root_class = match class {
    Some(c) => slots.root + " " + c
    None => slots.root
  }

  // Toggle handler
  let toggle = fn() {
    if not(disabled) {
      checked.set(not(checked.get()))
    }
  }

  // Root wrapper with click handler
  let root_attrs : Array[(String, @luna.Attr[@js.Any])] = [
    ("class", @luna.attr_static(root_class)),
    (
      "data-checked",
      @luna.attr_dynamic(fn() { if checked.get() { "true" } else { "false" } }),
    ),
    ("click", @luna.attr_handler(@luna.handler(fn(_) { toggle() }))),
  ]
  if disabled {
    root_attrs.push(("data-disabled", @luna.attr_static("")))
  }
  if indeterminate {
    root_attrs.push(("data-indeterminate", @luna.attr_static("true")))
  }

  // Hidden input (for accessibility, but we control state via data-checked)
  let input_attrs : Array[(String, @luna.Attr[@js.Any])] = [
    ("type", @luna.attr_static("checkbox")),
    ("class", @luna.attr_static(slots.input)),
    ("id", @luna.attr_static(input_id)),
    ("name", @luna.attr_static(input_name)),
    ("aria-checked", @luna.attr_dynamic(fn() { if checked.get() { "true" } else { "false" } })),
  ]
  if disabled {
    input_attrs.push(("disabled", @luna.attr_static("")))
  }
  if indeterminate {
    input_attrs.push(("aria-checked", @luna.attr_static("mixed")))
  }

  // Visual control box
  let control = @luna.h(
    "span",
    [("class", @luna.attr_static(slots.control))],
    [
      // Check icon
      @luna.h(
        "span",
        [("class", @luna.attr_static(slots.icon + " " + slots.icon + "--check"))],
        [
          @luna.h(
            "svg",
            [
              ("width", @luna.attr_static("12")),
              ("height", @luna.attr_static("12")),
              ("viewBox", @luna.attr_static("0 0 12 12")),
              ("fill", @luna.attr_static("none")),
              ("aria-hidden", @luna.attr_static("true")),
            ],
            [
              @luna.h(
                "path",
                [
                  ("d", @luna.attr_static("M10 3L4.5 8.5L2 6")),
                  ("stroke", @luna.attr_static("currentColor")),
                  ("stroke-width", @luna.attr_static("2")),
                  ("stroke-linecap", @luna.attr_static("round")),
                  ("stroke-linejoin", @luna.attr_static("round")),
                ],
                [],
              ),
            ],
          ),
        ],
      ),
      // Indeterminate icon
      @luna.h(
        "span",
        [
          (
            "class",
            @luna.attr_static(slots.icon + " " + slots.icon + "--indeterminate"),
          ),
        ],
        [
          @luna.h(
            "svg",
            [
              ("width", @luna.attr_static("12")),
              ("height", @luna.attr_static("12")),
              ("viewBox", @luna.attr_static("0 0 12 12")),
              ("fill", @luna.attr_static("none")),
              ("aria-hidden", @luna.attr_static("true")),
            ],
            [
              @luna.h(
                "path",
                [
                  ("d", @luna.attr_static("M2 6H10")),
                  ("stroke", @luna.attr_static("currentColor")),
                  ("stroke-width", @luna.attr_static("2")),
                  ("stroke-linecap", @luna.attr_static("round")),
                ],
                [],
              ),
            ],
          ),
        ],
      ),
    ],
  )

  // Label (no 'for' attribute - root click handler handles toggle)
  let label = @luna.h(
    "span",
    [("class", @luna.attr_static(slots.label))],
    children,
  )

  @luna.h(
    "div",
    root_attrs,
    [@luna.h("input", input_attrs, []), control, label],
  )
}

///|
/// Checkbox group container
pub fn checkbox_group(
  aria_label? : String,
  class? : String,
  children : Array[@luna.Node[@js.Any]],
) -> @luna.Node[@js.Any] {
  let attrs : Array[(String, @luna.Attr[@js.Any])] = [
    ("role", @luna.attr_static("group")),
  ]
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  let group_class = match class {
    Some(c) => "checkbox-group " + c
    None => "checkbox-group"
  }
  attrs.push(("class", @luna.attr_static(group_class)))
  @luna.h("div", attrs, children)
}

///|
/// Get the CSS for the checkbox component.
pub fn checkbox_css() -> String {
  let css =
    #|/* Checkbox - APG Pattern */
    #|.checkbox {
    #|  position: relative;
    #|  display: inline-flex;
    #|  align-items: center;
    #|  vertical-align: middle;
    #|  gap: 0.5rem;
    #|}
    #|
    #|/* Hidden native input (visually hidden but focusable) */
    #|.checkbox__input {
    #|  position: absolute;
    #|  width: 1px;
    #|  height: 1px;
    #|  padding: 0;
    #|  margin: -1px;
    #|  overflow: hidden;
    #|  clip: rect(0, 0, 0, 0);
    #|  white-space: nowrap;
    #|  border: 0;
    #|}
    #|
    #|/* Visual checkbox box */
    #|.checkbox__control {
    #|  position: relative;
    #|  display: inline-flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  width: 1.25rem;
    #|  height: 1.25rem;
    #|  border-radius: 0.25rem;
    #|  background: var(--background);
    #|  border: 2px solid var(--border);
    #|  transition: background-color 0.15s, border-color 0.15s;
    #|  flex-shrink: 0;
    #|  cursor: pointer;
    #|}
    #|
    #|/* Focus state */
    #|.checkbox__input:focus-visible + .checkbox__control {
    #|  outline: 2px solid var(--accent);
    #|  outline-offset: 2px;
    #|}
    #|
    #|/* Hover state */
    #|.checkbox:hover .checkbox__control {
    #|  border-color: var(--foreground);
    #|}
    #|
    #|/* Checked state (using data-checked attribute) */
    #|.checkbox[data-checked="true"] .checkbox__control {
    #|  background: var(--accent);
    #|  border-color: var(--accent);
    #|}
    #|
    #|/* Disabled state */
    #|.checkbox[data-disabled] {
    #|  opacity: 0.5;
    #|  pointer-events: none;
    #|}
    #|
    #|.checkbox[data-disabled] .checkbox__control {
    #|  cursor: not-allowed;
    #|}
    #|
    #|/* Icon styles */
    #|.checkbox__icon {
    #|  position: absolute;
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  width: 0.75rem;
    #|  height: 0.75rem;
    #|  color: var(--background);
    #|  opacity: 0;
    #|  transition: opacity 0.15s;
    #|}
    #|
    #|.checkbox__icon svg {
    #|  width: 100%;
    #|  height: 100%;
    #|}
    #|
    #|/* Show check icon when checked */
    #|.checkbox[data-checked="true"] .checkbox__icon--check {
    #|  opacity: 1;
    #|}
    #|
    #|/* Indeterminate state */
    #|.checkbox[data-indeterminate="true"] .checkbox__control {
    #|  background: var(--accent);
    #|  border-color: var(--accent);
    #|}
    #|
    #|.checkbox[data-indeterminate="true"] .checkbox__icon--indeterminate {
    #|  opacity: 1;
    #|}
    #|
    #|.checkbox[data-indeterminate="true"] .checkbox__icon--check {
    #|  opacity: 0;
    #|}
    #|
    #|/* Label */
    #|.checkbox__label {
    #|  font-size: 0.875rem;
    #|  line-height: 1.25rem;
    #|  color: var(--foreground);
    #|  cursor: pointer;
    #|}
    #|
    #|.checkbox__input:disabled ~ .checkbox__label {
    #|  cursor: not-allowed;
    #|}
    #|
    #|/* Checkbox group */
    #|.checkbox-group {
    #|  display: flex;
    #|  flex-direction: column;
    #|  gap: 0.5rem;
    #|}
    #|
    #|/* Reduced motion */
    #|@media (prefers-reduced-motion: reduce) {
    #|  .checkbox__control,
    #|  .checkbox__icon {
    #|    transition: none;
    #|  }
    #|}
  css
}
