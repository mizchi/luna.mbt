// Sol SSG Components - Common Helpers
// These helpers provide a consistent API for building SSR components

///|
/// Create a server-side element
pub fn h(
  tag : String,
  attrs : Array[(String, @luna.Attr[Unit])],
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(tag, attrs, children)
}

///|
/// Create a static attribute
pub fn attr(key : String, value : String) -> (String, @luna.Attr[Unit]) {
  (key, @luna.attr_static(value))
}

///|
/// Create an empty fragment
pub fn empty() -> @luna.Node[Unit] {
  @luna.fragment([])
}
