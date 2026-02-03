///|
/// Headless Radio Group Component
///
/// Provides accessibility (ARIA) and keyboard navigation without styling.
///
/// APG Reference: https://www.w3.org/WAI/ARIA/apg/patterns/radio/
///
/// Keyboard:
/// - ArrowDown/ArrowRight: Move to next and select (wraps)
/// - ArrowUp/ArrowLeft: Move to previous and select (wraps)
/// - Home: Move to first and select
/// - End: Move to last and select
/// - Space: Select focused radio

///|
/// Radio item data for headless component.
pub(all) struct RadioItemData {
  value : String
  disabled : Bool
}

///|
pub fn radio_item_data(
  value : String,
  disabled? : Bool = false,
) -> RadioItemData {
  { value, disabled }
}

// Helper: Focus a radio element by ID

///|
fn focus_radio_element(radio_id : String) -> Unit {
  let doc = @js.global_this()._get("document")
  let el = doc._call("getElementById", [@js.any(radio_id)])
  let _ = el._call("focus", [])

}

// Helper: Find next enabled index (wrapping)

///|
fn find_next_enabled(items : Array[RadioItemData], current : Int) -> Int {
  let count = items.length()
  if count == 0 {
    return current
  }
  let mut idx = (current + 1) % count
  let mut iterations = 0
  while iterations < count {
    if not(items[idx].disabled) {
      return idx
    }
    idx = (idx + 1) % count
    iterations = iterations + 1
  }
  current
}

// Helper: Find previous enabled index (wrapping)

///|
fn find_prev_enabled(items : Array[RadioItemData], current : Int) -> Int {
  let count = items.length()
  if count == 0 {
    return current
  }
  let mut idx = if current == 0 { count - 1 } else { current - 1 }
  let mut iterations = 0
  while iterations < count {
    if not(items[idx].disabled) {
      return idx
    }
    idx = if idx == 0 { count - 1 } else { idx - 1 }
    iterations = iterations + 1
  }
  current
}

// Helper: Find first enabled index

///|
fn find_first_enabled(items : Array[RadioItemData]) -> Int {
  for i, item in items {
    if not(item.disabled) {
      return i
    }
  }
  0
}

// Helper: Find last enabled index

///|
fn find_last_enabled(items : Array[RadioItemData]) -> Int {
  let mut last = items.length() - 1
  while last >= 0 {
    if not(items[last].disabled) {
      return last
    }
    last = last - 1
  }
  items.length() - 1
}

///|
/// Create a keyboard handler for radio group navigation.
pub fn make_radio_keydown_handler(
  items : Array[RadioItemData],
  radio_ids : Array[String],
  current_index : Int,
  selected : @resource.Signal[String],
) -> @luna.EventHandler[@js.Any] {
  @luna.handler(fn(evt) {
    let key = evt._get("key").to_string()
    match key {
      " " | "Enter" => {
        let _ = evt._call("preventDefault", [])
        selected.set(items[current_index].value)
      }
      "ArrowDown" | "ArrowRight" => {
        let _ = evt._call("preventDefault", [])
        let next_idx = find_next_enabled(items, current_index)
        selected.set(items[next_idx].value)
        focus_radio_element(radio_ids[next_idx])
      }
      "ArrowUp" | "ArrowLeft" => {
        let _ = evt._call("preventDefault", [])
        let prev_idx = find_prev_enabled(items, current_index)
        selected.set(items[prev_idx].value)
        focus_radio_element(radio_ids[prev_idx])
      }
      "Home" => {
        let _ = evt._call("preventDefault", [])
        let first_idx = find_first_enabled(items)
        selected.set(items[first_idx].value)
        focus_radio_element(radio_ids[first_idx])
      }
      "End" => {
        let _ = evt._call("preventDefault", [])
        let last_idx = find_last_enabled(items)
        selected.set(items[last_idx].value)
        focus_radio_element(radio_ids[last_idx])
      }
      _ => ()
    }
  })
}

///|
/// Get ARIA attributes for radio group container.
pub fn radio_group_attrs(
  aria_label? : String,
  orientation? : String = "vertical",
) -> Array[(String, String)] {
  let attrs : Array[(String, String)] = [
    ("role", "radiogroup"),
    ("data-orientation", orientation),
  ]
  if aria_label is Some(label) {
    attrs.push(("aria-label", label))
  }
  attrs
}

///|
/// Props for a single radio item.
pub(all) struct RadioProps {
  attrs : Array[(String, @luna.Attr[@js.Any, String])]
  is_selected : Bool
  is_disabled : Bool
}

///|
/// Create props for a single radio item with keyboard navigation.
pub fn use_radio(
  radio_id : String,
  value : String,
  is_disabled : Bool,
  items : Array[RadioItemData],
  radio_ids : Array[String],
  index : Int,
  selected : @resource.Signal[String],
) -> RadioProps {
  let is_selected = selected.get() == value
  let attrs : Array[(String, @luna.Attr[@js.Any, String])] = [
    ("id", @luna.attr_static(radio_id)),
    ("role", @luna.attr_static("radio")),
    (
      "tabindex",
      @luna.attr_dynamic(fn() {
        if selected.get() == value {
          "0"
        } else {
          "-1"
        }
      }),
    ),
    (
      "aria-checked",
      @luna.attr_dynamic(fn() {
        if selected.get() == value {
          "true"
        } else {
          "false"
        }
      }),
    ),
    ("data-value", @luna.attr_static(value)),
  ]
  if is_disabled {
    attrs.push(("aria-disabled", @luna.attr_static("true")))
  } else {
    // Click handler
    attrs.push(
      (
        "click",
        @luna.attr_handler(@luna.handler(fn(_) { selected.set(value) })),
      ),
    )
    // Keyboard handler
    attrs.push(
      (
        "keydown",
        @luna.attr_handler(
          make_radio_keydown_handler(items, radio_ids, index, selected),
        ),
      ),
    )
  }
  { attrs, is_selected, is_disabled }
}

///|
/// Generate radio IDs for a group.
pub fn generate_radio_ids(name : String, count : Int) -> Array[String] {
  let ids : Array[String] = []
  for i in 0..<count {
    ids.push("radio-" + name + "-" + i.to_string())
  }
  ids
}
