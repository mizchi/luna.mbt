///|
/// Client-Side Router - SPA navigation with History API

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

// =============================================================================
// ClientRouter
// =============================================================================

///|
/// クライアントサイドルーター
/// History API と Signal を使った反応的なSPAナビゲーション
pub struct ClientRouter {
  routes : Array[@router.CompiledRoute]
  current_path : @signal.Signal[String]
  current_match : @signal.Signal[@router.MatchResult?]
}

///|
/// 現在のURLを取得（pathname + search）
fn get_current_url() -> String {
  let pathname = get_pathname()
  let search = get_search()
  if search.length() > 0 {
    pathname + search
  } else {
    pathname
  }
}

///|
/// 内部: ルーターを初期化してpopstateリスナーを登録
fn init_router(routes : Array[@router.CompiledRoute]) -> ClientRouter {
  let initial_path = get_current_url()
  let initial_match = @router.match_route(initial_path, routes, true)
  let router : ClientRouter = {
    routes,
    current_path: @signal.signal(initial_path),
    current_match: @signal.signal(initial_match),
  }
  // popstate イベントをリッスン（ブラウザの戻る/進む）
  add_popstate_listener(fn() { router.sync_from_url() })
  router
}

///|
/// Route定義から ClientRouter を作成
pub fn ClientRouter::new(routes : Array[@router.Route]) -> ClientRouter {
  init_router(@router.compile_routes(routes))
}

///|
/// コンパイル済みルートから ClientRouter を作成
pub fn ClientRouter::from_compiled(
  routes : Array[@router.CompiledRoute],
) -> ClientRouter {
  init_router(routes)
}

///|
/// URLからSignal状態を同期
fn ClientRouter::sync_from_url(self : ClientRouter) -> Unit {
  let path = get_current_url()
  self.current_path.set(path)
  self.current_match.set(@router.match_route(path, self.routes, true))
}

///|
/// 指定パスでSignal状態を更新
fn ClientRouter::update_state(self : ClientRouter, path : String) -> Unit {
  self.current_path.set(path)
  self.current_match.set(@router.match_route(path, self.routes, true))
}

///|
/// プログラマティックナビゲーション（履歴に追加）
pub fn ClientRouter::navigate(self : ClientRouter, path : String) -> Unit {
  push_state(path)
  self.update_state(path)
}

///|
/// 履歴を置換するナビゲーション（戻るボタンに残らない）
pub fn ClientRouter::replace(self : ClientRouter, path : String) -> Unit {
  replace_state(path)
  self.update_state(path)
}

// =============================================================================
// Getters
// =============================================================================

///|
/// 現在のパスを取得
pub fn ClientRouter::get_path(self : ClientRouter) -> String {
  self.current_path.get()
}

///|
/// 現在のマッチ結果を取得
pub fn ClientRouter::get_match(self : ClientRouter) -> @router.MatchResult? {
  self.current_match.get()
}

///|
/// 現在の RouterContext を取得
pub fn ClientRouter::get_context(self : ClientRouter) -> @router.RouterContext? {
  self.current_match.get().map(@router.RouterContext::from_match)
}

///|
/// ナビゲーション関数を取得（コンポーネントに渡す用）
pub fn ClientRouter::get_navigate(self : ClientRouter) -> (String) -> Unit {
  fn(path) { self.navigate(path) }
}

///|
/// パスSignalを取得（リアクティブUI用）
pub fn ClientRouter::current_path_signal(
  self : ClientRouter,
) -> @signal.Signal[String] {
  self.current_path
}

///|
/// マッチ結果Signalを取得（リアクティブUI用）
pub fn ClientRouter::current_match_signal(
  self : ClientRouter,
) -> @signal.Signal[@router.MatchResult?] {
  self.current_match
}

// =============================================================================
// Link Attributes
// =============================================================================

///|
extern "js" fn prevent_default_event(e : @js.Any) -> Unit =
  #| (e) => e.preventDefault()

///|
/// クライアントナビゲーション用リンク属性を生成
pub fn link_attrs(
  href : String,
  router : ClientRouter,
) -> Array[(String, @element.AttrValue)] {
  [
    ("href", @element.AttrValue::Static(href)),
    (
      "onclick",
      @element.AttrValue::Handler(fn(e) {
        prevent_default_event(e)
        router.navigate(href)
      }),
    ),
  ]
}
