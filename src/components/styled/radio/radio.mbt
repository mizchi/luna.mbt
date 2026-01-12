///|
/// Styled Radio Group Component (APG Pattern)
///
/// Based on APG: https://www.w3.org/WAI/ARIA/apg/patterns/radio/
///
/// Class names:
/// - .radio-group       - Group container
/// - .radio             - Radio item wrapper
/// - .radio__control    - Visual radio circle
/// - .radio__indicator  - Inner circle indicator
/// - .radio__label      - Label text
///
/// States via data attributes:
/// - [data-selected] on .radio when selected
/// - [data-disabled] on .radio when disabled

///|
pub(all) struct RadioSlots {
  group : String
  radio : String
  control : String
  indicator : String
  label : String
}

///|
pub fn radio_slots() -> RadioSlots {
  {
    group: "radio-group",
    radio: "radio",
    control: "radio__control",
    indicator: "radio__indicator",
    label: "radio__label",
  }
}

///|
pub(all) struct RadioItem {
  value : String
  label : String
  disabled : Bool
}

///|
pub fn radio_item(value : String, label : String, disabled~ : Bool = false) -> RadioItem {
  { value, label, disabled }
}

///|
/// Create a styled radio group.
/// Note: 'name' is reserved for future form integration
pub fn radio_group(
  _name : String,
  items : Array[RadioItem],
  selected : @signal.Signal[String],
  aria_label? : String,
  orientation~ : String = "vertical",
  class? : String,
) -> @luna.Node[@js.Any] {
  let slots = radio_slots()
  let group_class = match class {
    Some(c) => slots.group + " " + c
    None => slots.group
  }

  let group_attrs : Array[(String, @luna.Attr[@js.Any])] = [
    ("role", @luna.attr_static("radiogroup")),
    ("class", @luna.attr_static(group_class)),
    ("data-orientation", @luna.attr_static(orientation)),
  ]
  if aria_label is Some(label) {
    group_attrs.push(("aria-label", @luna.attr_static(label)))
  }

  let radios : Array[@luna.Node[@js.Any]] = []
  for item in items {
    let value = item.value
    let is_disabled = item.disabled

    let radio_attrs : Array[(String, @luna.Attr[@js.Any])] = [
      ("class", @luna.attr_static(slots.radio)),
      ("role", @luna.attr_static("radio")),
      ("tabindex", @luna.attr_dynamic(fn() { if selected.get() == value { "0" } else { "-1" } })),
      ("aria-checked", @luna.attr_dynamic(fn() { if selected.get() == value { "true" } else { "false" } })),
      ("data-value", @luna.attr_static(value)),
    ]

    // Data attributes for styling
    radio_attrs.push(("data-selected", @luna.attr_dynamic(fn() { if selected.get() == value { "" } else { "false" } })))

    if is_disabled {
      radio_attrs.push(("data-disabled", @luna.attr_static("")))
      radio_attrs.push(("aria-disabled", @luna.attr_static("true")))
    } else {
      // Click handler
      radio_attrs.push(("click", @luna.attr_handler(@luna.handler(fn(_) {
        selected.set(value)
      }))))
      // Keyboard handler
      radio_attrs.push(("keydown", @luna.attr_handler(@luna.handler(fn(evt) {
        let key = evt._get("key").to_string()
        if key == " " || key == "Enter" {
          let _ = evt._call("preventDefault", [])
          selected.set(value)
        }
      }))))
    }

    let radio_node = @luna.h(
      "div",
      radio_attrs,
      [
        // Control circle
        @luna.h(
          "span",
          [("class", @luna.attr_static(slots.control))],
          [
            @luna.h(
              "span",
              [("class", @luna.attr_static(slots.indicator))],
              [],
            ),
          ],
        ),
        // Label
        @luna.h(
          "span",
          [("class", @luna.attr_static(slots.label))],
          [@luna.text(item.label)],
        ),
      ],
    )
    radios.push(radio_node)
  }

  @luna.h("div", group_attrs, radios)
}

///|
/// Get the CSS for the radio group component.
pub fn radio_css() -> String {
  let css =
    #|/* Radio Group - APG Pattern */
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
    #|/* Radio Item */
    #|.radio {
    #|  position: relative;
    #|  display: inline-flex;
    #|  align-items: center;
    #|  gap: 0.5rem;
    #|  cursor: pointer;
    #|  user-select: none;
    #|  outline: none;
    #|}
    #|
    #|/* Radio Control (Circle) */
    #|.radio__control {
    #|  position: relative;
    #|  display: inline-flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  width: 1.25rem;
    #|  height: 1.25rem;
    #|  border-radius: 50%;
    #|  background: var(--background);
    #|  border: 2px solid var(--border);
    #|  transition: background-color 0.15s, border-color 0.15s;
    #|  flex-shrink: 0;
    #|}
    #|
    #|/* Radio Indicator (Inner Circle) */
    #|.radio__indicator {
    #|  width: 0.5rem;
    #|  height: 0.5rem;
    #|  border-radius: 50%;
    #|  background: var(--background);
    #|  transform: scale(0);
    #|  transition: transform 0.15s;
    #|}
    #|
    #|/* Focus state */
    #|.radio:focus-visible .radio__control {
    #|  outline: 2px solid var(--accent);
    #|  outline-offset: 2px;
    #|}
    #|
    #|/* Hover state */
    #|.radio:not([data-disabled]):hover .radio__control {
    #|  border-color: var(--foreground);
    #|}
    #|
    #|/* Selected state */
    #|.radio[data-selected]:not([data-selected="false"]) .radio__control {
    #|  background: var(--accent);
    #|  border-color: var(--accent);
    #|}
    #|
    #|.radio[data-selected]:not([data-selected="false"]) .radio__indicator {
    #|  transform: scale(1);
    #|}
    #|
    #|/* Disabled state */
    #|.radio[data-disabled] {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
    #|
    #|.radio[data-disabled] .radio__control {
    #|  cursor: not-allowed;
    #|}
    #|
    #|/* Radio Label */
    #|.radio__label {
    #|  font-size: 0.875rem;
    #|  line-height: 1.25rem;
    #|  color: var(--foreground);
    #|}
    #|
    #|/* Reduced motion */
    #|@media (prefers-reduced-motion: reduce) {
    #|  .radio__control,
    #|  .radio__indicator {
    #|    transition: none;
    #|  }
    #|}
  css
}
