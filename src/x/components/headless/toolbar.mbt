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

///|
/// Generate toolbar item IDs.
pub fn generate_toolbar_item_ids(
  prefix : String,
  item_ids : Array[String],
) -> Array[String] {
  let result : Array[String] = []
  for item_id in item_ids {
    result.push(prefix + "-" + item_id)
  }
  result
}

///|
/// Props for toolbar item with keyboard navigation.
pub(all) struct ToolbarItemNavProps {
  attrs : Array[(String, @luna.Attr[@js.Any, String])]
  is_pressed : Bool
  is_disabled : Bool
}

///|
/// Create toolbar item props with keyboard navigation.
pub fn use_toolbar_item_nav(
  button_id : String,
  item_id : String,
  all_item_ids : Array[String],
  index : Int,
  is_pressed : Bool,
  is_disabled : Bool,
  on_click : (String) -> Unit,
) -> ToolbarItemNavProps {
  let attrs : Array[(String, @luna.Attr[@js.Any, String])] = [
    ("type", @luna.attr_static("button")),
    ("id", @luna.attr_static(button_id)),
    (
      "aria-pressed",
      @luna.attr_static(if is_pressed { "true" } else { "false" }),
    ),
  ]
  if is_disabled {
    attrs.push(("aria-disabled", @luna.attr_static("true")))
    attrs.push(("disabled", @luna.attr_static("")))
    attrs.push(("tabindex", @luna.attr_static("-1")))
  } else {
    // Roving tabindex: first item gets 0, others get -1
    if index == 0 {
      attrs.push(("tabindex", @luna.attr_static("0")))
    } else {
      attrs.push(("tabindex", @luna.attr_static("-1")))
    }
    attrs.push(
      ("click", @luna.attr_handler(@luna.handler(fn(_) { on_click(item_id) }))),
    )
    attrs.push(
      (
        "keydown",
        @luna.attr_handler(make_toolbar_keydown_handler(all_item_ids, index)),
      ),
    )
  }
  { attrs, is_pressed, is_disabled }
}

///|
/// Props for reactive toolbar item with dynamic pressed state.
pub(all) struct ToolbarItemReactiveProps {
  attrs : Array[(String, @luna.Attr[@js.Any, String])]
}

///|
/// Create reactive toolbar item props.
pub fn use_toolbar_item_reactive(
  button_id : String,
  item_id : String,
  all_item_ids : Array[String],
  index : Int,
  pressed_states : @resource.Signal[Map[String, Bool]],
  is_disabled : Bool,
  on_click : (String) -> Unit,
) -> ToolbarItemReactiveProps {
  let attrs : Array[(String, @luna.Attr[@js.Any, String])] = [
    ("type", @luna.attr_static("button")),
    ("id", @luna.attr_static(button_id)),
    (
      "aria-pressed",
      @luna.attr_dynamic(fn() {
        if pressed_states.get().get(item_id).unwrap_or(false) {
          "true"
        } else {
          "false"
        }
      }),
    ),
  ]
  if is_disabled {
    attrs.push(("aria-disabled", @luna.attr_static("true")))
    attrs.push(("disabled", @luna.attr_static("")))
    attrs.push(("tabindex", @luna.attr_static("-1")))
  } else {
    // Roving tabindex: first item gets 0, others get -1
    if index == 0 {
      attrs.push(("tabindex", @luna.attr_static("0")))
    } else {
      attrs.push(("tabindex", @luna.attr_static("-1")))
    }
    attrs.push(
      ("click", @luna.attr_handler(@luna.handler(fn(_) { on_click(item_id) }))),
    )
    attrs.push(
      (
        "keydown",
        @luna.attr_handler(make_toolbar_keydown_handler(all_item_ids, index)),
      ),
    )
  }
  { attrs, }
}
