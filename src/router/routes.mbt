///| Routes - Unified route definition with component binding
///|
///| ServerComponent: サーバーでのみ実行、async データ取得可能
///| ClientComponent: Island としてHydration可能、ln:url でスクリプト指定

///|
/// Route定義 - コンポーネントIDを持つツリー構造
pub(all) enum Routes {
  /// サーバーコンポーネントページ
  /// - path: パス (e.g., "/", "/about")
  /// - component: コンポーネントID (resolver で解決)
  /// - title: ページタイトル
  /// - meta: メタ情報
  Page(
    path~ : String,
    component~ : String,
    title~ : String,
    meta~ : Array[(String, String)]
  )
  /// クライアントコンポーネントページ (Island)
  /// - path: パス
  /// - component: コンポーネントID
  /// - url: Hydration用スクリプトURL
  /// - trigger: Hydrationトリガー
  /// - title: ページタイトル
  /// - meta: メタ情報
  Island(
    path~ : String,
    component~ : String,
    url~ : String,
    trigger~ : @luna.IslandTrigger,
    title~ : String,
    meta~ : Array[(String, String)]
  )
  /// 動的パラメータセグメント
  /// - key: パラメータ名 (e.g., "id" for ":id")
  /// - children: 子ルート
  Param(key~ : String, children~ : Array[Routes])
  /// パスグループ (共通プレフィックス + レイアウト)
  /// - segment: パスセグメント (e.g., "/user", "/api")
  /// - children: 子ルート
  /// - layout: レイアウトコンポーネントID
  Layout(segment~ : String, children~ : Array[Routes], layout~ : String)
  /// パスグループ (レイアウトなし)
  Group(segment~ : String, children~ : Array[Routes])
  /// APIルート (GET)
  Get(path~ : String, handler~ : String)
  /// APIルート (POST)
  Post(path~ : String, handler~ : String)
}

///|
/// コンパイル済みルート (マッチング用)
pub struct CompiledRoutes {
  /// フルパスパターン
  pattern : String
  /// パラメータ名のリスト (順序付き)
  param_names : Array[String]
  /// コンポーネントID
  component : String
  /// 適用されるレイアウトID (ネストした順)
  layouts : Array[String]
  /// ルートの種類
  kind : RoutesKind
  /// タイトル
  title : String
  /// メタ情報
  meta : Array[(String, String)]
  /// Island情報 (ClientComponentの場合)
  island : IslandInfo?
}

///|
/// Island情報
pub struct IslandInfo {
  /// Hydration用スクリプトURL
  url : String
  /// Hydrationトリガー
  trigger : @luna.IslandTrigger
}

///|
/// ルートの種類
pub enum RoutesKind {
  /// サーバーコンポーネントページ
  Page
  /// クライアントコンポーネントページ (Island)
  IslandPage
  /// GET API
  GetApi
  /// POST API
  PostApi
} derive(Eq, Show)

///|
/// パスを正規化（重複スラッシュ除去、末尾スラッシュ除去）
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
  // 末尾スラッシュを除去（ルート以外）
  let len = result.length()
  if len > 1 && result[len - 1] == '/' {
    let _ = result.pop()
  }
  String::from_array(result)
}

///|
/// Routes を CompiledRoutes にコンパイル
pub fn compile(routes : Array[Routes]) -> Array[CompiledRoutes] {
  let result : Array[CompiledRoutes] = []
  compile_inner(routes, "", [], [], result)
  result
}

///|
/// Routes を CompiledRoutes にコンパイル（ベースパス指定）
pub fn compile_with_base(
  routes : Array[Routes],
  base : String,
) -> Array[CompiledRoutes] {
  let result : Array[CompiledRoutes] = []
  compile_inner(routes, base, [], [], result)
  result
}

///|
fn compile_inner(
  routes : Array[Routes],
  prefix : String,
  inherited_params : Array[String],
  inherited_layouts : Array[String],
  result : Array[CompiledRoutes],
) -> Unit {
  for route in routes {
    match route {
      Page(path~, component~, title~, meta~) => {
        let full_path = normalize_path(prefix + path)
        result.push({
          pattern: full_path,
          param_names: inherited_params.copy(),
          component,
          layouts: inherited_layouts.copy(),
          kind: Page,
          title,
          meta,
          island: None,
        })
      }
      Island(path~, component~, url~, trigger~, title~, meta~) => {
        let full_path = normalize_path(prefix + path)
        result.push({
          pattern: full_path,
          param_names: inherited_params.copy(),
          component,
          layouts: inherited_layouts.copy(),
          kind: IslandPage,
          title,
          meta,
          island: Some({ url, trigger }),
        })
      }
      Get(path~, handler~) => {
        let full_path = normalize_path(prefix + path)
        result.push({
          pattern: full_path,
          param_names: inherited_params.copy(),
          component: handler,
          layouts: [],
          kind: GetApi,
          title: "",
          meta: [],
          island: None,
        })
      }
      Post(path~, handler~) => {
        let full_path = normalize_path(prefix + path)
        result.push({
          pattern: full_path,
          param_names: inherited_params.copy(),
          component: handler,
          layouts: [],
          kind: PostApi,
          title: "",
          meta: [],
          island: None,
        })
      }
      Param(key~, children~) => {
        // Param adds :key to the prefix and passes it to children
        let new_prefix = normalize_path(prefix + "/:" + key)
        let new_params = inherited_params.copy()
        new_params.push(key)
        compile_inner(children, new_prefix, new_params, inherited_layouts, result)
      }
      Layout(segment~, children~, layout~) => {
        let new_prefix = normalize_path(prefix + segment)
        let new_layouts = inherited_layouts.copy()
        new_layouts.push(layout)
        compile_inner(children, new_prefix, inherited_params, new_layouts, result)
      }
      Group(segment~, children~) => {
        let new_prefix = normalize_path(prefix + segment)
        compile_inner(children, new_prefix, inherited_params, inherited_layouts, result)
      }
    }
  }
}

///|
/// マッチ結果
pub struct RoutesMatch {
  route : CompiledRoutes
  params : Array[(String, String)]
  query : Array[(String, String)]
  path : String
}

///|
/// URLをルートにマッチング
pub fn match_url(
  url : String,
  routes : Array[CompiledRoutes],
) -> RoutesMatch? {
  let (path, query) = parse_url_parts(url)
  for route in routes {
    match try_match_pattern(path, route) {
      Some(params) => return Some({ route, params, query, path })
      None => continue
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
  if query == "" {
    return []
  }
  let result : Array[(String, String)] = []
  let pairs = split_by(query, '&')
  for pair in pairs {
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
fn split_by(s : String, sep : Char) -> Array[String] {
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
fn try_match_pattern(
  path : String,
  route : CompiledRoutes,
) -> Array[(String, String)]? {
  let pattern_segments = split_path_segments(route.pattern)
  let path_segments = split_path_segments(path)

  if pattern_segments.length() != path_segments.length() {
    return None
  }

  let params : Array[(String, String)] = []
  let mut param_idx = 0
  for i, pattern_seg in pattern_segments {
    let path_seg = path_segments[i]
    if starts_with_char(pattern_seg, ':') {
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

///|
fn starts_with_char(s : String, c : Char) -> Bool {
  let chars = s.to_array()
  chars.length() > 0 && chars[0] == c
}

///|
fn split_path_segments(path : String) -> Array[String] {
  split_by(path, '/').filter(fn(s) { s != "" })
}

///|
/// コンポーネントIDを取得
pub fn RoutesMatch::component(self : RoutesMatch) -> String {
  self.route.component
}

///|
/// レイアウトIDリストを取得
pub fn RoutesMatch::layouts(self : RoutesMatch) -> Array[String] {
  self.route.layouts
}

///|
/// パラメータを取得
pub fn RoutesMatch::get_param(self : RoutesMatch, key : String) -> String? {
  for pair in self.params {
    if pair.0 == key {
      return Some(pair.1)
    }
  }
  None
}

///|
/// クエリパラメータを取得
pub fn RoutesMatch::get_query(self : RoutesMatch, key : String) -> String? {
  for pair in self.query {
    if pair.0 == key {
      return Some(pair.1)
    }
  }
  None
}

///|
/// Islandページかどうか
pub fn RoutesMatch::is_island(self : RoutesMatch) -> Bool {
  self.route.kind == IslandPage
}

///|
/// Island情報を取得
pub fn RoutesMatch::island_info(self : RoutesMatch) -> IslandInfo? {
  self.route.island
}

///|
/// ルートの種類を取得
pub fn RoutesMatch::kind(self : RoutesMatch) -> RoutesKind {
  self.route.kind
}

///|
/// タイトルを取得
pub fn RoutesMatch::title(self : RoutesMatch) -> String {
  self.route.title
}

///|
/// メタ情報を取得
pub fn RoutesMatch::meta(self : RoutesMatch) -> Array[(String, String)] {
  self.route.meta
}
