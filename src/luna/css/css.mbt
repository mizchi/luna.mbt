// CSS Utility Functions
//
// Direct CSS API - property names are NOT abstracted.
// Compression happens automatically through class name generation.

///|
/// Single CSS property-value pair
/// Returns the generated class name
///
/// Example:
/// ```moonbit
/// css("display", "flex")  // Returns "_a"
/// css("display", "flex")  // Returns "_a" (same, deduplicated)
/// css("padding", "1rem")  // Returns "_b"
/// ```
pub fn css(property : String, value : String) -> String {
  let decl = property + ":" + value
  register_decl(decl)
}

///|
/// Multiple CSS properties at once
/// Returns space-separated class names
///
/// Example:
/// ```moonbit
/// styles([
///   ("display", "flex"),
///   ("align-items", "center"),
///   ("padding", "1rem"),
/// ])  // Returns "_a _b _c"
/// ```
pub fn styles(props : Array[(String, String)]) -> String {
  let classes : Array[String] = []
  for pair in props {
    let (property, value) = pair
    let decl = property + ":" + value
    let class_name = register_decl(decl)
    classes.push(class_name)
  }
  classes.join(" ")
}

///|
/// Combine multiple class names (from css() or styles() calls)
///
/// Example:
/// ```moonbit
/// let flex = css("display", "flex")
/// let center = css("align-items", "center")
/// combine([flex, center])  // Returns "_a _b"
/// ```
pub fn combine(classes : Array[String]) -> String {
  classes.join(" ")
}
