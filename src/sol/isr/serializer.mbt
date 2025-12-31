// ISR Manifest Serialization
//
// JSON serialization for ISR manifest (used by SSG at build time).

// =============================================================================
// JSON Serialization
// =============================================================================

///|
/// Serialize manifest to JSON string
pub fn ISRManifest::to_json(self : ISRManifest) -> String {
  let buf = StringBuilder::new()
  buf.write_string("{\n")
  buf.write_string("  \"version\": \{self.version},\n")
  buf.write_string("  \"pages\": {")
  let mut first = true
  for url_path, entry in self.pages {
    if not(first) {
      buf.write_string(",")
    }
    first = false
    buf.write_string("\n    \"")
    buf.write_string(escape_json(url_path))
    buf.write_string("\": {")
    buf.write_string("\"revalidate\": \{entry.revalidate}, ")
    buf.write_string("\"renderer\": \"")
    buf.write_string(entry.renderer)
    buf.write_string("\", \"source\": \"")
    buf.write_string(escape_json(entry.source))
    buf.write_string("\"}")
  }
  if not(self.pages.is_empty()) {
    buf.write_string("\n  ")
  }
  buf.write_string("}\n}")
  buf.to_string()
}

///|
/// Escape special characters for JSON string
fn escape_json(s : String) -> String {
  let buf = StringBuilder::new()
  for c in s {
    if c == '\\' {
      buf.write_string("\\\\")
    } else if c == '"' {
      buf.write_string("\\\"")
    } else if c == '\n' {
      buf.write_string("\\n")
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}
