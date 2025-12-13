///| URLPattern - Browser URLPattern API wrapper
///|
///| URLPattern API を使ったルートマッチング
///| https://developer.mozilla.org/en-US/docs/Web/API/URLPattern

///|
/// URLPattern のラッパー
pub struct URLPattern {
  inner : @js.Any
}

///|
/// URLPattern マッチ結果
pub struct URLPatternResult {
  inner : @js.Any
}

///|
/// URLPattern を作成
extern "js" fn ffi_create_url_pattern(pattern : String) -> @js.Any =
  #| (pattern) => new URLPattern({ pathname: pattern })

///|
/// URLPattern を作成 (baseURL付き)
extern "js" fn ffi_create_url_pattern_with_base(
  pattern : String,
  base : String,
) -> @js.Any =
  #| (pattern, base) => new URLPattern({ pathname: pattern }, base)

///|
/// URLPattern でマッチング
extern "js" fn ffi_url_pattern_test(pattern : @js.Any, url : String) -> Bool =
  #| (pattern, url) => pattern.test(url, window.location.origin)

///|
/// URLPattern でマッチングし結果を取得
extern "js" fn ffi_url_pattern_exec(pattern : @js.Any, url : String) -> @js.Any? =
  #| (pattern, url) => pattern.exec(url, window.location.origin)

///|
/// マッチ結果からパラメータグループを取得
extern "js" fn ffi_get_pathname_groups(result : @js.Any) -> @js.Any =
  #| (result) => result.pathname.groups

///|
/// オブジェクトのキー一覧を取得
extern "js" fn ffi_object_keys(obj : @js.Any) -> Array[String] =
  #| (obj) => Object.keys(obj)

///|
/// オブジェクトからプロパティを取得
extern "js" fn ffi_get_prop(obj : @js.Any, key : String) -> String =
  #| (obj, key) => obj[key] ?? ''

///|
/// URLPattern を作成
pub fn URLPattern::new(pattern : String) -> URLPattern {
  { inner: ffi_create_url_pattern(pattern) }
}

///|
/// URLPattern を作成 (baseURL付き)
pub fn URLPattern::with_base(pattern : String, base : String) -> URLPattern {
  { inner: ffi_create_url_pattern_with_base(pattern, base) }
}

///|
/// URLがパターンにマッチするかテスト
pub fn URLPattern::matches(self : URLPattern, url : String) -> Bool {
  ffi_url_pattern_test(self.inner, url)
}

///|
/// URLをパターンにマッチングし、パラメータを取得
pub fn URLPattern::exec(
  self : URLPattern,
  url : String,
) -> Array[(String, String)]? {
  match ffi_url_pattern_exec(self.inner, url) {
    Some(result) => {
      let groups = ffi_get_pathname_groups(result)
      let keys = ffi_object_keys(groups)
      let params : Array[(String, String)] = []
      for key in keys {
        let value = ffi_get_prop(groups, key)
        params.push((key, value))
      }
      Some(params)
    }
    None => None
  }
}

///|
/// CompiledRoutes から URLPattern を作成
pub fn pattern_from_route(route : CompiledRoutes) -> URLPattern {
  // :param を :param に変換 (URLPattern は :param 形式をそのままサポート)
  URLPattern::new(route.pattern)
}

///|
/// CompiledRoutes 配列と URLPattern を組み合わせたマッチャー
pub struct RouteMatcher {
  routes : Array[(CompiledRoutes, URLPattern)]
}

///|
/// RouteMatcher を作成
pub fn RouteMatcher::new(routes : Array[CompiledRoutes]) -> RouteMatcher {
  let pairs : Array[(CompiledRoutes, URLPattern)] = []
  for route in routes {
    pairs.push((route, pattern_from_route(route)))
  }
  { routes: pairs }
}

///|
/// URLをマッチング
pub fn RouteMatcher::match_url(self : RouteMatcher, url : String) -> RoutesMatch? {
  let (path, query) = parse_url_for_match(url)
  for pair in self.routes {
    let (route, pattern) = pair
    match pattern.exec(url) {
      Some(params) => return Some({ route, params, query, path })
      None => continue
    }
  }
  None
}

///|
fn parse_url_for_match(url : String) -> (String, Array[(String, String)]) {
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
  let query = parse_query_for_match(query_str)
  (path, query)
}

///|
fn parse_query_for_match(query : String) -> Array[(String, String)] {
  if query == "" {
    return []
  }
  let result : Array[(String, String)] = []
  let pairs = split_by_char(query, '&')
  for pair in pairs {
    let kv = split_by_char(pair, '=')
    if kv.length() == 2 {
      result.push((kv[0], kv[1]))
    } else if kv.length() == 1 && kv[0] != "" {
      result.push((kv[0], ""))
    }
  }
  result
}

///|
fn split_by_char(s : String, sep : Char) -> Array[String] {
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
