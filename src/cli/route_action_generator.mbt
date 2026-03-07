// Route & Action Generator
// Generates type-safe route path constants, param name constants,
// and ActionRef factory functions from routes.mbt parsing results.

// =============================================================================
// Route Path & Param Constants
// =============================================================================

///|
/// Extract parameter names from a route path pattern
/// e.g., "/blog/:slug" -> ["slug"]
///       "/users/:id/posts/:postId" -> ["id", "postId"]
///       "/docs/[...slug]" -> ["slug"]
///       "/blog/[[...path]]" -> ["path"]
fn extract_param_names_from_path(path : String) -> Array[String] {
  let result : Array[String] = []
  for segment_view in path.split("/") {
    let segment = segment_view.to_string()
    if segment.has_prefix(":") && segment.length() > 1 {
      // :param style
      let name = segment.substring(start=1)
      if not(result.contains(name)) {
        result.push(name)
      }
    } else if segment.has_prefix("[[...") &&
      segment.has_suffix("]]") &&
      segment.length() > 7 {
      // [[...param]] optional catch-all
      let name = segment.substring(start=5, end=segment.length() - 2)
      if not(result.contains(name)) {
        result.push(name)
      }
    } else if segment.has_prefix("[...") &&
      segment.has_suffix("]") &&
      segment.length() > 5 {
      // [...param] catch-all
      let name = segment.substring(start=4, end=segment.length() - 1)
      if not(result.contains(name)) {
        result.push(name)
      }
    } else if segment.has_prefix("[") &&
      segment.has_suffix("]") &&
      segment.length() > 2 {
      // [param] style
      let name = segment.substring(start=1, end=segment.length() - 1)
      if not(result.contains(name)) {
        result.push(name)
      }
    }
  }
  result
}

///|
/// Convert a route path to a valid MoonBit identifier
/// e.g., "/blog/:slug" -> "blog_slug"
///       "/api/users/:id" -> "api_users_id"
///       "/" -> "root"
fn path_to_identifier(path : String) -> String {
  if path == "/" {
    return "root"
  }
  let buf = StringBuilder::new()
  let mut first = true
  for segment_view in path.split("/") {
    let segment = segment_view.to_string()
    if segment.is_empty() {
      continue
    }
    if not(first) {
      buf.write_string("_")
    }
    first = false
    // Strip parameter markers to get the name
    if segment.has_prefix(":") {
      buf.write_string(segment.substring(start=1))
    } else if segment.has_prefix("[[...") && segment.has_suffix("]]") {
      buf.write_string(segment.substring(start=5, end=segment.length() - 2))
    } else if segment.has_prefix("[...") && segment.has_suffix("]") {
      buf.write_string(segment.substring(start=4, end=segment.length() - 1))
    } else if segment.has_prefix("[") && segment.has_suffix("]") {
      buf.write_string(segment.substring(start=1, end=segment.length() - 1))
    } else {
      // Replace hyphens with underscores for valid identifiers
      for c in segment {
        if c == '-' {
          buf.write_char('_')
        } else {
          buf.write_char(c)
        }
      }
    }
  }
  buf.to_string()
}

///|
/// Generate route constants and param constants MoonBit code
fn generate_route_constants(route_paths : Array[String]) -> String {
  if route_paths.is_empty() {
    return ""
  }
  let buf = StringBuilder::new()
  buf.write_string(
    "// =============================================================================\n",
  )
  buf.write_string("// Route Path Constants\n")
  buf.write_string(
    "// =============================================================================\n\n",
  )

  // Collect all unique param names across all routes
  let all_param_names : Array[String] = []

  for path in route_paths {
    let ident = path_to_identifier(path)
    buf.write_string("///|\n")
    buf.write_string("/// Route path: \{path}\n")
    buf.write_string("pub let route_\{ident} : String = \"\{path}\"\n\n")

    // Collect param names
    let params = extract_param_names_from_path(path)
    for name in params {
      if not(all_param_names.contains(name)) {
        all_param_names.push(name)
      }
    }
  }

  // Generate param name constants
  if not(all_param_names.is_empty()) {
    buf.write_string(
      "// =============================================================================\n",
    )
    buf.write_string("// Param Name Constants\n")
    buf.write_string(
      "// =============================================================================\n\n",
    )
    for name in all_param_names {
      buf.write_string("///|\n")
      buf.write_string("/// Route parameter name: \{name}\n")
      buf.write_string("pub let param_\{name} : String = \"\{name}\"\n\n")
    }
  }
  buf.to_string()
}

// =============================================================================
// ActionRef Factory Functions
// =============================================================================

///|
/// Convert an action ID to a valid MoonBit function name
/// e.g., "create-user" -> "action_create_user"
///       "submit-contact" -> "action_submit_contact"
fn action_id_to_fn_name(id : String) -> String {
  let buf = StringBuilder::new()
  buf.write_string("action_")
  for c in id {
    if c == '-' {
      buf.write_char('_')
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
/// Generate ActionRef factory functions MoonBit code
fn generate_action_ref_factories(action_ids : Array[String]) -> String {
  if action_ids.is_empty() {
    return ""
  }
  let buf = StringBuilder::new()
  buf.write_string(
    "// =============================================================================\n",
  )
  buf.write_string("// ActionRef Factory Functions\n")
  buf.write_string(
    "// =============================================================================\n\n",
  )
  for id in action_ids {
    let fn_name = action_id_to_fn_name(id)
    buf.write_string("///|\n")
    buf.write_string("/// ActionRef for \"\{id}\" action\n")
    buf.write_string("pub fn \{fn_name}() -> @action.ActionRef {\n")
    buf.write_string("  { id: \"\{id}\", base_path: \"/_action\" }\n")
    buf.write_string("}\n\n")
  }
  buf.to_string()
}

// =============================================================================
// Locale Enum
// =============================================================================

///|
/// Generate Locale enum from i18n configs across all static dirs
fn generate_locale_enum(static_dirs : Array[StaticDirEntry]) -> String {
  // Collect unique locale codes from all static dirs
  let locale_codes : Array[String] = []
  let locale_labels : Array[(String, String)] = []
  for dir in static_dirs {
    for locale in dir.i18n.locales {
      if not(locale_codes.contains(locale.code)) {
        locale_codes.push(locale.code)
        locale_labels.push((locale.code, locale.label))
      }
    }
  }
  if locale_codes.length() <= 1 {
    // Single locale (or none), no enum needed
    return ""
  }
  let buf = StringBuilder::new()
  buf.write_string(
    "// =============================================================================\n",
  )
  buf.write_string("// Locale Enum\n")
  buf.write_string(
    "// =============================================================================\n\n",
  )
  buf.write_string("///|\n")
  buf.write_string("/// Available locales (auto-generated from i18n config)\n")
  buf.write_string("pub enum Locale {\n")
  for pair in locale_labels {
    let variant = locale_code_to_variant(pair.0)
    buf.write_string("  /// \{pair.1}\n")
    buf.write_string("  \{variant}\n")
  }
  buf.write_string("} derive(Eq, Show)\n\n")

  // Generate code() method
  buf.write_string("///|\n")
  buf.write_string("/// Get locale code string\n")
  buf.write_string("pub fn Locale::code(self : Locale) -> String {\n")
  buf.write_string("  match self {\n")
  for pair in locale_labels {
    let variant = locale_code_to_variant(pair.0)
    buf.write_string("    \{variant} => \"\{pair.0}\"\n")
  }
  buf.write_string("  }\n")
  buf.write_string("}\n\n")

  // Generate label() method
  buf.write_string("///|\n")
  buf.write_string("/// Get locale display label\n")
  buf.write_string("pub fn Locale::label(self : Locale) -> String {\n")
  buf.write_string("  match self {\n")
  for pair in locale_labels {
    let variant = locale_code_to_variant(pair.0)
    buf.write_string("    \{variant} => \"\{pair.1}\"\n")
  }
  buf.write_string("  }\n")
  buf.write_string("}\n")
  buf.to_string()
}

///|
/// Convert locale code to PascalCase enum variant
/// e.g., "en" -> "En", "ja" -> "Ja", "zh-CN" -> "ZhCn"
fn locale_code_to_variant(code : String) -> String {
  let buf = StringBuilder::new()
  let mut capitalize_next = true
  for c in code {
    if c == '-' || c == '_' {
      capitalize_next = true
    } else if capitalize_next {
      if c >= 'a' && c <= 'z' {
        buf.write_char(Char::from_int(c.to_int() - 32))
      } else {
        buf.write_char(c)
      }
      capitalize_next = false
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}
