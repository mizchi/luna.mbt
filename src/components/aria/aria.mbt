///|
/// ARIA Attribute Helpers
///
/// Pure ARIA attributes as key-value pairs.
/// No DOM dependencies - usable with any UI framework (Web, TUI, etc.)
///
/// APG Reference: https://www.w3.org/WAI/ARIA/apg/

// =============================================================================
// Switch
// =============================================================================

///|
/// Switch ARIA attributes
///
/// Returns attributes for an accessible switch/toggle element.
///
/// Example:
/// ```moonbit
/// let attrs = switch_aria(true, false)
/// // [("role", "switch"), ("aria-checked", "true"), ("tabindex", "0")]
/// ```
pub fn switch_aria(on : Bool, disabled : Bool) -> Array[(String, String)] {
  let attrs = [
    ("role", "switch"),
    ("aria-checked", if on { "true" } else { "false" }),
    ("tabindex", if disabled { "-1" } else { "0" }),
  ]
  if disabled {
    attrs.push(("aria-disabled", "true"))
  }
  attrs
}

///|
/// Switch ARIA attributes with optional label
pub fn switch_aria_labelled(
  on : Bool,
  disabled : Bool,
  aria_label? : String,
  aria_labelledby? : String,
) -> Array[(String, String)] {
  let attrs = switch_aria(on, disabled)
  if aria_label is Some(label) {
    attrs.push(("aria-label", label))
  }
  if aria_labelledby is Some(id) {
    attrs.push(("aria-labelledby", id))
  }
  attrs
}

// =============================================================================
// Checkbox
// =============================================================================

///|
/// Checkbox ARIA attributes
pub fn checkbox_aria(
  checked : Bool,
  disabled : Bool,
  indeterminate : Bool,
) -> Array[(String, String)] {
  let attrs : Array[(String, String)] = [
    ("role", "checkbox"),
    (
      "aria-checked",
      if indeterminate {
        "mixed"
      } else if checked {
        "true"
      } else {
        "false"
      },
    ),
    ("tabindex", if disabled { "-1" } else { "0" }),
  ]
  if disabled {
    attrs.push(("aria-disabled", "true"))
  }
  attrs
}

// =============================================================================
// Radio
// =============================================================================

///|
/// Radio button ARIA attributes
pub fn radio_aria(checked : Bool, disabled : Bool) -> Array[(String, String)] {
  let attrs : Array[(String, String)] = [
    ("role", "radio"),
    ("aria-checked", if checked { "true" } else { "false" }),
    ("tabindex", if checked { "0" } else { "-1" }),
  ]
  if disabled {
    attrs.push(("aria-disabled", "true"))
  }
  attrs
}

///|
/// Radio group ARIA attributes
pub fn radiogroup_aria(
  aria_label? : String,
  aria_labelledby? : String,
) -> Array[(String, String)] {
  let attrs : Array[(String, String)] = [("role", "radiogroup")]
  if aria_label is Some(label) {
    attrs.push(("aria-label", label))
  }
  if aria_labelledby is Some(id) {
    attrs.push(("aria-labelledby", id))
  }
  attrs
}

// =============================================================================
// Accordion / Disclosure
// =============================================================================

///|
/// Accordion header ARIA attributes
pub fn accordion_header_aria(
  id : String,
  expanded : Bool,
  controls : String,
) -> Array[(String, String)] {
  [
    ("type", "button"),
    ("id", id),
    ("aria-expanded", if expanded { "true" } else { "false" }),
    ("aria-controls", controls),
  ]
}

///|
/// Accordion panel ARIA attributes
pub fn accordion_panel_aria(
  id : String,
  labelledby : String,
  hidden : Bool,
  use_region : Bool,
) -> Array[(String, String)] {
  let attrs : Array[(String, String)] = [
    ("id", id),
    ("aria-labelledby", labelledby),
  ]
  if use_region {
    attrs.push(("role", "region"))
  }
  if hidden {
    attrs.push(("hidden", ""))
  }
  attrs
}

///|
/// Disclosure button ARIA attributes
pub fn disclosure_button_aria(
  expanded : Bool,
  controls : String,
) -> Array[(String, String)] {
  [
    ("type", "button"),
    ("aria-expanded", if expanded { "true" } else { "false" }),
    ("aria-controls", controls),
  ]
}

///|
/// Disclosure content ARIA attributes
pub fn disclosure_content_aria(id : String) -> Array[(String, String)] {
  [("id", id)]
}

// =============================================================================
// Tabs
// =============================================================================

///|
/// Tab ARIA attributes
pub fn tab_aria(
  id : String,
  selected : Bool,
  controls : String,
) -> Array[(String, String)] {
  [
    ("role", "tab"),
    ("id", id),
    ("aria-selected", if selected { "true" } else { "false" }),
    ("aria-controls", controls),
    ("tabindex", if selected { "0" } else { "-1" }),
  ]
}

///|
/// Tablist ARIA attributes
pub fn tablist_aria(aria_label? : String) -> Array[(String, String)] {
  let attrs : Array[(String, String)] = [("role", "tablist")]
  if aria_label is Some(label) {
    attrs.push(("aria-label", label))
  }
  attrs
}

///|
/// Tabpanel ARIA attributes
pub fn tabpanel_aria(
  id : String,
  labelledby : String,
) -> Array[(String, String)] {
  [
    ("role", "tabpanel"),
    ("id", id),
    ("aria-labelledby", labelledby),
    ("tabindex", "0"),
  ]
}

// =============================================================================
// Dialog
// =============================================================================

///|
/// Dialog ARIA attributes
pub fn dialog_aria(
  id : String,
  aria_label? : String,
  aria_labelledby? : String,
  aria_describedby? : String,
  modal : Bool,
) -> Array[(String, String)] {
  let attrs : Array[(String, String)] = [("role", "dialog"), ("id", id)]
  if modal {
    attrs.push(("aria-modal", "true"))
  }
  if aria_label is Some(label) {
    attrs.push(("aria-label", label))
  }
  if aria_labelledby is Some(id) {
    attrs.push(("aria-labelledby", id))
  }
  if aria_describedby is Some(id) {
    attrs.push(("aria-describedby", id))
  }
  attrs
}

// =============================================================================
// Tooltip
// =============================================================================

///|
/// Tooltip ARIA attributes (for the trigger element)
pub fn tooltip_trigger_aria(describedby : String) -> Array[(String, String)] {
  [("aria-describedby", describedby)]
}

///|
/// Tooltip content ARIA attributes
pub fn tooltip_aria(id : String) -> Array[(String, String)] {
  [("role", "tooltip"), ("id", id)]
}

// =============================================================================
// Alert
// =============================================================================

///|
/// Alert ARIA attributes
pub fn alert_aria(assertive : Bool) -> Array[(String, String)] {
  [
    ("role", "alert"),
    ("aria-live", if assertive { "assertive" } else { "polite" }),
  ]
}

// =============================================================================
// Meter / Progress
// =============================================================================

///|
/// Meter ARIA attributes
pub fn meter_aria(
  value : Double,
  min : Double,
  max : Double,
  aria_label? : String,
) -> Array[(String, String)] {
  let attrs : Array[(String, String)] = [
    ("role", "meter"),
    ("aria-valuenow", value.to_string()),
    ("aria-valuemin", min.to_string()),
    ("aria-valuemax", max.to_string()),
  ]
  if aria_label is Some(label) {
    attrs.push(("aria-label", label))
  }
  attrs
}

// =============================================================================
// Slider
// =============================================================================

///|
/// Slider ARIA attributes
pub fn slider_aria(
  value : Double,
  min : Double,
  max : Double,
  disabled : Bool,
  aria_label? : String,
) -> Array[(String, String)] {
  let attrs : Array[(String, String)] = [
    ("role", "slider"),
    ("aria-valuenow", value.to_string()),
    ("aria-valuemin", min.to_string()),
    ("aria-valuemax", max.to_string()),
    ("tabindex", if disabled { "-1" } else { "0" }),
  ]
  if disabled {
    attrs.push(("aria-disabled", "true"))
  }
  if aria_label is Some(label) {
    attrs.push(("aria-label", label))
  }
  attrs
}

// =============================================================================
// Listbox
// =============================================================================

///|
/// Listbox ARIA attributes
pub fn listbox_aria(
  aria_label? : String,
  multiselectable : Bool,
) -> Array[(String, String)] {
  let attrs : Array[(String, String)] = [("role", "listbox"), ("tabindex", "0")]
  if multiselectable {
    attrs.push(("aria-multiselectable", "true"))
  }
  if aria_label is Some(label) {
    attrs.push(("aria-label", label))
  }
  attrs
}

///|
/// Listbox option ARIA attributes
pub fn option_aria(
  id : String,
  selected : Bool,
  disabled : Bool,
) -> Array[(String, String)] {
  let attrs : Array[(String, String)] = [
    ("role", "option"),
    ("id", id),
    ("aria-selected", if selected { "true" } else { "false" }),
  ]
  if disabled {
    attrs.push(("aria-disabled", "true"))
  }
  attrs
}

// =============================================================================
// Spinbutton
// =============================================================================

///|
/// Spinbutton ARIA attributes
pub fn spinbutton_aria(
  value : Int,
  min : Int,
  max : Int,
  disabled : Bool,
  aria_label? : String,
) -> Array[(String, String)] {
  let attrs : Array[(String, String)] = [
    ("role", "spinbutton"),
    ("aria-valuenow", value.to_string()),
    ("aria-valuemin", min.to_string()),
    ("aria-valuemax", max.to_string()),
    ("tabindex", if disabled { "-1" } else { "0" }),
  ]
  if disabled {
    attrs.push(("aria-disabled", "true"))
  }
  if aria_label is Some(label) {
    attrs.push(("aria-label", label))
  }
  attrs
}

// =============================================================================
// Utilities
// =============================================================================

///|
/// Boolean to ARIA string conversion
pub fn bool_to_aria(value : Bool) -> String {
  if value { "true" } else { "false" }
}

///|
/// Check if a key is a toggle key (Space or Enter)
pub fn is_toggle_key(key : String) -> Bool {
  key == " " || key == "Enter"
}

///|
/// Check if a key is an arrow key
pub fn is_arrow_key(key : String) -> Bool {
  key == "ArrowUp" || key == "ArrowDown" || key == "ArrowLeft" || key == "ArrowRight"
}

///|
/// Check if a key is Home or End
pub fn is_home_end_key(key : String) -> Bool {
  key == "Home" || key == "End"
}
