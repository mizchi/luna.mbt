// Routes Matcher - URL pattern matching
//

///|
/// URLをルートにマッチング
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
  for pair in @utils.split_by(query, '&') {
    let kv = @utils.split_by(pair, '=')
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

  // キャッチオールルートの処理
  match route.catch_all {
    Some(catch_all_info) => {
      // キャッチオールセグメントを除いたパターンセグメント数
      let base_pattern_len = pattern_segments.length() - 1
      let path_len = path_segments.length()

      // 必須キャッチオール: 少なくとも1つのセグメントが必要
      // オプショナルキャッチオール: 0個でもOK
      if catch_all_info.optional {
        if path_len < base_pattern_len {
          return None
        }
        // 必須: path_len >= base_pattern_len + 1
      } else if path_len <= base_pattern_len {
        return None
      }

      // ベースパターンのマッチング
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

      // 残りのセグメントをキャッチオールパラメータに
      let catch_all_segments : Array[String] = []
      for i = base_pattern_len; i < path_len; i = i + 1 {
        catch_all_segments.push(path_segments[i])
      }
      let catch_all_value = join_segments(catch_all_segments)
      params.push((catch_all_info.name, catch_all_value))
      return Some(params)
    }
    None => {
      // 通常のマッチング（キャッチオールなし）
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
/// [id] 形式のパラメータかどうか（キャッチオールは除く）
fn is_bracket_param(s : String) -> Bool {
  s.has_prefix("[") &&
  s.has_suffix("]") &&
  not(s.has_prefix("[...")) &&
  not(s.has_prefix("[[..."))
}

///|
/// セグメントを "/" で結合
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
  @utils.split_by(path, '/').filter(fn(s) { s != "" })
}
