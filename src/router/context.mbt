///| Router Context - ルーティング情報を保持

///|
/// ルートのメタ情報
pub struct RouteMeta {
  title : String
  meta : Array[(String, String)]
}

///|
/// RouteMeta の Show 実装
pub impl Show for RouteMeta with output(self, logger) {
  logger.write_string("RouteMeta { title: ")
  logger.write_string(self.title)
  logger.write_string(", meta: [")
  for i, pair in self.meta {
    if i > 0 {
      logger.write_string(", ")
    }
    logger.write_string("(")
    logger.write_string(pair.0)
    logger.write_string(", ")
    logger.write_string(pair.1)
    logger.write_string(")")
  }
  logger.write_string("] }")
}

///|
/// Router コンテキスト
/// サーバー/クライアント両方で使用される情報
pub struct RouterContext {
  /// 現在のパス
  path : String
  /// マッチしたルートのパラメータ
  params : Array[(String, String)]
  /// クエリパラメータ
  query : Array[(String, String)]
  /// ルートのメタ情報
  route_meta : RouteMeta
  /// ルートの種類
  kind : RouteKind
}

///|
/// RouterContext の Show 実装
pub impl Show for RouterContext with output(self, logger) {
  logger.write_string("RouterContext { path: ")
  logger.write_string(self.path)
  logger.write_string(", kind: ")
  self.kind.output(logger)
  logger.write_string(" }")
}

///|
/// RouterContext を作成
pub fn RouterContext::new(
  path~ : String,
  params? : Array[(String, String)] = [],
  query? : Array[(String, String)] = [],
  route_meta? : RouteMeta = { title: "", meta: [] },
  kind? : RouteKind = Page,
) -> RouterContext {
  { path, params, query, route_meta, kind }
}

///|
/// MatchResult から RouterContext を作成
pub fn RouterContext::from_match(m : MatchResult) -> RouterContext {
  {
    path: m.props.path,
    params: m.props.params,
    query: m.props.query,
    route_meta: { title: m.route.title, meta: m.route.meta },
    kind: m.route.kind,
  }
}

///|
/// パラメータを取得
pub fn RouterContext::get_param(self : RouterContext, key : String) -> String? {
  for pair in self.params {
    if pair.0 == key {
      return Some(pair.1)
    }
  }
  None
}

///|
/// クエリパラメータを取得
pub fn RouterContext::get_query(self : RouterContext, key : String) -> String? {
  for pair in self.query {
    if pair.0 == key {
      return Some(pair.1)
    }
  }
  None
}

///|
/// 404 Not Found 用のコンテキストを作成
pub fn RouterContext::not_found(path : String) -> RouterContext {
  {
    path,
    params: [],
    query: [],
    route_meta: { title: "Not Found", meta: [] },
    kind: Page,
  }
}
