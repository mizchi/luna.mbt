///|
/// Client-Side Router - SPA navigation with History API

///|

///| 2つのRouter API:

///| - ClientRouter: 旧API (Route enum使用) - 後方互換性のため維持

///|
/// - SpaRouter: 新API (Routes enum使用) - ServerComponent/Island対応

// =============================================================================
// Browser API FFI (History API)
// =============================================================================

extern "js" fn get_pathname() -> String =
  #| () => window.location.pathname

///|
extern "js" fn get_search() -> String =
  #| () => window.location.search

///|
extern "js" fn push_state(path : String) -> Unit =
  #| (path) => window.history.pushState(null, '', path)

///|
extern "js" fn replace_state(path : String) -> Unit =
  #| (path) => window.history.replaceState(null, '', path)

///|
extern "js" fn add_popstate_listener(callback : () -> Unit) -> Unit =
  #| (callback) => window.addEventListener('popstate', () => callback())

///|
/// 現在のURLを取得（pathname + search）
fn get_current_url() -> String {
  let pathname = get_pathname()
  let search = get_search()
  if not(search.is_empty()) {
    pathname + search
  } else {
    pathname
  }
}

// =============================================================================
// BrowserRouter - シンプルなクライアントサイドルーター
// =============================================================================

///|
/// ブラウザルーター
/// History API と Signal を使ったSPAナビゲーション
pub struct BrowserRouter {
  routes : Array[@router.CompiledRoutes]
  base : String
  current_path : @signal.Signal[String]
  current_match : @signal.Signal[@router.RoutesMatch?]
}

///|
/// Routes定義から BrowserRouter を作成
/// base~ : ベースパス（例: "/playground/browser_app"）
pub fn BrowserRouter::new(
  routes : Array[@router.Routes],
  base? : String = "",
) -> BrowserRouter {
  let compiled = @router.compile_with_base(routes, base)
  let initial_path = get_current_url()
  let initial_match = @router.match_url(initial_path, compiled)
  let router : BrowserRouter = {
    routes: compiled,
    base,
    current_path: @signal.signal(initial_path),
    current_match: @signal.signal(initial_match),
  }
  add_popstate_listener(fn() { router.sync_from_url() })
  router
}

///|
/// コンパイル済みルートから BrowserRouter を作成
pub fn BrowserRouter::from_compiled(
  routes : Array[@router.CompiledRoutes],
  base? : String = "",
) -> BrowserRouter {
  let initial_path = get_current_url()
  let initial_match = @router.match_url(initial_path, routes)
  let router : BrowserRouter = {
    routes,
    base,
    current_path: @signal.signal(initial_path),
    current_match: @signal.signal(initial_match),
  }
  add_popstate_listener(fn() { router.sync_from_url() })
  router
}

///|
/// ベースパスを取得
pub fn BrowserRouter::get_base(self : BrowserRouter) -> String {
  self.base
}

///|
/// URLからSignal状態を同期
fn BrowserRouter::sync_from_url(self : BrowserRouter) -> Unit {
  let path = get_current_url()
  self.current_path.set(path)
  self.current_match.set(@router.match_url(path, self.routes))
}

///|
/// 指定パスでSignal状態を更新
fn BrowserRouter::update_state(self : BrowserRouter, path : String) -> Unit {
  self.current_path.set(path)
  self.current_match.set(@router.match_url(path, self.routes))
}

///|
/// プログラマティックナビゲーション（履歴に追加）
pub fn BrowserRouter::navigate(self : BrowserRouter, path : String) -> Unit {
  push_state(path)
  self.update_state(path)
}

///|
/// 履歴を置換するナビゲーション（戻るボタンに残らない）
pub fn BrowserRouter::replace(self : BrowserRouter, path : String) -> Unit {
  replace_state(path)
  self.update_state(path)
}

///|
/// 現在のパスを取得
pub fn BrowserRouter::get_path(self : BrowserRouter) -> String {
  self.current_path.get()
}

///|
/// 現在のマッチ結果を取得
pub fn BrowserRouter::get_match(self : BrowserRouter) -> @router.RoutesMatch? {
  self.current_match.get()
}

///|
/// 現在のコンポーネントIDを取得
pub fn BrowserRouter::get_component(self : BrowserRouter) -> String? {
  self.current_match.get().map(fn(m) { m.component() })
}

///|
/// ナビゲーション関数を取得（コンポーネントに渡す用）
pub fn BrowserRouter::get_navigate(self : BrowserRouter) -> (String) -> Unit {
  fn(path) { self.navigate(path) }
}

///|
/// パスSignalを取得（リアクティブUI用）
pub fn BrowserRouter::path_signal(
  self : BrowserRouter,
) -> @signal.Signal[String] {
  self.current_path
}

///|
/// マッチ結果Signalを取得（リアクティブUI用）
pub fn BrowserRouter::match_signal(
  self : BrowserRouter,
) -> @signal.Signal[@router.RoutesMatch?] {
  self.current_match
}
