// Routes Matcher - URL pattern matching
//

///|
/// Match URL to routes
pub fn match_url(url : String, routes : Array[CompiledRoutes]) -> RoutesMatch? {
  let (path, query) = parse_url_parts(url)
  for route in routes {
    if try_match_pattern(path, route) is Some(params) {
      return Some({ route, params, query, path })
    }
  }
  None
}

///|
fn parse_url_parts(url : String) -> (String, Array[(String, String)]) {
  let chars = url.to_array()
  let mut query_start = -1
  for i, c in chars {
    if c == '?' {
      query_start = i
      break
    }
  }
  if query_start == -1 {
    return (url, [])
  }
  let path = String::from_array(chars[0:query_start])
  let query_str = String::from_array(chars[query_start + 1:])
  let query = parse_query(query_str)
  (path, query)
}

///|
fn parse_query(query : String) -> Array[(String, String)] {
  guard query != "" else { return [] }
  let result : Array[(String, String)] = []
  for pair in split_by(query, '&') {
    let kv = split_by(pair, '=')
    if kv.length() == 2 {
      result.push((kv[0], kv[1]))
    } else if kv.length() == 1 && kv[0] != "" {
      result.push((kv[0], ""))
    }
  }
  result
}

///|
fn try_match_pattern(
  path : String,
  route : CompiledRoutes,
) -> Array[(String, String)]? {
  let pattern_segments = split_path_segments(route.pattern)
  let path_segments = split_path_segments(path)

  // Handle catch-all routes
  match route.catch_all {
    Some(catch_all_info) => {
      // Pattern segment count excluding catch-all segment
      let base_pattern_len = pattern_segments.length() - 1
      let path_len = path_segments.length()

      // Required catch-all: needs at least one segment
      // Optional catch-all: zero segments is OK
      if catch_all_info.optional {
        if path_len < base_pattern_len {
          return None
        }
        // Required: path_len >= base_pattern_len + 1
      } else if path_len <= base_pattern_len {
        return None
      }

      // Base pattern matching
      let params : Array[(String, String)] = []
      let mut param_idx = 0
      for i = 0; i < base_pattern_len; i = i + 1 {
        let pattern_seg = pattern_segments[i]
        let path_seg = path_segments[i]
        if starts_with_char(pattern_seg, ':') || is_bracket_param(pattern_seg) {
          if param_idx < route.param_names.length() {
            params.push((route.param_names[param_idx], path_seg))
            param_idx += 1
          } else {
            return None
          }
        } else if pattern_seg != path_seg {
          return None
        }
      }

      // Collect remaining segments as catch-all parameter
      let catch_all_segments : Array[String] = []
      for i = base_pattern_len; i < path_len; i = i + 1 {
        catch_all_segments.push(path_segments[i])
      }
      let catch_all_value = join_segments(catch_all_segments)
      params.push((catch_all_info.name, catch_all_value))
      return Some(params)
    }
    None => {
      // Normal matching (no catch-all)
      if pattern_segments.length() != path_segments.length() {
        return None
      }
      let params : Array[(String, String)] = []
      let mut param_idx = 0
      for i, pattern_seg in pattern_segments {
        let path_seg = path_segments[i]
        if starts_with_char(pattern_seg, ':') || is_bracket_param(pattern_seg) {
          if param_idx < route.param_names.length() {
            params.push((route.param_names[param_idx], path_seg))
            param_idx += 1
          } else {
            return None
          }
        } else if pattern_seg != path_seg {
          return None
        }
      }
      Some(params)
    }
  }
}

///|
fn starts_with_char(s : String, c : Char) -> Bool {
  s.has_prefix(c.to_string())
}

///|
/// Check if segment is a [id] style parameter (excluding catch-all)
fn is_bracket_param(s : String) -> Bool {
  s.has_prefix("[") &&
  s.has_suffix("]") &&
  not(s.has_prefix("[...")) &&
  not(s.has_prefix("[[..."))
}

///|
/// Join segments with "/"
fn join_segments(segments : Array[String]) -> String {
  if segments.is_empty() {
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
fn split_path_segments(path : String) -> Array[String] {
  split_by(path, '/').filter(fn(s) { s != "" })
}
