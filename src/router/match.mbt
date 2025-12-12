///| URL Matching - Match URL against compiled routes

///|
/// マッチ結果
pub struct MatchResult {
  route : CompiledRoute
  props : RouteProps
}

///|
/// URLをコンパイル済みルートに対してマッチング
pub fn match_route(
  url : String,
  routes : Array[CompiledRoute],
  is_client : Bool,
) -> MatchResult? {
  let (path, query) = parse_url(url)
  for route in routes {
    match try_match(path, route) {
      Some(params) => {
        let props : RouteProps = { is_client, params, query, path }
        return Some({ route, props })
      }
      None => continue
    }
  }
  None
}

///|
/// URLをパスとクエリに分割
fn parse_url(url : String) -> (String, Array[(String, String)]) {
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
  let query = parse_query_string(query_str)
  (path, query)
}

///|
/// クエリ文字列をパース
fn parse_query_string(query : String) -> Array[(String, String)] {
  if query == "" {
    return []
  }
  let result : Array[(String, String)] = []
  let pairs = split_string(query, '&')
  for pair in pairs {
    let kv = split_string(pair, '=')
    if kv.length() == 2 {
      result.push((kv[0], kv[1]))
    } else if kv.length() == 1 && kv[0] != "" {
      result.push((kv[0], ""))
    }
  }
  result
}

///|
/// 文字列を区切り文字で分割
fn split_string(s : String, sep : Char) -> Array[String] {
  let result : Array[String] = []
  let chars = s.to_array()
  let current : Array[Char] = []
  for c in chars {
    if c == sep {
      result.push(String::from_array(current))
      current.clear()
    } else {
      current.push(c)
    }
  }
  result.push(String::from_array(current))
  result
}

///|
/// ルートパターンに対してパスをマッチング
/// パターンは :param 形式のプレースホルダーを含む
fn try_match(path : String, route : CompiledRoute) -> Array[(String, String)]? {
  let pattern = route.pattern
  let param_names = route.param_names

  // パターンとパスをセグメントに分割
  let pattern_segments = split_path(pattern)
  let path_segments = split_path(path)

  // セグメント数が異なる場合はマッチしない
  if pattern_segments.length() != path_segments.length() {
    return None
  }

  // パラメータを収集しながらセグメントを比較
  let params : Array[(String, String)] = []
  let mut param_idx = 0
  for i, pattern_seg in pattern_segments {
    let path_seg = path_segments[i]

    // パラメータセグメント（:で始まる）
    if starts_with_colon(pattern_seg) {
      if param_idx < param_names.length() {
        params.push((param_names[param_idx], path_seg))
        param_idx += 1
      } else {
        return None
      }
      // 静的セグメントは完全一致
    } else if pattern_seg != path_seg {
      return None
    }
  }
  Some(params)
}

///|
/// 文字列が : で始まるかチェック
fn starts_with_colon(s : String) -> Bool {
  let chars = s.to_array()
  chars.length() > 0 && chars[0] == ':'
}

///|
/// パスをセグメントに分割
fn split_path(path : String) -> Array[String] {
  let segments = split_string(path, '/')
  // 空文字列を除去（先頭/末尾のスラッシュによる）
  segments.filter(fn(s) { s != "" })
}
