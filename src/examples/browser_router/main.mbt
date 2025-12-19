//

///|
/// Browser App Example
/// BrowserRouter を使った新しいルーティングシステムのデモ
/// - Routes enum によるルート定義
/// - component ID ベースのコンポーネント解決
/// - Layout によるネストしたレイアウト

// =============================================================================
// Helpers
// =============================================================================

using @dom {
  a,
  events,
  div,
  nav,
  span,
  h1,
  h2,
  h3,
  text,
  p,
  button,
  ul,
  li,
  hr,
  text_dyn,
}

///|
fn console_log(msg : String) -> Unit {
  let global = @global.global_this()
  global["console"]._call("log", [@js.any(msg)]) |> ignore
}

// =============================================================================
// Route Definitions
// =============================================================================

///|
/// ルート定義
/// ベースパスは BrowserRouter::new の base~ パラメータで指定
fn create_routes() -> Array[@routes.Routes] {
  [
    // ホームページ
    Page(path="", component="home", title="Home", meta=[]),
    // About ページ
    Page(path="/about", component="about", title="About", meta=[]),
    // ユーザー関連ページ (レイアウト付き)
    Layout(segment="/users", layout="users_layout", children=[
      // ユーザー一覧
      Page(path="", component="users_list", title="Users", meta=[]),
      // ユーザー詳細 (動的パラメータ - パスに直接埋め込み)
      Page(path="/:id", component="user_detail", title="User Detail", meta=[]),
    ]),
    // 設定ページ (レイアウトなしでも Layout で代用)
    Layout(segment="/settings", layout="settings_layout", children=[
      Page(path="", component="settings_index", title="Settings", meta=[]),
      Page(
        path="/profile",
        component="settings_profile",
        title="Profile Settings",
        meta=[],
      ),
    ]),
  ]
}

// =============================================================================
// Components
// =============================================================================

///|
/// ナビゲーションコンポーネント
fn nav_component(router : @router.BrowserRouter) -> @dom.DomNode {
  let base = router.get_base()
  fn nav_link(href : String, label : String) -> @dom.DomNode {
    a(
      href~,
      on=events().click(fn(e) {
        e.preventDefault()
        router.navigate(href)
      }),
      [text(label)],
    )
  }

  nav(style="background: #333; padding: 10px;", [
    span(style="color: white; margin-right: 20px;", [nav_link(base, "Home")]),
    span(style="color: white; margin-right: 20px;", [
      nav_link(base + "/about", "About"),
    ]),
    span(style="color: white; margin-right: 20px;", [
      nav_link(base + "/users", "Users"),
    ]),
    span(style="color: white; margin-right: 20px;", [
      nav_link(base + "/settings", "Settings"),
    ]),
  ])
}

///|
/// カウンターコンポーネント（動的要素のテスト用）
fn counter_component() -> @dom.DomNode {
  let count = @signal.signal(0)
  console_log(
    "Creating counter component, initial count: " + count.get().to_string(),
  )
  div(class="counter", attrs=[("data-testid", AttrString("counter"))], [
    h3([text("Interactive Counter")]),
    p(attrs=[("data-testid", AttrString("count-display"))], [
      text_dyn(fn() { "Count: " + count.get().to_string() }),
    ]),
    div(class="counter-buttons", [
      button(
        attrs=[("data-testid", AttrString("decrement-btn"))],
        on=events().click(fn(_) {
          console_log("Decrement clicked, current: " + count.get().to_string())
          count.update(n => n - 1)
          console_log("After decrement: " + count.get().to_string())
        }),
        [text("-")],
      ),
      button(
        attrs=[("data-testid", AttrString("increment-btn"))],
        on=events().click(fn(_) {
          console_log("Increment clicked, current: " + count.get().to_string())
          count.update(n => n + 1)
          console_log("After increment: " + count.get().to_string())
        }),
        [text("+")],
      ),
      button(
        attrs=[("data-testid", AttrString("reset-btn"))],
        on=events().click(fn(_) {
          console_log("Reset clicked")
          count.set(0)
        }),
        [text("Reset")],
      ),
    ]),
  ])
}

///|
/// ホームページ
fn home_component(router : @router.BrowserRouter) -> @dom.DomNode {
  div(class="page home", attrs=[("data-page", AttrString("home"))], [
    h1([text("Welcome to Browser App")]),
    p([text("This is an example of the new Routes-based routing system.")]),
    // カウンターを追加（動的要素のテスト）
    counter_component(),
    hr(),
    h2([text("Features")]),
    ul([
      li([text("Routes enum for declarative route definitions")]),
      li([text("Component ID-based resolution")]),
      li([text("Layout support for nested routes")]),
      li([text("Dynamic parameters with :id syntax")]),
      li([text("URLPattern API for matching")]),
    ]),
    p(attrs=[("data-testid", AttrString("current-path"))], [
      text("Current path: "),
      text_dyn(fn() { router.get_path() }),
    ]),
  ])
}

///|
/// About ページ
fn about_component(_router : @router.BrowserRouter) -> @dom.DomNode {
  div(class="page about", attrs=[("data-page", AttrString("about"))], [
    h1([text("About")]),
    p([text("This app demonstrates the new routing architecture:")]),
    ul([
      li([text("ServerComponent: async data fetching on server")]),
      li([text("ClientComponent (Island): Hydration with luna:url")]),
      li([text("Layout: shared wrapper for nested routes")]),
    ]),
  ])
}

///|
/// ユーザーレイアウト
fn users_layout_component(
  router : @router.BrowserRouter,
  children : @dom.DomNode,
) -> @dom.DomNode {
  let base = router.get_base()
  div(
    class="users-layout",
    style="border: 2px solid #007bff; padding: 15px; margin: 10px 0;",
    [
      div(
        style="background: #007bff; color: white; padding: 10px; margin: -15px -15px 15px -15px;",
        [
          h2(style="margin: 0;", [text("Users Section")]),
          p(style="margin: 5px 0 0 0; font-size: 0.9em;", [
            text("This is a layout wrapper for all /users/* routes"),
          ]),
        ],
      ),
      div(style="margin-bottom: 10px;", [
        button(
          style="margin-right: 10px;",
          on=events().click(fn(_) { router.navigate(base + "/users") }),
          [text("User List")],
        ),
        button(
          style="margin-right: 10px;",
          on=events().click(fn(_) { router.navigate(base + "/users/1") }),
          [text("User 1")],
        ),
        button(
          style="margin-right: 10px;",
          on=events().click(fn(_) { router.navigate(base + "/users/2") }),
          [text("User 2")],
        ),
        button(
          on=events().click(fn(_) { router.navigate(base + "/users/3") }),
          [text("User 3")],
        ),
      ]),
      children,
    ],
  )
}

///|
/// ユーザー一覧
fn users_list_component(_router : @router.BrowserRouter) -> @dom.DomNode {
  div(class="users-list", [
    h3([text("User List")]),
    ul([
      li([text("User 1 - Alice")]),
      li([text("User 2 - Bob")]),
      li([text("User 3 - Charlie")]),
    ]),
  ])
}

///|
/// ユーザー詳細
fn user_detail_component(
  _router : @router.BrowserRouter,
  m : @routes.RoutesMatch,
) -> @dom.DomNode {
  let user_id = m.get_param("id").unwrap_or("unknown")
  let user_name = match user_id {
    "1" => "Alice"
    "2" => "Bob"
    "3" => "Charlie"
    _ => "Unknown User"
  }
  div(class="user-detail", [
    h3([text("User Detail")]),
    p([text("User ID: " + user_id)]),
    p([text("Name: " + user_name)]),
    p(style="color: #666; font-style: italic;", [
      text("(In a real app, this data would be fetched from an API)"),
    ]),
  ])
}

///|
/// 設定インデックス
fn settings_index_component(router : @router.BrowserRouter) -> @dom.DomNode {
  let base = router.get_base()
  let profile_path = base + "/settings/profile"
  div(class="settings-index", [
    h1([text("Settings")]),
    ul([
      li([
        a(
          href=profile_path,
          on=events().click(fn(e) {
            e.preventDefault()
            router.navigate(profile_path)
          }),
          [text("Profile Settings")],
        ),
      ]),
    ]),
  ])
}

///|
/// プロファイル設定
fn settings_profile_component(router : @router.BrowserRouter) -> @dom.DomNode {
  let base = router.get_base()
  div(class="settings-profile", [
    h1([text("Profile Settings")]),
    p([text("Edit your profile here.")]),
    button(on=events().click(fn(_) { router.navigate(base + "/settings") }), [
      text("Back to Settings"),
    ]),
  ])
}

///|
/// 404 ページ
fn not_found_component(router : @router.BrowserRouter) -> @dom.DomNode {
  let base = router.get_base()
  div(class="not-found", [
    h1([text("404 - Not Found")]),
    p([text("Page not found: "), text_dyn(fn() { router.get_path() })]),
    button(on=events().click(fn(_) { router.navigate(base) }), [text("Go Home")]),
  ])
}

// =============================================================================
// Component Resolver
// =============================================================================

///|
/// コンポーネントIDからコンポーネントを解決
fn resolve_component(
  router : @router.BrowserRouter,
  m : @routes.RoutesMatch,
) -> @dom.DomNode {
  let component_id = m.component()
  let layouts = m.layouts()
  console_log(
    "Resolving component: " +
    component_id +
    ", layouts: " +
    layouts.length().to_string(),
  )

  // コンポーネントを解決
  let content : @dom.DomNode = match component_id {
    "home" => home_component(router)
    "about" => about_component(router)
    "users_list" => users_list_component(router)
    "user_detail" => user_detail_component(router, m)
    "settings_index" => settings_index_component(router)
    "settings_profile" => settings_profile_component(router)
    _ => not_found_component(router)
  }

  // レイアウトを適用（内側から外側へ）
  let mut result = content
  let mut i = layouts.length() - 1
  while i >= 0 {
    let layout_id = layouts[i]
    result = match layout_id {
      "users_layout" => users_layout_component(router, result)
      _ => result
    }
    i -= 1
  }
  result
}

// =============================================================================
// Router Renderer
// =============================================================================

///|
/// ルートをレンダリング
fn render_route(
  router : @router.BrowserRouter,
  container : @dom.DomElement,
) -> Unit {
  let _ = @signal.effect(fn() {
    // Track only the match_signal for re-rendering
    let match_result = router.match_signal().get()
    let path = router.path_signal().peek() // Use peek to avoid double subscription
    console_log("Route changed (effect triggered): " + path)

    // コンテナをクリア
    @dom.clear(container)

    // Create components untracked to avoid subscribing to their internal signals
    // This ensures counter's signal changes don't re-trigger the route effect
    let (nav, page) = @signal.untracked(fn() {
      let nav = nav_component(router)
      let page = match match_result {
        Some(m) => resolve_component(router, m)
        None => not_found_component(router)
      }
      (nav, page)
    })

    // レイアウト - also untracked since it creates elements
    let app = @signal.untracked(fn() {
      div(
        class="app",
        style="font-family: system-ui, sans-serif; max-width: 800px; margin: 0 auto;",
        [nav, div(style="padding: 20px;", [page])],
      )
    })
    @dom.mount(container, app)
  })

}

// =============================================================================
// Main
// =============================================================================

///|
fn main {
  console_log("Browser App Starting...")
  let doc = @js_dom.document()
  let container = doc.getElementById("app")
  match container {
    Some(el) => {
      // ルーターを作成（ベースパスを指定）
      let base = "/playground/browser_router"
      let routes = create_routes()
      let router = @router.BrowserRouter::new(routes, base~)

      // Debug: log compiled routes
      for route in router.routes {
        console_log(
          "Compiled route: pattern=" +
          route.pattern +
          ", component=" +
          route.component,
        )
      }
      console_log("Router created with path: " + router.get_path())

      // レンダリング開始
      let dom_container = el |> @dom.DomElement::from_jsdom
      render_route(router, dom_container)
      console_log("App rendered!")
    }
    None => console_log("ERROR: #app container not found")
  }
}
