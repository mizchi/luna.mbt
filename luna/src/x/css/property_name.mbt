///|
/// Accepted by the composable style API. Property provides checked names;
/// String preserves existing callers and supports custom or vendor properties.
pub trait PropertyName {
  fn css_name(Self) -> String
}

///|
pub impl PropertyName for Property with fn css_name(self) {
  self.css_name()
}

///|
pub impl PropertyName for String with fn css_name(self) {
  self
}
