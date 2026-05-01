// Generic String Utilities
//
// Shared string manipulation helpers used across Luna modules.

// =============================================================================
// String Slice Helpers
// =============================================================================

///|
/// Safely slice string from start index
pub fn slice_from(s : String, start : Int) -> String {
  if start >= s.length() || start < 0 {
    ""
  } else {
    s[start:].to_string() catch {
      _ => ""
    }
  }
}

///|
/// Safely slice string to end index
pub fn slice_to(s : String, end : Int) -> String {
  if end <= 0 || end > s.length() {
    s
  } else {
    s[:end].to_string() catch {
      _ => s
    }
  }
}

///|
/// Safely slice StringView from start index
pub fn slice_view_from(s : StringView, start : Int) -> String {
  if start >= s.length() || start < 0 {
    ""
  } else {
    s[start:].to_string() catch {
      _ => ""
    }
  }
}

///|
/// Safely slice StringView to end index
pub fn slice_view_to(s : StringView, end : Int) -> String {
  if end <= 0 || end > s.length() {
    s.to_string()
  } else {
    s[:end].to_string() catch {
      _ => s.to_string()
    }
  }
}

// =============================================================================
// String Split and Extract
// =============================================================================

///|
/// Split string by a single separator character
pub fn split_by(s : String, sep : Char) -> Array[String] {
  let result : Array[String] = []
  let chars = s.to_array()
  let current : Array[Char] = []
  for c in chars {
    if c == sep {
      result.push(String::from_array(current))
      current.clear()
    } else {
      current.push(c)
    }
  }
  result.push(String::from_array(current))
  result
}

///|
/// Extract string until one of the delimiter characters
pub fn extract_until(s : String, delimiters : Array[Char]) -> String {
  let buf = StringBuilder::new()
  for c in s {
    if delimiters.contains(c) {
      break
    }
    buf.write_char(c)
  }
  buf.to_string()
}

///|
/// Extract substring from start to end position
pub fn extract_substring(s : String, start : Int, end : Int) -> String {
  let buf = StringBuilder::new()
  let mut idx = 0
  for c in s {
    if idx >= start && idx < end {
      buf.write_char(c)
    }
    idx = idx + 1
    if idx >= end {
      break
    }
  }
  buf.to_string()
}
