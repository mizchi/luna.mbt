///|
/// APG Helper Utilities
/// Common utilities for APG components including ID generation and keyboard navigation

///|
/// Global ID counter for auto-generated IDs
let id_counter : Ref[Int] = Ref::new(0)

///|
/// Generate a unique ID with a given prefix.
/// Useful for automatically creating IDs for tabs, panels, etc.
/// ```mbt check
/// test {
///   let id1 = @components.auto_id("tab")
///   let id2 = @components.auto_id("tab")
///   assert_true(id1 != id2)
/// }
/// ```
pub fn auto_id(prefix : String) -> String {
  id_counter.val = id_counter.val + 1
  prefix + "-" + id_counter.val.to_string()
}

///|
/// Reset the ID counter (useful for testing)
pub fn reset_id_counter() -> Unit {
  id_counter.val = 0
}

///|
/// Common key codes for keyboard navigation
pub(all) enum KeyCode {
  Enter
  Space
  ArrowUp
  ArrowDown
  ArrowLeft
  ArrowRight
  Home
  End
  Tab
  Escape
} derive(Eq, Show)

///|
pub fn KeyCode::from_string(key : String) -> KeyCode? {
  match key {
    "Enter" => Some(Enter)
    " " => Some(Space)
    "ArrowUp" => Some(ArrowUp)
    "ArrowDown" => Some(ArrowDown)
    "ArrowLeft" => Some(ArrowLeft)
    "ArrowRight" => Some(ArrowRight)
    "Home" => Some(Home)
    "End" => Some(End)
    "Tab" => Some(Tab)
    "Escape" => Some(Escape)
    _ => None
  }
}

///|
/// Boolean to ARIA string conversion
pub fn bool_to_aria(value : Bool) -> String {
  if value { "true" } else { "false" }
}

// =============================================================================
// Keyboard Navigation Helpers
// =============================================================================

///|
/// Check if a key matches a KeyCode
pub fn key_matches(key : String, code : KeyCode) -> Bool {
  match code {
    Enter => key == "Enter"
    Space => key == " "
    ArrowUp => key == "ArrowUp"
    ArrowDown => key == "ArrowDown"
    ArrowLeft => key == "ArrowLeft"
    ArrowRight => key == "ArrowRight"
    Home => key == "Home"
    End => key == "End"
    Tab => key == "Tab"
    Escape => key == "Escape"
  }
}

///|
/// Check if a key is a toggle key (Space or Enter)
pub fn is_toggle_key(key : String) -> Bool {
  key == " " || key == "Enter"
}

///|
/// Check if a key is an arrow key
pub fn is_arrow_key(key : String) -> Bool {
  key == "ArrowUp" || key == "ArrowDown" || key == "ArrowLeft" ||
  key == "ArrowRight"
}

///|
/// Check if a key is a horizontal arrow key
pub fn is_horizontal_arrow(key : String) -> Bool {
  key == "ArrowLeft" || key == "ArrowRight"
}

///|
/// Check if a key is a vertical arrow key
pub fn is_vertical_arrow(key : String) -> Bool {
  key == "ArrowUp" || key == "ArrowDown"
}

///|
/// Get direction from arrow key (-1 for up/left, 1 for down/right, 0 for other)
pub fn arrow_direction(key : String) -> Int {
  match key {
    "ArrowUp" | "ArrowLeft" => -1
    "ArrowDown" | "ArrowRight" => 1
    _ => 0
  }
}

///|
/// Calculate next index for list navigation with wrapping
pub fn wrap_index(current : Int, direction : Int, length : Int) -> Int {
  if length <= 0 {
    return 0
  }
  let next = current + direction
  if next < 0 {
    length - 1
  } else if next >= length {
    0
  } else {
    next
  }
}

///|
/// Calculate next index for list navigation without wrapping (clamped)
pub fn clamp_index(current : Int, direction : Int, length : Int) -> Int {
  if length <= 0 {
    return 0
  }
  let next = current + direction
  if next < 0 {
    0
  } else if next >= length {
    length - 1
  } else {
    next
  }
}

///|
/// Get the key string from a keyboard event
fn get_event_key(e : @js.Any) -> String {
  e._get("key").to_string()
}

///|
/// Create a toggle handler that responds to Space and Enter keys
pub fn make_toggle_handler(on_toggle : () -> Unit) -> @luna.EventHandler[@js.Any] {
  @luna.handler(fn(e : @js.Any) {
    let key = get_event_key(e)
    if is_toggle_key(key) {
      on_toggle()
    }
  })
}

///|
/// Create a horizontal arrow key handler for tabs/sliders
/// - ArrowLeft: move to previous
/// - ArrowRight: move to next
/// - Home: move to first (optional)
/// - End: move to last (optional)
pub fn make_horizontal_nav_handler(
  current_index : () -> Int,
  length : Int,
  on_change : (Int) -> Unit,
  wrap? : Bool,
  support_home_end? : Bool
) -> @luna.EventHandler[@js.Any] {
  let do_wrap = match wrap {
    Some(w) => w
    None => true
  }
  let home_end = match support_home_end {
    Some(h) => h
    None => true
  }
  @luna.handler(fn(e : @js.Any) {
    let key = get_event_key(e)
    if is_horizontal_arrow(key) {
      let dir = arrow_direction(key)
      let curr = current_index()
      let next = if do_wrap {
        wrap_index(curr, dir, length)
      } else {
        clamp_index(curr, dir, length)
      }
      if next != curr {
        on_change(next)
      }
    } else if home_end && key == "Home" {
      on_change(0)
    } else if home_end && key == "End" {
      on_change(length - 1)
    }
  })
}

///|
/// Create a vertical arrow key handler for radio groups/listboxes
/// - ArrowUp: move to previous
/// - ArrowDown: move to next
/// - Home: move to first (optional)
/// - End: move to last (optional)
pub fn make_vertical_nav_handler(
  current_index : () -> Int,
  length : Int,
  on_change : (Int) -> Unit,
  wrap? : Bool,
  support_home_end? : Bool
) -> @luna.EventHandler[@js.Any] {
  let do_wrap = match wrap {
    Some(w) => w
    None => true
  }
  let home_end = match support_home_end {
    Some(h) => h
    None => true
  }
  @luna.handler(fn(e : @js.Any) {
    let key = get_event_key(e)
    if is_vertical_arrow(key) {
      let dir = arrow_direction(key)
      let curr = current_index()
      let next = if do_wrap {
        wrap_index(curr, dir, length)
      } else {
        clamp_index(curr, dir, length)
      }
      if next != curr {
        on_change(next)
      }
    } else if home_end && key == "Home" {
      on_change(0)
    } else if home_end && key == "End" {
      on_change(length - 1)
    }
  })
}

///|
/// Create a slider keyboard handler
/// - ArrowUp/Right: increase by step
/// - ArrowDown/Left: decrease by step
/// - Home: set to min
/// - End: set to max
/// - PageUp: increase by large step (optional)
/// - PageDown: decrease by large step (optional)
pub fn make_slider_handler(
  current_value : () -> Double,
  min : Double,
  max : Double,
  step : Double,
  on_change : (Double) -> Unit,
  large_step? : Double
) -> @luna.EventHandler[@js.Any] {
  let big_step = match large_step {
    Some(s) => s
    None => step * 10.0
  }
  @luna.handler(fn(e : @js.Any) {
    let key = get_event_key(e)
    let curr = current_value()
    let new_val = match key {
      "ArrowUp" | "ArrowRight" => {
        let v = curr + step
        if v > max { max } else { v }
      }
      "ArrowDown" | "ArrowLeft" => {
        let v = curr - step
        if v < min { min } else { v }
      }
      "PageUp" => {
        let v = curr + big_step
        if v > max { max } else { v }
      }
      "PageDown" => {
        let v = curr - big_step
        if v < min { min } else { v }
      }
      "Home" => min
      "End" => max
      _ => curr
    }
    if new_val != curr {
      on_change(new_val)
    }
  })
}

///|
/// Create an escape key handler
pub fn make_escape_handler(on_escape : () -> Unit) -> @luna.EventHandler[@js.Any] {
  @luna.handler(fn(e : @js.Any) {
    let key = get_event_key(e)
    if key == "Escape" {
      on_escape()
    }
  })
}
