///|
/// Radix CSS Presets using luna/css
/// Provides reusable style functions that integrate with SSR CSS extraction

// =============================================================================
// Button Styles
// =============================================================================

///|
/// Base button styles using atomic CSS
pub fn button_base_styles() -> String {
  @css.styles([
    ("display", "inline-flex"),
    ("align-items", "center"),
    ("justify-content", "center"),
    ("gap", "0.5em"),
    ("border", "none"),
    ("border-radius", "4px"),
    ("cursor", "pointer"),
    ("font-family", "inherit"),
    ("font-weight", "500"),
    ("transition", "all 0.15s ease"),
  ])
}

///|
/// Button size styles
pub fn button_size_styles(size : RadixSize) -> String {
  match size {
    Small => @css.styles([("padding", "0.25em 0.5em"), ("font-size", "0.75rem")])
    Medium => @css.styles([("padding", "0.5em 1em"), ("font-size", "0.875rem")])
    Large =>
      @css.styles([("padding", "0.75em 1.5em"), ("font-size", "1rem")])
  }
}

///|
/// Button variant styles
pub fn button_variant_styles(variant : RadixButtonVariant) -> String {
  let base = match variant {
    Default => @css.styles([("background", "#18181b"), ("color", "#fafafa")])
    Destructive => @css.styles([("background", "#dc2626"), ("color", "white")])
    Outline =>
      @css.styles([
        ("background", "transparent"),
        ("border", "1px solid #e4e4e7"),
        ("color", "#18181b"),
      ])
    Secondary => @css.styles([("background", "#f4f4f5"), ("color", "#18181b")])
    Ghost => @css.styles([("background", "transparent"), ("color", "#18181b")])
    Link =>
      @css.styles([
        ("background", "transparent"),
        ("color", "#2563eb"),
        ("text-decoration", "underline"),
        ("text-underline-offset", "4px"),
      ])
  }

  // Add hover states
  let hover = match variant {
    Default => @css.hover("background", "#27272a")
    Destructive => @css.hover("background", "#b91c1c")
    Outline => @css.hover("background", "#f4f4f5")
    Secondary => @css.hover("background", "#e4e4e7")
    Ghost => @css.hover("background", "#f4f4f5")
    Link => @css.hover("color", "#1d4ed8")
  }

  @css.combine([base, hover])
}

///|
/// Button disabled styles
pub fn button_disabled_styles() -> String {
  @css.styles([("opacity", "0.5"), ("pointer-events", "none"), ("cursor", "not-allowed")])
}

///|
/// Button focus styles
pub fn button_focus_styles() -> String {
  @css.on(":focus-visible", "outline", "2px solid #2563eb") +
  " " +
  @css.on(":focus-visible", "outline-offset", "2px")
}

// =============================================================================
// Badge Styles
// =============================================================================

///|
/// Base badge styles
pub fn badge_base_styles() -> String {
  @css.styles([
    ("display", "inline-flex"),
    ("align-items", "center"),
    ("border-radius", "9999px"),
    ("font-size", "0.75rem"),
    ("font-weight", "500"),
    ("line-height", "1"),
    ("padding", "0.25rem 0.625rem"),
  ])
}

///|
/// Badge variant styles
pub fn badge_variant_styles(variant : BadgeVariant) -> String {
  match variant {
    Default =>
      @css.styles([("background", "#18181b"), ("color", "#fafafa")])
    Secondary => @css.styles([("background", "#f4f4f5"), ("color", "#18181b")])
    Destructive => @css.styles([("background", "#dc2626"), ("color", "white")])
    Outline =>
      @css.styles([
        ("background", "transparent"),
        ("border", "1px solid #e4e4e7"),
        ("color", "#18181b"),
      ])
  }
}

// =============================================================================
// Checkbox Styles
// =============================================================================

///|
/// Checkbox root styles
pub fn checkbox_root_styles() -> String {
  @css.styles([
    ("display", "inline-flex"),
    ("align-items", "center"),
    ("justify-content", "center"),
    ("width", "1rem"),
    ("height", "1rem"),
    ("border", "1px solid #18181b"),
    ("border-radius", "2px"),
    ("background", "transparent"),
    ("cursor", "pointer"),
    ("transition", "all 0.15s ease"),
    ("flex-shrink", "0"),
  ])
}

///|
/// Checkbox checked styles
pub fn checkbox_checked_styles() -> String {
  @css.styles([("background", "#18181b"), ("border-color", "#18181b")])
}

///|
/// Checkbox focus styles
pub fn checkbox_focus_styles() -> String {
  @css.on(":focus-visible", "outline", "2px solid #2563eb") +
  " " +
  @css.on(":focus-visible", "outline-offset", "2px")
}

// =============================================================================
// Switch Styles
// =============================================================================

///|
/// Switch root styles
pub fn switch_root_styles() -> String {
  @css.styles([
    ("position", "relative"),
    ("display", "inline-flex"),
    ("align-items", "center"),
    ("width", "2.5rem"),
    ("height", "1.5rem"),
    ("border-radius", "9999px"),
    ("background", "#e4e4e7"),
    ("border", "none"),
    ("cursor", "pointer"),
    ("transition", "background 0.15s ease"),
    ("flex-shrink", "0"),
  ])
}

///|
/// Switch checked styles
pub fn switch_checked_styles() -> String {
  @css.styles([("background", "#18181b")])
}

///|
/// Switch thumb styles
pub fn switch_thumb_styles() -> String {
  @css.styles([
    ("position", "absolute"),
    ("left", "2px"),
    ("width", "1.25rem"),
    ("height", "1.25rem"),
    ("border-radius", "9999px"),
    ("background", "white"),
    ("box-shadow", "0 1px 3px rgba(0,0,0,0.2)"),
    ("transition", "transform 0.15s ease"),
  ])
}

///|
/// Switch thumb checked styles (translated position)
pub fn switch_thumb_checked_styles() -> String {
  @css.styles([("transform", "translateX(1rem)")])
}

// =============================================================================
// Input Styles
// =============================================================================

///|
/// Input base styles
pub fn input_base_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("width", "100%"),
    ("box-sizing", "border-box"),
    ("border", "1px solid #e4e4e7"),
    ("border-radius", "6px"),
    ("font-family", "inherit"),
    ("font-size", "0.875rem"),
    ("padding", "0 0.75rem"),
    ("background", "white"),
    ("transition", "all 0.15s ease"),
  ])
}

///|
/// Input size styles
pub fn input_size_styles(size : RadixSize) -> String {
  match size {
    Small =>
      @css.styles([("height", "2rem"), ("font-size", "0.75rem"), ("padding", "0 0.5rem")])
    Medium => @css.styles([("height", "2.5rem"), ("font-size", "0.875rem")])
    Large =>
      @css.styles([("height", "3rem"), ("font-size", "1rem"), ("padding", "0 1rem")])
  }
}

///|
/// Input focus styles
pub fn input_focus_styles() -> String {
  @css.on(":focus", "outline", "none") +
  " " +
  @css.on(":focus", "border-color", "#18181b") +
  " " +
  @css.on(":focus", "box-shadow", "0 0 0 1px #18181b")
}

///|
/// Input disabled styles
pub fn input_disabled_styles() -> String {
  @css.styles([("background", "#f4f4f5"), ("color", "#a1a1aa"), ("cursor", "not-allowed"), ("opacity", "0.5")])
}

// =============================================================================
// Separator Styles
// =============================================================================

///|
/// Separator horizontal styles
pub fn separator_horizontal_styles() -> String {
  @css.styles([
    ("width", "100%"),
    ("height", "1px"),
    ("background", "#e4e4e7"),
  ])
}

///|
/// Separator vertical styles
pub fn separator_vertical_styles() -> String {
  @css.styles([
    ("width", "1px"),
    ("height", "100%"),
    ("background", "#e4e4e7"),
  ])
}

// =============================================================================
// Toggle Styles
// =============================================================================

///|
/// Toggle base styles
pub fn toggle_base_styles() -> String {
  @css.styles([
    ("display", "inline-flex"),
    ("align-items", "center"),
    ("justify-content", "center"),
    ("border-radius", "4px"),
    ("font-size", "0.875rem"),
    ("font-weight", "500"),
    ("padding", "0.5rem"),
    ("background", "transparent"),
    ("border", "none"),
    ("cursor", "pointer"),
    ("transition", "all 0.15s ease"),
  ])
}

///|
/// Toggle pressed styles
pub fn toggle_pressed_styles() -> String {
  @css.styles([("background", "#f4f4f5"), ("color", "#18181b")])
}

///|
/// Toggle hover styles
pub fn toggle_hover_styles() -> String {
  @css.hover("background", "#e4e4e7")
}

///|
/// Toggle focus styles
pub fn toggle_focus_styles() -> String {
  @css.on(":focus-visible", "outline", "2px solid #2563eb") +
  " " +
  @css.on(":focus-visible", "outline-offset", "2px")
}

// =============================================================================
// Textarea Styles
// =============================================================================

///|
/// Textarea base styles
pub fn textarea_base_styles() -> String {
  @css.styles([
    ("display", "block"),
    ("width", "100%"),
    ("min-height", "5rem"),
    ("box-sizing", "border-box"),
    ("border", "1px solid #e4e4e7"),
    ("border-radius", "6px"),
    ("font-family", "inherit"),
    ("font-size", "0.875rem"),
    ("line-height", "1.5"),
    ("padding", "0.5rem 0.75rem"),
    ("resize", "vertical"),
    ("background", "white"),
    ("transition", "all 0.15s ease"),
  ])
}

///|
/// Textarea focus styles
pub fn textarea_focus_styles() -> String {
  @css.on(":focus", "outline", "none") +
  " " +
  @css.on(":focus", "border-color", "#18181b") +
  " " +
  @css.on(":focus", "box-shadow", "0 0 0 1px #18181b")
}

///|
/// Textarea disabled styles
pub fn textarea_disabled_styles() -> String {
  @css.styles([
    ("background", "#f4f4f5"),
    ("color", "#a1a1aa"),
    ("cursor", "not-allowed"),
    ("opacity", "0.5"),
    ("resize", "none"),
  ])
}

// =============================================================================
// Select Styles
// =============================================================================

///|
/// Select base styles
pub fn select_base_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("width", "100%"),
    ("box-sizing", "border-box"),
    ("border", "1px solid #e4e4e7"),
    ("border-radius", "6px"),
    ("font-family", "inherit"),
    ("font-size", "0.875rem"),
    ("padding", "0 0.75rem"),
    ("background", "white"),
    ("cursor", "pointer"),
    ("transition", "all 0.15s ease"),
    ("appearance", "none"),
  ])
}

///|
/// Select size styles
pub fn select_size_styles(size : RadixSize) -> String {
  match size {
    Small =>
      @css.styles([("height", "2rem"), ("font-size", "0.75rem"), ("padding", "0 0.5rem")])
    Medium => @css.styles([("height", "2.5rem"), ("font-size", "0.875rem")])
    Large =>
      @css.styles([("height", "3rem"), ("font-size", "1rem"), ("padding", "0 1rem")])
  }
}

///|
/// Select focus styles
pub fn select_focus_styles() -> String {
  @css.on(":focus", "outline", "none") +
  " " +
  @css.on(":focus", "border-color", "#18181b") +
  " " +
  @css.on(":focus", "box-shadow", "0 0 0 1px #18181b")
}

///|
/// Select disabled styles
pub fn select_disabled_styles() -> String {
  @css.styles([
    ("background", "#f4f4f5"),
    ("color", "#a1a1aa"),
    ("cursor", "not-allowed"),
    ("opacity", "0.5"),
  ])
}

// =============================================================================
// Radio Styles
// =============================================================================

///|
/// Radio group base styles
pub fn radio_group_base_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("flex-direction", "column"),
    ("gap", "0.5rem"),
  ])
}

///|
/// Radio group horizontal styles
pub fn radio_group_horizontal_styles() -> String {
  @css.styles([
    ("flex-direction", "row"),
    ("flex-wrap", "wrap"),
    ("gap", "1rem"),
  ])
}

///|
/// Radio item styles
pub fn radio_item_styles() -> String {
  @css.styles([
    ("display", "inline-flex"),
    ("align-items", "center"),
    ("gap", "0.5rem"),
    ("cursor", "pointer"),
  ])
}

///|
/// Radio control styles
pub fn radio_control_styles() -> String {
  @css.styles([
    ("appearance", "none"),
    ("width", "1rem"),
    ("height", "1rem"),
    ("border", "1px solid #18181b"),
    ("border-radius", "50%"),
    ("cursor", "inherit"),
    ("transition", "all 0.15s ease"),
    ("background", "white"),
    ("flex-shrink", "0"),
  ])
}

///|
/// Radio control focus styles
pub fn radio_control_focus_styles() -> String {
  @css.on(":focus-visible", "outline", "2px solid #2563eb") +
  " " +
  @css.on(":focus-visible", "outline-offset", "2px")
}

///|
/// Radio label styles
pub fn radio_label_styles() -> String {
  @css.styles([
    ("font-size", "0.875rem"),
    ("color", "#18181b"),
    ("user-select", "none"),
  ])
}
