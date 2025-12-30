// Shared styles used across components
// These should be detected as "shared" in split mode

///|
pub fn flex_center() -> String {
  @css.styles([
    ("display", "flex"),
    ("align-items", "center"),
    ("justify-content", "center"),
  ])
}

///|
pub fn text_base() -> String {
  @css.styles([
    ("font-family", "system-ui, sans-serif"),
    ("font-size", "14px"),
    ("color", "#333"),
  ])
}

///|
pub fn rounded() -> String {
  @css.css("border-radius", "8px")
}

///|
pub fn shadow() -> String {
  @css.css("box-shadow", "0 2px 4px rgba(0,0,0,0.1)")
}
