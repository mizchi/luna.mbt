// Pseudo-class and Pseudo-element Support
//
// Provides functions for :hover, :focus, :active, ::before, etc.
// Uses DJB2 hash for deterministic class names that match extract.ts output.

///|
/// Pseudo-class/element registry
priv struct PseudoRegistry {
  // ":hover:background:#2563eb" → "_abc123"
  pseudo_to_class : Map[String, String]
  // Store for CSS generation: class_name → (pseudo, property, value)
  entries : Array[(String, String, String, String)]
}

///|
/// Global pseudo registry
let pseudo_registry : PseudoRegistry = {
  pseudo_to_class: Map::new(),
  entries: [],
}

///|
/// Generate hash-based class name for pseudo declarations
/// Key format: ":hover:property:value" (same as extract.ts)
fn hash_pseudo_class_name(key : String) -> String {
  let hash = djb2_hash(key)
  let base36 = to_base36(hash)
  "_" + base36
}

///|
/// Register a pseudo-class declaration
fn register_pseudo(
  pseudo : String,
  property : String,
  value : String,
) -> String {
  let key = pseudo + ":" + property + ":" + value
  match pseudo_registry.pseudo_to_class.get(key) {
    Some(cls) => cls
    None => {
      let cls = hash_pseudo_class_name(key)
      pseudo_registry.pseudo_to_class.set(key, cls)
      pseudo_registry.entries.push((cls, pseudo, property, value))
      cls
    }
  }
}

///|
/// Generic pseudo-class/element handler
///
/// ```mbt check
/// test {
///   reset_pseudo_registry()
///   let cls = on(":hover", "background", "#2563eb")
///   inspect(cls.has_prefix("_"), content="true")
/// }
/// ```
pub fn on(pseudo : String, property : String, value : String) -> String {
  register_pseudo(pseudo, property, value)
}

///|
/// Hover pseudo-class shorthand
pub fn hover(property : String, value : String) -> String {
  on(":hover", property, value)
}

///|
/// Focus pseudo-class shorthand
pub fn focus(property : String, value : String) -> String {
  on(":focus", property, value)
}

///|
/// Active pseudo-class shorthand
pub fn active(property : String, value : String) -> String {
  on(":active", property, value)
}

///|
/// Reset pseudo registry (for testing)
pub fn reset_pseudo_registry() -> Unit {
  pseudo_registry.pseudo_to_class.clear()
  pseudo_registry.entries.clear()
}

///|
/// Get pseudo registry entries for CSS generation
pub fn get_pseudo_entries() -> Array[(String, String, String, String)] {
  pseudo_registry.entries
}
