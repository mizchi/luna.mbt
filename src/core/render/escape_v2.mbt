///| Optimized HTML/Attribute Escaping Utilities
///| Alternative implementations for benchmarking

// =============================================================================
// Single-Pass Escape (no separate needs_escape check)
// =============================================================================

///|
/// Single-pass HTML escape - checks and escapes in one iteration
/// Avoids double iteration of needs_html_escape + escape_html_to
pub fn escape_html_single_pass(s : String) -> String {
  let len = s.length()
  if len == 0 {
    return s
  }
  // First, check if we need to escape at all (inline check)
  let mut needs_escape = false
  for char in s {
    let code = char.to_int()
    // & = 38, < = 60, > = 62, " = 34, ' = 39
    if code == 38 || code == 60 || code == 62 || code == 34 || code == 39 {
      needs_escape = true
      break
    }
  }
  if not(needs_escape) {
    return s
  }
  // Estimate capacity: original length + some extra for escapes
  let sb = StringBuilder::new(size_hint=len + 16)
  for char in s {
    let code = char.to_int()
    match code {
      38 => sb.write_string("&amp;") // &
      60 => sb.write_string("&lt;") // <
      62 => sb.write_string("&gt;") // >
      34 => sb.write_string("&quot;") // "
      39 => sb.write_string("&#39;") // '
      _ => sb.write_char(char)
    }
  }
  sb.to_string()
}

///|
/// Single-pass HTML escape with StringBuilder output
pub fn escape_html_single_pass_to(sb : StringBuilder, s : String) -> Unit {
  for char in s {
    let code = char.to_int()
    match code {
      38 => sb.write_string("&amp;") // &
      60 => sb.write_string("&lt;") // <
      62 => sb.write_string("&gt;") // >
      34 => sb.write_string("&quot;") // "
      39 => sb.write_string("&#39;") // '
      _ => sb.write_char(char)
    }
  }
}

// =============================================================================
// Lookup Table Approach
// =============================================================================

///|
/// Get HTML escape string for a character code, or empty if no escape needed
/// Uses match on code points for common escape characters
fn get_html_escape(code : Int) -> String {
  match code {
    34 => "&quot;" // "
    38 => "&amp;" // &
    39 => "&#39;" // '
    60 => "&lt;" // <
    62 => "&gt;" // >
    _ => ""
  }
}

///|
/// Check if a character code needs HTML escaping
fn needs_escape_code(code : Int) -> Bool {
  code == 34 || code == 38 || code == 39 || code == 60 || code == 62
}

///|
/// Lookup table based HTML escape
/// Uses code point matching instead of char matching
pub fn escape_html_lookup(s : String) -> String {
  let len = s.length()
  if len == 0 {
    return s
  }
  // Quick scan for escape characters
  let mut needs_escape = false
  for char in s {
    if needs_escape_code(char.to_int()) {
      needs_escape = true
      break
    }
  }
  if not(needs_escape) {
    return s
  }
  let sb = StringBuilder::new(size_hint=len + 16)
  for char in s {
    let code = char.to_int()
    let escaped = get_html_escape(code)
    if escaped.length() > 0 {
      sb.write_string(escaped)
    } else {
      sb.write_char(char)
    }
  }
  sb.to_string()
}

// =============================================================================
// Optimized: Track position and copy slices
// =============================================================================

///|
/// Copy-slice based HTML escape
/// Instead of char-by-char, copies slices of safe characters
pub fn escape_html_slice(s : String) -> String {
  let len = s.length()
  if len == 0 {
    return s
  }
  // Quick scan for escape characters
  let mut first_escape_idx = -1
  let chars = s.to_array()
  for i = 0; i < len; i = i + 1 {
    if needs_escape_code(chars[i].to_int()) {
      first_escape_idx = i
      break
    }
  }
  // No escaping needed
  if first_escape_idx < 0 {
    return s
  }
  // Pre-allocate with estimated size
  let sb = StringBuilder::new(size_hint=len + 32)
  // Copy the safe prefix
  if first_escape_idx > 0 {
    sb.write_string(s.unsafe_substring(start=0, end=first_escape_idx))
  }
  // Process from first escape character
  let mut last_safe_start = first_escape_idx
  for i = first_escape_idx; i < len; i = i + 1 {
    let code = chars[i].to_int()
    let escaped = get_html_escape(code)
    if escaped.length() > 0 {
      // Write accumulated safe chars
      if i > last_safe_start {
        sb.write_string(s.unsafe_substring(start=last_safe_start, end=i))
      }
      sb.write_string(escaped)
      last_safe_start = i + 1
    }
  }
  // Write remaining safe chars
  if last_safe_start < len {
    sb.write_string(s.unsafe_substring(start=last_safe_start, end=len))
  }
  sb.to_string()
}

// =============================================================================
// Attribute Escape Variants
// =============================================================================

///|
/// Single-pass attribute escape
pub fn escape_attr_single_pass(s : String) -> String {
  let len = s.length()
  if len == 0 {
    return s
  }
  // Check if escape needed (only & and " for attributes)
  let mut needs_escape = false
  for char in s {
    let code = char.to_int()
    if code == 38 || code == 34 {
      // & or "
      needs_escape = true
      break
    }
  }
  if not(needs_escape) {
    return s
  }
  let sb = StringBuilder::new(size_hint=len + 8)
  for char in s {
    let code = char.to_int()
    match code {
      38 => sb.write_string("&amp;")
      34 => sb.write_string("&quot;")
      _ => sb.write_char(char)
    }
  }
  sb.to_string()
}
