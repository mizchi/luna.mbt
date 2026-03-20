// Link Validator - Build-time internal link validation for SSG
// Detects broken internal links in markdown/MDX content

// =============================================================================
// Types
// =============================================================================

///|
/// Diagnostic for a broken internal link
pub(all) struct LinkDiagnostic {
  source_page : String // page where the broken link was found
  target_link : String // the broken link
  message : String
}

// =============================================================================
// Internal Link Extraction
// =============================================================================

///|
/// Extract all internal link targets from markdown/HTML content.
/// Finds markdown links [text](url) and HTML href="url" attributes.
/// Returns only internal links (starting with `/`), excluding:
/// - External URLs (http:// or https://)
/// - Fragment-only links (#section)
/// - Empty links
/// Anchors and query strings are stripped from returned URLs.
pub fn extract_internal_links(content : String) -> Array[String] {
  let links : Array[String] = []
  let chars = content.to_array()
  let len = chars.length()
  let mut i = 0
  while i < len {
    // Try to match markdown link: [text](url)
    if chars[i] == '[' {
      let bracket_start = i
      let mut j = i + 1
      let mut depth = 1
      while j < len && depth > 0 {
        if chars[j] == '[' {
          depth += 1
        } else if chars[j] == ']' {
          depth -= 1
        }
        j += 1
      }
      // j now points after ]
      if depth == 0 && j < len && chars[j] == '(' {
        // Found markdown link syntax - extract URL
        let paren_start = j + 1
        let mut k = paren_start
        // Find closing ) - scan until unescaped )
        while k < len && chars[k] != ')' {
          k += 1
        }
        if k < len {
          // Extract raw URL substring (may include title like "url \"title\"")
          let raw = content.substring(start=paren_start, end=k)
          // Split on first space to get URL part (title in quotes follows)
          let url = match raw.find(" ") {
            Some(space_idx) => raw.substring(end=space_idx)
            None => raw
          }
          let trimmed = url.trim(chars=" \t\n\r").to_string()
          if is_internal_link(trimmed) {
            links.push(normalize_link(trimmed))
          }
          i = k + 1
          continue
        } else {
          i = bracket_start + 1
          continue
        }
      } else {
        i = bracket_start + 1
        continue
      }
    }
    // Try to match HTML href="url" or href='url'
    // Check for 'h' 'r' 'e' 'f' '='
    if i + 4 < len &&
      chars[i] == 'h' &&
      chars[i + 1] == 'r' &&
      chars[i + 2] == 'e' &&
      chars[i + 3] == 'f' &&
      chars[i + 4] == '=' {
      let quote_start = i + 5
      if quote_start < len {
        let quote_char = chars[quote_start]
        if quote_char == '"' || quote_char == '\'' {
          let url_start = quote_start + 1
          let mut k = url_start
          while k < len && chars[k] != quote_char {
            k += 1
          }
          if k < len {
            let url = content.substring(start=url_start, end=k)
            let trimmed = url.trim(chars=" \t\n\r").to_string()
            if is_internal_link(trimmed) {
              links.push(normalize_link(trimmed))
            }
            i = k + 1
            continue
          }
        }
      }
    }
    i += 1
  }
  links
}

///|
/// Determine if a URL is an internal link that should be validated.
/// Internal links start with `/` but are not:
/// - External (http:// or https://)
/// - Fragment-only (#something)
/// - Empty
fn is_internal_link(url : String) -> Bool {
  if url.is_empty() {
    return false
  }
  // External protocols
  if url.has_prefix("http://") ||
    url.has_prefix("https://") ||
    url.has_prefix("mailto:") ||
    url.has_prefix("ftp://") ||
    url.has_prefix("//") {
    return false
  }
  // Fragment-only links
  if url.has_prefix("#") {
    return false
  }
  // Must start with / to be a root-relative internal link
  url.has_prefix("/")
}

///|
/// Normalize a link for comparison with known URLs.
/// Strips fragment (#section) and query string (?query) parts.
fn normalize_link(url : String) -> String {
  // Strip fragment
  let without_fragment = match url.find("#") {
    Some(idx) => url.substring(end=idx)
    None => url
  }
  // Strip query string
  let without_query = match without_fragment.find("?") {
    Some(idx) => without_fragment.substring(end=idx)
    None => without_fragment
  }
  without_query
}

// =============================================================================
// Validation
// =============================================================================

///|
/// Validate internal links across all pages.
///
/// Takes an array of (source_path, content) pairs and a map of known page URLs
/// (keys are the URL paths), and returns diagnostics for any broken internal
/// links found.
///
/// Ignores:
/// - External URLs (http:// or https://)
/// - Fragment-only links (#section)
/// - Query strings (?query) - stripped before checking
/// - Anchors within URLs - stripped before checking
pub fn validate_internal_links(
  pages : Array[(String, String)],
  known_urls : Map[String, Bool],
) -> Array[LinkDiagnostic] {
  let diagnostics : Array[LinkDiagnostic] = []
  for entry in pages {
    let (source_path, content) = entry
    let links = extract_internal_links(content)
    for link in links {
      if not(known_urls.contains(link)) {
        diagnostics.push(LinkDiagnostic::{
          source_page: source_path,
          target_link: link,
          message: "Broken internal link: '\{link}' not found in site pages",
        })
      }
    }
  }
  diagnostics
}

///|
/// Build a URL set from an array of page URL paths.
/// Convenience helper to create the known_urls map for validate_internal_links.
pub fn build_url_set(url_paths : Array[String]) -> Map[String, Bool] {
  let m : Map[String, Bool] = {}
  for url in url_paths {
    m[url] = true
  }
  m
}
