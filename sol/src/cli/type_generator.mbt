// Type Generator - Generate types.mbt for Props and ComponentRef

// =============================================================================
// Types Generation
// =============================================================================

///|
/// Generate types.mbt content with all Props struct definitions, ComponentRef factories,
/// route constants, action key factories, and Locale enum
fn generate_types_mbt(
  structs : Array[StructExport],
  route_info? : RouteInfo = RouteInfo::{
    _page_components: [],
    _api_handlers: [],
    route_paths: [],
    action_ids: [],
  },
  static_dirs? : Array[StaticDirEntry] = [],
  external_client_bundle? : Bool = false,
) -> String {
  let buf = StringBuilder::new()
  buf.write_string("///| Auto-generated types for island props\n")
  buf.write_string("///| Re-exports Props structs from client packages\n\n")

  // Generate struct definitions
  for s in structs {
    buf.write_string("///| Props type from @\{s.import_alias}\n")
    // Check if raw_definition already has derive
    if s.raw_definition.contains("derive(") {
      buf.write_string(s.raw_definition)
      buf.write_string("\n\n")
    } else {
      buf.write_string(s.raw_definition)
      buf.write_string(" derive(ToJson, FromJson)\n\n")
    }
  }

  // Generate ComponentRef factory functions
  if !structs.is_empty() {
    buf.write_string(
      "// =============================================================================\n",
    )
    buf.write_string("// ComponentRef Factory Functions\n")
    buf.write_string(
      "// =============================================================================\n\n",
    )
  }
  for s in structs {
    let component_name = extract_component_name_from_props(s.name)
    let url = "/static/\{component_name}.js"
    let is_wc = is_web_component(component_name)
    buf.write_string("///|\n")
    buf.write_string(
      "///| Create ComponentRef for \{component_name} component with an explicit client URL\n",
    )
    buf.write_string("pub fn \{component_name}_at(\n")
    buf.write_string("  url : String,\n")
    buf.write_string("  props : \{s.name},\n")
    buf.write_string("  trigger~ : @luna.Trigger = @luna.TriggerType::Load,\n")
    buf.write_string(") -> @luna.ComponentRef[\{s.name}] {\n")
    buf.write_string("  { url, props, wc: \{is_wc}, trigger }\n")
    buf.write_string("}\n\n")
    if !external_client_bundle {
      buf.write_string("///|\n")
      buf.write_string(
        "///| Create ComponentRef for \{component_name} component using Sol's generated client URL\n",
      )
      buf.write_string("pub fn \{component_name}(\n")
      buf.write_string("  props : \{s.name},\n")
      buf.write_string(
        "  trigger~ : @luna.Trigger = @luna.TriggerType::Load,\n",
      )
      buf.write_string(") -> @luna.ComponentRef[\{s.name}] {\n")
      buf.write_string("  \{component_name}_at(\"\{url}\", props, trigger~)\n")
      buf.write_string("}\n\n")
    }
  }

  // Generate route path constants and param name constants
  buf.write_string(generate_route_constants(route_info.route_paths))

  // Generate route-specific typed param accessors
  buf.write_string(generate_route_param_accessors(route_info.route_paths))

  // Generate link builder functions
  buf.write_string(generate_link_builders(route_info.route_paths))

  // Generate action key factory functions
  buf.write_string(generate_action_key_factories(route_info.action_ids))

  // Generate Locale enum
  buf.write_string(generate_locale_enum(static_dirs))

  buf.to_string()
}

///|
/// Generate round-trip tests for all Props types.
/// These tests verify that to_json → from_json produces identical values.
fn generate_types_roundtrip_tests(
  structs : Array[StructExport],
  external_client_bundle? : Bool = false,
) -> String {
  if structs.is_empty() {
    return ""
  }
  let buf = StringBuilder::new()
  buf.write_string("///| Auto-generated Props round-trip tests\n")
  buf.write_string(
    "///| Verifies to_json/from_json symmetry for all island Props types\n\n",
  )
  for s in structs {
    let component_name = extract_component_name_from_props(s.name)
    buf.write_string("///|\n")
    buf.write_string("test \"\{s.name} round-trip\" {\n")
    buf.write_string("  let json_str = \{default_props_json(s)}\n")
    buf.write_string(
      "  let json : Json = @json.parse(json_str) catch { _ => panic() }\n",
    )
    buf.write_string("  let props : \{s.name} = @json.from_json(json)\n")
    buf.write_string("  let roundtrip = props.to_json()\n")
    buf.write_string(
      "  let restored : \{s.name} = @json.from_json(roundtrip)\n",
    )
    buf.write_string(
      "  assert_eq(props.to_json().stringify(), restored.to_json().stringify())\n",
    )
    buf.write_string("}\n\n")
    // Also verify ComponentRef factory creates valid ref
    buf.write_string("///|\n")
    buf.write_string("test \"\{component_name} ComponentRef url\" {\n")
    buf.write_string("  let json_str = \{default_props_json(s)}\n")
    buf.write_string(
      "  let json : Json = @json.parse(json_str) catch { _ => panic() }\n",
    )
    buf.write_string("  let props : \{s.name} = @json.from_json(json)\n")
    let factory_call = if external_client_bundle {
      "\{component_name}_at(\"/static/\{component_name}.js\", props)"
    } else {
      "\{component_name}(props)"
    }
    buf.write_string("  let cref = \{factory_call}\n")
    buf.write_string(
      "  assert_true(cref.url.has_suffix(\"\{component_name}.js\"))\n",
    )
    buf.write_string("}\n\n")
  }
  buf.to_string()
}

///|
/// Generate a default JSON string for a Props struct (using empty/zero values)
fn default_props_json(s : StructExport) -> String {
  // Parse fields from raw_definition to build a minimal valid JSON
  let fields = extract_struct_fields(s.raw_definition)
  if fields.is_empty() {
    return "\"{}\""
  }
  let buf = StringBuilder::new()
  buf.write_string("\"{ ")
  for i, field in fields {
    if i > 0 {
      buf.write_string(", ")
    }
    buf.write_string("\\\"")
    buf.write_string(field.0) // field name
    buf.write_string("\\\": ")
    buf.write_string(default_json_value(field.1)) // field type → default value
  }
  buf.write_string(" }\"")
  buf.to_string()
}

///|
/// Extract field name-type pairs from struct definition
fn extract_struct_fields(raw : String) -> Array[(String, String)] {
  let fields : Array[(String, String)] = []
  // Find { ... } block
  let start = match raw.find("{") {
    Some(i) => i + 1
    None => return fields
  }
  let end = match raw.find("}") {
    Some(i) => i
    None => return fields
  }
  let body = raw.substring(start~, end~)
  // Split by newlines, parse "name : Type"
  for line_view in body.split("\n") {
    let line = line_view.to_string().trim_space().to_string()
    if line.is_empty() || line.has_prefix("//") {
      continue
    }
    match line.find(":") {
      Some(colon) => {
        let name = line.substring(end=colon).trim_space().to_string()
        let mut type_str = line
          .substring(start=colon + 1)
          .trim_space()
          .to_string()
        // Remove trailing comma if present
        if type_str.has_suffix(",") {
          type_str = type_str
            .substring(end=type_str.length() - 1)
            .trim_space()
            .to_string()
        }
        if !name.is_empty() && !type_str.is_empty() {
          fields.push((name, type_str))
        }
      }
      None => ()
    }
  }
  fields
}

///|
/// Default JSON value for common MoonBit types
fn default_json_value(type_str : String) -> String {
  if type_str == "Int" || type_str == "Double" || type_str == "Float" {
    "0"
  } else if type_str == "String" {
    "\\\"\\\"" // escaped empty string
  } else if type_str == "Bool" {
    "false"
  } else if type_str.has_prefix("Array") {
    "[]"
  } else if type_str.has_prefix("Map") {
    "{}"
  } else if type_str.has_suffix("?") {
    "null"
  } else {
    "{}" // fallback for nested structs
  }
}

///|
/// Generate types/moon.pkg
fn generate_types_pkg(
  structs : Array[StructExport],
  has_actions? : Bool = false,
  external_client_bundle? : Bool = false,
  has_route_params? : Bool = false,
) -> String {
  let buf = StringBuilder::new()
  buf.write_string("import {\n")
  buf.write_string("  \"moonbitlang/core/json\",\n")
  buf.write_string("  \"mizchi/luna\" @luna,\n")
  if has_route_params {
    buf.write_string("  \"mizchi/sol/router\" @router,\n")
  }
  if has_actions {
    buf.write_string("  \"mizchi/sol/action\" @action,\n")
  }
  buf.write_string("}\n\n")
  buf.write_string("supported_targets = \"js\"\n\n")
  buf.write_string("warnings = \"-29\"\n\n")
  buf.write_string("options(\n")
  // Export all struct names and factory functions
  let exports : Array[String] = []
  for s in structs {
    exports.push(s.name)
    // Add factory function name (derived from Props name)
    let fn_name = extract_component_name_from_props(s.name)
    exports.push("\{fn_name}_at")
    if !external_client_bundle {
      exports.push(fn_name)
    }
  }
  let exports_str = exports.map(fn(n) { "\"\{n}\"" }).join(", ")
  buf.write_string(
    "  link: { \"js\": { \"exports\": [ \{exports_str} ], \"format\": \"esm\" } },\n",
  )
  buf.write_string(")\n")
  buf.to_string()
}

// =============================================================================
// Signature Utilities
// =============================================================================

///|
/// Split parameters respecting nested brackets
pub fn split_params(params_str : String) -> Array[String] {
  let result : Array[String] = []
  let current = StringBuilder::new()
  let mut depth = 0
  for char in params_str {
    match char {
      '(' | '[' | '{' => {
        depth += 1
        current.write_char(char)
      }
      ')' | ']' | '}' => {
        depth -= 1
        current.write_char(char)
      }
      ',' =>
        if depth == 0 {
          let s = current.to_string().trim_space().to_string()
          if !s.is_empty() {
            result.push(s)
          }
          current.reset()
        } else {
          current.write_char(char)
        }
      _ => current.write_char(char)
    }
  }
  // Add last param
  let s = current.to_string().trim_space().to_string()
  if !s.is_empty() {
    result.push(s)
  }
  result
}

///|
/// Find matching closing paren position
pub fn find_matching_paren(s : String, start : Int) -> Int? {
  let mut depth = 0
  let chars = s.to_array()
  for i = start; i < chars.length(); i = i + 1 {
    match chars[i] {
      '(' => depth += 1
      ')' => {
        depth -= 1
        if depth == 0 {
          return Some(i)
        }
      }
      _ => ()
    }
  }
  None
}

///|
/// Generate parameter names for signature
pub fn generate_params_with_names(signature : String) -> (String, String) {
  // signature: "(Type1, Type2) -> RetType" or "() -> RetType"
  // Returns: (signature_with_names, call_args)
  // e.g., "(String, Int) -> Unit" => ("(p0 : String, p1 : Int) -> Unit", "(p0, p1)")
  match signature.find("(") {
    None => (signature, "()")
    Some(paren_start) =>
      match find_matching_paren(signature, paren_start) {
        None => (signature, "()")
        Some(paren_end) => {
          let params_str = signature.unsafe_substring(
            start=paren_start + 1,
            end=paren_end,
          )
          if params_str.trim_space().to_string().is_empty() {
            // No params: () -> RetType
            (signature, "()")
          } else {
            // Parse params and add names (respecting nested brackets)
            let params = split_params(params_str)
            let named_params = StringBuilder::new()
            let call_args = StringBuilder::new()
            named_params.write_string("(")
            call_args.write_string("(")
            for i, param_str in params {
              if i > 0 {
                named_params.write_string(", ")
                call_args.write_string(", ")
              }
              named_params.write_string("p\{i} : \{param_str}")
              call_args.write_string("p\{i}")
            }
            named_params.write_string(")")
            call_args.write_string(")")
            // Add return type
            let ret_type = signature.unsafe_substring(
              start=paren_end + 1,
              end=signature.length(),
            )
            named_params.write_string(ret_type)
            (named_params.to_string(), call_args.to_string())
          }
        }
      }
  }
}

///|
/// Check if signature uses @luna types
pub fn uses_luna_types(signature : String) -> Bool {
  signature.contains("@luna.")
}

///|
/// Check if signature uses @js types
pub fn uses_js_types(signature : String) -> Bool {
  signature.contains("@js.")
}

///|
/// Check if signature uses @signal types
pub fn uses_signal_types(signature : String) -> Bool {
  signature.contains("@signal.")
}

///|
/// Check if signature uses @hono types
pub fn uses_hono_types(signature : String) -> Bool {
  signature.contains("@hono.")
}
