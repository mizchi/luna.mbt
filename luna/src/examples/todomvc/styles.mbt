// TodoMVC Styles - Luna CSS Utilities
// All dynamic styles are defined here for zero-runtime extraction

// =============================================================================
// Layout & Display
// =============================================================================

///|
pub let display_none : String = @css.css("display", "none")

///|
pub let display_block : String = @css.css("display", "block")

///|
pub let display_flex : String = @css.css("display", "flex")

///|
pub let display_inline : String = @css.css("display", "inline")

///|
pub let display_inline_block : String = @css.css("display", "inline-block")

// Position

///|
pub let position_relative : String = @css.css("position", "relative")

///|
pub let position_absolute : String = @css.css("position", "absolute")

// Flexbox

///|
pub let align_items_center : String = @css.css("align-items", "center")

///|
pub let justify_content_center : String = @css.css("justify-content", "center")

// =============================================================================
// Sizing
// =============================================================================

///|
pub let width_full : String = @css.css("width", "100%")

///|
pub let width_40 : String = @css.css("width", "40px")

///|
pub let width_45 : String = @css.css("width", "45px")

///|
pub let height_40 : String = @css.css("height", "40px")

///|
pub let height_65 : String = @css.css("height", "65px")

///|
pub let height_auto : String = @css.css("height", "auto")

///|
pub let height_full : String = @css.css("height", "100%")

// =============================================================================
// Spacing
// =============================================================================

// Margin

///|
pub let margin_0 : String = @css.css("margin", "0")

///|
pub let margin_auto : String = @css.css("margin", "auto 0")

///|
pub let margin_top_130 : String = @css.css("margin-top", "130px")

///|
pub let margin_bottom_40 : String = @css.css("margin-bottom", "40px")

///|
pub let margin_bottom_neg1 : String = @css.css("margin-bottom", "-1px")

// Padding

///|
pub let padding_0 : String = @css.css("padding", "0")

///|
pub let padding_6 : String = @css.css("padding", "6px")

///|
pub let padding_3_7 : String = @css.css("padding", "3px 7px")

///|
pub let padding_10_15 : String = @css.css("padding", "10px 15px")

///|
pub let padding_15_60 : String = @css.css("padding", "15px 15px 15px 60px")

///|
pub let padding_16_60 : String = @css.css("padding", "16px 16px 16px 60px")

///|
pub let padding_12_16 : String = @css.css("padding", "12px 16px")

// =============================================================================
// Typography
// =============================================================================

// Font size

///|
pub let font_size_11 : String = @css.css("font-size", "11px")

///|
pub let font_size_14 : String = @css.css("font-size", "14px")

///|
pub let font_size_15 : String = @css.css("font-size", "15px")

///|
pub let font_size_22 : String = @css.css("font-size", "22px")

///|
pub let font_size_24 : String = @css.css("font-size", "24px")

///|
pub let font_size_30 : String = @css.css("font-size", "30px")

///|
pub let font_size_80 : String = @css.css("font-size", "80px")

///|
pub let font_size_0 : String = @css.css("font-size", "0")

// Font weight

///|
pub let font_weight_200 : String = @css.css("font-weight", "200")

///|
pub let font_weight_300 : String = @css.css("font-weight", "300")

///|
pub let font_weight_400 : String = @css.css("font-weight", "400")

// Line height

///|
pub let line_height_1 : String = @css.css("line-height", "1")

///|
pub let line_height_1_1 : String = @css.css("line-height", "1.1")

///|
pub let line_height_1_2 : String = @css.css("line-height", "1.2")

///|
pub let line_height_1_4 : String = @css.css("line-height", "1.4em")

///|
pub let line_height_19 : String = @css.css("line-height", "19px")

// Text

///|
pub let text_align_center : String = @css.css("text-align", "center")

///|
pub let text_align_left : String = @css.css("text-align", "left")

///|
pub let text_decoration_none : String = @css.css("text-decoration", "none")

///|
pub let text_decoration_line_through : String = @css.css(
  "text-decoration", "line-through",
)

///|
pub let text_decoration_underline : String = @css.css(
  "text-decoration", "underline",
)

///|
pub let word_break_all : String = @css.css("word-break", "break-all")

// =============================================================================
// Colors
// =============================================================================

// Text colors

///|
pub let color_inherit : String = @css.css("color", "inherit")

///|
pub let color_dark : String = @css.css("color", "#111111")

///|
pub let color_text : String = @css.css("color", "#484848")

///|
pub let color_muted : String = @css.css("color", "#949494")

///|
pub let color_title : String = @css.css("color", "#b83f45")

///|
pub let color_danger : String = @css.css("color", "#C18585")

///|
pub let color_info : String = @css.css("color", "#4d4d4d")

// Background colors

///|
pub let bg_white : String = @css.css("background", "#fff")

///|
pub let bg_body : String = @css.css("background", "#f5f5f5")

///|
pub let bg_none : String = @css.css("background", "none")

///|
pub let bg_transparent : String = @css.css("background", "rgba(0, 0, 0, 0.003)")

// =============================================================================
// Borders
// =============================================================================

///|
pub let border_none : String = @css.css("border", "none")

///|
pub let border_0 : String = @css.css("border", "0")

///|
pub let border_1_solid_999 : String = @css.css("border", "1px solid #999")

///|
pub let border_1_transparent : String = @css.css(
  "border", "1px solid transparent",
)

///|
pub let border_top_1_e6 : String = @css.css("border-top", "1px solid #e6e6e6")

///|
pub let border_bottom_1_ed : String = @css.css(
  "border-bottom", "1px solid #ededed",
)

///|
pub let border_bottom_none : String = @css.css("border-bottom", "none")

///|
pub let border_radius_3 : String = @css.css("border-radius", "3px")

// Border colors

///|
pub let border_color_transparent : String = @css.css(
  "border-color", "transparent",
)

///|
pub let border_color_selected : String = @css.css("border-color", "#CE4646")

///|
pub let border_color_hover : String = @css.css("border-color", "#DB7676")

// =============================================================================
// Shadows
// =============================================================================

///|
pub let box_shadow_app : String = @css.css(
  "box-shadow", "0 2px 4px 0 rgba(0, 0, 0, 0.2), 0 25px 50px 0 rgba(0, 0, 0, 0.1)",
)

///|
pub let box_shadow_input : String = @css.css(
  "box-shadow", "inset 0 -1px 5px 0 rgba(0, 0, 0, 0.2)",
)

///|
pub let box_shadow_new_todo : String = @css.css(
  "box-shadow", "inset 0 -2px 1px rgba(0,0,0,0.03)",
)

// =============================================================================
// Positioning
// =============================================================================

///|
pub let top_0 : String = @css.css("top", "0")

///|
pub let top_neg_65 : String = @css.css("top", "-65px")

///|
pub let top_neg_140 : String = @css.css("top", "-140px")

///|
pub let right_0 : String = @css.css("right", "0")

///|
pub let right_10 : String = @css.css("right", "10px")

///|
pub let bottom_0 : String = @css.css("bottom", "0")

///|
pub let left_0 : String = @css.css("left", "0")

// =============================================================================
// Visual Effects
// =============================================================================

///|
pub let opacity_0 : String = @css.css("opacity", "0")

///|
pub let cursor_pointer : String = @css.css("cursor", "pointer")

///|
pub let list_style_none : String = @css.css("list-style", "none")

///|
pub let z_index_2 : String = @css.css("z-index", "2")

// =============================================================================
// Transitions
// =============================================================================

///|
pub let transition_color : String = @css.css("transition", "color 0.4s")

///|
pub let transition_color_fast : String = @css.css(
  "transition", "color 0.2s ease-out",
)

///|
pub let transition_border : String = @css.css(
  "transition", "color 0.2s, border-color 0.2s",
)

// =============================================================================
// Float
// =============================================================================

///|
pub let float_left : String = @css.css("float", "left")

///|
pub let float_right : String = @css.css("float", "right")

// =============================================================================
// Box sizing
// =============================================================================

///|
pub let box_sizing_border : String = @css.css("box-sizing", "border-box")

// =============================================================================
// Hover States
// =============================================================================

///|
pub let hover_border_color : String = @css.hover("border-color", "#DB7676")

///|
pub let hover_underline : String = @css.hover("text-decoration", "underline")

///|
pub let hover_color_danger : String = @css.hover("color", "#C18585")

///|
pub let hover_display_block : String = @css.hover("display", "block")

// =============================================================================
// Focus States
// =============================================================================

///|
pub let focus_outline_none : String = @css.focus("outline", "none")

///|
pub let focus_color_danger : String = @css.focus("color", "#C18585")

// =============================================================================
// Active States
// =============================================================================

// (none currently needed)

// =============================================================================
// Utility Functions
// =============================================================================

///|
/// Combine multiple class names
pub fn classes(arr : Array[String]) -> String {
  arr.filter(fn(s) { s.length() > 0 }).join(" ")
}

///|
/// Conditional class
pub fn when(condition : Bool, cls : String) -> String {
  if condition {
    cls
  } else {
    ""
  }
}
