// Route & Action Generator
// Generates type-safe route path constants, param name constants,
// and action key factory functions from routes.mbt parsing results.

// =============================================================================
// Route Path & Param Constants
// =============================================================================

///|
priv struct RouteParamSpec {
  name : String
  optional : Bool
}

///|
fn push_param_spec(
  specs : Array[RouteParamSpec],
  name : String,
  optional : Bool,
) -> Unit {
  for i, spec in specs {
    if spec.name == name {
      if spec.optional && !optional {
        specs[i] = { name, optional }
      }
      return
    }
  }
  specs.push({ name, optional })
}

///|
fn normalize_colon_param_name(raw : String) -> String {
  match raw.find("{") {
    Some(idx) => raw.substring(end=idx)
    None => raw
  }
}

///|
/// Extract parameter specs from a route path pattern.
/// Optional catch-all params are marked optional so generated accessors expose
/// them as `String?` instead of forcing a missing route segment through Result.
fn extract_param_specs_from_path(path : String) -> Array[RouteParamSpec] {
  let specs : Array[RouteParamSpec] = []
  for segment_view in path.split("/") {
    let segment = segment_view.to_string()
    let param_segment = if segment.has_prefix("@") && segment.length() > 1 {
      segment.substring(start=1)
    } else {
      segment
    }
    if param_segment.has_prefix(":") && param_segment.length() > 1 {
      // :param style
      let name = normalize_colon_param_name(param_segment.substring(start=1))
      push_param_spec(specs, name, false)
    } else if param_segment.has_prefix("[[...") &&
      param_segment.has_suffix("]]") &&
      param_segment.length() > 7 {
      // [[...param]] optional catch-all
      let name = param_segment.substring(
        start=5,
        end=param_segment.length() - 2,
      )
      push_param_spec(specs, name, true)
    } else if param_segment.has_prefix("[...") &&
      param_segment.has_suffix("]") &&
      param_segment.length() > 5 {
      // [...param] catch-all
      let name = param_segment.substring(
        start=4,
        end=param_segment.length() - 1,
      )
      push_param_spec(specs, name, false)
    } else if param_segment.has_prefix("[") &&
      param_segment.has_suffix("]") &&
      param_segment.length() > 2 {
      // [param] style
      let name = param_segment.substring(
        start=1,
        end=param_segment.length() - 1,
      )
      push_param_spec(specs, name, false)
    }
  }
  specs
}

///|
/// Extract parameter names from a route path pattern
/// e.g., "/blog/:slug" -> ["slug"]
///       "/users/:id/posts/:postId" -> ["id", "postId"]
///       "/docs/[...slug]" -> ["slug"]
///       "/blog/[[...path]]" -> ["path"]
fn extract_param_names_from_path(path : String) -> Array[String] {
  let result : Array[String] = []
  for spec in extract_param_specs_from_path(path) {
    result.push(spec.name)
  }
  result
}

///|
fn param_name_to_identifier(name : String) -> String {
  let buf = StringBuilder::new()
  for i, c in name {
    let is_alpha = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
    let is_digit = c >= '0' && c <= '9'
    if i == 0 && is_digit {
      buf.write_char('_')
    }
    if is_alpha || is_digit || c == '_' {
      buf.write_char(c)
    } else {
      buf.write_char('_')
    }
  }
  let ident = buf.to_string()
  if ident.is_empty() {
    "_"
  } else {
    ident
  }
}

///|
fn unique_param_fields(
  specs : Array[RouteParamSpec],
) -> Array[(RouteParamSpec, String)] {
  let result : Array[(RouteParamSpec, String)] = []
  let used : Array[String] = []
  for spec in specs {
    let base = param_name_to_identifier(spec.name)
    let mut field = base
    let mut suffix = 1
    while used.contains(field) {
      field = "\{base}_\{suffix}"
      suffix += 1
    }
    used.push(field)
    result.push((spec, field))
  }
  result
}

///|
fn identifier_to_pascal(ident : String) -> String {
  let buf = StringBuilder::new()
  let mut capitalize_next = true
  for c in ident {
    if c == '_' {
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
  let pascal = buf.to_string()
  if pascal.is_empty() {
    "Root"
  } else {
    pascal
  }
}

///|
fn route_params_type_name(ident : String) -> String {
  "Route\{identifier_to_pascal(ident)}Params"
}

///|
fn route_paths_have_params(route_paths : Array[String]) -> Bool {
  for path in route_paths {
    if !extract_param_specs_from_path(path).is_empty() {
      return true
    }
  }
  false
}

///|
fn optional_catch_all_base_pattern(path : String) -> String {
  let buf = StringBuilder::new()
  for segment_view in path.split("/") {
    let segment = segment_view.to_string()
    if segment.is_empty() {
      continue
    }
    if segment.has_prefix("[[...") && segment.has_suffix("]]") {
      break
    }
    buf.write_string("/")
    buf.write_string(segment)
  }
  let result = buf.to_string()
  if result.is_empty() {
    "/"
  } else {
    result
  }
}

///|
fn field_name_for_param(
  fields : Array[(RouteParamSpec, String)],
  name : String,
) -> String {
  for item in fields {
    if item.0.name == name {
      return item.1
    }
  }
  param_name_to_identifier(name)
}

///|
fn write_link_expression(
  buf : StringBuilder,
  path : String,
  fields : Array[(RouteParamSpec, String)],
  field_prefix? : String = "",
) -> Unit {
  let segments = split_path_segments(path)
  let mut first_expr = true
  for seg in segments {
    if !first_expr {
      buf.write_string(" + ")
    }
    first_expr = false
    match classify_segment(seg) {
      StaticSegment(s) => buf.write_string("\"\{s}\"")
      DynamicSegment(name) =>
        buf.write_string(field_prefix + field_name_for_param(fields, name))
    }
  }
}

///|
fn write_link_call_from_params(
  buf : StringBuilder,
  ident : String,
  fields : Array[(RouteParamSpec, String)],
  local_optional_field? : String? = None,
) -> Unit {
  buf.write_string("link_\{ident}(")
  for i, item in fields {
    if i > 0 {
      buf.write_string(", ")
    }
    let field = item.1
    match local_optional_field {
      Some(local_field) =>
        if field == local_field {
          buf.write_string("\{field}~")
        } else {
          buf.write_string("\{field}=params.\{field}")
        }
      None => buf.write_string("\{field}=params.\{field}")
    }
  }
  buf.write_string(")")
}

///|
/// Convert a route path to a valid MoonBit identifier
/// e.g., "/blog/:slug" -> "blog_slug"
///       "/api/users/:id" -> "api_users_id"
///       "/" -> "root"
///       "/@[user_id]" -> "user_id"
fn path_to_identifier(path : String) -> String {
  if path == "/" {
    return "root"
  }
  let buf = StringBuilder::new()
  let mut first = true
  for segment_view in path.split("/") {
    let segment_raw = segment_view.to_string()
    if segment_raw.is_empty() {
      continue
    }
    // Strip a leading "@" (Twitter-style /@user routes) before
    // applying the standard parameter pattern matching.
    let segment = if segment_raw.has_prefix("@") {
      segment_raw.substring(start=1)
    } else {
      segment_raw
    }
    if segment.is_empty() {
      continue
    }
    if !first {
      buf.write_string("_")
    }
    first = false
    // Strip parameter markers to get the name
    let token = if segment.has_prefix(":") {
      normalize_colon_param_name(segment.substring(start=1))
    } else if segment.has_prefix("[[...") && segment.has_suffix("]]") {
      segment.substring(start=5, end=segment.length() - 2)
    } else if segment.has_prefix("[...") && segment.has_suffix("]") {
      segment.substring(start=4, end=segment.length() - 1)
    } else if segment.has_prefix("[") && segment.has_suffix("]") {
      segment.substring(start=1, end=segment.length() - 1)
    } else {
      segment
    }
    // Sanitize: replace anything that isn't [A-Za-z0-9_] with '_'
    // so identifiers stay valid even for unusual segments.
    for c in token {
      let is_alpha = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
      let is_digit = c >= '0' && c <= '9'
      if is_alpha || is_digit || c == '_' {
        buf.write_char(c)
      } else {
        buf.write_char('_')
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
      if !all_param_names.contains(name) {
        all_param_names.push(name)
      }
    }
  }

  // Generate param name constants
  if !all_param_names.is_empty() {
    buf.write_string(
      "// =============================================================================\n",
    )
    buf.write_string("// Param Name Constants\n")
    buf.write_string(
      "// =============================================================================\n\n",
    )
    for name in all_param_names {
      let ident = param_name_to_identifier(name)
      buf.write_string("///|\n")
      buf.write_string("/// Route parameter name: \{name}\n")
      buf.write_string("pub let param_\{ident} : String = \"\{name}\"\n\n")
    }
  }
  buf.to_string()
}

// =============================================================================
// Route Param Accessors
// =============================================================================

///|
/// Generate route-specific typed param accessors.
/// User code should call these instead of spelling `props.get_param("id")`.
fn generate_route_param_accessors(route_paths : Array[String]) -> String {
  if !route_paths_have_params(route_paths) {
    return ""
  }
  let buf = StringBuilder::new()
  buf.write_string(
    "// =============================================================================\n",
  )
  buf.write_string("// Route Param Accessors\n")
  buf.write_string(
    "// =============================================================================\n\n",
  )
  for path in route_paths {
    let specs = extract_param_specs_from_path(path)
    if specs.is_empty() {
      continue
    }
    let ident = path_to_identifier(path)
    let type_name = route_params_type_name(ident)
    let fields = unique_param_fields(specs)
    buf.write_string("///|\n")
    buf.write_string("/// Route params for: \{path}\n")
    buf.write_string("pub(all) struct \{type_name} {\n")
    for item in fields {
      let spec = item.0
      let field = item.1
      let field_type = if spec.optional { "String?" } else { "String" }
      buf.write_string("  \{field} : \{field_type}\n")
    }
    buf.write_string("}\n\n")
    buf.write_string("///|\n")
    buf.write_string("/// Extract typed route params for: \{path}\n")
    buf.write_string(
      "pub fn params_\{ident}(props : @router.PageProps) -> Result[\{type_name}, @router.ApiResponse] {\n",
    )
    for item in fields {
      let spec = item.0
      let field = item.1
      if spec.optional {
        buf.write_string(
          "  let \{field} = props.params.get_param(\"\{spec.name}\")\n",
        )
      } else {
        buf.write_string(
          "  let \{field} = match @router.require(props, \"\{spec.name}\") {\n",
        )
        buf.write_string("    Ok(value) => value\n")
        buf.write_string("    Err(err) => return Err(err)\n")
        buf.write_string("  }\n")
      }
    }
    buf.write_string("  Ok({ ")
    for i, item in fields {
      if i > 0 {
        buf.write_string(", ")
      }
      buf.write_string(item.1)
    }
    buf.write_string(",")
    buf.write_string(" })\n")
    buf.write_string("}\n\n")
  }
  buf.to_string()
}

// =============================================================================
// Link Builder Functions
// =============================================================================

///|
/// Generate type-safe link builder functions from route paths
/// e.g., "/blog/:slug" -> pub fn link_blog_slug(slug~ : String) -> String { "/blog/" + slug }
fn generate_link_builders(route_paths : Array[String]) -> String {
  if route_paths.is_empty() {
    return ""
  }
  let buf = StringBuilder::new()
  buf.write_string(
    "// =============================================================================\n",
  )
  buf.write_string("// Link Builder Functions\n")
  buf.write_string(
    "// =============================================================================\n\n",
  )
  for path in route_paths {
    let ident = path_to_identifier(path)
    let specs = extract_param_specs_from_path(path)
    let fields = unique_param_fields(specs)
    buf.write_string("///|\n")
    buf.write_string("/// Link builder for route: \{path}\n")
    if specs.is_empty() {
      // No parameters - constant returning function
      buf.write_string("pub fn link_\{ident}() -> String {\n")
      buf.write_string("  \"\{path}\"\n")
      buf.write_string("}\n\n")
    } else {
      // Has parameters - labeled args function
      buf.write_string("pub fn link_\{ident}(")
      for i, item in fields {
        if i > 0 {
          buf.write_string(", ")
        }
        buf.write_string("\{item.1}~ : String")
      }
      buf.write_string(") -> String {\n")
      // Build the path expression by walking segments
      buf.write_string("  ")
      write_link_expression(buf, path, fields)
      buf.write_string("\n")
      buf.write_string("}\n\n")
      let type_name = route_params_type_name(ident)
      buf.write_string("///|\n")
      buf.write_string("/// Link builder for route params: \{path}\n")
      buf.write_string(
        "pub fn link_\{ident}_params(params : \{type_name}) -> String {\n",
      )
      let optional_fields = fields.filter(fn(item) { item.0.optional })
      if optional_fields.length() == 1 {
        let field = optional_fields[0].1
        buf.write_string("  match params.\{field} {\n")
        buf.write_string("    Some(\{field}) => ")
        write_link_call_from_params(
          buf,
          ident,
          fields,
          local_optional_field=Some(field),
        )
        buf.write_string("\n")
        buf.write_string("    None => ")
        write_link_expression(
          buf,
          optional_catch_all_base_pattern(path),
          fields,
          field_prefix="params.",
        )
        buf.write_string("\n")
        buf.write_string("  }\n")
      } else {
        buf.write_string("  ")
        write_link_call_from_params(buf, ident, fields)
        buf.write_string("\n")
      }
      buf.write_string("}\n\n")
    }
  }
  buf.to_string()
}

///|
/// Segment classification for link builder generation
priv enum SegmentKind {
  StaticSegment(String)
  DynamicSegment(String)
}

///|
/// Classify a path segment as static or dynamic
fn classify_segment(segment : String) -> SegmentKind {
  if segment.has_prefix(":") && segment.length() > 1 {
    DynamicSegment(normalize_colon_param_name(segment.substring(start=1)))
  } else if segment.has_prefix("[[...") &&
    segment.has_suffix("]]") &&
    segment.length() > 7 {
    DynamicSegment(segment.substring(start=5, end=segment.length() - 2))
  } else if segment.has_prefix("[...") &&
    segment.has_suffix("]") &&
    segment.length() > 5 {
    DynamicSegment(segment.substring(start=4, end=segment.length() - 1))
  } else if segment.has_prefix("[") &&
    segment.has_suffix("]") &&
    segment.length() > 2 {
    DynamicSegment(segment.substring(start=1, end=segment.length() - 1))
  } else {
    StaticSegment(segment)
  }
}

///|
/// Split a route path into alternating static/dynamic pieces for string concatenation.
/// e.g., "/blog/:slug" -> ["/blog/", ":slug"]
///       "/users/:id/posts/:postId" -> ["/users/", ":id", "/posts/", ":postId"]
///       "/" -> ["/"]
fn split_path_segments(path : String) -> Array[String] {
  if path == "/" {
    return ["/"]
  }
  let result : Array[String] = []
  let static_buf = StringBuilder::new()
  for segment_view in path.split("/") {
    let segment = segment_view.to_string()
    if segment.is_empty() {
      static_buf.write_string("/")
      continue
    }
    if segment.has_prefix("@") && segment.length() > 1 {
      let rest = segment.substring(start=1)
      match classify_segment(rest) {
        DynamicSegment(_) => {
          static_buf.write_string("@")
          let s = static_buf.to_string()
          if !s.is_empty() {
            result.push(s)
            static_buf.reset()
          }
          result.push(rest)
          static_buf.write_string("/")
          continue
        }
        StaticSegment(_) => ()
      }
    }
    match classify_segment(segment) {
      StaticSegment(_) => {
        static_buf.write_string(segment)
        static_buf.write_string("/")
      }
      DynamicSegment(_) => {
        // Flush accumulated static text
        let s = static_buf.to_string()
        if !s.is_empty() {
          result.push(s)
          static_buf.reset()
        }
        result.push(segment)
        // After dynamic segment, prepare for next "/"
        static_buf.write_string("/")
      }
    }
  }
  // Flush remaining static text, removing trailing slash if it's extra
  let remaining = static_buf.to_string()
  if !remaining.is_empty() {
    // Remove trailing "/" unless it's the only content
    if remaining == "/" && !result.is_empty() {
      // Don't add trailing slash
      ()
      // Remove trailing slash for cleanliness
    } else if remaining.length() > 1 && remaining.has_suffix("/") {
      result.push(remaining.substring(end=remaining.length() - 1))
    } else if remaining == "/" && result.is_empty() {
      result.push(remaining)
    }
  }
  result
}

// =============================================================================
// Action Key Factory Functions
// =============================================================================

///|
/// Convert an action ID to a valid MoonBit function name
/// e.g., "create-user" -> "action_create_user"
///       "submit-contact" -> "action_submit_contact"
fn action_id_to_fn_name(id : String) -> String {
  let buf = StringBuilder::new()
  buf.write_string("action_")
  for c in id {
    if c == '-' || c == ':' || c == '/' || c == '.' {
      buf.write_char('_')
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
fn action_id_to_type_name(id : String) -> String {
  let fn_name = action_id_to_fn_name(id)
  let ident = if fn_name.has_prefix("action_") {
    fn_name.substring(start="action_".length())
  } else {
    fn_name
  }
  "Action\{identifier_to_pascal(ident)}"
}

///|
/// Generate action key factory functions MoonBit code
fn generate_action_key_factories(action_ids : Array[String]) -> String {
  if action_ids.is_empty() {
    return ""
  }
  let buf = StringBuilder::new()
  buf.write_string(
    "// =============================================================================\n",
  )
  buf.write_string("// Action Key Factory Functions\n")
  buf.write_string(
    "// =============================================================================\n\n",
  )
  for id in action_ids {
    let fn_name = action_id_to_fn_name(id)
    let type_name = action_id_to_type_name(id)
    buf.write_string("///|\n")
    buf.write_string("/// Action key for \"\{id}\" action\n")
    buf.write_string("pub(all) struct \{type_name} {}\n\n")
    buf.write_string("///|\n")
    buf.write_string(
      "pub impl @action.ActionKey for \{type_name} with id(_self) {\n",
    )
    buf.write_string("  \"\{id}\"\n")
    buf.write_string("}\n\n")
    buf.write_string("///|\n")
    buf.write_string(
      "pub impl @action.ActionKey for \{type_name} with base_path(_self) {\n",
    )
    buf.write_string("  \"/_action\"\n")
    buf.write_string("}\n\n")
    buf.write_string("///|\n")
    buf.write_string("/// Action key for \"\{id}\" action\n")
    buf.write_string("pub fn \{fn_name}() -> \{type_name} {\n")
    buf.write_string("  \{type_name}::{}\n")
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
      if !locale_codes.contains(locale.code) {
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
