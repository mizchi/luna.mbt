///| Route Definition - Declarative routing DSL

///|
/// ルートコンポーネントが受け取るProps
pub struct RouteProps {
  is_client : Bool // クライアントサイドかどうか
  params : Array[(String, String)] // URLパラメータ [("id", "123")]
  query : Array[(String, String)] // クエリパラメータ [("page", "1")]
  path : String // 現在のパス
}

///|
/// RouteProps を作成
pub fn RouteProps::new(path : String) -> RouteProps {
  { is_client: false, params: [], query: [], path }
}

///|
/// params から値を取得
pub fn RouteProps::get_param(self : RouteProps, key : String) -> String? {
  for pair in self.params {
    if pair.0 == key {
      return Some(pair.1)
    }
  }
  None
}

///|
/// query から値を取得
pub fn RouteProps::get_query(self : RouteProps, key : String) -> String? {
  for pair in self.query {
    if pair.0 == key {
      return Some(pair.1)
    }
  }
  None
}

///|
/// ルート定義
pub(all) enum Route {
  /// ページルート
  Page(path~ : String, title~ : String, meta~ : Array[(String, String)])
  /// APIルート (GET)
  Get(path~ : String, title~ : String, meta~ : Array[(String, String)])
  /// APIルート (POST)
  Post(path~ : String, title~ : String, meta~ : Array[(String, String)])
  /// 動的パラメータセグメント ":id"
  Param(String, key~ : String, title~ : String, meta~ : Array[(String, String)])
  /// 正規表現パラメータ ":user_id(\\d+)"
  RegexParam(
    String,
    key~ : String,
    title~ : String,
    meta~ : Array[(String, String)]
  )
  /// ワイルドカード "*"
  Wildcard(key~ : String, title~ : String, meta~ : Array[(String, String)])
  /// ネストしたルートグループ
  Path(String, Array[Route], title~ : String, meta~ : Array[(String, String)])
}

///|
/// コンパイル済みルート（マッチング用）
pub struct CompiledRoute {
  /// フルパスパターン
  pattern : String
  /// パラメータ名のリスト（順序付き）
  param_names : Array[String]
  /// ルートの種類
  kind : RouteKind
  /// タイトル
  title : String
  /// メタ情報
  meta : Array[(String, String)]
}

///|
/// ルートの種類
pub enum RouteKind {
  Page
  GetApi
  PostApi
} derive(Eq, Show)
