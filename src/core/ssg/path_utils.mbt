// SSG Path Utilities
//
// Path manipulation and string operations for static site generation.
// Handles numeric prefix parsing, URL conversion, and path transformations.
//
// String utilities (slice_from, slice_to, etc.) are imported from @utils.

// =============================================================================
// Numeric Prefix Handling
// =============================================================================

///|
/// Simple integer parser (positive only)
pub fn parse_int_simple(s : String) -> Int {
  let mut result = 0
  for c in s {
    if c >= '0' && c <= '9' {
      result = result * 10 + (c.to_int() - '0'.to_int())
    }
  }
  result
}

///|
/// Parse numeric prefix from a path segment (e.g., "00_guide" -> (0, "guide"))
/// Returns (sort_order, stripped_name). If no prefix, returns (max_int, original)
pub fn parse_numeric_prefix(name : String) -> (Int, String) {
  let chars = name.to_array()
  let mut i = 0
  while i < chars.length() && chars[i] >= '0' && chars[i] <= '9' {
    i = i + 1
  }
  if i > 0 && i < chars.length() && chars[i] == '_' {
    let num_str = @utils.slice_to(name, i)
    let stripped = @utils.slice_from(name, i + 1)
    let num = parse_int_simple(num_str)
    (num, stripped)
  } else {
    (2147483647, name)
  }
}

///|
/// Strip numeric prefixes from all segments of a path
/// e.g., "00_guide/01_intro.md" -> "guide/intro.md"
pub fn strip_numeric_prefixes(path : String) -> String {
  let segments = path.split("/")
  let stripped : Array[String] = []
  for seg in segments {
    let (_, name) = parse_numeric_prefix(seg.to_string())
    stripped.push(name)
  }
  stripped.join("/")
}

///|
/// Pad number with leading zeros
pub fn pad_number(n : Int, width : Int) -> String {
  let s = n.to_string()
  if s.length() >= width {
    s
  } else {
    let zeros = width - s.length()
    let mut result = ""
    for i = 0; i < zeros; i = i + 1 {
      result = result + "0"
    }
    result + s
  }
}

///|
/// Build sort key from path (preserves structure for proper sorting)
/// e.g., "00_guide/01_intro.md" -> "00000000_guide/00000001_intro.md"
pub fn build_sort_key(path : String) -> String {
  let segments = path.split("/")
  let keyed : Array[String] = []
  for seg in segments {
    let (order, name) = parse_numeric_prefix(seg.to_string())
    let padded = pad_number(order, 8)
    keyed.push(padded + "_" + name)
  }
  keyed.join("/")
}

// =============================================================================
// Path Conversion
// =============================================================================

///|
/// Convert file path to URL path (strips numeric prefixes)
/// 00_guide/01_getting-started.md -> /guide/getting-started/ (with trailing slash)
/// 00_guide/01_getting-started.md -> /guide/getting-started (without trailing slash)
/// docs/index.md -> /
pub fn file_to_url_path(
  file_path : String,
  trailing_slash? : Bool = true,
) -> String {
  let stripped = strip_numeric_prefixes(file_path)
  let path = stripped
    .replace(old=".mdx", new="")
    .replace(old=".md", new="")
    .replace(old=".html", new="")
    .replace(old="\\", new="/")
  if path.has_suffix("/index") {
    let trimmed = @utils.slice_to(path, path.length() - 6)
    if trimmed.is_empty() {
      "/"
    } else if trailing_slash {
      "/" + trimmed + "/"
    } else {
      "/" + trimmed
    }
  } else if path == "index" {
    "/"
  } else if trailing_slash {
    "/" + path + "/"
  } else {
    "/" + path
  }
}

///|
/// Convert URL path to output file path
/// / -> index.html
/// /guide/intro -> guide/intro/index.html
pub fn url_to_output_path(url_path : String) -> String {
  if url_path == "/" {
    "index.html"
  } else {
    let trimmed = if url_path.has_prefix("/") {
      @utils.slice_from(url_path, 1)
    } else {
      url_path
    }
    if trimmed.has_suffix("/") {
      trimmed + "index.html"
    } else {
      trimmed + "/index.html"
    }
  }
}

// =============================================================================
// String Comparison
// =============================================================================

///|
/// Compare two strings with proper lexicographic ordering
pub fn compare_strings_lex(a : String, b : String) -> Int {
  let a_chars = a.to_array()
  let b_chars = b.to_array()
  let min_len = if a_chars.length() < b_chars.length() {
    a_chars.length()
  } else {
    b_chars.length()
  }
  for i = 0; i < min_len; i = i + 1 {
    if a_chars[i] < b_chars[i] {
      return -1
    }
    if a_chars[i] > b_chars[i] {
      return 1
    }
  }
  if a_chars.length() < b_chars.length() {
    -1
  } else if a_chars.length() > b_chars.length() {
    1
  } else {
    0
  }
}

// =============================================================================
// String Utilities
// =============================================================================

///|
/// Capitalize first letter of a string
pub fn capitalize_first(s : String) -> String {
  if s.is_empty() {
    return s
  }
  let chars = s.to_array()
  let first = chars[0]
  if first >= 'a' && first <= 'z' {
    chars[0] = Int::unsafe_to_char(first.to_int() - 32)
  }
  String::from_array(chars)
}

///|
/// Get directory part of a path
pub fn get_dir_name(path : String) -> String {
  let parts = path.split("/").to_array()
  if parts.length() > 0 {
    parts[parts.length() - 1].to_string()
  } else {
    ""
  }
}

///|
/// Get directory part of URL path
pub fn get_url_dir(url_path : String) -> String {
  let trimmed = if url_path.has_prefix("/") {
    @utils.slice_from(url_path, 1)
  } else {
    url_path
  }
  match trimmed.rev_find("/") {
    Some(idx) => "/" + @utils.slice_to(trimmed, idx)
    None => "/"
  }
}

// =============================================================================
// Locale Suffix Extraction
// =============================================================================

///|
/// Extract locale suffix from filename
/// "intro.ja.md" → Some(("ja", "intro.md"))
/// "intro.md" → None
pub fn extract_locale_suffix(
  filename : String,
  locale_codes : Array[String],
) -> (String, String)? {
  // Find extension: .md, .mdx, .html
  let ext = if filename.has_suffix(".mdx") {
    ".mdx"
  } else if filename.has_suffix(".md") {
    ".md"
  } else if filename.has_suffix(".html") {
    ".html"
  } else {
    return None
  }
  // Strip extension: "intro.ja.md" → "intro.ja"
  let without_ext = @utils.slice_to(filename, filename.length() - ext.length())
  // Find last dot for locale: "intro.ja" → "ja"
  match without_ext.rev_find(".") {
    Some(dot_idx) => {
      let potential_locale = @utils.slice_from(without_ext, dot_idx + 1)
      // Check if it's a valid locale code
      for code in locale_codes {
        if code == potential_locale {
          let base_name = @utils.slice_to(without_ext, dot_idx)
          let clean_filename = base_name + ext
          return Some((code, clean_filename))
        }
      }
      None
    }
    None => None
  }
}

///|
/// Get filename from path
/// "guide/intro.ja.md" → "intro.ja.md"
pub fn get_filename(path : String) -> String {
  match path.rev_find("/") {
    Some(idx) => @utils.slice_from(path, idx + 1)
    None => path
  }
}

///|
/// Replace filename in path
/// ("guide/intro.ja.md", "intro.md") → "guide/intro.md"
pub fn replace_filename(path : String, new_filename : String) -> String {
  match path.rev_find("/") {
    Some(idx) => @utils.slice_to(path, idx + 1) + new_filename
    None => new_filename
  }
}
