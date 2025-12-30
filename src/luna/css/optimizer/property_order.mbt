// CSS Property Order Normalizer
// Provides consistent property ordering for better compression

/// Property category enum for grouping related properties
pub enum PropertyCategory {
  // Box model (outer to inner)
  Position     // position, top, right, bottom, left, z-index
  Display      // display, visibility, opacity
  BoxSizing    // box-sizing
  Margin       // margin-*
  Border       // border-*
  Padding      // padding-*
  Dimension    // width, height, min-*, max-*
  Overflow     // overflow-*
  // Flex/Grid
  Flex         // flex-*, align-*, justify-*
  Grid         // grid-*
  // Typography
  Font         // font-*
  Text         // text-*, letter-spacing, line-height, word-*
  Color        // color, background-*
  // Visual effects
  Transform    // transform, transform-origin
  Transition   // transition-*
  Animation    // animation-*
  // Other
  Cursor       // cursor, pointer-events
  Other        // everything else
} derive(Eq, Compare, Show)

/// Get property category for ordering
pub fn get_property_category(property : String) -> PropertyCategory {
  // Position
  if property == "position" ||
     property == "top" ||
     property == "right" ||
     property == "bottom" ||
     property == "left" ||
     property == "z-index" ||
     property == "inset" {
    return Position
  }

  // Display
  if property == "display" ||
     property == "visibility" ||
     property == "opacity" {
    return Display
  }

  // Box sizing
  if property == "box-sizing" {
    return BoxSizing
  }

  // Margin
  if property.has_prefix("margin") {
    return Margin
  }

  // Border
  if property.has_prefix("border") {
    return Border
  }

  // Padding
  if property.has_prefix("padding") {
    return Padding
  }

  // Dimensions
  if property == "width" ||
     property == "height" ||
     property.has_prefix("min-") ||
     property.has_prefix("max-") {
    return Dimension
  }

  // Overflow
  if property.has_prefix("overflow") {
    return Overflow
  }

  // Flex
  if property.has_prefix("flex") ||
     property.has_prefix("align-") ||
     property.has_prefix("justify-") ||
     property == "gap" ||
     property == "row-gap" ||
     property == "column-gap" ||
     property == "order" {
    return Flex
  }

  // Grid
  if property.has_prefix("grid") {
    return Grid
  }

  // Font
  if property.has_prefix("font") {
    return Font
  }

  // Text
  if property.has_prefix("text") ||
     property == "letter-spacing" ||
     property == "line-height" ||
     property.has_prefix("word-") ||
     property == "white-space" ||
     property == "vertical-align" {
    return Text
  }

  // Color
  if property == "color" || property.has_prefix("background") {
    return Color
  }

  // Transform
  if property.has_prefix("transform") {
    return Transform
  }

  // Transition
  if property.has_prefix("transition") {
    return Transition
  }

  // Animation
  if property.has_prefix("animation") {
    return Animation
  }

  // Cursor
  if property == "cursor" ||
     property == "pointer-events" ||
     property == "user-select" {
    return Cursor
  }

  Other
}

/// Canonical order within each category (sub-property index)
fn get_property_subindex(property : String) -> Int {
  // Position sub-ordering
  if property == "position" { return 0 }
  if property == "inset" { return 1 }
  if property == "top" { return 2 }
  if property == "right" { return 3 }
  if property == "bottom" { return 4 }
  if property == "left" { return 5 }
  if property == "z-index" { return 6 }

  // Display sub-ordering
  if property == "display" { return 0 }
  if property == "visibility" { return 1 }
  if property == "opacity" { return 2 }

  // Margin sub-ordering (shorthand first)
  if property == "margin" { return 0 }
  if property == "margin-top" { return 1 }
  if property == "margin-right" { return 2 }
  if property == "margin-bottom" { return 3 }
  if property == "margin-left" { return 4 }
  if property == "margin-inline" { return 5 }
  if property == "margin-block" { return 6 }

  // Padding sub-ordering (shorthand first)
  if property == "padding" { return 0 }
  if property == "padding-top" { return 1 }
  if property == "padding-right" { return 2 }
  if property == "padding-bottom" { return 3 }
  if property == "padding-left" { return 4 }
  if property == "padding-inline" { return 5 }
  if property == "padding-block" { return 6 }

  // Border sub-ordering
  if property == "border" { return 0 }
  if property == "border-width" { return 1 }
  if property == "border-style" { return 2 }
  if property == "border-color" { return 3 }
  if property == "border-radius" { return 10 }
  if property.has_prefix("border-top") { return 20 }
  if property.has_prefix("border-right") { return 30 }
  if property.has_prefix("border-bottom") { return 40 }
  if property.has_prefix("border-left") { return 50 }

  // Dimension sub-ordering
  if property == "width" { return 0 }
  if property == "min-width" { return 1 }
  if property == "max-width" { return 2 }
  if property == "height" { return 3 }
  if property == "min-height" { return 4 }
  if property == "max-height" { return 5 }

  // Flex sub-ordering
  if property == "flex" { return 0 }
  if property == "flex-direction" { return 1 }
  if property == "flex-wrap" { return 2 }
  if property == "flex-flow" { return 3 }
  if property == "flex-grow" { return 4 }
  if property == "flex-shrink" { return 5 }
  if property == "flex-basis" { return 6 }
  if property == "justify-content" { return 10 }
  if property == "align-items" { return 11 }
  if property == "align-content" { return 12 }
  if property == "align-self" { return 13 }
  if property == "gap" { return 20 }
  if property == "row-gap" { return 21 }
  if property == "column-gap" { return 22 }
  if property == "order" { return 30 }

  // Font sub-ordering
  if property == "font" { return 0 }
  if property == "font-family" { return 1 }
  if property == "font-size" { return 2 }
  if property == "font-weight" { return 3 }
  if property == "font-style" { return 4 }
  if property == "font-variant" { return 5 }

  // Text sub-ordering
  if property == "line-height" { return 0 }
  if property == "text-align" { return 1 }
  if property == "text-decoration" { return 2 }
  if property == "text-transform" { return 3 }
  if property == "text-indent" { return 4 }
  if property == "letter-spacing" { return 5 }
  if property == "word-spacing" { return 6 }
  if property == "white-space" { return 7 }

  // Color sub-ordering
  if property == "color" { return 0 }
  if property == "background" { return 1 }
  if property == "background-color" { return 2 }
  if property == "background-image" { return 3 }
  if property == "background-position" { return 4 }
  if property == "background-size" { return 5 }
  if property == "background-repeat" { return 6 }

  // Default: alphabetical fallback handled by caller
  100
}

/// Sort key for a CSS property (category * 1000 + subindex)
pub fn get_property_sort_key(property : String) -> Int {
  let category = get_property_category(property)
  let category_order = match category {
    Position => 0
    Display => 1
    BoxSizing => 2
    Margin => 3
    Border => 4
    Padding => 5
    Dimension => 6
    Overflow => 7
    Flex => 8
    Grid => 9
    Font => 10
    Text => 11
    Color => 12
    Transform => 13
    Transition => 14
    Animation => 15
    Cursor => 16
    Other => 17
  }

  let subindex = get_property_subindex(property)

  category_order * 1000 + subindex
}

/// Sort declarations by property order
pub fn sort_declarations(declarations : Array[Declaration]) -> Array[Declaration] {
  let result = declarations.copy()

  result.sort_by(fn(a, b) {
    let key_a = get_property_sort_key(a.property)
    let key_b = get_property_sort_key(b.property)
    if key_a != key_b {
      key_a - key_b
    } else {
      // Fallback to alphabetical for same category/subindex
      a.property.compare(b.property)
    }
  })

  result
}

/// Normalize a rule by sorting its declarations
pub fn normalize_rule_order(rule : Rule) -> Rule {
  { selector: rule.selector, declarations: sort_declarations(rule.declarations) }
}
