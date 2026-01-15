///|
/// Headless Component Helpers (Web-specific)
///
/// DOM event utilities for headless components.
/// For pure ARIA utilities, use @aria package.

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
/// Stop event propagation
pub fn stop_propagation(e : @js.Any) -> Unit {
  let _ = e._call("stopPropagation", [])

}
