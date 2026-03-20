// Path utility functions shared across router components

///|
/// Normalize path (remove duplicate slashes, trailing slash)
fn normalize_path(path : String) -> String {
  if path == "" || path == "/" {
    return "/"
  }
  let buf = StringBuilder::new()
  let mut prev_slash = false
  for c in path {
    if c == '/' {
      if not(prev_slash) {
        buf.write_char(c)
      }
      prev_slash = true
    } else {
      buf.write_char(c)
      prev_slash = false
    }
  }
  // Remove trailing slash: prev_slash tracks if last char was '/'
  let s = buf.to_string()
  if prev_slash && s.length() > 1 {
    s.substring(end=s.length() - 1)
  } else {
    s
  }
}

///|
fn split_by_char(s : String, c : Char) -> Array[String] {
  let result : Array[String] = []
  let current = StringBuilder::new()
  for ch in s {
    if ch == c {
      let seg = current.to_string()
      if seg.length() > 0 {
        result.push(seg)
        current.reset()
      }
    } else {
      current.write_char(ch)
    }
  }
  let seg = current.to_string()
  if seg.length() > 0 {
    result.push(seg)
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
      let name = segment[1:].to_string()
      result.push(name)
    } else if segment.has_prefix("[") &&
      not(segment.has_prefix("[...")) &&
      not(segment.has_prefix("[[...")) {
      // [id] style param (Next.js style)
      if segment.has_suffix("]") && segment.length() > 2 {
        let name = segment[1:segment.length() - 1].to_string()
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
  match segments[0:] {
    [.., last] => {
      // Optional catch-all: [[...name]]
      if last.has_prefix("[[...") && last.has_suffix("]]") && last.length() > 7 {
        let name = last[5:last.length() - 2].to_string()
        return Some({ name, optional: true })
      }
      // Required catch-all: [...name]
      if last.has_prefix("[...") && last.has_suffix("]") && last.length() > 5 {
        let name = last[4:last.length() - 1].to_string()
        return Some({ name, optional: false })
      }
      None
    }
    [] => None
  }
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
      match segments[0:] {
        [.. base_segs, _] => {
          let base = if base_segs.length() == 0 {
            ""
          } else {
            "/" + join_segments(base_segs)
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
        [] => path
      }
    }
    None => path
  }
}
