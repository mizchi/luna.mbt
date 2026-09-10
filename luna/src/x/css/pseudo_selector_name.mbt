///|
/// Accepted by rule_on and rule_when. String supports compound selectors and
/// selectors outside the typed catalog. Neither form validates argument syntax.
pub trait PseudoSelector {
  fn css_selector(Self) -> String
}

///|
pub impl PseudoSelector for Pseudo with fn css_selector(self) {
  self.css_selector()
}

///|
pub impl PseudoSelector for String with fn css_selector(self) {
  self
}
