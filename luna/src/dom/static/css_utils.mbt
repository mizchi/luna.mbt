// CSS Utility Re-exports
//
// Re-exports CSS utility functions for convenient access from static_dom.

///|
/// Single CSS property-value pair
/// Returns the generated class name
pub fn ucss(property : String, value : String) -> String {
  @css.css(property, value)
}

///|
/// Multiple CSS properties at once
/// Returns space-separated class names
pub fn ustyles(props : Array[(String, String)]) -> String {
  @css.styles(props)
}

///|
/// Combine multiple class names
pub fn ucombine(classes : Array[String]) -> String {
  @css.combine(classes)
}

///|
/// Hover pseudo-class
pub fn uhover(property : String, value : String) -> String {
  @css.hover(property, value)
}

///|
/// Focus pseudo-class
pub fn ufocus(property : String, value : String) -> String {
  @css.focus(property, value)
}

///|
/// Active pseudo-class
pub fn uactive(property : String, value : String) -> String {
  @css.active(property, value)
}

///|
/// Generic pseudo-class/element handler
pub fn uon(pseudo : String, property : String, value : String) -> String {
  @css.on(pseudo, property, value)
}

///|
/// Medium breakpoint (min-width: 768px)
pub fn uat_md(property : String, value : String) -> String {
  @css.at_md(property, value)
}

///|
/// Large breakpoint (min-width: 1024px)
pub fn uat_lg(property : String, value : String) -> String {
  @css.at_lg(property, value)
}

///|
/// Dark mode
pub fn udark(property : String, value : String) -> String {
  @css.dark(property, value)
}

///|
/// Generate CSS output (for SSR)
pub fn generate_utility_css() -> String {
  @css.generate_full_css()
}
