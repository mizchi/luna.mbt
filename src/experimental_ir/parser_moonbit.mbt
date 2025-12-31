/// MoonBit source code parser for IR extraction
///
/// Parses MoonBit source code and extracts type definitions marked with
/// special annotations (e.g., `/// @island`).

// =============================================================================
// Parser Types
// =============================================================================

/// Result of parsing MoonBit source
pub struct ParseResult {
  /// Extracted schema
  schema : Schema
  /// Parser errors
  errors : Array[ParseError]
} derive(Show)

/// Parse error
pub struct ParseError {
  /// Line number (1-based)
  line : Int
  /// Error message
  message : String
} derive(Show, Eq)

// =============================================================================
// Main Parser
// =============================================================================

/// Parse MoonBit source code and extract IR schema
pub fn parse_moonbit(source : String) -> ParseResult {
  parse_moonbit_with_options(source, file="<input>")
}

/// Parse MoonBit source code with options
pub fn parse_moonbit_with_options(
  source : String,
  file~ : String
) -> ParseResult {
  let schema : Schema = {
    version: "1.0",
    definitions: {},
    source: Some({ file, lang: MoonBit }),
  }
  let errors : Array[ParseError] = []

  let lines = source.split("\n").to_array()
  let mut i = 0
  let mut pending_doc : String? = None
  let mut pending_annotations : Array[String] = []

  while i < lines.length() {
    let line_view = lines[i]
    let line = line_view.to_string().trim(chars=" \t").to_string()

    // Doc comment
    if line.has_prefix("///") {
      let content = safe_substring(line, 3).trim(chars=" ").to_string()

      // Check for annotation
      if content.has_prefix("@") {
        pending_annotations.push(safe_substring(content, 1))
      } else {
        // Regular doc comment
        match pending_doc {
          Some(doc) => pending_doc = Some(doc + "\n" + content)
          None => pending_doc = Some(content)
        }
      }
      i = i + 1
      continue
    }

    // Check for struct definition
    if line.has_prefix("pub struct ") || line.has_prefix("struct ") {
      // Only process if marked with @island annotation
      if pending_annotations.iter().any(fn(a) { a == "island" }) {
        match parse_struct_def(lines, i, pending_doc) {
          Ok((struct_def, end_line)) => {
            schema.definitions[struct_def.name] = Struct(struct_def)
            i = end_line
          }
          Err(err) => {
            errors.push({ line: i + 1, message: err })
            i = i + 1
          }
        }
      } else {
        i = i + 1
      }
      pending_doc = None
      pending_annotations = []
      continue
    }

    // Check for enum definition
    if line.has_prefix("pub enum ") || line.has_prefix("enum ") {
      if pending_annotations.iter().any(fn(a) { a == "island" }) {
        match parse_enum_def(lines, i, pending_doc) {
          Ok((enum_def, end_line)) => {
            schema.definitions[enum_def.name] = Enum(enum_def)
            i = end_line
          }
          Err(err) => {
            errors.push({ line: i + 1, message: err })
            i = i + 1
          }
        }
      } else {
        i = i + 1
      }
      pending_doc = None
      pending_annotations = []
      continue
    }

    // Check for type alias
    if line.has_prefix("pub typealias ") || line.has_prefix("typealias ") {
      if pending_annotations.iter().any(fn(a) { a == "island" }) {
        match parse_alias_def(line, pending_doc) {
          Ok(alias_def) => {
            schema.definitions[alias_def.name] = Alias(alias_def)
          }
          Err(err) => {
            errors.push({ line: i + 1, message: err })
          }
        }
      }
      pending_doc = None
      pending_annotations = []
      i = i + 1
      continue
    }

    // Reset pending state for other non-empty lines
    if line.length() > 0 && not(line.has_prefix("//")) && not(line.has_prefix("/*")) {
      pending_doc = None
      pending_annotations = []
    }

    i = i + 1
  }

  { schema, errors }
}

// =============================================================================
// Struct Parser
// =============================================================================

/// Parse a struct definition starting at the given line
fn parse_struct_def(
  lines : Array[StringView],
  start : Int,
  doc : String?
) -> Result[(StructDef, Int), String] {
  let line = lines[start].to_string().trim(chars=" \t").to_string()

  // Extract struct name
  let prefix_len = if line.has_prefix("pub struct ") { 11 } else { 7 }
  let rest = safe_substring(line, prefix_len)

  // Find struct name (up to space, [ or {)
  let name = extract_identifier(rest)
  if name.length() == 0 {
    return Err("Expected struct name")
  }

  // Check if this line has opening brace
  let has_brace = line.contains("{")
  if not(has_brace) {
    // Look for opening brace on next lines
    let mut j = start + 1
    while j < lines.length() {
      let l = lines[j].to_string().trim(chars=" \t").to_string()
      if l.has_prefix("{") {
        break
      }
      if l.length() > 0 && not(l.has_prefix("//")) {
        return Err("Expected '{' for struct body")
      }
      j = j + 1
    }
  }

  // Parse fields
  let fields : Array[Field] = []
  let mut i = start + 1
  let mut found_close = false

  while i < lines.length() {
    let l = lines[i].to_string().trim(chars=" \t").to_string()

    // Skip empty lines and comments
    if l.length() == 0 || l.has_prefix("//") {
      i = i + 1
      continue
    }

    // Check for closing brace (may have derive clause)
    if l.has_prefix("}") {
      found_close = true
      i = i + 1
      break
    }

    // Parse field
    match parse_field(l) {
      Ok(field) => fields.push(field)
      Err(_) => () // Skip unparseable lines
    }

    i = i + 1
  }

  if not(found_close) {
    return Err("Unclosed struct definition")
  }

  // Parse derives from the line with closing brace
  let derives : Array[String] = []
  if i > 0 && i - 1 < lines.length() {
    let close_line = lines[i - 1].to_string()
    if close_line.contains("derive(") {
      let derive_idx = find_substring(close_line, "derive(")
      match derive_idx {
        Some(idx) => {
          let derive_str = safe_substring(close_line, idx + 7)
          let end_idx = find_char(derive_str, ')')
          match end_idx {
            Some(end) => {
              let derives_content = derive_str[0:end].to_string() catch { _ => "" }
              for d in derives_content.split(",") {
                let trimmed = d.to_string().trim(chars=" \t").to_string()
                if trimmed.length() > 0 {
                  derives.push(trimmed)
                }
              }
            }
            None => ()
          }
        }
        None => ()
      }
    }
  }

  let struct_def : StructDef = {
    name,
    doc,
    type_params: [],
    fields,
    derives,
  }

  Ok((struct_def, i))
}

// =============================================================================
// Field Parser
// =============================================================================

/// Parse a single field definition
fn parse_field(line : String) -> Result[Field, String] {
  // Skip lines that don't look like fields
  if line.has_prefix("//") || line.has_prefix("{") || line.has_prefix("}") {
    return Err("Not a field")
  }

  // Find the colon separator
  let colon_idx = find_char(line, ':')
  match colon_idx {
    None => Err("No colon in field definition")
    Some(idx) => {
      let name = (line[0:idx].to_string() catch { _ => "" }).trim(chars=" \t").to_string()
      let type_str = safe_substring(line, idx + 1).trim(chars=" \t").to_string()

      // Check for optional marker
      let (actual_type, optional) = if type_str.has_suffix("?") {
        (type_str[0:type_str.length() - 1].to_string() catch { _ => type_str }, true)
      } else {
        (type_str, false)
      }

      let type_ref = parse_type_ref(actual_type)

      Ok({
        name,
        doc: None,
        type_: type_ref,
        optional,
        default: None,
        attrs: {},
      })
    }
  }
}

// =============================================================================
// Type Reference Parser
// =============================================================================

/// Parse a type reference from a string
pub fn parse_type_ref(type_str : String) -> TypeRef {
  let s = type_str.trim(chars=" \t").to_string()

  // Check for Option type (trailing ?)
  if s.has_suffix("?") {
    let inner = s[0:s.length() - 1].to_string() catch { _ => s }
    return Option(parse_type_ref(inner))
  }

  // Check for Array type
  if s.has_prefix("Array[") && s.has_suffix("]") {
    let inner = s[6:s.length() - 1].to_string() catch { _ => "" }
    return Array(parse_type_ref(inner))
  }

  // Check for Map type
  if s.has_prefix("Map[") && s.has_suffix("]") {
    let inner = s[4:s.length() - 1].to_string() catch { _ => "" }
    // Find comma separator (simple case, no nested generics)
    match find_char(inner, ',') {
      Some(idx) => {
        let key = (inner[0:idx].to_string() catch { _ => "" }).trim(chars=" \t").to_string()
        let value = safe_substring(inner, idx + 1).trim(chars=" \t").to_string()
        return Map(parse_type_ref(key), parse_type_ref(value))
      }
      None => return Unknown
    }
  }

  // Check for function type: (params) -> return
  if s.contains("->") {
    match find_substring(s, "->") {
      Some(arrow_idx) => {
        let params_part = (s[0:arrow_idx].to_string() catch { _ => "" }).trim(chars=" \t").to_string()
        let return_part = safe_substring(s, arrow_idx + 2).trim(chars=" \t").to_string()

        // Parse parameters
        let params : Array[TypeRef] = []
        if params_part.has_prefix("(") && params_part.has_suffix(")") {
          let inner = params_part[1:params_part.length() - 1].to_string() catch { _ => "" }
          if inner.length() > 0 {
            for p in inner.split(",") {
              params.push(parse_type_ref(p.to_string().trim(chars=" \t").to_string()))
            }
          }
        }

        return Function({ params, return_: parse_type_ref(return_part) })
      }
      None => ()
    }
  }

  // Primitive types
  match s {
    "Bool" => Primitive(PrimitiveType::Bool)
    "Int" => Primitive(PrimitiveType::Int)
    "Int64" => Primitive(PrimitiveType::Int64)
    "Float" => Primitive(PrimitiveType::Float)
    "Double" => Primitive(PrimitiveType::Float64)
    "String" => Primitive(PrimitiveType::String)
    "Unit" => Primitive(PrimitiveType::Unit)
    "Json" => Unknown
    _ => Named(s)
  }
}

// =============================================================================
// Enum Parser
// =============================================================================

/// Parse an enum definition
fn parse_enum_def(
  lines : Array[StringView],
  start : Int,
  doc : String?
) -> Result[(EnumDef, Int), String] {
  let line = lines[start].to_string().trim(chars=" \t").to_string()

  // Extract enum name
  let prefix_len = if line.has_prefix("pub enum ") { 9 } else { 5 }
  let rest = safe_substring(line, prefix_len)
  let name = extract_identifier(rest)

  if name.length() == 0 {
    return Err("Expected enum name")
  }

  // Parse variants
  let variants : Array[EnumVariant] = []
  let mut i = start + 1
  let mut found_close = false

  while i < lines.length() {
    let l = lines[i].to_string().trim(chars=" \t").to_string()

    if l.length() == 0 || l.has_prefix("//") {
      i = i + 1
      continue
    }

    if l.has_prefix("}") {
      found_close = true
      i = i + 1
      break
    }

    // Parse variant
    match parse_variant(l) {
      Ok(variant) => variants.push(variant)
      Err(_) => ()
    }

    i = i + 1
  }

  if not(found_close) {
    return Err("Unclosed enum definition")
  }

  let enum_def : EnumDef = {
    name,
    doc,
    type_params: [],
    variants,
    derives: [],
  }

  Ok((enum_def, i))
}

/// Parse a single enum variant
fn parse_variant(line : String) -> Result[EnumVariant, String] {
  // Check for payload
  let paren_idx = find_char(line, '(')
  match paren_idx {
    Some(idx) => {
      let name = (line[0:idx].to_string() catch { _ => "" }).trim(chars=" \t").to_string()
      let payload_str = safe_substring(line, idx + 1)
      let close_idx = find_char(payload_str, ')')
      match close_idx {
        Some(end_idx) => {
          let payload_type = (payload_str[0:end_idx].to_string() catch {
            _ => ""
          }).trim(chars=" \t").to_string()
          Ok({ name, doc: None, payload: Some(parse_type_ref(payload_type)) })
        }
        None => Err("Unclosed variant payload")
      }
    }
    None => {
      // No payload - remove trailing comma if present
      let name = if line.has_suffix(",") {
        line[0:line.length() - 1].to_string() catch { _ => line }
      } else {
        line
      }
      Ok({ name: name.trim(chars=" \t").to_string(), doc: None, payload: None })
    }
  }
}

// =============================================================================
// Alias Parser
// =============================================================================

/// Parse a type alias definition
fn parse_alias_def(line : String, doc : String?) -> Result[AliasDef, String] {
  let prefix_len = if line.has_prefix("pub typealias ") { 14 } else { 10 }
  let rest = safe_substring(line, prefix_len)

  // Find the = separator
  match find_char(rest, '=') {
    None => Err("Expected '=' in type alias")
    Some(idx) => {
      let name = (rest[0:idx].to_string() catch { _ => "" }).trim(chars=" \t").to_string()
      let target_str = safe_substring(rest, idx + 1).trim(chars=" \t").to_string()

      Ok({
        name,
        doc,
        type_params: [],
        target: parse_type_ref(target_str),
      })
    }
  }
}

// =============================================================================
// Helper Functions
// =============================================================================

/// Extract an identifier from the start of a string
fn extract_identifier(s : String) -> String {
  let buf = StringBuilder::new()
  for c in s {
    if is_ident_char(c) {
      buf.write_char(c)
    } else {
      break
    }
  }
  buf.to_string()
}

/// Check if a character is valid in an identifier
fn is_ident_char(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') ||
    (c >= 'A' && c <= 'Z') ||
    (c >= '0' && c <= '9') ||
    c == '_'
}

/// Safe substring from start index
fn safe_substring(s : String, start : Int) -> String {
  if start >= s.length() {
    return ""
  }
  s[start:].to_string() catch { _ => "" }
}

/// Find first occurrence of a character
fn find_char(s : String, c : Char) -> Int? {
  let mut i = 0
  for ch in s {
    if ch == c {
      return Some(i)
    }
    i = i + 1
  }
  None
}

/// Find first occurrence of a substring
fn find_substring(s : String, pattern : String) -> Int? {
  if pattern.length() == 0 {
    return Some(0)
  }
  if pattern.length() > s.length() {
    return None
  }

  let max_start = s.length() - pattern.length()
  for i = 0; i <= max_start; i = i + 1 {
    let sub = s[i:i + pattern.length()].to_string() catch { _ => continue }
    if sub == pattern {
      return Some(i)
    }
  }
  None
}
