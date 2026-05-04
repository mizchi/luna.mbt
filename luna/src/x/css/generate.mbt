// CSS Generation
//
// Generates CSS output from registered styles.

///|
/// Generate CSS for base styles only (minified)
pub fn generate_css() -> String {
  let buf = StringBuilder::new()
  for decl in registry.declarations {
    match registry.decl_to_class.get(decl) {
      Some(cls) => {
        buf.write_char('.')
        buf.write_string(cls)
        buf.write_char('{')
        buf.write_string(decl)
        buf.write_char('}')
      }
      None => ()
    }
  }
  buf.to_string()
}

///|
/// Generate CSS for base styles (pretty printed)
pub fn generate_css_pretty() -> String {
  let buf = StringBuilder::new()
  for decl in registry.declarations {
    match registry.decl_to_class.get(decl) {
      Some(cls) => {
        buf.write_char('.')
        buf.write_string(cls)
        buf.write_string(" { ")
        buf.write_string(decl)
        buf.write_string(" }\n")
      }
      None => ()
    }
  }
  buf.to_string()
}

///|
/// Generate complete CSS including pseudo-classes and media queries (minified)
pub fn generate_full_css() -> String {
  let buf = StringBuilder::new()

  // Base styles
  buf.write_string(generate_css())

  // Pseudo-class styles
  for entry in get_pseudo_entries() {
    let (cls, pseudo, property, value) = entry
    buf.write_char('.')
    buf.write_string(cls)
    buf.write_string(pseudo)
    buf.write_char('{')
    buf.write_string(property)
    buf.write_char(':')
    buf.write_string(value)
    buf.write_char('}')
  }

  // Media query styles (grouped by condition for better compression)
  let media_groups : Map[String, Array[(String, String, String)]] = Map::new()
  for entry in get_media_entries() {
    let (cls, condition, property, value) = entry
    match media_groups.get(condition) {
      Some(arr) => arr.push((cls, property, value))
      None => media_groups.set(condition, [(cls, property, value)])
    }
  }
  for condition, entries in media_groups {
    buf.write_string("@media(")
    buf.write_string(condition)
    buf.write_string("){")
    for entry in entries {
      let (cls, property, value) = entry
      buf.write_char('.')
      buf.write_string(cls)
      buf.write_char('{')
      buf.write_string(property)
      buf.write_char(':')
      buf.write_string(value)
      buf.write_char('}')
    }
    buf.write_char('}')
  }
  buf.to_string()
}

///|
/// Reset all registries (for testing)
pub fn reset_all() -> Unit {
  reset_registry()
  reset_pseudo_registry()
  reset_media_registry()
}
