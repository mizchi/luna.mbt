// Internal utilities for serialize package (inlined to avoid cross-package dependencies)

///|
/// Extract substring from start to end position
fn extract_substring(s : String, start : Int, end : Int) -> String {
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
