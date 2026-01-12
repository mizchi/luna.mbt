///|
/// JS API for Luna Styled Components CSS
///
/// Provides CSS extraction for JavaScript consumers.
/// Import individual CSS functions for tree-shaking.

// =============================================================================
// CSS Extraction API
// =============================================================================

///|
/// Get CSS variables for theming
pub fn get_theme_variables() -> String {
  @styled.theme_variables()
}

///|
/// Get switch CSS
pub fn get_switch_css() -> String {
  @switch.switch_css()
}

///|
/// Get checkbox CSS
pub fn get_checkbox_css() -> String {
  @checkbox.checkbox_css()
}

///|
/// Get tabs CSS
pub fn get_tabs_css() -> String {
  @tabs.tabs_css()
}

///|
/// Get accordion CSS
pub fn get_accordion_css() -> String {
  @accordion.accordion_css()
}

///|
/// Get all CSS combined (theme variables + all components)
pub fn get_all_css() -> String {
  let buf = StringBuilder::new()
  buf.write_string("/* Luna Styled Components */\n\n")
  buf.write_string(@styled.theme_variables())
  buf.write_string("\n\n")
  buf.write_string(@switch.switch_css())
  buf.write_string("\n\n")
  buf.write_string(@checkbox.checkbox_css())
  buf.write_string("\n\n")
  buf.write_string(@tabs.tabs_css())
  buf.write_string("\n\n")
  buf.write_string(@accordion.accordion_css())
  buf.to_string()
}
