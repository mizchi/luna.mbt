///|
/// Check if element has dynamic content that needs hydration
pub fn[E, A] has_dynamic_content(attrs : Array[(String, Attr[E, A])]) -> Bool {
  for attr in attrs {
    let (_, value) = attr
    match value {
      VDynamic(_) | VHandler(_) | VAction(_) => return true
      _ => ()
    }
  }
  false
}

// Attr factory functions for external packages

///|
/// Create a static attribute value.
/// ```mbt check
/// test {
///   let attr : Attr[Unit, String] = attr_static("my-class")
///   guard attr is VStatic(v) else { fail("expected VStatic") }
///   inspect(v, content="my-class")
/// }
/// ```
pub fn[E, A] attr_static(value : A) -> Attr[E, A] {
  VStatic(value)
}

///|
/// Create a dynamic attribute value.
/// The value is computed lazily on each render.
/// ```mbt check
/// test {
///   let mut count = 0
///   let attr : Attr[Unit, String] = attr_dynamic(fn() {
///     "count-" + count.to_string()
///   })
///   guard attr is VDynamic(getter) else { fail("expected VDynamic") }
///   inspect(getter(), content="count-0")
///   count = 5
///   inspect(getter(), content="count-5")
/// }
/// ```
pub fn[E, A] attr_dynamic(getter : () -> A) -> Attr[E, A] {
  VDynamic(getter)
}

///|
/// Create a handler attribute value
pub fn[E, A] attr_handler(handler : EventHandler[E]) -> Attr[E, A] {
  VHandler(handler)
}

///|
/// Create a style attribute value (string form, e.g. "color: red; margin: 10px")
/// Note: For Web (A = String), pass the style string directly
pub fn[E] attr_style(style : String) -> Attr[E, String] {
  attr_static(style)
}

///|
/// Create a dynamic style attribute value
/// Note: For Web (A = String), the getter returns a style string
pub fn[E] attr_dynamic_style(getter : () -> String) -> Attr[E, String] {
  attr_dynamic(getter)
}

///|
/// Create an action attribute value - dispatches named action on event
/// Used for declarative event handling with enum types:
///   ("onclick", action(Increment))  // requires derive(Show)
///
/// Example:
/// ```
/// pub enum MyAction { Increment; Decrement } derive(Show)
/// h("button", [("onclick", action(Increment))], [...])
/// ```
pub fn[E, V, Act : Show] action(a : Act) -> Attr[E, V] {
  VAction(a.to_string())
}
