///|
/// Derive a valid custom element name for a component module URL.
/// Plain filenames need a hyphen so browsers can attach Declarative Shadow DOM.
pub fn component_tag_name(url : String) -> String {
  let pathname = url.split("?").to_array()[0].split("#").to_array()[0]
  let parts = pathname.split("/").to_array()
  let filename = parts[parts.length() - 1].to_owned().to_lower()
  let stem = if filename.has_suffix(".js") {
    filename[:filename.length() - 3].to_owned()
  } else {
    filename
  }
  let buf = StringBuilder()
  for c in stem {
    match c {
      'a'..='z' | '0'..='9' | '-' | '.' => buf.write_char(c)
      _ => buf.write_char('-')
    }
  }
  let name = buf.to_string()
  if name.is_empty() {
    return "luna-island"
  }
  let reserved = [
    "annotation-xml", "color-profile", "font-face", "font-face-src", "font-face-uri",
    "font-face-format", "font-face-name", "missing-glyph",
  ]
  if !name.contains("-") ||
    !(name[0] >= 'a' && name[0] <= 'z') ||
    reserved.contains(name) {
    "luna-" + name
  } else {
    name
  }
}
