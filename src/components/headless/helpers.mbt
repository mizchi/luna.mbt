///|
/// Headless Component Helpers
///
/// Internal utilities for headless components.

///|
/// Get the key string from a keyboard event
pub fn get_event_key(e : @js.Any) -> String {
  e._get("key").to_string()
}

///|
/// Prevent default event behavior
pub fn prevent_default(e : @js.Any) -> Unit {
  let _ = e._call("preventDefault", [])

}

///|
/// Check if a key is a toggle key (Space or Enter)
pub fn is_toggle_key(key : String) -> Bool {
  key == " " || key == "Enter"
}

///|
/// Boolean to ARIA string conversion
pub fn bool_to_aria(value : Bool) -> String {
  if value {
    "true"
  } else {
    "false"
  }
}
