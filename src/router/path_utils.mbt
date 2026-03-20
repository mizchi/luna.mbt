// Path utility functions shared across router components

///|
/// Normalize path (remove duplicate slashes, trailing slash)
fn normalize_path(path : String) -> String {
  if path == "" || path == "/" {
    return "/"
  }
  let chars = path.to_array()
  let result : Array[Char] = []
  let mut prev_slash = false
  for c in chars {
    if c == '/' {
      if not(prev_slash) {
        result.push(c)
      }
      prev_slash = true
    } else {
      result.push(c)
      prev_slash = false
    }
  }
  // Remove trailing slash (except for root)
  let len = result.length()
  if len > 1 && result[len - 1] == '/' {
    let _ = result.pop()
  }
  String::from_array(result)
}

///|
fn split_by_char(s : String, c : Char) -> Array[String] {
  let result : Array[String] = []
  let current : Array[Char] = []
  for ch in s {
    if ch == c {
      if current.length() > 0 {
        result.push(String::from_array(current))
        current.clear()
      }
    } else {
      current.push(ch)
    }
  }
  if current.length() > 0 {
    result.push(String::from_array(current))
  }
  result
}

///|
/// Join segments with "/"
fn join_segments(segments : ArrayView[String]) -> String {
  if segments.length() == 0 {
    return ""
  }
  let result = StringBuilder::new()
  for i, seg in segments {
    if i > 0 {
      result.write_string("/")
    }
    result.write_string(seg)
  }
  result.to_string()
}

///|
/// Extract parameter names from path pattern (excludes catch-all)
/// Example: "/user/:id/posts/:postId" -> ["id", "postId"]
fn extract_param_names(path : String) -> Array[String] {
  let result : Array[String] = []
  let segments = split_by_char(path, '/')
  for segment in segments {
    if segment.has_prefix(":") && segment.length() > 1 {
      let name = segment[1:].to_string() catch { _ => continue }
      result.push(name)
    } else if segment.has_prefix("[") &&
      not(segment.has_prefix("[...")) &&
      not(segment.has_prefix("[[...")) {
      // [id] style param (Next.js style)
      if segment.has_suffix("]") && segment.length() > 2 {
        let name = segment[1:segment.length() - 1].to_string() catch {
          _ => continue
        }
        result.push(name)
      }
    }
  }
  result
}

///|
/// Extract catch-all info from path pattern
/// Example: "/docs/[...slug]" -> Some({ name: "slug", optional: false })
///          "/docs/[[...slug]]" -> Some({ name: "slug", optional: true })
fn extract_catch_all(path : String) -> CatchAllInfo? {
  let segments = split_by_char(path, '/')
  if segments.is_empty() {
    return None
  }
  let last = segments[segments.length() - 1]
  // Optional catch-all: [[...name]]
  if last.has_prefix("[[...") && last.has_suffix("]]") && last.length() > 7 {
    let name = last[5:last.length() - 2].to_string() catch { _ => return None }
    return Some({ name, optional: true })
  }
  // Required catch-all: [...name]
  if last.has_prefix("[...") && last.has_suffix("]") && last.length() > 5 {
    let name = last[4:last.length() - 1].to_string() catch { _ => return None }
    return Some({ name, optional: false })
  }
  None
}

///|
/// Convert catch-all pattern to Hono v4 regex pattern
/// Example: "/docs/[...slug]" -> "/docs/:slug{.+}"    (required: 1+ chars)
///          "/blog/[[...path]]" -> "/blog/:path{.*}?" (optional: 0+ chars)
fn convert_to_hono_pattern(path : String, catch_all : CatchAllInfo?) -> String {
  match catch_all {
    Some(info) => {
      // Remove the catch-all segment and add Hono v4 regex pattern
      let segments = split_by_char(path, '/')
      let base_segments = segments[0:segments.length() - 1]
      let base = if base_segments.length() == 0 {
        ""
      } else {
        "/" + join_segments(base_segments)
      }
      // Hono v4: :name{regex} for named catch-all
      // Required: {.+} matches 1 or more chars (must have at least one segment)
      // Optional: {.*}? matches 0 or more chars (can be empty)
      if info.optional {
        base + "/:" + info.name + "{.*}?"
      } else {
        base + "/:" + info.name + "{.+}"
      }
    }
    None => path
  }
}
