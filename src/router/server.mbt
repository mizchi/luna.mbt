///| Server-Side Router - SSR用ルーター

///|
/// サーバーサイドレンダリングオプション
pub struct ServerRenderOptions {
  /// preloadタグを収集するか (default: true)
  preload : Bool
  /// hydrationマーカーを含めるか (default: true)
  hydration : Bool
}

///|
/// ServerRenderOptions をラベル引数で作成
pub fn ServerRenderOptions::new(
  preload? : Bool = true,
  hydration? : Bool = true,
) -> ServerRenderOptions {
  { preload, hydration }
}

///|
/// ServerRenderOptions のデフォルト値
pub fn ServerRenderOptions::default() -> ServerRenderOptions {
  ServerRenderOptions::new()
}

///|
/// preloadなしのオプション
pub fn ServerRenderOptions::no_preload() -> ServerRenderOptions {
  ServerRenderOptions::new(preload=false)
}

///|
/// hydrationなしのオプション（静的HTMLのみ）
pub fn ServerRenderOptions::static_only() -> ServerRenderOptions {
  ServerRenderOptions::new(preload=false, hydration=false)
}

///|
/// サーバーサイドルーター
/// コンパイル済みルートを保持し、URLマッチングを行う
pub struct ServerRouter {
  routes : Array[CompiledRoute]
  /// レンダリングオプション
  options : ServerRenderOptions
}

///|
/// ServerRouter を作成
pub fn ServerRouter::new(routes : Array[Route]) -> ServerRouter {
  { routes: compile_routes(routes), options: ServerRenderOptions::default() }
}

///|
/// オプション付きで ServerRouter を作成
pub fn ServerRouter::with_options(
  routes : Array[Route],
  options : ServerRenderOptions,
) -> ServerRouter {
  { routes: compile_routes(routes), options }
}

///|
/// コンパイル済みルートから ServerRouter を作成
pub fn ServerRouter::from_compiled(
  routes : Array[CompiledRoute],
) -> ServerRouter {
  { routes, options: ServerRenderOptions::default() }
}

///|
/// URLに対してルートをマッチング
pub fn ServerRouter::match_url(
  self : ServerRouter,
  url : String,
) -> MatchResult? {
  match_route(url, self.routes, false)
}

///|
/// URLに対してルートをマッチングし、RouterContext を返す
pub fn ServerRouter::resolve(
  self : ServerRouter,
  url : String,
) -> RouterContext? {
  match self.match_url(url) {
    Some(m) => Some(RouterContext::from_match(m))
    None => None
  }
}

///|
/// コンパイル済みルート一覧を取得
pub fn ServerRouter::get_routes(self : ServerRouter) -> Array[CompiledRoute] {
  self.routes
}

///|
/// ルート数を取得
pub fn ServerRouter::length(self : ServerRouter) -> Int {
  self.routes.length()
}

///|
/// レンダリングオプションを取得
pub fn ServerRouter::get_options(self : ServerRouter) -> ServerRenderOptions {
  self.options
}

///|
/// preload が有効か
pub fn ServerRouter::has_preload(self : ServerRouter) -> Bool {
  self.options.preload
}

///|
/// hydration が有効か
pub fn ServerRouter::has_hydration(self : ServerRouter) -> Bool {
  self.options.hydration
}
