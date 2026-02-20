// Type Generator - Generate types.mbt for Props and ComponentRef

// =============================================================================
// Types Generation
// =============================================================================

///|
/// Generate types.mbt content with all Props struct definitions and ComponentRef factory functions
fn generate_types_mbt(structs : Array[StructExport]) -> String {
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
  if not(structs.is_empty()) {
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
      "///| Create ComponentRef for \{component_name} component\n",
    )
    buf.write_string("pub fn \{component_name}(\n")
    buf.write_string("  props : \{s.name},\n")
    buf.write_string("  trigger~ : @luna.Trigger = @luna.TriggerType::Load,\n")
    buf.write_string(") -> @luna.ComponentRef[\{s.name}] {\n")
    buf.write_string("  { url: \"\{url}\", props, wc: \{is_wc}, trigger }\n")
    buf.write_string("}\n\n")
  }
  buf.to_string()
}

///|
/// Generate types/moon.pkg
fn generate_types_pkg(structs : Array[StructExport]) -> String {
  let buf = StringBuilder::new()
  buf.write_string("import {\n")
  buf.write_string("  \"moonbitlang/core/json\",\n")
  buf.write_string("  \"mizchi/luna\" @luna,\n")
  buf.write_string("}\n\n")
  buf.write_string("options(\n")
  buf.write_string("  \"supported-targets\": [ \"js\" ],\n")
  buf.write_string("  \"warn-list\": \"-29\",\n")
  // Export all struct names and factory functions
  let exports : Array[String] = []
  for s in structs {
    exports.push(s.name)
    // Add factory function name (derived from Props name)
    let fn_name = extract_component_name_from_props(s.name)
    exports.push(fn_name)
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
          if not(s.is_empty()) {
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
  if not(s.is_empty()) {
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
