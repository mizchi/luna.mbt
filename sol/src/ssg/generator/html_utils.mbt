// HTML Utilities - Pure utility functions for HTML/URL transformation

// =============================================================================
// Helper Functions (same pattern as transformer.mbt)
// =============================================================================

///|
/// Create a server-side element
fn h(
  tag : String,
  attrs : Array[(String, @luna.Attr[Unit, String])],
  children : Array[@luna.Node[Unit, String]],
) -> @luna.Node[Unit, String] {
  @luna.h(tag, attrs, children)
}

///|
/// Create a static attribute
fn attr(key : String, value : String) -> (String, @luna.Attr[Unit, String]) {
  (key, @luna.attr_static(value))
}

///|
/// Transform internal links in HTML content
/// Converts numeric prefix paths like /00_introduction/ to /introduction/
fn transform_internal_links(html : String, trailing_slash : Bool) -> String {
  // Simple regex-like replacement for href="/NN_name/" patterns
  // We need to find href="..." attributes and transform the paths
  let buf = StringBuilder::new()
  let chars = html.to_array()
  let len = chars.length()
  let mut i = 0
  while i < len {
    // Look for href=" or src="
    if i + 6 < len &&
      chars[i] == 'h' &&
      chars[i + 1] == 'r' &&
      chars[i + 2] == 'e' &&
      chars[i + 3] == 'f' &&
      chars[i + 4] == '=' &&
      chars[i + 5] == '"' {
      // Found href="
      buf.write_string("href=\"")
      i = i + 6
      // Read the URL until closing quote
      let url_start = i
      while i < len && chars[i] != '"' {
        i = i + 1
      }
      let url = String::from_array(chars[url_start:i])
      // Transform the URL if it's an internal link
      let transformed = transform_url_path(url, trailing_slash)
      buf.write_string(transformed)
    } else {
      buf.write_char(chars[i])
      i = i + 1
    }
  }
  buf.to_string()
}

///|
/// Transform a URL path by removing numeric prefixes from path segments
/// e.g., /00_introduction/01_overview/ -> /introduction/overview/
fn transform_url_path(url : String, trailing_slash : Bool) -> String {
  // Only transform internal absolute paths starting with /
  if !(url.has_prefix("/")) || url.has_prefix("//") {
    return url
  }
  // Split by / and process each segment
  let segments = url.split("/").collect()
  let result : Array[String] = []
  for segment in segments {
    if segment.is_empty() {
      result.push("")
    } else {
      // Remove numeric prefix (e.g., "00_intro" -> "intro", "01_getting-started" -> "getting-started")
      let (_, name) = @ssg.parse_numeric_prefix(segment.to_string())
      result.push(name)
    }
  }
  let path = result.join("/")
  // Ensure trailing slash consistency
  if trailing_slash && !(path.has_suffix("/")) && !(path.contains(".")) {
    path + "/"
  } else {
    path
  }
}

// =============================================================================
// HTML Sanitization
// =============================================================================

///|
/// Sanitize HTML by removing potentially dangerous tags
/// Removes: <script>, <iframe>, <object>, <embed>, <form>, on* event handlers
fn sanitize_html(html : String) -> String {
  sanitize_html_js(html)
}

///|
/// JavaScript implementation of HTML sanitization
extern "js" fn sanitize_html_js(html : String) -> String =
  #| (html) => {
  #|   // Remove script tags and their content
  #|   let result = html.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '');
  #|   // Remove iframe, object, embed tags
  #|   result = result.replace(/<iframe\b[^>]*>.*?<\/iframe>/gi, '');
  #|   result = result.replace(/<object\b[^>]*>.*?<\/object>/gi, '');
  #|   result = result.replace(/<embed\b[^>]*\/?>/gi, '');
  #|   // Remove form tags (keep content)
  #|   result = result.replace(/<\/?form\b[^>]*>/gi, '');
  #|   // Remove on* event handlers from all tags
  #|   result = result.replace(/\s+on\w+\s*=\s*["'][^"']*["']/gi, '');
  #|   result = result.replace(/\s+on\w+\s*=\s*[^\s>]+/gi, '');
  #|   // Remove javascript: URLs
  #|   result = result.replace(/\bhref\s*=\s*["']javascript:[^"']*["']/gi, 'href="#"');
  #|   result = result.replace(/\bsrc\s*=\s*["']javascript:[^"']*["']/gi, 'src=""');
  #|   return result;
  #| }

// =============================================================================
// Utility Functions
// =============================================================================

///|
/// Ensure directory exists
fn ensure_dir(path : String) -> Unit {
  @fs.mkdirSync(path, recursive=true) catch {
    _ => ()
  }
}
