// CSS Utility Functions
//
// Direct CSS API - property names are NOT abstracted.
// Compression happens automatically through class name generation.

///|
/// Single CSS property-value pair
/// Returns the generated class name
///
/// ```mbt check
/// test {
///   reset_all()
///   let cls1 = css("display", "flex")
///   inspect(cls1.has_prefix("_"), content="true")
///   let cls2 = css("display", "flex") // same declaration
///   inspect(cls1 == cls2, content="true") // deduplicated
/// }
/// ```
pub fn css(property : String, value : String) -> String {
  let decl = property + ":" + value
  register_decl(decl)
}

///|
/// Multiple CSS properties at once
/// Returns space-separated class names
///
/// ```mbt check
/// test {
///   reset_all()
///   let cls = styles([("display", "flex"), ("padding", "1rem")])
///   inspect(cls.contains(" "), content="true") // multiple classes
/// }
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
/// ```mbt check
/// test {
///   reset_all()
///   let flex = css("display", "flex")
///   let center = css("align-items", "center")
///   let combined = combine([flex, center])
///   inspect(combined.contains(flex), content="true")
///   inspect(combined.contains(center), content="true")
/// }
/// ```
pub fn combine(classes : Array[String]) -> String {
  classes.join(" ")
}
