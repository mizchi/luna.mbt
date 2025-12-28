// CSS Utility Registry
//
// Tracks CSS declarations and generates minimal class names.
// Used for CSS-in-MoonBit with automatic deduplication.

///|
/// Style registry: declaration → short class name
priv struct StyleRegistry {
  // "display:flex" → "_a"
  decl_to_class : Map[String, String]
  // All declarations in order (for deterministic output)
  declarations : Array[String]
  // Counter for class name generation
  mut counter : Int
}

///|
/// Global style registry (singleton)
let registry : StyleRegistry = {
  decl_to_class: Map::new(),
  declarations: [],
  counter: 0,
}

///|
/// Character set for class name generation
let class_chars : String = "abcdefghijklmnopqrstuvwxyz"

///|
/// Generate short class name from counter
fn next_class_name() -> String {
  let n = registry.counter
  registry.counter += 1
  let name = if n < 26 {
    class_chars[n].to_string()
  } else {
    class_chars[n % 26].to_string() + (n / 26).to_string()
  }
  "_" + name // Prefix to avoid collision with external CSS
}

///|
/// Register a CSS declaration and return its class name
fn register_decl(decl : String) -> String {
  match registry.decl_to_class.get(decl) {
    Some(cls) => cls
    None => {
      let cls = next_class_name()
      registry.decl_to_class.set(decl, cls)
      registry.declarations.push(decl)
      cls
    }
  }
}

///|
/// Reset registry (useful for testing)
pub fn reset_registry() -> Unit {
  registry.decl_to_class.clear()
  registry.declarations.clear()
  registry.counter = 0
}

///|
/// Get number of registered declarations
pub fn registry_size() -> Int {
  registry.declarations.length()
}
