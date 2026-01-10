// Media Query Support
//
// Provides functions for responsive styles and dark mode.

///|
/// Media query registry
priv struct MediaRegistry {
  // "@media(min-width:768px):padding:2rem" → "_m0"
  media_to_class : Map[String, String]
  mut counter : Int
  // Store for CSS generation: class_name → (condition, property, value)
  entries : Array[(String, String, String, String)]
}

///|
/// Global media registry
let media_registry : MediaRegistry = {
  media_to_class: Map::new(),
  counter: 0,
  entries: [],
}

///|
/// Generate media query class name
fn next_media_class_name() -> String {
  let n = media_registry.counter
  media_registry.counter += 1
  "_m" + n.to_string()
}

///|
/// Register a media query declaration
fn register_media(
  condition : String,
  property : String,
  value : String,
) -> String {
  let key = "@media(" + condition + "):" + property + ":" + value
  match media_registry.media_to_class.get(key) {
    Some(cls) => cls
    None => {
      let cls = next_media_class_name()
      media_registry.media_to_class.set(key, cls)
      media_registry.entries.push((cls, condition, property, value))
      cls
    }
  }
}

///|
/// Generic media query handler
///
/// ```mbt check
/// test {
///   reset_media_registry()
///   let cls = media("min-width:768px", "padding", "2rem")
///   inspect(cls.has_prefix("_m"), content="true")
/// }
/// ```
pub fn media(condition : String, property : String, value : String) -> String {
  register_media(condition, property, value)
}

///|
/// Small breakpoint (min-width: 640px)
pub fn at_sm(property : String, value : String) -> String {
  media("min-width:640px", property, value)
}

///|
/// Medium breakpoint (min-width: 768px)
pub fn at_md(property : String, value : String) -> String {
  media("min-width:768px", property, value)
}

///|
/// Large breakpoint (min-width: 1024px)
pub fn at_lg(property : String, value : String) -> String {
  media("min-width:1024px", property, value)
}

///|
/// Extra large breakpoint (min-width: 1280px)
pub fn at_xl(property : String, value : String) -> String {
  media("min-width:1280px", property, value)
}

///|
/// Dark mode (prefers-color-scheme: dark)
pub fn dark(property : String, value : String) -> String {
  media("prefers-color-scheme:dark", property, value)
}

///|
/// Reset media registry (for testing)
pub fn reset_media_registry() -> Unit {
  media_registry.media_to_class.clear()
  media_registry.entries.clear()
  media_registry.counter = 0
}

///|
/// Get media registry entries for CSS generation
pub fn get_media_entries() -> Array[(String, String, String, String)] {
  media_registry.entries
}
