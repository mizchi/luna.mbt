// MDX Props Validator
//
// Validates JSX component attributes in MDX against island Props type definitions.
// Catches missing required fields, unknown attributes, and literal type mismatches
// at build time (sol generate / sol check).

// =============================================================================
// Validation Result Types
// =============================================================================

///|
/// A single validation diagnostic
pub(all) struct PropsDiagnostic {
  /// Component tag name (e.g., "Counter")
  component : String
  /// Diagnostic severity
  severity : DiagnosticSeverity
  /// Human-readable message
  message : String
}

///|
pub(all) enum DiagnosticSeverity {
  Error
  Warning
} derive(Eq, Show)

///|
pub fn PropsDiagnostic::to_string(self : PropsDiagnostic) -> String {
  let prefix = match self.severity {
    Error => "error"
    Warning => "warning"
  }
  "\{prefix}: <\{self.component}> \{self.message}"
}

// =============================================================================
// Props Schema (extracted from StructExport)
// =============================================================================

///|
/// Parsed field info from a Props struct definition
struct PropsField {
  name : String
  type_str : String
  optional : Bool // true if type is `T?` or has default
}

///|
/// Build a props schema (field name → type) from a StructExport
fn build_props_schema(struct_export : StructExport) -> Array[PropsField] {
  let fields = extract_struct_fields(struct_export.raw_definition)
  fields.map(fn(pair) {
    let name = pair.0
    let type_str = pair.1
    let optional = type_str.has_suffix("?") ||
      type_str.contains("?") // e.g., Int?, String?
    { name, type_str, optional }
  })
}

// =============================================================================
// Component Registry (maps JSX tag → Props schema)
// =============================================================================

///|
/// Registry mapping component names to their Props field schemas
pub struct ComponentPropsRegistry {
  /// Maps lowercase component name (e.g., "counter") to fields
  entries : Map[String, Array[PropsField]]
}

///|
/// Build registry from collected StructExports
pub fn ComponentPropsRegistry::from_structs(
  structs : Array[StructExport],
) -> ComponentPropsRegistry {
  let entries : Map[String, Array[PropsField]] = {}
  for s in structs {
    let component_name = extract_component_name_from_props(s.name)
    let fields = build_props_schema(s)
    entries[component_name] = fields
  }
  { entries, }
}

///|
/// Look up fields by JSX tag name (case-insensitive match)
fn ComponentPropsRegistry::lookup(
  self : ComponentPropsRegistry,
  jsx_tag : String,
) -> Array[PropsField]? {
  // JSX tag "Counter" → "counter" for lookup
  let key = jsx_tag.to_lower()
  self.entries.get(key)
}

// =============================================================================
// Literal Type Checking
// =============================================================================

///|
/// Check if a StringLiteral value is compatible with the expected type
fn check_literal_compat(
  value : String,
  type_str : String,
) -> String? {
  let base_type = if type_str.has_suffix("?") {
    type_str.substring(end=type_str.length() - 1)
  } else {
    type_str
  }
  match base_type {
    "Int" => {
      // Try parse as int
      try {
        let _ = @strconv.parse_int!(value)
        None
      } catch {
        _ => Some("expected Int, got string \"\{value}\"")
      }
    }
    "Double" | "Float" => {
      try {
        let _ = @strconv.parse_double!(value)
        None
      } catch {
        _ => Some("expected \{base_type}, got string \"\{value}\"")
      }
    }
    "Bool" =>
      match value {
        "true" | "false" => None
        _ => Some("expected Bool, got string \"\{value}\"")
      }
    "String" => None // String literal always compatible with String
    _ => None // Unknown type — skip validation
  }
}

// =============================================================================
// Validate a Single Component Embed
// =============================================================================

///|
/// Validate a JsxComponentEmbed against the props registry
pub fn validate_jsx_embed(
  embed : @ssg.JsxComponentEmbed,
  registry : ComponentPropsRegistry,
) -> Array[PropsDiagnostic] {
  let diags : Array[PropsDiagnostic] = []
  let tag = embed.tag
  let fields = match registry.lookup(tag) {
    Some(f) => f
    None => return diags // Unknown component — skip (might be external)
  }
  // Build field lookup
  let field_map : Map[String, PropsField] = {}
  for f in fields {
    field_map[f.name] = f
  }
  // Check each MDX attribute against schema
  let provided_names : Array[String] = []
  for attr in embed.attrs {
    let attr_name = attr.0
    let attr_value = attr.1
    provided_names.push(attr_name)
    // Skip CLS hints (cls:width, cls:height)
    if attr_name.has_prefix("cls:") {
      continue
    }
    // Skip trigger attribute
    if attr_name == "trigger" || attr_name == "luna:trigger" {
      continue
    }
    match field_map.get(attr_name) {
      Some(field) =>
        // Type check for literal values only
        check_attr_value(tag, attr_name, attr_value, field, diags)
      None =>
        diags.push({
          component: tag,
          severity: Warning,
          message: "unknown prop \"\{attr_name}\" (not in Props struct)",
        })
    }
  }
  // Check for missing required fields
  for field in fields {
    if not(field.optional) && not(provided_names.contains(field.name)) {
      diags.push({
        component: tag,
        severity: Error,
        message: "missing required prop \"\{field.name}\" (type: \{field.type_str})",
      })
    }
  }
  diags
}

///|
fn check_attr_value(
  tag : String,
  attr_name : String,
  attr_value : @ssg.MdxAttrValue,
  field : PropsField,
  diags : Array[PropsDiagnostic],
) -> Unit {
  let val : @ssg.MdxAttrValue = attr_value
  match val {
    StringLiteral(value) =>
      match check_literal_compat(value, field.type_str) {
        Some(msg) =>
          diags.push({
            component: tag,
            severity: Error,
            message: "prop \"\{attr_name}\": \{msg}",
          })
        None => ()
      }
    Boolean =>
      if not(field.type_str.contains("Bool")) {
        diags.push({
          component: tag,
          severity: Warning,
          message: "prop \"\{attr_name}\": bare attribute used for \{field.type_str} field",
        })
      }
    Expression(_) => () // Skip expression validation
  }
}

// =============================================================================
// Batch Validation (for build pipeline)
// =============================================================================

///|
/// Validate all JSX embeds in an array of MdNodes
pub fn validate_mdx_props(
  nodes : Array[@ssg.MdNode],
  registry : ComponentPropsRegistry,
) -> Array[PropsDiagnostic] {
  let diags : Array[PropsDiagnostic] = []
  collect_jsx_embeds(nodes, diags, registry)
  diags
}

///|
fn collect_jsx_embeds(
  nodes : Array[@ssg.MdNode],
  diags : Array[PropsDiagnostic],
  registry : ComponentPropsRegistry,
) -> Unit {
  for node in nodes {
    let n : @ssg.MdNode = node
    match n {
      JsxComponent(embed) => {
        let embed_diags = validate_jsx_embed(embed, registry)
        for d in embed_diags {
          diags.push(d)
        }
      }
      Heading(children~, ..) | Paragraph(children~) | Bold(children~) | Italic(
        children~,
      ) | Link(children~, ..) | Blockquote(children~) =>
        collect_jsx_embeds(children, diags, registry)
      List(items~, ..) =>
        for item in items {
          collect_jsx_embeds(item, diags, registry)
        }
      _ => ()
    }
  }
}
