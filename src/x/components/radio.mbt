///|
/// APG Radio Group Pattern
/// https://www.w3.org/WAI/ARIA/apg/patterns/radio/
///
/// A radio group is a set of checkable buttons where only one can be checked at a time.
///
/// Keyboard Interaction:
/// - Tab/Shift+Tab: Move focus into/out of the group
/// - Space: Check focused radio button
/// - Right/Down Arrow: Move to next radio, check it
/// - Left/Up Arrow: Move to previous radio, check it
///
/// ARIA:
/// - radiogroup: Container role
/// - radio: Each button with aria-checked

///|
/// Radio option data
pub(all) struct RadioOption[E] {
  value : String // Option value
  label : Array[@luna.Node[E, String]] // Label content
  disabled : Bool // Whether disabled
}

///|
/// Create a radio option
pub fn[E] radio_option(
  value : String,
  label : Array[@luna.Node[E, String]],
  disabled? : Bool,
) -> RadioOption[E] {
  { value, label, disabled: disabled.unwrap_or(false) }
}

///|
/// Create a radio group container.
///
/// Parameters:
/// - aria_label: Accessible label for the group
/// - aria_labelledby: ID of labelling element
/// - children: Radio buttons (use `radio()` to create)
pub fn[E] radiogroup(
  aria_label? : String,
  aria_labelledby? : String,
  children : Array[@luna.Node[E, String]],
) -> @luna.Node[E, String] {
  let attrs : Array[(String, @luna.Attr[E, String])] = [
    ("role", @luna.attr_static("radiogroup")),
  ]
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  if aria_labelledby is Some(id) {
    attrs.push(("aria-labelledby", @luna.attr_static(id)))
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a single radio button.
///
/// Parameters:
/// - value: Radio value
/// - checked: Whether this radio is checked
/// - disabled: Whether this radio is disabled
/// - on_click: Click handler
/// - on_keydown: Keydown handler (for arrow key navigation)
/// - children: Radio label content
pub fn[E] radio(
  value : String,
  checked : Bool,
  disabled? : Bool,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E, String]],
) -> @luna.Node[E, String] {
  let attrs : Array[(String, @luna.Attr[E, String])] = [
    ("role", @luna.attr_static("radio")),
    ("aria-checked", @luna.attr_static(if checked { "true" } else { "false" })),
    ("tabindex", @luna.attr_static(if checked { "0" } else { "-1" })),
    ("data-value", @luna.attr_static(value)),
  ]
  if disabled is Some(true) {
    attrs.push(("aria-disabled", @luna.attr_static("true")))
  }
  if on_click is Some(handler) {
    attrs.push(("click", @luna.attr_handler(handler)))
  }
  if on_keydown is Some(handler) {
    attrs.push(("keydown", @luna.attr_handler(handler)))
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a dynamic radio with signal-based checked state.
pub fn[E] radio_dyn(
  value : String,
  selected_value : @resource.Signal[String],
  disabled? : Bool,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E, String]],
) -> @luna.Node[E, String] {
  let attrs : Array[(String, @luna.Attr[E, String])] = [
    ("role", @luna.attr_static("radio")),
    (
      "aria-checked",
      @luna.attr_dynamic(fn() {
        if selected_value.get() == value {
          "true"
        } else {
          "false"
        }
      }),
    ),
    (
      "tabindex",
      @luna.attr_dynamic(fn() {
        if selected_value.get() == value {
          "0"
        } else {
          "-1"
        }
      }),
    ),
    ("data-value", @luna.attr_static(value)),
  ]
  if disabled is Some(true) {
    attrs.push(("aria-disabled", @luna.attr_static("true")))
  }
  if on_click is Some(handler) {
    attrs.push(("click", @luna.attr_handler(handler)))
  }
  if on_keydown is Some(handler) {
    attrs.push(("keydown", @luna.attr_handler(handler)))
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a radio with computed checked state (accepts getter function).
/// Useful for derived radio states.
pub fn[E] radio_computed(
  value : String,
  checked : () -> Bool,
  disabled? : Bool,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E, String]],
) -> @luna.Node[E, String] {
  let attrs : Array[(String, @luna.Attr[E, String])] = [
    ("role", @luna.attr_static("radio")),
    ("aria-checked", @luna.attr_dynamic(fn() { bool_to_aria(checked()) })),
    (
      "tabindex",
      @luna.attr_dynamic(fn() { if checked() { "0" } else { "-1" } }),
    ),
    ("data-value", @luna.attr_static(value)),
  ]
  if disabled is Some(true) {
    attrs.push(("aria-disabled", @luna.attr_static("true")))
  }
  if on_click is Some(handler) {
    attrs.push(("click", @luna.attr_handler(handler)))
  }
  if on_keydown is Some(handler) {
    attrs.push(("keydown", @luna.attr_handler(handler)))
  }
  @luna.h("div", attrs, children)
}

///|
/// Build a complete radio group from options.
///
/// Parameters:
/// - name: Group name (for form submission)
/// - options: Array of RadioOption
/// - selected_value: Currently selected value
/// - aria_label: Accessible label for the group
pub fn[E] radio_group(
  name : String,
  options : Array[RadioOption[E]],
  selected_value : String,
  aria_label? : String,
) -> @luna.Node[E, String] {
  let radios : Array[@luna.Node[E, String]] = []
  for option in options {
    let is_checked = option.value == selected_value
    radios.push(
      radio(option.value, is_checked, disabled=option.disabled, option.label),
    )
  }
  let attrs : Array[(String, @luna.Attr[E, String])] = [
    ("role", @luna.attr_static("radiogroup")),
    ("data-name", @luna.attr_static(name)),
  ]
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  @luna.h("div", attrs, radios)
}

///|
/// Create a native radio input with label.
/// Uses HTML native radio for better form integration.
pub fn[E] radio_native(
  name : String,
  value : String,
  checked : Bool,
  disabled? : Bool,
  id? : String,
  children : Array[@luna.Node[E, String]],
) -> @luna.Node[E, String] {
  let input_id = id.unwrap_or(name + "-" + value)
  let input_attrs : Array[(String, @luna.Attr[E, String])] = [
    ("type", @luna.attr_static("radio")),
    ("name", @luna.attr_static(name)),
    ("value", @luna.attr_static(value)),
    ("id", @luna.attr_static(input_id)),
  ]
  if checked {
    input_attrs.push(("checked", @luna.attr_static("")))
  }
  if disabled is Some(true) {
    input_attrs.push(("disabled", @luna.attr_static("")))
  }
  let label_attrs : Array[(String, @luna.Attr[E, String])] = [
    ("for", @luna.attr_static(input_id)),
  ]
  @luna.fragment([
    @luna.h("input", input_attrs, []),
    @luna.h("label", label_attrs, children),
  ])
}

// =============================================================================
// Keyboard Navigation for Radio Group (APG required)
// =============================================================================

///|
/// Focus a radio element by ID.
fn focus_radio(radio_id : String) -> Unit {
  let doc = @js.global_this()._get("document")
  let el = doc._call("getElementById", [@js.any(radio_id)])
  let _ = el._call("focus", [])
}

///|
/// Find next enabled index (wrapping).
fn find_next_enabled(
  options : Array[RadioOption[@js.Any]],
  current_index : Int,
) -> Int {
  let count = options.length()
  let mut idx = (current_index + 1) % count
  let mut iterations = 0
  while iterations < count {
    if not(options[idx].disabled) {
      return idx
    }
    idx = (idx + 1) % count
    iterations = iterations + 1
  }
  current_index // All disabled, stay
}

///|
/// Find previous enabled index (wrapping).
fn find_prev_enabled(
  options : Array[RadioOption[@js.Any]],
  current_index : Int,
) -> Int {
  let count = options.length()
  let mut idx = if current_index == 0 { count - 1 } else { current_index - 1 }
  let mut iterations = 0
  while iterations < count {
    if not(options[idx].disabled) {
      return idx
    }
    idx = if idx == 0 { count - 1 } else { idx - 1 }
    iterations = iterations + 1
  }
  current_index // All disabled, stay
}

///|
/// Find first enabled index.
fn find_first_enabled(options : Array[RadioOption[@js.Any]]) -> Int {
  let mut idx = 0
  while idx < options.length() {
    if not(options[idx].disabled) {
      return idx
    }
    idx = idx + 1
  }
  0
}

///|
/// Find last enabled index.
fn find_last_enabled(options : Array[RadioOption[@js.Any]]) -> Int {
  let mut idx = options.length() - 1
  while idx >= 0 {
    if not(options[idx].disabled) {
      return idx
    }
    idx = idx - 1
  }
  options.length() - 1
}

///|
/// Create a keyboard handler for radio group with arrow navigation.
///
/// APG keyboard support:
/// - ArrowDown/ArrowRight: Move to next and select (wraps)
/// - ArrowUp/ArrowLeft: Move to previous and select (wraps)
/// - Home: Move to first and select
/// - End: Move to last and select
/// - Space: Select focused radio
///
/// Parameters:
/// - options: Array of radio options
/// - radio_ids: Array of radio element IDs
/// - current_index: Index of the current radio
/// - on_select: Callback to select a value by index
pub fn make_radio_keydown_handler(
  options : Array[RadioOption[@js.Any]],
  radio_ids : Array[String],
  current_index : Int,
  on_select : (Int) -> Unit,
) -> @luna.EventHandler[@js.Any] {
  @luna.handler(fn(e : @js.Any) {
    let key : String = e._get("key").cast()
    match key {
      "ArrowDown" | "ArrowRight" => {
        let _ = e._call("preventDefault", [])
        let next_idx = find_next_enabled(options, current_index)
        on_select(next_idx)
        focus_radio(radio_ids[next_idx])
      }
      "ArrowUp" | "ArrowLeft" => {
        let _ = e._call("preventDefault", [])
        let prev_idx = find_prev_enabled(options, current_index)
        on_select(prev_idx)
        focus_radio(radio_ids[prev_idx])
      }
      "Home" => {
        let _ = e._call("preventDefault", [])
        let first_idx = find_first_enabled(options)
        on_select(first_idx)
        focus_radio(radio_ids[first_idx])
      }
      "End" => {
        let _ = e._call("preventDefault", [])
        let last_idx = find_last_enabled(options)
        on_select(last_idx)
        focus_radio(radio_ids[last_idx])
      }
      " " => {
        let _ = e._call("preventDefault", [])
        if not(options[current_index].disabled) {
          on_select(current_index)
        }
      }
      _ => ()
    }
  })
}

///|
/// Create a complete interactive radio group with keyboard navigation.
///
/// Features:
/// - Arrow key navigation (wraps)
/// - Home/End navigation
/// - Space selects
/// - Roving tabindex
///
/// Parameters:
/// - id: Group container ID
/// - name: Form field name
/// - options: Array of RadioOption
/// - selected: Signal for currently selected value
/// - aria_label: Accessible label
pub fn radiogroup_interactive(
  id : String,
  name : String,
  options : Array[RadioOption[@js.Any]],
  selected : @resource.Signal[String],
  aria_label? : String,
) -> @luna.Node[@js.Any, String] {
  // Build radio IDs
  let radio_ids : Array[String] = []
  let mut i = 0
  while i < options.length() {
    radio_ids.push(id + "-" + options[i].value)
    i = i + 1
  }
  // Find current index from selected value
  fn find_selected_index() -> Int {
    let sel = selected.get()
    let mut idx = 0
    while idx < options.length() {
      if options[idx].value == sel {
        return idx
      }
      idx = idx + 1
    }
    find_first_enabled(options) // Default to first enabled
  }

  let on_select = fn(idx : Int) { selected.set(options[idx].value) }
  // Build radios
  let radios : Array[@luna.Node[@js.Any, String]] = []
  i = 0
  while i < options.length() {
    let option = options[i]
    let index = i
    let radio_id = radio_ids[i]
    let keydown_handler = make_radio_keydown_handler(
      options, radio_ids, index, on_select,
    )
    let click_handler = @luna.handler(fn(_) {
      if not(option.disabled) {
        on_select(index)
      }
    })
    let attrs : Array[(String, @luna.Attr[@js.Any, String])] = [
      ("role", @luna.attr_static("radio")),
      ("id", @luna.attr_static(radio_id)),
      (
        "aria-checked",
        @luna.attr_dynamic(fn() {
          if selected.get() == option.value {
            "true"
          } else {
            "false"
          }
        }),
      ),
      (
        "tabindex",
        @luna.attr_dynamic(fn() {
          let sel_idx = find_selected_index()
          if index == sel_idx {
            "0"
          } else {
            "-1"
          }
        }),
      ),
      ("data-value", @luna.attr_static(option.value)),
      ("keydown", @luna.attr_handler(keydown_handler)),
      ("click", @luna.attr_handler(click_handler)),
    ]
    if option.disabled {
      attrs.push(("aria-disabled", @luna.attr_static("true")))
    }
    radios.push(@luna.h("div", attrs, option.label))
    i = i + 1
  }
  // Container
  let group_attrs : Array[(String, @luna.Attr[@js.Any, String])] = [
    ("role", @luna.attr_static("radiogroup")),
    ("id", @luna.attr_static(id)),
    ("data-name", @luna.attr_static(name)),
  ]
  if aria_label is Some(label) {
    group_attrs.push(("aria-label", @luna.attr_static(label)))
  }
  @luna.h("div", group_attrs, radios)
}
