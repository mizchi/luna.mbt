// Route Pattern Utilities
//
// Shared utilities for extracting and building route patterns.
// Used by both Astra (SSG) and Sol (SSR) for route matching.

// =============================================================================
// Pattern Extraction
// =============================================================================

///|
/// Extract regex pattern and parameter names from a URL path
/// Supports both :slug (Express/Hono style) and [slug] (Next.js style) syntaxes
pub fn extract_url_pattern(path : String) -> (String, Array[String]) {
  let param_names : Array[String] = []
  let pattern = StringBuilder::new()
  pattern.write_string("^")
  let mut i = 0
  let len = path.length()
  while i < len {
    let ch = safe_char_at(path, i)
    if ch == ':' {
      // Express/Hono style :name parameter
      let param_start = i + 1
      let mut param_end = param_start
      while param_end < len && is_param_char(safe_char_at(path, param_end)) {
        param_end = param_end + 1
      }
      let param_name = safe_substring(path, param_start, param_end)
      param_names.push(param_name)
      pattern.write_string("([^/]+)")
      i = param_end
    } else if ch == '*' {
      // Catch-all wildcard
      param_names.push("*")
      pattern.write_string("(.*)")
      i = i + 1
    } else if ch == '[' {
      // Next.js style [param], [...param], or [[...param]]
      let (new_i, param_name, is_catch_all) = parse_bracket_param(path, i)
      param_names.push(param_name)
      if is_catch_all {
        pattern.write_string("(.*)")
      } else {
        pattern.write_string("([^/]+)")
      }
      i = new_i
    } else if is_regex_special(ch) {
      // Escape regex special characters
      pattern.write_char('\\')
      pattern.write_char(ch)
      i = i + 1
    } else {
      pattern.write_char(ch)
      i = i + 1
    }
  }
  pattern.write_char('$')
  (pattern.to_string(), param_names)
}

///|
/// Extract catch-all info from a URL path
pub fn extract_catch_all(path : String) -> CatchAllInfo? {
  // Check for [...param] or [[...param]] (Next.js style)
  if path.contains("[...") {
    let optional = path.contains("[[...")
    // Extract param name - simplified extraction
    let name = extract_catch_all_name(path)
    Some(CatchAllInfo::{ name, optional })
  } else if path.contains("*") {
    // Wildcard style
    Some(CatchAllInfo::{ name: "*", optional: false })
  } else {
    None
  }
}

///|
/// Extract catch-all parameter name from path
fn extract_catch_all_name(path : String) -> String {
  // Find [...name] or [[...name]]
  let mut i = 0
  let len = path.length()
  while i < len {
    if safe_char_at(path, i) == '[' {
      let (_, name, is_catch_all) = parse_bracket_param(path, i)
      if is_catch_all {
        return name
      }
    }
    i = i + 1
  }
  "path" // Default name
}

///|
/// Parse bracket-style parameter [param], [...param], or [[...param]]
/// Returns (end_index, param_name, is_catch_all)
pub fn parse_bracket_param(path : String, start : Int) -> (Int, String, Bool) {
  let len = path.length()
  let mut i = start + 1 // Skip first [
  let mut is_optional = false
  let mut is_catch_all = false

  // Check for optional [[
  if i < len && safe_char_at(path, i) == '[' {
    is_optional = true
    i = i + 1
  }

  // Check for catch-all ...
  if i + 2 < len &&
    safe_char_at(path, i) == '.' &&
    safe_char_at(path, i + 1) == '.' &&
    safe_char_at(path, i + 2) == '.' {
    is_catch_all = true
    i = i + 3
  }

  // Extract parameter name
  let param_start = i
  while i < len && safe_char_at(path, i) != ']' {
    i = i + 1
  }
  let param_name = safe_substring(path, param_start, i)

  // Skip closing brackets
  if i < len && safe_char_at(path, i) == ']' {
    i = i + 1
  }
  if is_optional && i < len && safe_char_at(path, i) == ']' {
    i = i + 1
  }

  // Note: is_optional could be used for [[...param]] matching
  let _ = is_optional
  (i, param_name, is_catch_all)
}

// =============================================================================
// Path Normalization
// =============================================================================

///|
/// Normalize a URL path (ensure leading slash, remove double slashes)
pub fn normalize_url_path(path : String) -> String {
  if path.is_empty() {
    "/"
  } else if path.has_prefix("/") {
    // Remove any double slashes
    remove_double_slashes(path)
  } else {
    remove_double_slashes("/" + path)
  }
}

///|
/// Remove consecutive slashes from path
fn remove_double_slashes(path : String) -> String {
  let result = StringBuilder::new()
  let mut prev_slash = false
  for ch in path {
    if ch == '/' {
      if not(prev_slash) {
        result.write_char(ch)
      }
      prev_slash = true
    } else {
      result.write_char(ch)
      prev_slash = false
    }
  }
  result.to_string()
}

// =============================================================================
// String Utilities
// =============================================================================

///|
/// Check if character is valid for a parameter name
pub fn is_param_char(ch : Char) -> Bool {
  (ch >= 'a' && ch <= 'z') ||
  (ch >= 'A' && ch <= 'Z') ||
  (ch >= '0' && ch <= '9') ||
  ch == '_'
}

///|
/// Check if character is a regex special character that needs escaping
fn is_regex_special(ch : Char) -> Bool {
  ch == '.' ||
  ch == '+' ||
  ch == '?' ||
  ch == '(' ||
  ch == ')' ||
  ch == '{' ||
  ch == '}' ||
  ch == '^' ||
  ch == '$' ||
  ch == '|'
}

///|
/// Safe character access at index
pub fn safe_char_at(s : String, idx : Int) -> Char {
  if idx < 0 || idx >= s.length() {
    '\u0000'
  } else {
    let code = s.code_unit_at(idx).to_int()
    code.unsafe_to_char()
  }
}

///|
/// Safe substring extraction
pub fn safe_substring(s : String, start : Int, end : Int) -> String {
  if start < 0 || end > s.length() || start >= end {
    ""
  } else {
    let buf = StringBuilder::new()
    for i = start; i < end; i = i + 1 {
      buf.write_char(safe_char_at(s, i))
    }
    buf.to_string()
  }
}
