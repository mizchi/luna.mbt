///| Browser Router - CSR-optimized client-side router

///|
/// ブラウザルーター（CSR用）
/// History APIを使用したクライアントサイドナビゲーション
pub struct BrowserRouter {
  routes : Array[CompiledRoute]
  /// 現在のパス
  current_path : Ref[String]
}

///|
/// BrowserRouter を作成
pub fn BrowserRouter::new(routes : Array[Route]) -> BrowserRouter {
  { routes: compile_routes(routes), current_path: { val: "/" } }
}

///|
/// コンパイル済みルートから BrowserRouter を作成
pub fn BrowserRouter::from_compiled(
  routes : Array[CompiledRoute],
) -> BrowserRouter {
  { routes, current_path: { val: "/" } }
}

///|
/// 現在のパスを設定
pub fn BrowserRouter::set_path(self : BrowserRouter, path : String) -> Unit {
  self.current_path.val = path
}

///|
/// 現在のパスを取得
pub fn BrowserRouter::get_path(self : BrowserRouter) -> String {
  self.current_path.val
}

///|
/// URLに対してルートをマッチング（クライアントサイド）
pub fn BrowserRouter::match_url(
  self : BrowserRouter,
  url : String,
) -> MatchResult? {
  match_route(url, self.routes, true)
}

///|
/// URLに対してルートをマッチングし、RouterContext を返す
pub fn BrowserRouter::resolve(
  self : BrowserRouter,
  url : String,
) -> RouterContext? {
  match self.match_url(url) {
    Some(m) => Some(RouterContext::from_match(m))
    None => None
  }
}

///|
/// ナビゲーション（パス更新のみ、DOM操作はJS側で行う）
pub fn BrowserRouter::navigate(
  self : BrowserRouter,
  path : String,
) -> RouterContext? {
  self.current_path.val = path
  self.resolve(path)
}

///|
/// コンパイル済みルート一覧を取得
pub fn BrowserRouter::get_routes(self : BrowserRouter) -> Array[CompiledRoute] {
  self.routes
}

///|
/// ルート数を取得
pub fn BrowserRouter::length(self : BrowserRouter) -> Int {
  self.routes.length()
}
