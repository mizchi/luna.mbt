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
pub fn radio_item(
  value : String,
  label : String,
  disabled? : Bool = false,
) -> RadioItem {
  { value, label, disabled }
}

// Convert RadioItem to headless RadioItemData

///|
fn to_headless_items(
  items : Array[RadioItem],
) -> Array[@headless.RadioItemData] {
  let result : Array[@headless.RadioItemData] = []
  for item in items {
    result.push(@headless.radio_item_data(item.value, disabled=item.disabled))
  }
  result
}

///|
/// Create a styled radio group with full APG keyboard support.
///
/// Keyboard:
/// - ArrowDown/ArrowRight: Move to next and select (wraps)
/// - ArrowUp/ArrowLeft: Move to previous and select (wraps)
/// - Home: Move to first and select
/// - End: Move to last and select
/// - Space: Select focused radio
///
/// Note: 'name' is reserved for future form integration
pub fn radio_group(
  name : String,
  items : Array[RadioItem],
  selected : @resource.Signal[String],
  aria_label? : String,
  orientation? : String = "vertical",
  class? : String,
) -> @luna.Node[@js.Any] {
  let slots = radio_slots()
  let group_class = match class {
    Some(c) => slots.group + " " + c
    None => slots.group
  }

  // Convert to headless items and generate IDs
  let headless_items = to_headless_items(items)
  let radio_ids = @headless.generate_radio_ids(name, items.length())

  // Build group attrs with headless attrs
  let group_attrs : Array[(String, @luna.Attr[@js.Any])] = [
    ("role", @luna.attr_static("radiogroup")),
    ("class", @luna.attr_static(group_class)),
    ("data-orientation", @luna.attr_static(orientation)),
  ]
  if aria_label is Some(label) {
    group_attrs.push(("aria-label", @luna.attr_static(label)))
  }
  let radios : Array[@luna.Node[@js.Any]] = []
  for i, item in items {
    let value = item.value
    let radio_id = radio_ids[i]

    // Get headless props
    let props = @headless.use_radio(
      radio_id,
      value,
      item.disabled,
      headless_items,
      radio_ids,
      i,
      selected,
    )

    // Build radio attrs from headless props + styling
    let radio_attrs : Array[(String, @luna.Attr[@js.Any])] = [
      ("class", @luna.attr_static(slots.radio)),
    ]
    for attr in props.attrs {
      radio_attrs.push(attr)
    }

    // Data attributes for styling
    radio_attrs.push(
      (
        "data-selected",
        @luna.attr_dynamic(fn() {
          if selected.get() == value {
            ""
          } else {
            "false"
          }
        }),
      ),
    )
    if props.is_disabled {
      radio_attrs.push(("data-disabled", @luna.attr_static("")))
    }
    let radio_node = @luna.h("div", radio_attrs, [
      // Control circle
      @luna.h("span", [("class", @luna.attr_static(slots.control))], [
        @luna.h("span", [("class", @luna.attr_static(slots.indicator))], []),
      ]),
      // Label
      @luna.h("span", [("class", @luna.attr_static(slots.label))], [
        @luna.text(item.label),
      ]),
    ])
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
    #|  background: white;
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
