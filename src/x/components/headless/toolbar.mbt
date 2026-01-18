///|
/// Headless Toolbar Component
///
/// Provides accessibility (ARIA) and keyboard navigation without styling.
///
/// APG Reference: https://www.w3.org/WAI/ARIA/apg/patterns/toolbar/
///
/// Keyboard:
/// - ArrowRight: Move focus to next item
/// - ArrowLeft: Move focus to previous item
/// - Home: Move focus to first item
/// - End: Move focus to last item

// Helper: Focus a toolbar item by ID
fn focus_toolbar_item(item_id : String) -> Unit {
  let doc = @js.global_this()._get("document")
  let el = doc._call("getElementById", [@js.any(item_id)])
  let _ = el._call("focus", [])
}

///|
/// Create a keyboard handler for toolbar navigation.
///
/// Parameters:
/// - item_ids: Array of item IDs in order
/// - current_index: Index of the current item
pub fn make_toolbar_keydown_handler(
  item_ids : Array[String],
  current_index : Int,
) -> @luna.EventHandler[@js.Any] {
  let count = item_ids.length()
  @luna.handler(fn(evt) {
    let key = evt._get("key").to_string()
    match key {
      "ArrowRight" => {
        let _ = evt._call("preventDefault", [])
        // Move to next item (no wrap)
        if current_index < count - 1 {
          focus_toolbar_item(item_ids[current_index + 1])
        }
      }
      "ArrowLeft" => {
        let _ = evt._call("preventDefault", [])
        // Move to previous item (no wrap)
        if current_index > 0 {
          focus_toolbar_item(item_ids[current_index - 1])
        }
      }
      "Home" => {
        let _ = evt._call("preventDefault", [])
        focus_toolbar_item(item_ids[0])
      }
      "End" => {
        let _ = evt._call("preventDefault", [])
        focus_toolbar_item(item_ids[count - 1])
      }
      _ => ()
    }
  })
}

///|
/// Get ARIA attributes for a toolbar container.
pub fn toolbar_attrs(
  aria_label : String,
  orientation? : String = "horizontal",
) -> Array[(String, String)] {
  [
    ("role", "toolbar"),
    ("aria-label", aria_label),
    ("aria-orientation", orientation),
  ]
}

///|
/// Get ARIA attributes for a toolbar item (button).
///
/// Parameters:
/// - is_pressed: Whether the button is in pressed state
/// - is_disabled: Whether the button is disabled
/// - is_first_focusable: Whether this is the first focusable item (gets tabindex=0)
pub fn toolbar_item_attrs(
  is_pressed : Bool,
  is_disabled : Bool,
  is_first_focusable : Bool,
) -> Array[(String, String)] {
  let attrs : Array[(String, String)] = [("type", "button")]

  // Only the first focusable item should have tabindex=0
  // Others have tabindex=-1 (roving tabindex pattern)
  if is_first_focusable {
    attrs.push(("tabindex", "0"))
  } else {
    attrs.push(("tabindex", "-1"))
  }

  if is_pressed {
    attrs.push(("aria-pressed", "true"))
  } else {
    attrs.push(("aria-pressed", "false"))
  }

  if is_disabled {
    attrs.push(("aria-disabled", "true"))
    attrs.push(("disabled", ""))
  }

  attrs
}
