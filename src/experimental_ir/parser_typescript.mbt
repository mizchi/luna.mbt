/// TypeScript source code parser for IR extraction
///
/// Parses TypeScript source code and extracts type definitions.
/// Supports interface definitions with optional JSDoc @island annotation.

// =============================================================================
// Main Parser
// =============================================================================

/// Parse TypeScript source code and extract IR schema
pub fn parse_typescript(source : String) -> ParseResult {
  parse_typescript_with_options(source, file="<input>")
}

/// Parse TypeScript source code with options
pub fn parse_typescript_with_options(
  source : String,
  file~ : String
) -> ParseResult {
  let schema : Schema = {
    version: "1.0",
    definitions: {},
    source: Some({ file, lang: TypeScript }),
  }
  let errors : Array[ParseError] = []

  let lines = source.split("\n").to_array()
  let mut i = 0
  let mut pending_doc : String? = None
  let mut pending_annotations : Array[String] = []

  while i < lines.length() {
    let line_view = lines[i]
    let line = line_view.to_string().trim(chars=" \t").to_string()

    // JSDoc comment block start
    if line.has_prefix("/**") {
      let (doc, annotations, end_line) = parse_jsdoc(lines, i)
      pending_doc = doc
      pending_annotations = annotations
      i = end_line
      continue
    }

    // Single line JSDoc
    if line.has_prefix("//") && line.contains("@island") {
      pending_annotations.push("island")
      i = i + 1
      continue
    }

    // Check for interface definition
    if line.has_prefix("export interface ") || line.has_prefix("interface ") {
      // Only process if marked with @island annotation
      if pending_annotations.iter().any(fn(a) { a == "island" }) {
        match parse_ts_interface(lines, i, pending_doc) {
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

    // Check for type alias
    if line.has_prefix("export type ") || line.has_prefix("type ") {
      if pending_annotations.iter().any(fn(a) { a == "island" }) {
        match parse_ts_type_alias(line, pending_doc) {
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
// JSDoc Parser
// =============================================================================

/// Parse JSDoc comment block and extract doc text and annotations
fn parse_jsdoc(
  lines : Array[StringView],
  start : Int
) -> (String?, Array[String], Int) {
  let doc_parts : Array[String] = []
  let annotations : Array[String] = []
  let mut i = start

  while i < lines.length() {
    let line = lines[i].to_string().trim(chars=" \t").to_string()

    // End of JSDoc
    if line.contains("*/") {
      // Check for @island in the closing line
      if line.contains("@island") {
        annotations.push("island")
      }
      // Extract content before */
      let content = extract_jsdoc_content(line)
      if content.length() > 0 {
        doc_parts.push(content)
      }
      i = i + 1
      break
    }

    // Middle line of JSDoc
    if line.has_prefix("*") {
      let content = safe_substring(line, 1).trim(chars=" \t").to_string()
      if content.has_prefix("@island") {
        annotations.push("island")
      } else if content.has_prefix("@") {
        // Skip other annotations
        ()
      } else if content.length() > 0 {
        doc_parts.push(content)
      }
    }

    i = i + 1
  }

  let doc = if doc_parts.length() > 0 {
    Some(doc_parts.join("\n"))
  } else {
    None
  }

  (doc, annotations, i)
}

/// Extract content from a JSDoc line
fn extract_jsdoc_content(line : String) -> String {
  let trimmed = line.trim(chars=" \t*").to_string()
  if trimmed.has_prefix("/") {
    safe_substring(trimmed, 1).trim(chars=" \t").to_string()
  } else if trimmed.has_suffix("/") {
    let end = trimmed.length() - 1
    (trimmed[0:end].to_string() catch { _ => "" }).trim(chars=" \t").to_string()
  } else {
    trimmed
  }
}

// =============================================================================
// Interface Parser
// =============================================================================

/// Parse a TypeScript interface definition
fn parse_ts_interface(
  lines : Array[StringView],
  start : Int,
  doc : String?
) -> Result[(StructDef, Int), String] {
  let line = lines[start].to_string().trim(chars=" \t").to_string()

  // Extract interface name
  let prefix_len = if line.has_prefix("export interface ") { 17 } else { 10 }
  let rest = safe_substring(line, prefix_len)

  // Find interface name (up to space, < or {)
  let name = extract_ts_identifier(rest)
  if name.length() == 0 {
    return Err("Expected interface name")
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

    // Check for closing brace
    if l.has_prefix("}") {
      found_close = true
      i = i + 1
      break
    }

    // Parse field
    match parse_ts_field(l) {
      Ok(field) => fields.push(field)
      Err(_) => () // Skip unparseable lines
    }

    i = i + 1
  }

  if not(found_close) {
    return Err("Unclosed interface definition")
  }

  let struct_def : StructDef = {
    name,
    doc,
    type_params: [],
    fields,
    derives: [],
  }

  Ok((struct_def, i))
}

// =============================================================================
// Field Parser
// =============================================================================

/// Parse a TypeScript interface field
fn parse_ts_field(line : String) -> Result[Field, String] {
  // Remove trailing semicolon and comma
  let trimmed = line.trim(chars=" \t;,").to_string()

  // Skip lines that don't look like fields
  if trimmed.has_prefix("//") || trimmed.has_prefix("{") || trimmed.has_prefix("}") {
    return Err("Not a field")
  }

  // Check for optional marker (name?: type or name: type | undefined)
  let has_optional_marker = trimmed.contains("?:")

  // Find the colon separator (accounting for ?: pattern)
  let colon_idx = if has_optional_marker {
    match find_char(trimmed, '?') {
      Some(q_idx) => Some(q_idx + 1)
      None => find_char(trimmed, ':')
    }
  } else {
    find_char(trimmed, ':')
  }

  match colon_idx {
    None => Err("No colon in field definition")
    Some(idx) => {
      // Extract name (without optional marker)
      let name_part = (trimmed[0:idx].to_string() catch { _ => "" }).trim(chars=" \t?").to_string()
      let type_str = safe_substring(trimmed, idx + 1).trim(chars=" \t").to_string()

      // Check for | null or | undefined
      let is_nullable = type_str.contains("| null") || type_str.contains("| undefined")

      // Remove | null or | undefined from type
      let actual_type = if is_nullable {
        type_str
          .replace_all(old="| null", new="")
          .replace_all(old="| undefined", new="")
          .trim(chars=" \t")
          .to_string()
      } else {
        type_str
      }

      let type_ref = parse_ts_type_ref(actual_type)

      Ok({
        name: name_part,
        doc: None,
        type_: type_ref,
        optional: has_optional_marker || is_nullable,
        default: None,
        attrs: {},
      })
    }
  }
}

// =============================================================================
// Type Reference Parser
// =============================================================================

/// Parse a TypeScript type reference
pub fn parse_ts_type_ref(type_str : String) -> TypeRef {
  let s = type_str.trim(chars=" \t").to_string()

  // Check for array type (T[] or Array<T>)
  if s.has_suffix("[]") {
    let inner = s[0:s.length() - 2].to_string() catch { _ => "" }
    return Array(parse_ts_type_ref(inner))
  }
  if s.has_prefix("Array<") && s.has_suffix(">") {
    let inner = s[6:s.length() - 1].to_string() catch { _ => "" }
    return Array(parse_ts_type_ref(inner))
  }

  // Check for Record type
  if s.has_prefix("Record<") && s.has_suffix(">") {
    let inner = s[7:s.length() - 1].to_string() catch { _ => "" }
    match find_char(inner, ',') {
      Some(idx) => {
        let key = (inner[0:idx].to_string() catch { _ => "" }).trim(chars=" \t").to_string()
        let value = safe_substring(inner, idx + 1).trim(chars=" \t").to_string()
        return Map(parse_ts_type_ref(key), parse_ts_type_ref(value))
      }
      None => return Unknown
    }
  }

  // Check for function type: (args) => return
  if s.contains("=>") {
    match find_substring(s, "=>") {
      Some(arrow_idx) => {
        let params_part = (s[0:arrow_idx].to_string() catch { _ => "" }).trim(chars=" \t").to_string()
        let return_part = safe_substring(s, arrow_idx + 2).trim(chars=" \t").to_string()

        let params : Array[TypeRef] = []
        if params_part.has_prefix("(") && params_part.has_suffix(")") {
          let inner = params_part[1:params_part.length() - 1].to_string() catch { _ => "" }
          // Simple parsing - split by comma (doesn't handle nested generics)
          if inner.length() > 0 {
            for p in inner.split(",") {
              // TypeScript params have name: type format
              let p_str = p.to_string()
              match find_char(p_str, ':') {
                Some(colon_idx) => {
                  let type_part = safe_substring(p_str, colon_idx + 1).trim(chars=" \t").to_string()
                  params.push(parse_ts_type_ref(type_part))
                }
                None => params.push(parse_ts_type_ref(p_str.trim(chars=" \t").to_string()))
              }
            }
          }
        }

        return Function({ params, return_: parse_ts_type_ref(return_part) })
      }
      None => ()
    }
  }

  // Check for union type
  if s.contains("|") {
    let types : Array[TypeRef] = []
    for part in s.split("|") {
      let part_str = part.to_string().trim(chars=" \t").to_string()
      if part_str.length() > 0 {
        types.push(parse_ts_type_ref(part_str))
      }
    }
    if types.length() > 1 {
      return Union(types)
    }
  }

  // Check for string literal type
  if (s.has_prefix("\"") && s.has_suffix("\"")) ||
    (s.has_prefix("'") && s.has_suffix("'")) {
    let inner = s[1:s.length() - 1].to_string() catch { _ => "" }
    return Literal(StringLit(inner))
  }

  // Primitive types
  match s {
    "boolean" => Primitive(PrimitiveType::Bool)
    "number" => Primitive(PrimitiveType::Int)
    "bigint" => Primitive(PrimitiveType::Int64)
    "string" => Primitive(PrimitiveType::String)
    "void" => Primitive(PrimitiveType::Unit)
    "never" => Primitive(PrimitiveType::Never)
    "undefined" => Primitive(PrimitiveType::Unit)
    "null" => Primitive(PrimitiveType::Unit)
    "unknown" => Unknown
    "any" => Unknown
    _ => Named(s)
  }
}

// =============================================================================
// Type Alias Parser
// =============================================================================

/// Parse a TypeScript type alias
fn parse_ts_type_alias(line : String, doc : String?) -> Result[AliasDef, String] {
  let prefix_len = if line.has_prefix("export type ") { 12 } else { 5 }
  let rest = safe_substring(line, prefix_len)

  // Find the = separator
  match find_char(rest, '=') {
    None => Err("Expected '=' in type alias")
    Some(idx) => {
      let name_part = (rest[0:idx].to_string() catch { _ => "" }).trim(chars=" \t").to_string()
      // Extract just the name without generic parameters
      let name = extract_ts_identifier(name_part)
      let target_str = safe_substring(rest, idx + 1).trim(chars=" \t;").to_string()

      Ok({
        name,
        doc,
        type_params: [],
        target: parse_ts_type_ref(target_str),
      })
    }
  }
}

// =============================================================================
// Helper Functions
// =============================================================================

/// Extract a TypeScript identifier from the start of a string
fn extract_ts_identifier(s : String) -> String {
  let buf = StringBuilder::new()
  for c in s {
    if is_ts_ident_char(c) {
      buf.write_char(c)
    } else {
      break
    }
  }
  buf.to_string()
}

/// Check if a character is valid in a TypeScript identifier
fn is_ts_ident_char(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') ||
    (c >= 'A' && c <= 'Z') ||
    (c >= '0' && c <= '9') ||
    c == '_' ||
    c == '$'
}
