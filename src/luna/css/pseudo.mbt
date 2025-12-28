// Pseudo-class and Pseudo-element Support
//
// Provides functions for :hover, :focus, :active, ::before, etc.

///|
/// Pseudo-class/element registry
priv struct PseudoRegistry {
  // ":hover:background:#2563eb" → "_h0"
  pseudo_to_class : Map[String, String]
  mut hover_counter : Int
  mut focus_counter : Int
  mut active_counter : Int
  mut other_counter : Int
  // Store for CSS generation: class_name → (pseudo, property, value)
  entries : Array[(String, String, String, String)]
}

///|
/// Global pseudo registry
let pseudo_registry : PseudoRegistry = {
  pseudo_to_class: Map::new(),
  hover_counter: 0,
  focus_counter: 0,
  active_counter: 0,
  other_counter: 0,
  entries: [],
}

///|
/// Generate pseudo-class specific class name
fn next_pseudo_class_name(pseudo : String) -> String {
  match pseudo {
    ":hover" => {
      let n = pseudo_registry.hover_counter
      pseudo_registry.hover_counter += 1
      "_h" + n.to_string()
    }
    ":focus" => {
      let n = pseudo_registry.focus_counter
      pseudo_registry.focus_counter += 1
      "_f" + n.to_string()
    }
    ":active" => {
      let n = pseudo_registry.active_counter
      pseudo_registry.active_counter += 1
      "_ac" + n.to_string()
    }
    _ => {
      let n = pseudo_registry.other_counter
      pseudo_registry.other_counter += 1
      "_p" + n.to_string()
    }
  }
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
      let cls = next_pseudo_class_name(pseudo)
      pseudo_registry.pseudo_to_class.set(key, cls)
      pseudo_registry.entries.push((cls, pseudo, property, value))
      cls
    }
  }
}

///|
/// Generic pseudo-class/element handler
///
/// Example:
/// ```moonbit
/// on(":hover", "background", "#2563eb")
/// on(":focus", "outline", "2px solid blue")
/// on("::before", "content", "\"→\"")
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
  pseudo_registry.hover_counter = 0
  pseudo_registry.focus_counter = 0
  pseudo_registry.active_counter = 0
  pseudo_registry.other_counter = 0
}

///|
/// Get pseudo registry entries for CSS generation
pub fn get_pseudo_entries() -> Array[(String, String, String, String)] {
  pseudo_registry.entries
}
