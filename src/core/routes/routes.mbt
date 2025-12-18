// Routes - Core route definitions (target-independent)
//
// This module provides the fundamental route definition types and
// matching logic that works across all targets (js, wasm-gc, native).
//

///|
/// Route定義 - フラットな構造（URLPattern 構文をサポート）
pub(all) enum Routes {
  /// サーバーコンポーネントページ
  /// - path: パス (e.g., "/", "/about", "/user/:id")
  ///   URLPattern 構文で動的パラメータを定義可能
  /// - component: コンポーネントID (resolver で解決)
  /// - title: ページタイトル
  /// - meta: メタ情報
  Page(
    path~ : String,
    component~ : String,
    title~ : String,
    meta~ : Array[(String, String)]
  )
  /// パスグループ (共通プレフィックス + レイアウト)
  /// - segment: パスセグメント (e.g., "/user", "/api")
  /// - children: 子ルート
  /// - layout: レイアウトコンポーネントID
  Layout(segment~ : String, children~ : Array[Routes], layout~ : String)
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
}

///|
/// ルートの種類
pub enum RoutesKind {
  /// サーバーコンポーネントページ
  Page
  /// GET API
  GetApi
  /// POST API
  PostApi
} derive(Eq, Show)

///|
/// マッチ結果
pub struct RoutesMatch {
  route : CompiledRoutes
  params : Array[(String, String)]
  query : Array[(String, String)]
  path : String
}
