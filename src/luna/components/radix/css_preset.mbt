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

// =============================================================================
// Card Styles
// =============================================================================

///|
/// Card base styles
pub fn card_base_styles() -> String {
  @css.styles([
    ("background", "white"),
    ("border", "1px solid #e4e4e7"),
    ("border-radius", "8px"),
    ("box-shadow", "0 1px 3px rgba(0,0,0,0.1)"),
    ("overflow", "hidden"),
  ])
}

///|
/// Card header styles
pub fn card_header_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("flex-direction", "column"),
    ("gap", "0.375rem"),
    ("padding", "1.5rem"),
  ])
}

///|
/// Card title styles
pub fn card_title_styles() -> String {
  @css.styles([
    ("margin", "0"),
    ("font-size", "1.25rem"),
    ("font-weight", "600"),
    ("line-height", "1.2"),
    ("color", "#18181b"),
  ])
}

///|
/// Card description styles
pub fn card_description_styles() -> String {
  @css.styles([
    ("margin", "0"),
    ("font-size", "0.875rem"),
    ("color", "#71717a"),
    ("line-height", "1.5"),
  ])
}

///|
/// Card content styles
pub fn card_content_styles() -> String {
  @css.styles([("padding", "0 1.5rem 1.5rem")])
}

///|
/// Card footer styles
pub fn card_footer_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("align-items", "center"),
    ("gap", "0.5rem"),
    ("padding", "1.5rem"),
    ("border-top", "1px solid #e4e4e7"),
  ])
}

// =============================================================================
// Avatar Styles
// =============================================================================

///|
/// Avatar base styles
pub fn avatar_base_styles() -> String {
  @css.styles([
    ("display", "inline-flex"),
    ("align-items", "center"),
    ("justify-content", "center"),
    ("border-radius", "50%"),
    ("overflow", "hidden"),
    ("background", "#e4e4e7"),
    ("vertical-align", "middle"),
    ("user-select", "none"),
  ])
}

///|
/// Avatar size styles
pub fn avatar_size_styles(size : AvatarSize) -> String {
  match size {
    Small =>
      @css.styles([("width", "2rem"), ("height", "2rem"), ("font-size", "0.75rem")])
    Medium =>
      @css.styles([
        ("width", "2.5rem"),
        ("height", "2.5rem"),
        ("font-size", "0.875rem"),
      ])
    Large =>
      @css.styles([("width", "3rem"), ("height", "3rem"), ("font-size", "1rem")])
    XLarge =>
      @css.styles([("width", "4rem"), ("height", "4rem"), ("font-size", "1.25rem")])
  }
}

///|
/// Avatar image styles
pub fn avatar_image_styles() -> String {
  @css.styles([("width", "100%"), ("height", "100%"), ("object-fit", "cover")])
}

///|
/// Avatar fallback styles
pub fn avatar_fallback_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("align-items", "center"),
    ("justify-content", "center"),
    ("width", "100%"),
    ("height", "100%"),
    ("font-weight", "500"),
    ("color", "#71717a"),
    ("text-transform", "uppercase"),
  ])
}

// =============================================================================
// Label Styles
// =============================================================================

///|
/// Label base styles
pub fn label_base_styles() -> String {
  @css.styles([
    ("font-size", "0.875rem"),
    ("font-weight", "500"),
    ("color", "#18181b"),
    ("line-height", "1"),
    ("cursor", "default"),
  ])
}

///|
/// Label disabled styles
pub fn label_disabled_styles() -> String {
  @css.styles([("opacity", "0.5"), ("cursor", "not-allowed")])
}

// =============================================================================
// Progress Styles
// =============================================================================

///|
/// Progress base styles
pub fn progress_base_styles() -> String {
  @css.styles([
    ("position", "relative"),
    ("height", "0.5rem"),
    ("width", "100%"),
    ("background", "#e4e4e7"),
    ("border-radius", "9999px"),
    ("overflow", "hidden"),
  ])
}

///|
/// Progress indicator styles
pub fn progress_indicator_styles() -> String {
  @css.styles([
    ("height", "100%"),
    ("width", "100%"),
    ("background", "#18181b"),
    ("transition", "transform 0.3s ease"),
  ])
}

// =============================================================================
// Skeleton Styles
// =============================================================================

///|
/// Skeleton base styles
pub fn skeleton_base_styles() -> String {
  @css.styles([
    ("background", "linear-gradient(90deg, #e4e4e7 25%, #f4f4f5 50%, #e4e4e7 75%)"),
    ("background-size", "200% 100%"),
  ])
}

///|
/// Skeleton shape styles
pub fn skeleton_shape_styles(shape : SkeletonShape) -> String {
  match shape {
    Rectangle =>
      @css.styles([("border-radius", "4px"), ("min-height", "1rem")])
    Circle =>
      @css.styles([
        ("border-radius", "50%"),
        ("width", "2.5rem"),
        ("height", "2.5rem"),
      ])
    Text => @css.styles([("border-radius", "2px"), ("height", "1em"), ("width", "100%")])
  }
}

// =============================================================================
// Alert Styles
// =============================================================================

///|
/// Alert base styles
pub fn alert_base_styles() -> String {
  @css.styles([
    ("position", "relative"),
    ("padding", "1rem"),
    ("border-radius", "8px"),
    ("border", "1px solid"),
  ])
}

///|
/// Alert variant styles
pub fn alert_variant_styles(variant : AlertVariant) -> String {
  match variant {
    Default =>
      @css.styles([
        ("background", "#fafafa"),
        ("border-color", "#e4e4e7"),
        ("color", "#18181b"),
      ])
    Destructive =>
      @css.styles([
        ("background", "#fef2f2"),
        ("border-color", "#fecaca"),
        ("color", "#991b1b"),
      ])
    Warning =>
      @css.styles([
        ("background", "#fffbeb"),
        ("border-color", "#fde68a"),
        ("color", "#92400e"),
      ])
    Success =>
      @css.styles([
        ("background", "#f0fdf4"),
        ("border-color", "#bbf7d0"),
        ("color", "#166534"),
      ])
  }
}

///|
/// Alert title styles
pub fn alert_title_styles() -> String {
  @css.styles([
    ("margin", "0 0 0.25rem 0"),
    ("font-size", "0.875rem"),
    ("font-weight", "500"),
    ("line-height", "1.4"),
  ])
}

///|
/// Alert description styles
pub fn alert_description_styles() -> String {
  @css.styles([("font-size", "0.875rem"), ("line-height", "1.5"), ("opacity", "0.9")])
}

// =============================================================================
// Tabs Styles
// =============================================================================

///|
/// Tabs base styles
pub fn tabs_base_styles() -> String {
  @css.styles([("display", "flex")])
}

///|
/// Tabs orientation styles
pub fn tabs_orientation_styles(orientation : Orientation) -> String {
  match orientation {
    Horizontal => @css.styles([("flex-direction", "column")])
    Vertical => @css.styles([("flex-direction", "row")])
  }
}

///|
/// Tabs list styles
pub fn tabs_list_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("gap", "0.25rem"),
    ("background", "#f4f4f5"),
    ("padding", "0.25rem"),
    ("border-radius", "6px"),
  ])
}

///|
/// Tabs trigger styles
pub fn tabs_trigger_styles() -> String {
  @css.styles([
    ("display", "inline-flex"),
    ("align-items", "center"),
    ("justify-content", "center"),
    ("padding", "0.5rem 0.75rem"),
    ("font-size", "0.875rem"),
    ("font-weight", "500"),
    ("background", "transparent"),
    ("border", "none"),
    ("border-radius", "4px"),
    ("color", "#71717a"),
    ("cursor", "pointer"),
    ("transition", "all 0.15s ease"),
  ])
}

///|
/// Tabs trigger focus styles
pub fn tabs_trigger_focus_styles() -> String {
  @css.on(":focus-visible", "outline", "2px solid #2563eb") +
  " " +
  @css.on(":focus-visible", "outline-offset", "2px")
}

///|
/// Tabs trigger active styles
pub fn tabs_trigger_active_styles() -> String {
  @css.styles([
    ("background", "white"),
    ("color", "#18181b"),
    ("box-shadow", "0 1px 2px rgba(0,0,0,0.1)"),
  ])
}

///|
/// Tabs content styles
pub fn tabs_content_styles() -> String {
  @css.styles([("padding", "1rem 0")])
}

// =============================================================================
// Accordion Styles
// =============================================================================

///|
/// Accordion base styles
pub fn accordion_base_styles() -> String {
  @css.styles([
    ("border", "1px solid #e4e4e7"),
    ("border-radius", "8px"),
    ("overflow", "hidden"),
  ])
}

///|
/// Accordion item styles
pub fn accordion_item_styles() -> String {
  @css.styles([("border-bottom", "1px solid #e4e4e7")])
}

///|
/// Accordion trigger styles
pub fn accordion_trigger_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("width", "100%"),
    ("align-items", "center"),
    ("justify-content", "space-between"),
    ("padding", "1rem"),
    ("font-size", "0.875rem"),
    ("font-weight", "500"),
    ("background", "transparent"),
    ("border", "none"),
    ("text-align", "left"),
    ("cursor", "pointer"),
    ("transition", "background 0.15s ease"),
  ])
}

///|
/// Accordion trigger focus styles
pub fn accordion_trigger_focus_styles() -> String {
  @css.on(":focus-visible", "outline", "2px solid #2563eb") +
  " " +
  @css.on(":focus-visible", "outline-offset", "-2px")
}

///|
/// Accordion content styles
pub fn accordion_content_styles() -> String {
  @css.styles([
    ("padding", "0 1rem 1rem"),
    ("font-size", "0.875rem"),
    ("color", "#71717a"),
  ])
}

// =============================================================================
// Dialog Styles
// =============================================================================

///|
/// Dialog overlay styles
pub fn dialog_overlay_styles() -> String {
  @css.styles([
    ("position", "fixed"),
    ("inset", "0"),
    ("background", "rgba(0,0,0,0.5)"),
    ("z-index", "50"),
  ])
}

///|
/// Dialog content styles
pub fn dialog_content_styles() -> String {
  @css.styles([
    ("position", "fixed"),
    ("left", "50%"),
    ("top", "50%"),
    ("transform", "translate(-50%, -50%)"),
    ("max-width", "32rem"),
    ("width", "100%"),
    ("max-height", "85vh"),
    ("background", "white"),
    ("border-radius", "8px"),
    ("box-shadow", "0 25px 50px -12px rgba(0,0,0,0.25)"),
    ("z-index", "51"),
    ("padding", "1.5rem"),
    ("overflow", "auto"),
  ])
}

///|
/// Dialog header styles
pub fn dialog_header_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("flex-direction", "column"),
    ("gap", "0.25rem"),
    ("margin-bottom", "1rem"),
  ])
}

///|
/// Dialog title styles
pub fn dialog_title_styles() -> String {
  @css.styles([
    ("margin", "0"),
    ("font-size", "1.125rem"),
    ("font-weight", "600"),
    ("color", "#18181b"),
  ])
}

///|
/// Dialog description styles
pub fn dialog_description_styles() -> String {
  @css.styles([("margin", "0"), ("font-size", "0.875rem"), ("color", "#71717a")])
}

///|
/// Dialog footer styles
pub fn dialog_footer_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("justify-content", "flex-end"),
    ("gap", "0.5rem"),
    ("margin-top", "1.5rem"),
  ])
}

// =============================================================================
// Tooltip Styles
// =============================================================================

///|
/// Tooltip base styles
pub fn tooltip_base_styles() -> String {
  @css.styles([("display", "inline-block"), ("position", "relative")])
}

///|
/// Tooltip trigger styles
pub fn tooltip_trigger_styles() -> String {
  @css.styles([("background", "transparent"), ("border", "none"), ("cursor", "pointer")])
}

///|
/// Tooltip content styles
pub fn tooltip_content_styles() -> String {
  @css.styles([
    ("position", "absolute"),
    ("z-index", "50"),
    ("padding", "0.375rem 0.75rem"),
    ("font-size", "0.75rem"),
    ("background", "#18181b"),
    ("color", "white"),
    ("border-radius", "4px"),
    ("white-space", "nowrap"),
    ("pointer-events", "none"),
  ])
}

///|
/// Tooltip side styles
pub fn tooltip_side_styles(side : TooltipSide) -> String {
  match side {
    Top =>
      @css.styles([
        ("bottom", "100%"),
        ("left", "50%"),
        ("transform", "translateX(-50%)"),
        ("margin-bottom", "0.5rem"),
      ])
    Bottom =>
      @css.styles([
        ("top", "100%"),
        ("left", "50%"),
        ("transform", "translateX(-50%)"),
        ("margin-top", "0.5rem"),
      ])
    Left =>
      @css.styles([
        ("right", "100%"),
        ("top", "50%"),
        ("transform", "translateY(-50%)"),
        ("margin-right", "0.5rem"),
      ])
    Right =>
      @css.styles([
        ("left", "100%"),
        ("top", "50%"),
        ("transform", "translateY(-50%)"),
        ("margin-left", "0.5rem"),
      ])
  }
}

// =============================================================================
// Popover Styles
// =============================================================================

///|
/// Popover base styles
pub fn popover_base_styles() -> String {
  @css.styles([("display", "inline-block"), ("position", "relative")])
}

///|
/// Popover trigger styles
pub fn popover_trigger_styles() -> String {
  @css.styles([("background", "transparent"), ("border", "none"), ("cursor", "pointer")])
}

///|
/// Popover content styles
pub fn popover_content_styles() -> String {
  @css.styles([
    ("position", "absolute"),
    ("z-index", "50"),
    ("min-width", "12rem"),
    ("padding", "1rem"),
    ("background", "white"),
    ("border", "1px solid #e4e4e7"),
    ("border-radius", "8px"),
    ("box-shadow", "0 4px 6px -1px rgba(0,0,0,0.1)"),
  ])
}

///|
/// Popover side styles
pub fn popover_side_styles(side : TooltipSide) -> String {
  match side {
    Top =>
      @css.styles([
        ("bottom", "100%"),
        ("left", "50%"),
        ("transform", "translateX(-50%)"),
        ("margin-bottom", "0.5rem"),
      ])
    Bottom =>
      @css.styles([
        ("top", "100%"),
        ("left", "50%"),
        ("transform", "translateX(-50%)"),
        ("margin-top", "0.5rem"),
      ])
    Left =>
      @css.styles([
        ("right", "100%"),
        ("top", "50%"),
        ("transform", "translateY(-50%)"),
        ("margin-right", "0.5rem"),
      ])
    Right =>
      @css.styles([
        ("left", "100%"),
        ("top", "50%"),
        ("transform", "translateY(-50%)"),
        ("margin-left", "0.5rem"),
      ])
  }
}

// =============================================================================
// DropdownMenu Styles
// =============================================================================

///|
/// DropdownMenu base styles
pub fn dropdown_menu_base_styles() -> String {
  @css.styles([("display", "inline-block"), ("position", "relative")])
}

///|
/// DropdownMenu trigger styles
pub fn dropdown_menu_trigger_styles() -> String {
  @css.styles([
    ("display", "inline-flex"),
    ("align-items", "center"),
    ("gap", "0.25rem"),
    ("background", "transparent"),
    ("border", "none"),
    ("cursor", "pointer"),
  ])
}

///|
/// DropdownMenu content styles
pub fn dropdown_menu_content_styles() -> String {
  @css.styles([
    ("position", "absolute"),
    ("top", "100%"),
    ("left", "0"),
    ("z-index", "50"),
    ("min-width", "8rem"),
    ("padding", "0.25rem"),
    ("background", "white"),
    ("border", "1px solid #e4e4e7"),
    ("border-radius", "6px"),
    ("box-shadow", "0 4px 6px -1px rgba(0,0,0,0.1)"),
  ])
}

///|
/// DropdownMenu item styles
pub fn dropdown_menu_item_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("align-items", "center"),
    ("gap", "0.5rem"),
    ("padding", "0.5rem 0.75rem"),
    ("font-size", "0.875rem"),
    ("border-radius", "4px"),
    ("cursor", "pointer"),
  ])
}

///|
/// DropdownMenu separator styles
pub fn dropdown_menu_separator_styles() -> String {
  @css.styles([
    ("height", "1px"),
    ("margin", "0.25rem -0.25rem"),
    ("background", "#e4e4e7"),
  ])
}

///|
/// DropdownMenu label styles
pub fn dropdown_menu_label_styles() -> String {
  @css.styles([
    ("padding", "0.5rem 0.75rem"),
    ("font-size", "0.75rem"),
    ("font-weight", "600"),
    ("color", "#71717a"),
  ])
}

// =============================================================================
// Slider Styles
// =============================================================================

///|
/// Slider base styles
pub fn slider_base_styles() -> String {
  @css.styles([
    ("position", "relative"),
    ("display", "flex"),
    ("align-items", "center"),
    ("width", "100%"),
    ("touch-action", "none"),
    ("user-select", "none"),
  ])
}

///|
/// Slider orientation styles
pub fn slider_orientation_styles(orientation : SliderOrientation) -> String {
  match orientation {
    Horizontal => @css.styles([("flex-direction", "row")])
    Vertical =>
      @css.styles([
        ("flex-direction", "column"),
        ("width", "auto"),
        ("height", "100%"),
      ])
  }
}

///|
/// Slider track styles
pub fn slider_track_styles() -> String {
  @css.styles([
    ("position", "relative"),
    ("flex-grow", "1"),
    ("height", "8px"),
    ("background", "#e4e4e7"),
    ("border-radius", "9999px"),
    ("overflow", "hidden"),
  ])
}

///|
/// Slider range styles
pub fn slider_range_styles() -> String {
  @css.styles([
    ("position", "absolute"),
    ("height", "100%"),
    ("background", "#18181b"),
    ("border-radius", "9999px"),
  ])
}

///|
/// Slider thumb styles
pub fn slider_thumb_styles() -> String {
  @css.styles([
    ("position", "absolute"),
    ("top", "50%"),
    ("width", "20px"),
    ("height", "20px"),
    ("background", "white"),
    ("border", "2px solid #18181b"),
    ("border-radius", "50%"),
    ("transform", "translate(-50%, -50%)"),
    ("cursor", "grab"),
  ])
}

// =============================================================================
// Sheet Styles
// =============================================================================

///|
/// Sheet overlay styles
pub fn sheet_overlay_styles() -> String {
  @css.styles([
    ("position", "fixed"),
    ("inset", "0"),
    ("background", "rgba(0,0,0,0.5)"),
    ("z-index", "50"),
  ])
}

///|
/// Sheet content styles
pub fn sheet_content_styles() -> String {
  @css.styles([
    ("position", "fixed"),
    ("z-index", "51"),
    ("background", "white"),
    ("box-shadow", "-4px 0 6px -1px rgba(0,0,0,0.1)"),
    ("padding", "1.5rem"),
    ("overflow", "auto"),
  ])
}

///|
/// Sheet side styles
pub fn sheet_side_styles(side : SheetSide) -> String {
  match side {
    Top =>
      @css.styles([
        ("top", "0"),
        ("left", "0"),
        ("right", "0"),
        ("height", "auto"),
        ("max-height", "75%"),
      ])
    Right =>
      @css.styles([
        ("top", "0"),
        ("right", "0"),
        ("height", "100%"),
        ("width", "75%"),
        ("max-width", "400px"),
      ])
    Bottom =>
      @css.styles([
        ("bottom", "0"),
        ("left", "0"),
        ("right", "0"),
        ("height", "auto"),
        ("max-height", "75%"),
      ])
    Left =>
      @css.styles([
        ("top", "0"),
        ("left", "0"),
        ("height", "100%"),
        ("width", "75%"),
        ("max-width", "400px"),
      ])
  }
}

///|
/// Sheet header styles
pub fn sheet_header_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("flex-direction", "column"),
    ("gap", "0.25rem"),
    ("margin-bottom", "1rem"),
  ])
}

///|
/// Sheet title styles
pub fn sheet_title_styles() -> String {
  @css.styles([
    ("margin", "0"),
    ("font-size", "1.125rem"),
    ("font-weight", "600"),
    ("color", "#18181b"),
  ])
}

///|
/// Sheet description styles
pub fn sheet_description_styles() -> String {
  @css.styles([("margin", "0"), ("font-size", "0.875rem"), ("color", "#71717a")])
}

///|
/// Sheet footer styles
pub fn sheet_footer_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("justify-content", "flex-end"),
    ("gap", "0.5rem"),
    ("margin-top", "1.5rem"),
  ])
}

// =============================================================================
// Toast Styles
// =============================================================================

///|
/// Toast viewport styles
pub fn toast_viewport_styles() -> String {
  @css.styles([
    ("position", "fixed"),
    ("bottom", "0"),
    ("right", "0"),
    ("display", "flex"),
    ("flex-direction", "column"),
    ("gap", "0.5rem"),
    ("padding", "1rem"),
    ("max-height", "100vh"),
    ("width", "100%"),
    ("max-width", "420px"),
    ("z-index", "100"),
  ])
}

///|
/// Toast base styles
pub fn toast_base_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("align-items", "flex-start"),
    ("gap", "0.75rem"),
    ("padding", "1rem"),
    ("background", "white"),
    ("border", "1px solid #e4e4e7"),
    ("border-radius", "8px"),
    ("box-shadow", "0 4px 6px -1px rgba(0,0,0,0.1)"),
  ])
}

///|
/// Toast variant styles
pub fn toast_variant_styles(variant : ToastVariant) -> String {
  match variant {
    Default => ""
    Destructive =>
      @css.styles([
        ("background", "#fef2f2"),
        ("border-color", "#fecaca"),
        ("color", "#991b1b"),
      ])
    Success =>
      @css.styles([
        ("background", "#f0fdf4"),
        ("border-color", "#bbf7d0"),
        ("color", "#166534"),
      ])
  }
}

///|
/// Toast title styles
pub fn toast_title_styles() -> String {
  @css.styles([("font-weight", "600"), ("font-size", "0.875rem")])
}

///|
/// Toast description styles
pub fn toast_description_styles() -> String {
  @css.styles([("font-size", "0.875rem"), ("color", "#71717a")])
}

///|
/// Toast action styles
pub fn toast_action_styles() -> String {
  @css.styles([
    ("padding", "0.25rem 0.75rem"),
    ("font-size", "0.75rem"),
    ("font-weight", "500"),
    ("background", "transparent"),
    ("border", "1px solid #e4e4e7"),
    ("border-radius", "4px"),
    ("cursor", "pointer"),
  ])
}

// =============================================================================
// AlertDialog Styles
// =============================================================================

///|
/// AlertDialog overlay styles
pub fn alert_dialog_overlay_styles() -> String {
  @css.styles([
    ("position", "fixed"),
    ("inset", "0"),
    ("background", "rgba(0,0,0,0.5)"),
    ("z-index", "50"),
  ])
}

///|
/// AlertDialog content styles
pub fn alert_dialog_content_styles() -> String {
  @css.styles([
    ("position", "fixed"),
    ("left", "50%"),
    ("top", "50%"),
    ("transform", "translate(-50%, -50%)"),
    ("max-width", "32rem"),
    ("width", "100%"),
    ("background", "white"),
    ("border-radius", "8px"),
    ("box-shadow", "0 25px 50px -12px rgba(0,0,0,0.25)"),
    ("z-index", "51"),
    ("padding", "1.5rem"),
  ])
}

///|
/// AlertDialog header styles
pub fn alert_dialog_header_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("flex-direction", "column"),
    ("gap", "0.5rem"),
    ("text-align", "center"),
  ])
}

///|
/// AlertDialog title styles
pub fn alert_dialog_title_styles() -> String {
  @css.styles([
    ("margin", "0"),
    ("font-size", "1.125rem"),
    ("font-weight", "600"),
    ("color", "#18181b"),
  ])
}

///|
/// AlertDialog description styles
pub fn alert_dialog_description_styles() -> String {
  @css.styles([("margin", "0"), ("font-size", "0.875rem"), ("color", "#71717a")])
}

///|
/// AlertDialog footer styles
pub fn alert_dialog_footer_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("justify-content", "center"),
    ("gap", "0.5rem"),
    ("margin-top", "1.5rem"),
  ])
}

///|
/// AlertDialog cancel button styles
pub fn alert_dialog_cancel_styles() -> String {
  @css.styles([
    ("padding", "0.5rem 1rem"),
    ("font-size", "0.875rem"),
    ("font-weight", "500"),
    ("background", "white"),
    ("border", "1px solid #e4e4e7"),
    ("border-radius", "6px"),
    ("cursor", "pointer"),
  ])
}

///|
/// AlertDialog action button styles
pub fn alert_dialog_action_styles() -> String {
  @css.styles([
    ("padding", "0.5rem 1rem"),
    ("font-size", "0.875rem"),
    ("font-weight", "500"),
    ("color", "white"),
    ("background", "#dc2626"),
    ("border", "none"),
    ("border-radius", "6px"),
    ("cursor", "pointer"),
  ])
}

// =============================================================================
// ScrollArea Styles
// =============================================================================

///|
/// ScrollArea base styles
pub fn scroll_area_base_styles() -> String {
  @css.styles([("position", "relative"), ("overflow", "hidden")])
}

///|
/// ScrollArea viewport styles
pub fn scroll_area_viewport_styles() -> String {
  @css.styles([
    ("width", "100%"),
    ("height", "100%"),
    ("overflow", "auto"),
    ("scrollbar-width", "none"),
  ])
}

///|
/// ScrollArea scrollbar styles
pub fn scroll_area_scrollbar_styles(orientation : ScrollOrientation) -> String {
  let base = @css.styles([
    ("display", "flex"),
    ("touch-action", "none"),
    ("user-select", "none"),
    ("padding", "2px"),
  ])
  let position = match orientation {
    Vertical =>
      @css.styles([
        ("position", "absolute"),
        ("top", "0"),
        ("right", "0"),
        ("height", "100%"),
        ("width", "10px"),
        ("flex-direction", "column"),
      ])
    Horizontal =>
      @css.styles([
        ("position", "absolute"),
        ("bottom", "0"),
        ("left", "0"),
        ("width", "100%"),
        ("height", "10px"),
        ("flex-direction", "row"),
      ])
    Both => ""
  }
  base + " " + position
}

///|
/// ScrollArea thumb styles
pub fn scroll_area_thumb_styles() -> String {
  @css.styles([
    ("flex", "1"),
    ("background", "rgba(0,0,0,0.3)"),
    ("border-radius", "9999px"),
  ])
}

// =============================================================================
// Collapsible Styles
// =============================================================================

///|
/// Collapsible base styles
pub fn collapsible_base_styles() -> String {
  @css.styles([("width", "100%")])
}

///|
/// Collapsible trigger styles
pub fn collapsible_trigger_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("width", "100%"),
    ("align-items", "center"),
    ("justify-content", "space-between"),
    ("padding", "0.75rem 1rem"),
    ("font-size", "0.875rem"),
    ("font-weight", "500"),
    ("background", "transparent"),
    ("border", "1px solid #e4e4e7"),
    ("border-radius", "6px"),
    ("cursor", "pointer"),
  ])
}

///|
/// Collapsible content styles
pub fn collapsible_content_styles() -> String {
  @css.styles([
    ("overflow", "hidden"),
    ("margin-top", "0.5rem"),
    ("padding", "0.75rem 1rem"),
    ("border", "1px solid #e4e4e7"),
    ("border-radius", "6px"),
    ("font-size", "0.875rem"),
  ])
}

// =============================================================================
// HoverCard Styles
// =============================================================================

///|
/// HoverCard base styles
pub fn hover_card_base_styles() -> String {
  @css.styles([("display", "inline-block"), ("position", "relative")])
}

///|
/// HoverCard trigger styles
pub fn hover_card_trigger_styles() -> String {
  @css.styles([("cursor", "pointer")])
}

///|
/// HoverCard content styles
pub fn hover_card_content_styles() -> String {
  @css.styles([
    ("position", "absolute"),
    ("z-index", "50"),
    ("min-width", "16rem"),
    ("padding", "1rem"),
    ("background", "white"),
    ("border", "1px solid #e4e4e7"),
    ("border-radius", "8px"),
    ("box-shadow", "0 10px 15px -3px rgba(0,0,0,0.1)"),
  ])
}

///|
/// HoverCard side styles
pub fn hover_card_side_styles(side : TooltipSide) -> String {
  tooltip_side_styles(side)
}

// =============================================================================
// Table Styles
// =============================================================================

///|
/// Table wrapper styles
pub fn table_wrapper_styles() -> String {
  @css.styles([("width", "100%"), ("overflow", "auto")])
}

///|
/// Table base styles
pub fn table_base_styles() -> String {
  @css.styles([
    ("width", "100%"),
    ("border-collapse", "collapse"),
    ("font-size", "0.875rem"),
  ])
}

///|
/// Table header styles
pub fn table_header_styles() -> String {
  @css.styles([("border-bottom", "1px solid #e4e4e7")])
}

///|
/// Table row styles
pub fn table_row_styles() -> String {
  @css.styles([("border-bottom", "1px solid #e4e4e7")])
}

///|
/// Table head cell styles
pub fn table_head_styles() -> String {
  @css.styles([
    ("padding", "0.75rem 1rem"),
    ("text-align", "left"),
    ("font-weight", "500"),
    ("color", "#71717a"),
  ])
}

///|
/// Table cell styles
pub fn table_cell_styles() -> String {
  @css.styles([("padding", "0.75rem 1rem"), ("vertical-align", "middle")])
}

///|
/// Table caption styles
pub fn table_caption_styles() -> String {
  @css.styles([
    ("margin-top", "0.5rem"),
    ("font-size", "0.875rem"),
    ("color", "#71717a"),
  ])
}

// =============================================================================
// Breadcrumb Styles
// =============================================================================

///|
/// Breadcrumb list styles
pub fn breadcrumb_list_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("flex-wrap", "wrap"),
    ("align-items", "center"),
    ("gap", "0.375rem"),
    ("list-style", "none"),
    ("margin", "0"),
    ("padding", "0"),
  ])
}

///|
/// Breadcrumb item styles
pub fn breadcrumb_item_styles() -> String {
  @css.styles([("display", "flex"), ("align-items", "center"), ("gap", "0.375rem")])
}

///|
/// Breadcrumb link styles
pub fn breadcrumb_link_styles() -> String {
  @css.styles([
    ("font-size", "0.875rem"),
    ("color", "#71717a"),
    ("text-decoration", "none"),
  ])
}

///|
/// Breadcrumb page styles
pub fn breadcrumb_page_styles() -> String {
  @css.styles([
    ("font-size", "0.875rem"),
    ("font-weight", "500"),
    ("color", "#18181b"),
  ])
}

///|
/// Breadcrumb separator styles
pub fn breadcrumb_separator_styles() -> String {
  @css.styles([("font-size", "0.875rem"), ("color", "#a1a1aa")])
}

// =============================================================================
// Pagination Styles
// =============================================================================

///|
/// Pagination base styles
pub fn pagination_base_styles() -> String {
  @css.styles([("display", "flex"), ("justify-content", "center")])
}

///|
/// Pagination content styles
pub fn pagination_content_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("align-items", "center"),
    ("gap", "0.25rem"),
    ("list-style", "none"),
    ("margin", "0"),
    ("padding", "0"),
  ])
}

///|
/// Pagination link styles
pub fn pagination_link_styles() -> String {
  @css.styles([
    ("display", "inline-flex"),
    ("align-items", "center"),
    ("justify-content", "center"),
    ("min-width", "2.25rem"),
    ("height", "2.25rem"),
    ("padding", "0 0.5rem"),
    ("font-size", "0.875rem"),
    ("text-decoration", "none"),
    ("color", "#18181b"),
    ("border", "1px solid #e4e4e7"),
    ("border-radius", "6px"),
  ])
}

///|
/// Pagination link active styles
pub fn pagination_link_active_styles() -> String {
  @css.styles([
    ("background", "#18181b"),
    ("color", "white"),
    ("border-color", "#18181b"),
  ])
}

///|
/// Pagination nav button styles
pub fn pagination_nav_styles() -> String {
  @css.styles([
    ("display", "inline-flex"),
    ("align-items", "center"),
    ("justify-content", "center"),
    ("min-width", "2.25rem"),
    ("height", "2.25rem"),
    ("padding", "0 0.5rem"),
    ("font-size", "0.875rem"),
    ("text-decoration", "none"),
    ("color", "#18181b"),
    ("border", "1px solid #e4e4e7"),
    ("border-radius", "6px"),
  ])
}

///|
/// Pagination ellipsis styles
pub fn pagination_ellipsis_styles() -> String {
  @css.styles([
    ("display", "inline-flex"),
    ("align-items", "center"),
    ("justify-content", "center"),
    ("min-width", "2.25rem"),
    ("height", "2.25rem"),
    ("font-size", "0.875rem"),
    ("color", "#71717a"),
  ])
}

// =============================================================================
// AspectRatio Styles
// =============================================================================

///|
/// AspectRatio outer styles
pub fn aspect_ratio_outer_styles() -> String {
  @css.styles([("position", "relative"), ("width", "100%")])
}

///|
/// AspectRatio inner styles
pub fn aspect_ratio_inner_styles() -> String {
  @css.styles([
    ("position", "absolute"),
    ("top", "0"),
    ("right", "0"),
    ("bottom", "0"),
    ("left", "0"),
  ])
}

// =============================================================================
// ContextMenu Styles
// =============================================================================

///|
/// ContextMenu content styles
pub fn context_menu_content_styles() -> String {
  @css.styles([
    ("position", "fixed"),
    ("z-index", "50"),
    ("min-width", "8rem"),
    ("padding", "0.25rem"),
    ("background", "white"),
    ("border", "1px solid #e4e4e7"),
    ("border-radius", "6px"),
    ("box-shadow", "0 4px 6px -1px rgba(0,0,0,0.1)"),
  ])
}

///|
/// ContextMenu item styles
pub fn context_menu_item_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("align-items", "center"),
    ("gap", "0.5rem"),
    ("padding", "0.5rem 0.75rem"),
    ("font-size", "0.875rem"),
    ("border-radius", "4px"),
    ("cursor", "pointer"),
  ])
}

///|
/// ContextMenu separator styles
pub fn context_menu_separator_styles() -> String {
  @css.styles([
    ("height", "1px"),
    ("margin", "0.25rem -0.25rem"),
    ("background", "#e4e4e7"),
  ])
}

///|
/// ContextMenu label styles
pub fn context_menu_label_styles() -> String {
  @css.styles([
    ("padding", "0.5rem 0.75rem"),
    ("font-size", "0.75rem"),
    ("font-weight", "600"),
    ("color", "#71717a"),
  ])
}

// =============================================================================
// NavigationMenu Styles
// =============================================================================

///|
/// NavigationMenu base styles
pub fn navigation_menu_base_styles() -> String {
  @css.styles([("position", "relative"), ("z-index", "10")])
}

///|
/// NavigationMenu list styles
pub fn navigation_menu_list_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("align-items", "center"),
    ("gap", "0.25rem"),
    ("list-style", "none"),
    ("margin", "0"),
    ("padding", "0"),
  ])
}

///|
/// NavigationMenu trigger styles
pub fn navigation_menu_trigger_styles() -> String {
  @css.styles([
    ("display", "inline-flex"),
    ("align-items", "center"),
    ("gap", "0.25rem"),
    ("padding", "0.5rem 0.75rem"),
    ("font-size", "0.875rem"),
    ("font-weight", "500"),
    ("background", "transparent"),
    ("border", "none"),
    ("border-radius", "4px"),
    ("cursor", "pointer"),
  ])
}

///|
/// NavigationMenu content styles
pub fn navigation_menu_content_styles() -> String {
  @css.styles([
    ("position", "absolute"),
    ("top", "100%"),
    ("left", "0"),
    ("min-width", "12rem"),
    ("padding", "0.5rem"),
    ("background", "white"),
    ("border", "1px solid #e4e4e7"),
    ("border-radius", "6px"),
    ("box-shadow", "0 4px 6px -1px rgba(0,0,0,0.1)"),
  ])
}

///|
/// NavigationMenu link styles
pub fn navigation_menu_link_styles() -> String {
  @css.styles([
    ("display", "block"),
    ("padding", "0.5rem 0.75rem"),
    ("font-size", "0.875rem"),
    ("text-decoration", "none"),
    ("color", "#18181b"),
    ("border-radius", "4px"),
  ])
}

// =============================================================================
// Menubar Styles
// =============================================================================

///|
/// Menubar base styles
pub fn menubar_base_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("align-items", "center"),
    ("gap", "0.25rem"),
    ("padding", "0.25rem"),
    ("background", "white"),
    ("border", "1px solid #e4e4e7"),
    ("border-radius", "6px"),
  ])
}

///|
/// Menubar trigger styles
pub fn menubar_trigger_styles() -> String {
  @css.styles([
    ("display", "inline-flex"),
    ("align-items", "center"),
    ("padding", "0.5rem 0.75rem"),
    ("font-size", "0.875rem"),
    ("font-weight", "500"),
    ("background", "transparent"),
    ("border", "none"),
    ("border-radius", "4px"),
    ("cursor", "pointer"),
  ])
}

///|
/// Menubar content styles
pub fn menubar_content_styles() -> String {
  @css.styles([
    ("position", "absolute"),
    ("top", "100%"),
    ("left", "0"),
    ("z-index", "50"),
    ("min-width", "12rem"),
    ("padding", "0.25rem"),
    ("background", "white"),
    ("border", "1px solid #e4e4e7"),
    ("border-radius", "6px"),
    ("box-shadow", "0 4px 6px -1px rgba(0,0,0,0.1)"),
  ])
}

///|
/// Menubar item styles
pub fn menubar_item_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("align-items", "center"),
    ("justify-content", "space-between"),
    ("padding", "0.5rem 0.75rem"),
    ("font-size", "0.875rem"),
    ("border-radius", "4px"),
    ("cursor", "pointer"),
  ])
}

///|
/// Menubar separator styles
pub fn menubar_separator_styles() -> String {
  @css.styles([
    ("height", "1px"),
    ("margin", "0.25rem -0.25rem"),
    ("background", "#e4e4e7"),
  ])
}

///|
/// Menubar shortcut styles
pub fn menubar_shortcut_styles() -> String {
  @css.styles([
    ("margin-left", "auto"),
    ("font-size", "0.75rem"),
    ("color", "#71717a"),
  ])
}

// =============================================================================
// ToggleGroup Styles
// =============================================================================

///|
/// ToggleGroup base styles
pub fn toggle_group_base_styles() -> String {
  @css.styles([
    ("display", "inline-flex"),
    ("align-items", "center"),
    ("border", "1px solid #e4e4e7"),
    ("border-radius", "6px"),
    ("overflow", "hidden"),
  ])
}

///|
/// ToggleGroup item styles
pub fn toggle_group_item_styles() -> String {
  @css.styles([
    ("display", "inline-flex"),
    ("align-items", "center"),
    ("justify-content", "center"),
    ("padding", "0.5rem 0.75rem"),
    ("font-size", "0.875rem"),
    ("font-weight", "500"),
    ("background", "transparent"),
    ("border", "none"),
    ("border-right", "1px solid #e4e4e7"),
    ("cursor", "pointer"),
  ])
}

///|
/// ToggleGroup item active styles
pub fn toggle_group_item_active_styles() -> String {
  @css.styles([("background", "#18181b"), ("color", "white")])
}

// =============================================================================
// Toolbar Styles
// =============================================================================

///|
/// Toolbar base styles
pub fn toolbar_base_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("align-items", "center"),
    ("gap", "0.25rem"),
    ("padding", "0.25rem"),
    ("background", "white"),
    ("border", "1px solid #e4e4e7"),
    ("border-radius", "6px"),
  ])
}

///|
/// Toolbar orientation styles
pub fn toolbar_orientation_styles(orientation : Orientation) -> String {
  match orientation {
    Horizontal => ""
    Vertical => @css.styles([("flex-direction", "column")])
  }
}

///|
/// Toolbar button styles
pub fn toolbar_button_styles() -> String {
  @css.styles([
    ("display", "inline-flex"),
    ("align-items", "center"),
    ("justify-content", "center"),
    ("padding", "0.5rem"),
    ("font-size", "0.875rem"),
    ("background", "transparent"),
    ("border", "none"),
    ("border-radius", "4px"),
    ("cursor", "pointer"),
  ])
}

///|
/// Toolbar separator styles
pub fn toolbar_separator_styles() -> String {
  @css.styles([
    ("width", "1px"),
    ("height", "1rem"),
    ("background", "#e4e4e7"),
    ("margin", "0 0.25rem"),
  ])
}

///|
/// Toolbar toggle item styles
pub fn toolbar_toggle_item_styles() -> String {
  @css.styles([
    ("display", "inline-flex"),
    ("align-items", "center"),
    ("justify-content", "center"),
    ("padding", "0.5rem"),
    ("font-size", "0.875rem"),
    ("background", "transparent"),
    ("border", "none"),
    ("border-radius", "4px"),
    ("cursor", "pointer"),
  ])
}

// =============================================================================
// Carousel Styles
// =============================================================================

///|
/// Carousel base styles
pub fn carousel_base_styles() -> String {
  @css.styles([("position", "relative"), ("width", "100%")])
}

///|
/// Carousel content styles
pub fn carousel_content_styles() -> String {
  @css.styles([("display", "flex"), ("overflow", "hidden")])
}

///|
/// Carousel item styles
pub fn carousel_item_styles() -> String {
  @css.styles([("flex", "0 0 100%"), ("min-width", "0")])
}

///|
/// Carousel nav button styles
pub fn carousel_nav_styles() -> String {
  @css.styles([
    ("display", "inline-flex"),
    ("align-items", "center"),
    ("justify-content", "center"),
    ("width", "2.5rem"),
    ("height", "2.5rem"),
    ("padding", "0"),
    ("background", "white"),
    ("border", "1px solid #e4e4e7"),
    ("border-radius", "50%"),
    ("cursor", "pointer"),
  ])
}

///|
/// Carousel dot styles
pub fn carousel_dot_styles() -> String {
  @css.styles([
    ("width", "0.5rem"),
    ("height", "0.5rem"),
    ("padding", "0"),
    ("background", "#d4d4d8"),
    ("border", "none"),
    ("border-radius", "50%"),
    ("cursor", "pointer"),
  ])
}

// =============================================================================
// Resizable Styles
// =============================================================================

///|
/// Resizable panel group styles
pub fn resizable_panel_group_styles(direction : ResizableDirection) -> String {
  let base = @css.styles([
    ("display", "flex"),
    ("width", "100%"),
    ("height", "100%"),
  ])
  let dir = match direction {
    Horizontal => @css.styles([("flex-direction", "row")])
    Vertical => @css.styles([("flex-direction", "column")])
  }
  base + " " + dir
}

///|
/// Resizable panel styles
pub fn resizable_panel_styles() -> String {
  @css.styles([("flex", "1"), ("overflow", "auto")])
}

///|
/// Resizable handle styles
pub fn resizable_handle_styles(direction : ResizableDirection) -> String {
  let base = @css.styles([
    ("flex", "0 0 auto"),
    ("display", "flex"),
    ("align-items", "center"),
    ("justify-content", "center"),
    ("background", "#e4e4e7"),
  ])
  let dir = match direction {
    Horizontal => @css.styles([("width", "4px"), ("cursor", "col-resize")])
    Vertical => @css.styles([("height", "4px"), ("cursor", "row-resize")])
  }
  base + " " + dir
}

// =============================================================================
// Command Styles
// =============================================================================

///|
/// Command base styles
pub fn command_base_styles() -> String {
  @css.styles([
    ("width", "100%"),
    ("max-width", "32rem"),
    ("background", "white"),
    ("border", "1px solid #e4e4e7"),
    ("border-radius", "8px"),
    ("overflow", "hidden"),
    ("box-shadow", "0 4px 6px -1px rgba(0,0,0,0.1)"),
  ])
}

///|
/// Command input styles
pub fn command_input_styles() -> String {
  @css.styles([
    ("width", "100%"),
    ("padding", "0.75rem 1rem"),
    ("font-size", "0.875rem"),
    ("background", "transparent"),
    ("border", "none"),
    ("border-bottom", "1px solid #e4e4e7"),
    ("outline", "none"),
  ])
}

///|
/// Command list styles
pub fn command_list_styles() -> String {
  @css.styles([
    ("max-height", "300px"),
    ("overflow", "auto"),
    ("padding", "0.25rem"),
  ])
}

///|
/// Command item styles
pub fn command_item_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("align-items", "center"),
    ("justify-content", "space-between"),
    ("padding", "0.5rem 0.75rem"),
    ("font-size", "0.875rem"),
    ("border-radius", "4px"),
    ("cursor", "pointer"),
  ])
}

///|
/// Command group heading styles
pub fn command_group_heading_styles() -> String {
  @css.styles([
    ("padding", "0.5rem 0.75rem"),
    ("font-size", "0.75rem"),
    ("font-weight", "500"),
    ("color", "#71717a"),
  ])
}

// =============================================================================
// Calendar Styles
// =============================================================================

///|
/// Calendar base styles
pub fn calendar_base_styles() -> String {
  @css.styles([
    ("padding", "0.75rem"),
    ("background", "white"),
    ("border", "1px solid #e4e4e7"),
    ("border-radius", "8px"),
  ])
}

///|
/// Calendar header styles
pub fn calendar_header_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("align-items", "center"),
    ("justify-content", "space-between"),
    ("margin-bottom", "0.5rem"),
  ])
}

///|
/// Calendar nav button styles
pub fn calendar_nav_button_styles() -> String {
  @css.styles([
    ("display", "inline-flex"),
    ("align-items", "center"),
    ("justify-content", "center"),
    ("width", "1.75rem"),
    ("height", "1.75rem"),
    ("padding", "0"),
    ("background", "transparent"),
    ("border", "1px solid #e4e4e7"),
    ("border-radius", "4px"),
    ("cursor", "pointer"),
  ])
}

///|
/// Calendar day styles
pub fn calendar_day_styles() -> String {
  @css.styles([
    ("width", "2rem"),
    ("height", "2rem"),
    ("padding", "0"),
    ("font-size", "0.875rem"),
    ("background", "transparent"),
    ("border", "none"),
    ("border-radius", "4px"),
    ("cursor", "pointer"),
  ])
}

// =============================================================================
// DatePicker Styles
// =============================================================================

///|
/// DatePicker base styles
pub fn date_picker_base_styles() -> String {
  @css.styles([("display", "inline-block"), ("position", "relative")])
}

///|
/// DatePicker trigger styles
pub fn date_picker_trigger_styles() -> String {
  @css.styles([
    ("display", "inline-flex"),
    ("align-items", "center"),
    ("gap", "0.5rem"),
    ("padding", "0.5rem 0.75rem"),
    ("font-size", "0.875rem"),
    ("background", "white"),
    ("border", "1px solid #e4e4e7"),
    ("border-radius", "6px"),
    ("cursor", "pointer"),
  ])
}

///|
/// DatePicker content styles
pub fn date_picker_content_styles() -> String {
  @css.styles([
    ("position", "absolute"),
    ("top", "100%"),
    ("left", "0"),
    ("z-index", "50"),
    ("margin-top", "0.25rem"),
  ])
}

// =============================================================================
// Combobox Styles
// =============================================================================

///|
/// Combobox base styles
pub fn combobox_base_styles() -> String {
  @css.styles([("display", "inline-block"), ("position", "relative")])
}

///|
/// Combobox trigger styles
pub fn combobox_trigger_styles() -> String {
  @css.styles([
    ("display", "inline-flex"),
    ("align-items", "center"),
    ("justify-content", "space-between"),
    ("min-width", "12rem"),
    ("padding", "0.5rem 0.75rem"),
    ("font-size", "0.875rem"),
    ("background", "white"),
    ("border", "1px solid #e4e4e7"),
    ("border-radius", "6px"),
    ("cursor", "pointer"),
  ])
}

///|
/// Combobox input styles
pub fn combobox_input_styles() -> String {
  @css.styles([
    ("width", "100%"),
    ("padding", "0.5rem 0.75rem"),
    ("font-size", "0.875rem"),
    ("background", "white"),
    ("border", "1px solid #e4e4e7"),
    ("border-radius", "6px"),
    ("outline", "none"),
  ])
}

///|
/// Combobox content styles
pub fn combobox_content_styles() -> String {
  @css.styles([
    ("position", "absolute"),
    ("top", "100%"),
    ("left", "0"),
    ("z-index", "50"),
    ("width", "100%"),
    ("min-width", "12rem"),
    ("max-height", "300px"),
    ("overflow", "auto"),
    ("padding", "0.25rem"),
    ("margin-top", "0.25rem"),
    ("background", "white"),
    ("border", "1px solid #e4e4e7"),
    ("border-radius", "6px"),
    ("box-shadow", "0 4px 6px -1px rgba(0,0,0,0.1)"),
  ])
}

///|
/// Combobox item styles
pub fn combobox_item_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("align-items", "center"),
    ("padding", "0.5rem 0.75rem"),
    ("font-size", "0.875rem"),
    ("border-radius", "4px"),
    ("cursor", "pointer"),
  ])
}

// =============================================================================
// Drawer Styles
// =============================================================================

///|
/// Drawer overlay styles
pub fn drawer_overlay_styles() -> String {
  @css.styles([
    ("position", "fixed"),
    ("inset", "0"),
    ("z-index", "50"),
    ("background", "rgba(0, 0, 0, 0.8)"),
  ])
}

///|
/// Drawer content styles
pub fn drawer_content_styles() -> String {
  @css.styles([
    ("position", "fixed"),
    ("z-index", "50"),
    ("display", "flex"),
    ("flex-direction", "column"),
    ("background", "white"),
    ("max-height", "96vh"),
  ])
}

///|
/// Drawer handle styles
pub fn drawer_handle_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("justify-content", "center"),
    ("padding", "0.5rem 0"),
  ])
}

///|
/// Drawer handle bar styles
pub fn drawer_handle_bar_styles() -> String {
  @css.styles([
    ("width", "3rem"),
    ("height", "0.25rem"),
    ("background", "#d4d4d8"),
    ("border-radius", "9999px"),
  ])
}

///|
/// Drawer header styles
pub fn drawer_header_styles() -> String {
  @css.styles([("padding", "1rem"), ("text-align", "center")])
}

///|
/// Drawer title styles
pub fn drawer_title_styles() -> String {
  @css.styles([
    ("font-size", "1.125rem"),
    ("font-weight", "600"),
    ("line-height", "1"),
    ("margin", "0"),
  ])
}

///|
/// Drawer footer styles
pub fn drawer_footer_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("flex-direction", "column"),
    ("gap", "0.5rem"),
    ("padding", "1rem"),
    ("margin-top", "auto"),
  ])
}

// =============================================================================
// Input OTP Styles
// =============================================================================

///|
/// Input OTP base styles
pub fn input_otp_base_styles() -> String {
  @css.styles([("display", "flex"), ("align-items", "center"), ("gap", "0.5rem")])
}

///|
/// Input OTP group styles
pub fn input_otp_group_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("align-items", "center"),
    ("gap", "0.25rem"),
  ])
}

///|
/// Input OTP slot styles
pub fn input_otp_slot_styles() -> String {
  @css.styles([
    ("position", "relative"),
    ("width", "2.5rem"),
    ("height", "2.5rem"),
    ("display", "flex"),
    ("align-items", "center"),
    ("justify-content", "center"),
    ("font-size", "1.125rem"),
    ("font-weight", "500"),
    ("border", "1px solid #e4e4e7"),
    ("border-radius", "6px"),
    ("background", "white"),
  ])
}

///|
/// Input OTP separator styles
pub fn input_otp_separator_styles() -> String {
  @css.styles([("color", "#a1a1aa"), ("font-size", "1.25rem")])
}

// =============================================================================
// Sidebar Styles
// =============================================================================

///|
/// Sidebar provider styles
pub fn sidebar_provider_styles() -> String {
  @css.styles([("display", "flex"), ("min-height", "100vh"), ("width", "100%")])
}

///|
/// Sidebar base styles
pub fn sidebar_base_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("flex-direction", "column"),
    ("width", "16rem"),
    ("background", "white"),
    ("border-right", "1px solid #e4e4e7"),
  ])
}

///|
/// Sidebar header styles
pub fn sidebar_header_styles() -> String {
  @css.styles([("padding", "1rem"), ("border-bottom", "1px solid #e4e4e7")])
}

///|
/// Sidebar content styles
pub fn sidebar_content_styles() -> String {
  @css.styles([("flex", "1"), ("overflow", "auto"), ("padding", "0.5rem")])
}

///|
/// Sidebar footer styles
pub fn sidebar_footer_styles() -> String {
  @css.styles([
    ("padding", "1rem"),
    ("border-top", "1px solid #e4e4e7"),
    ("margin-top", "auto"),
  ])
}

///|
/// Sidebar group label styles
pub fn sidebar_group_label_styles() -> String {
  @css.styles([
    ("padding", "0.5rem 0.75rem"),
    ("font-size", "0.75rem"),
    ("font-weight", "500"),
    ("color", "#71717a"),
    ("text-transform", "uppercase"),
    ("letter-spacing", "0.05em"),
  ])
}

///|
/// Sidebar menu button styles
pub fn sidebar_menu_button_styles() -> String {
  @css.styles([
    ("display", "flex"),
    ("align-items", "center"),
    ("gap", "0.5rem"),
    ("width", "100%"),
    ("padding", "0.5rem 0.75rem"),
    ("font-size", "0.875rem"),
    ("background", "transparent"),
    ("border", "none"),
    ("border-radius", "6px"),
    ("cursor", "pointer"),
    ("text-align", "left"),
    ("color", "#18181b"),
  ])
}
