// RoutesMatch accessor methods
//

///|
/// Get component ID
pub fn RoutesMatch::component(self : RoutesMatch) -> String {
  self.route.component
}

///|
/// Get layout ID list
pub fn RoutesMatch::layouts(self : RoutesMatch) -> Array[String] {
  self.route.layouts
}

///|
/// Get parameter
pub fn RoutesMatch::get_param(self : RoutesMatch, key : String) -> String? {
  for pair in self.params {
    if pair.0 == key {
      return Some(pair.1)
    }
  }
  None
}

///|
/// Get query parameter
pub fn RoutesMatch::get_query(self : RoutesMatch, key : String) -> String? {
  for pair in self.query {
    if pair.0 == key {
      return Some(pair.1)
    }
  }
  None
}

///|
/// Get route kind
pub fn RoutesMatch::kind(self : RoutesMatch) -> RoutesKind {
  self.route.kind
}

///|
/// Get title
pub fn RoutesMatch::title(self : RoutesMatch) -> String {
  self.route.title
}

///|
/// Get meta information
pub fn RoutesMatch::meta(self : RoutesMatch) -> Array[(String, String)] {
  self.route.meta
}
