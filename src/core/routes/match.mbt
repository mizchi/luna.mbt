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
    guard pair != "" else { continue }
    let (raw_key, raw_value_opt) = split_query_pair(pair)
    let key = decode_query_component(raw_key)
    if key == "" {
      continue
    }
    let value = match raw_value_opt {
      Some(raw_value) => decode_query_component(raw_value)
      None => ""
    }
    result.push((key, value))
  }
  result
}

///|
/// Split query pair by first '=' only.
/// "a=b=c" -> ("a", Some("b=c"))
fn split_query_pair(pair : String) -> (String, String?) {
  let chars = pair.to_array()
  let mut eq_index = -1
  for i, c in chars {
    if c == '=' {
      eq_index = i
      break
    }
  }
  if eq_index == -1 {
    (pair, None)
  } else {
    let key = String::from_array(chars[0:eq_index])
    let value = String::from_array(chars[eq_index + 1:])
    (key, Some(value))
  }
}

///|
/// Decode query component:
/// - '+' -> ' '
/// - percent encoding (%20 etc.) decoded as UTF-8 byte sequence
fn decode_query_component(s : String) -> String {
  let chars = s.to_array()
  let len = chars.length()
  let sb = StringBuilder::new(size_hint=len)
  let mut i = 0
  while i < len {
    let c = chars[i]
    let has_percent_triplet = c == '%' &&
      i + 2 < len &&
      is_hex_digit(chars[i + 1]) &&
      is_hex_digit(chars[i + 2])
    if c == '+' {
      sb.write_char(' ')
      i += 1
    } else if has_percent_triplet {
      let (decoded, next_i) = decode_percent_encoded_bytes(chars, i, len)
      sb.write_string(decoded)
      i = next_i
    } else {
      sb.write_char(c)
      i += 1
    }
  }
  sb.to_string()
}

///|
/// Decode contiguous percent-encoded bytes from `start`.
/// Returns (decoded_string, next_index_after_percent_run).
fn decode_percent_encoded_bytes(
  chars : Array[Char],
  start : Int,
  len : Int,
) -> (String, Int) {
  let bytes : Array[Byte] = []
  let mut i = start
  while i + 2 < len && chars[i] == '%' {
    let hi = chars[i + 1]
    let lo = chars[i + 2]
    if not(is_hex_digit(hi) && is_hex_digit(lo)) {
      break
    }
    let byte = hex_digit_to_int(hi) * 16 + hex_digit_to_int(lo)
    bytes.push(byte.to_byte())
    i += 3
  }
  (decode_percent_bytes(bytes), i)
}

///|
/// Decode bytes as UTF-8. If malformed, fall back to byte-wise chars.
fn decode_percent_bytes(bytes : Array[Byte]) -> String {
  let raw = Bytes::from_array(bytes)
  @utf8.decode(raw) catch {
    _ => {
      let fallback : Array[Char] = []
      for b in bytes {
        fallback.push(b.to_int().unsafe_to_char())
      }
      String::from_array(fallback)
    }
  }
}

///|
fn is_hex_digit(c : Char) -> Bool {
  (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')
}

///|
fn hex_digit_to_int(c : Char) -> Int {
  if c >= '0' && c <= '9' {
    c.to_int() - '0'.to_int()
  } else if c >= 'a' && c <= 'f' {
    c.to_int() - 'a'.to_int() + 10
  } else {
    c.to_int() - 'A'.to_int() + 10
  }
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
      for i in 0..<base_pattern_len {
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
      for i in base_pattern_len..<path_len {
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
