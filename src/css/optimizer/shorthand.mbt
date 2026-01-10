// CSS Shorthand Expansion and Compression
// Handles expanding shorthand properties to longhand and vice versa

///|
/// Shorthand property definitions
pub struct ShorthandDef {
  /// Shorthand property name (e.g., "margin")
  shorthand : String
  /// Longhand property names in order
  longhands : Array[String]
} derive(Show)

///|
/// Get shorthand definitions for box properties (margin, padding)
fn get_box_shorthand_def(shorthand : String) -> ShorthandDef {
  let longhands = [
    shorthand + "-top",
    shorthand + "-right",
    shorthand + "-bottom",
    shorthand + "-left",
  ]
  { shorthand, longhands }
}

///|
/// Get border-radius shorthand definition
fn get_border_radius_shorthand_def() -> ShorthandDef {
  {
    shorthand: "border-radius",
    longhands: [
      "border-top-left-radius", "border-top-right-radius", "border-bottom-right-radius",
      "border-bottom-left-radius",
    ],
  }
}

///|
/// Parse box shorthand value (1-4 values pattern)
/// "10px" -> [10px, 10px, 10px, 10px]
/// "10px 20px" -> [10px, 20px, 10px, 20px]
/// "10px 20px 30px" -> [10px, 20px, 30px, 20px]
/// "10px 20px 30px 40px" -> [10px, 20px, 30px, 40px]
fn parse_box_shorthand_value(value : String) -> Array[String] {
  let parts = split_css_value(value)
  let n = parts.length()
  if n == 0 {
    return ["0", "0", "0", "0"]
  }
  if n == 1 {
    return [parts[0], parts[0], parts[0], parts[0]]
  }
  if n == 2 {
    return [parts[0], parts[1], parts[0], parts[1]]
  }
  if n == 3 {
    return [parts[0], parts[1], parts[2], parts[1]]
  }

  // n >= 4
  [parts[0], parts[1], parts[2], parts[3]]
}

///|
/// Split CSS value by whitespace (simple tokenizer)
fn split_css_value(value : String) -> Array[String] {
  let result : Array[String] = []
  let current = StringBuilder::new()
  let mut in_parens = 0
  let paren_open : UInt16 = 40 // '('
  let paren_close : UInt16 = 41 // ')'
  let space : UInt16 = 32 // ' '
  for i = 0; i < value.length(); i = i + 1 {
    let c = value[i]
    if c == paren_open {
      in_parens = in_parens + 1
      current.write_char(c.to_int().unsafe_to_char())
    } else if c == paren_close {
      in_parens = in_parens - 1
      current.write_char(c.to_int().unsafe_to_char())
    } else if c == space && in_parens == 0 {
      let token = current.to_string()
      if token.length() > 0 {
        result.push(token)
      }
      current.reset()
    } else {
      current.write_char(c.to_int().unsafe_to_char())
    }
  }
  let final_token = current.to_string()
  if final_token.length() > 0 {
    result.push(final_token)
  }
  result
}

///|
/// Expand a shorthand declaration to longhand declarations
pub fn expand_shorthand(decl : Declaration) -> Array[Declaration] {
  let prop = decl.property
  let val = decl.value

  // Margin shorthand
  if prop == "margin" {
    let def = get_box_shorthand_def("margin")
    let values = parse_box_shorthand_value(val)
    let result : Array[Declaration] = []
    for i = 0; i < 4; i = i + 1 {
      result.push({ property: def.longhands[i], value: values[i] })
    }
    return result
  }

  // Padding shorthand
  if prop == "padding" {
    let def = get_box_shorthand_def("padding")
    let values = parse_box_shorthand_value(val)
    let result : Array[Declaration] = []
    for i = 0; i < 4; i = i + 1 {
      result.push({ property: def.longhands[i], value: values[i] })
    }
    return result
  }

  // Border-radius shorthand
  if prop == "border-radius" {
    let def = get_border_radius_shorthand_def()
    let values = parse_box_shorthand_value(val)
    let result : Array[Declaration] = []
    for i = 0; i < 4; i = i + 1 {
      result.push({ property: def.longhands[i], value: values[i] })
    }
    return result
  }

  // Gap shorthand
  if prop == "gap" {
    let parts = split_css_value(val)
    if parts.length() == 1 {
      return [
        { property: "row-gap", value: parts[0] },
        { property: "column-gap", value: parts[0] },
      ]
    }
    if parts.length() >= 2 {
      return [
        { property: "row-gap", value: parts[0] },
        { property: "column-gap", value: parts[1] },
      ]
    }
    return [decl]
  }

  // Inset shorthand (like margin/padding)
  if prop == "inset" {
    let values = parse_box_shorthand_value(val)
    return [
      { property: "top", value: values[0] },
      { property: "right", value: values[1] },
      { property: "bottom", value: values[2] },
      { property: "left", value: values[3] },
    ]
  }

  // Not a shorthand we handle, return as-is
  [decl]
}

///|
/// Check if declarations can be compressed to a box shorthand
fn can_compress_box_shorthand(
  decls : Map[String, String],
  prefix : String,
) -> Bool {
  decls.contains(prefix + "-top") &&
  decls.contains(prefix + "-right") &&
  decls.contains(prefix + "-bottom") &&
  decls.contains(prefix + "-left")
}

///|
/// Compress 4 box values to shorthand format
fn compress_box_values(
  top : String,
  right : String,
  bottom : String,
  left : String,
) -> String {
  // All same: "10px"
  if top == right && right == bottom && bottom == left {
    return top
  }

  // Top/bottom same, left/right same: "10px 20px"
  if top == bottom && right == left {
    return top + " " + right
  }

  // Left/right same: "10px 20px 30px"
  if right == left {
    return top + " " + right + " " + bottom
  }

  // All different: "10px 20px 30px 40px"
  top + " " + right + " " + bottom + " " + left
}

///|
/// Try to compress longhand declarations to shorthands
pub fn compress_to_shorthands(
  declarations : Array[Declaration],
) -> Array[Declaration] {
  // Build property -> value map
  let decl_map : Map[String, String] = {}
  for d in declarations {
    decl_map[d.property] = d.value
  }
  let result : Array[Declaration] = []
  let used : Map[String, Bool] = {}

  // Try margin shorthand
  if can_compress_box_shorthand(decl_map, "margin") {
    let top = decl_map.get("margin-top").unwrap()
    let right = decl_map.get("margin-right").unwrap()
    let bottom = decl_map.get("margin-bottom").unwrap()
    let left = decl_map.get("margin-left").unwrap()
    result.push({
      property: "margin",
      value: compress_box_values(top, right, bottom, left),
    })
    used["margin-top"] = true
    used["margin-right"] = true
    used["margin-bottom"] = true
    used["margin-left"] = true
  }

  // Try padding shorthand
  if can_compress_box_shorthand(decl_map, "padding") {
    let top = decl_map.get("padding-top").unwrap()
    let right = decl_map.get("padding-right").unwrap()
    let bottom = decl_map.get("padding-bottom").unwrap()
    let left = decl_map.get("padding-left").unwrap()
    result.push({
      property: "padding",
      value: compress_box_values(top, right, bottom, left),
    })
    used["padding-top"] = true
    used["padding-right"] = true
    used["padding-bottom"] = true
    used["padding-left"] = true
  }

  // Try border-radius shorthand
  if decl_map.contains("border-top-left-radius") &&
    decl_map.contains("border-top-right-radius") &&
    decl_map.contains("border-bottom-right-radius") &&
    decl_map.contains("border-bottom-left-radius") {
    let tl = decl_map.get("border-top-left-radius").unwrap()
    let tr = decl_map.get("border-top-right-radius").unwrap()
    let br = decl_map.get("border-bottom-right-radius").unwrap()
    let bl = decl_map.get("border-bottom-left-radius").unwrap()
    result.push({
      property: "border-radius",
      value: compress_box_values(tl, tr, br, bl),
    })
    used["border-top-left-radius"] = true
    used["border-top-right-radius"] = true
    used["border-bottom-right-radius"] = true
    used["border-bottom-left-radius"] = true
  }

  // Try gap shorthand
  if decl_map.contains("row-gap") && decl_map.contains("column-gap") {
    let row = decl_map.get("row-gap").unwrap()
    let col = decl_map.get("column-gap").unwrap()
    if row == col {
      result.push({ property: "gap", value: row })
    } else {
      result.push({ property: "gap", value: row + " " + col })
    }
    used["row-gap"] = true
    used["column-gap"] = true
  }

  // Try inset shorthand
  if decl_map.contains("top") &&
    decl_map.contains("right") &&
    decl_map.contains("bottom") &&
    decl_map.contains("left") {
    let top = decl_map.get("top").unwrap()
    let right = decl_map.get("right").unwrap()
    let bottom = decl_map.get("bottom").unwrap()
    let left = decl_map.get("left").unwrap()
    result.push({
      property: "inset",
      value: compress_box_values(top, right, bottom, left),
    })
    used["top"] = true
    used["right"] = true
    used["bottom"] = true
    used["left"] = true
  }

  // Add remaining declarations that weren't compressed
  for d in declarations {
    if not(used.contains(d.property)) {
      result.push(d)
    }
  }
  result
}

///|
/// Normalize declarations by expanding shorthands, sorting, then re-compressing
pub fn normalize_declarations(
  declarations : Array[Declaration],
) -> Array[Declaration] {
  // Step 1: Expand all shorthands
  let expanded : Array[Declaration] = []
  for d in declarations {
    for exp in expand_shorthand(d) {
      expanded.push(exp)
    }
  }

  // Step 2: Sort by property order
  let sorted = sort_declarations(expanded)

  // Step 3: Re-compress to shorthands
  compress_to_shorthands(sorted)
}
