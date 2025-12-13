///| Browser App Example
///|
///| BrowserRouter を使った新しいルーティングシステムのデモ
///| - Routes enum によるルート定義
///| - component ID ベースのコンポーネント解決
///| - Layout によるネストしたレイアウト

// =============================================================================
// Helpers
// =============================================================================

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
fn create_routes() -> Array[@router.Routes] {
  [
    // ホームページ
    @router.Routes::Page(path="", component="home", title="Home", meta=[]),
    // About ページ
    @router.Routes::Page(path="/about", component="about", title="About", meta=[]),
    // ユーザー関連ページ (レイアウト付き)
    @router.Routes::Layout(
      segment="/users",
      layout="users_layout",
      children=[
        // ユーザー一覧
        @router.Routes::Page(
          path="",
          component="users_list",
          title="Users",
          meta=[],
        ),
        // ユーザー詳細 (動的パラメータ)
        @router.Routes::Param(
          key="id",
          children=[
            @router.Routes::Page(
              path="",
              component="user_detail",
              title="User Detail",
              meta=[],
            ),
          ],
        ),
      ],
    ),
    // 設定ページ (グループ)
    @router.Routes::Group(
      segment="/settings",
      children=[
        @router.Routes::Page(
          path="",
          component="settings_index",
          title="Settings",
          meta=[],
        ),
        @router.Routes::Page(
          path="/profile",
          component="settings_profile",
          title="Profile Settings",
          meta=[],
        ),
      ],
    ),
  ]
}

// =============================================================================
// Components
// =============================================================================

///|
/// ナビゲーションコンポーネント
fn nav_component(router : @client.BrowserRouter) -> @dom.DomNode {
  let base = router.get_base()
  fn nav_link(href : String, label : String) -> @dom.DomNode {
    @dom.a(
      href=href,
      on=@dom.on(click=Some(fn(e) {
        e.preventDefault()
        router.navigate(href)
      })),
      [@dom.text(label)],
    )
  }

  @dom.nav(
    style="background: #333; padding: 10px;",
    [
      @dom.span(style="color: white; margin-right: 20px;", [
        nav_link(base, "Home"),
      ]),
      @dom.span(style="color: white; margin-right: 20px;", [
        nav_link(base + "/about", "About"),
      ]),
      @dom.span(style="color: white; margin-right: 20px;", [
        nav_link(base + "/users", "Users"),
      ]),
      @dom.span(style="color: white; margin-right: 20px;", [
        nav_link(base + "/settings", "Settings"),
      ]),
    ],
  )
}

///|
/// カウンターコンポーネント（動的要素のテスト用）
fn counter_component() -> @dom.DomNode {
  let count = @signal.signal(0)
  console_log("Creating counter component, initial count: " + count.get().to_string())
  @dom.div(
    class="counter",
    attrs=[("data-testid", @dom.AttrString("counter"))],
    [
      @dom.h3([@dom.text("Interactive Counter")]),
      @dom.p(
        attrs=[("data-testid", @dom.AttrString("count-display"))],
        [@dom.text_dyn(fn() { "Count: " + count.get().to_string() })],
      ),
      @dom.div(class="counter-buttons", [
        @dom.button(
          attrs=[("data-testid", @dom.AttrString("decrement-btn"))],
          on=@dom.on(click=Some(fn(_) {
            console_log("Decrement clicked, current: " + count.get().to_string())
            count.update(fn(n) { n - 1 })
            console_log("After decrement: " + count.get().to_string())
          })),
          [@dom.text("-")],
        ),
        @dom.button(
          attrs=[("data-testid", @dom.AttrString("increment-btn"))],
          on=@dom.on(click=Some(fn(_) {
            console_log("Increment clicked, current: " + count.get().to_string())
            count.update(fn(n) { n + 1 })
            console_log("After increment: " + count.get().to_string())
          })),
          [@dom.text("+")],
        ),
        @dom.button(
          attrs=[("data-testid", @dom.AttrString("reset-btn"))],
          on=@dom.on(click=Some(fn(_) {
            console_log("Reset clicked")
            count.set(0)
          })),
          [@dom.text("Reset")],
        ),
      ]),
    ],
  )
}

///|
/// ホームページ
fn home_component(router : @client.BrowserRouter) -> @dom.DomNode {
  @dom.div(
    class="page home",
    attrs=[("data-page", @dom.AttrString("home"))],
    [
      @dom.h1([@dom.text("Welcome to Browser App")]),
      @dom.p([@dom.text("This is an example of the new Routes-based routing system.")]),
      // カウンターを追加（動的要素のテスト）
      counter_component(),
      @dom.hr(),
      @dom.h2([@dom.text("Features")]),
      @dom.ul([
        @dom.li([@dom.text("Routes enum for declarative route definitions")]),
        @dom.li([@dom.text("Component ID-based resolution")]),
        @dom.li([@dom.text("Layout support for nested routes")]),
        @dom.li([@dom.text("Dynamic parameters with :id syntax")]),
        @dom.li([@dom.text("URLPattern API for matching")]),
      ]),
      @dom.p(
        attrs=[("data-testid", @dom.AttrString("current-path"))],
        [
          @dom.text("Current path: "),
          @dom.text_dyn(fn() { router.get_path() }),
        ],
      ),
    ],
  )
}

///|
/// About ページ
fn about_component(_router : @client.BrowserRouter) -> @dom.DomNode {
  @dom.div(
    class="page about",
    attrs=[("data-page", @dom.AttrString("about"))],
    [
      @dom.h1([@dom.text("About")]),
      @dom.p([@dom.text("This app demonstrates the new routing architecture:")]),
      @dom.ul([
        @dom.li([@dom.text("ServerComponent: async data fetching on server")]),
        @dom.li([@dom.text("ClientComponent (Island): Hydration with ln:url")]),
        @dom.li([@dom.text("Layout: shared wrapper for nested routes")]),
      ]),
    ],
  )
}

///|
/// ユーザーレイアウト
fn users_layout_component(
  router : @client.BrowserRouter,
  children : @dom.DomNode,
) -> @dom.DomNode {
  let base = router.get_base()
  @dom.div(
    class="users-layout",
    style="border: 2px solid #007bff; padding: 15px; margin: 10px 0;",
    [
      @dom.div(
        style="background: #007bff; color: white; padding: 10px; margin: -15px -15px 15px -15px;",
        [
          @dom.h2(style="margin: 0;", [@dom.text("Users Section")]),
          @dom.p(style="margin: 5px 0 0 0; font-size: 0.9em;", [
            @dom.text("This is a layout wrapper for all /users/* routes"),
          ]),
        ],
      ),
      @dom.div(style="margin-bottom: 10px;", [
        @dom.button(
          style="margin-right: 10px;",
          on=@dom.on(click=Some(fn(_) { router.navigate(base + "/users") })),
          [@dom.text("User List")],
        ),
        @dom.button(
          style="margin-right: 10px;",
          on=@dom.on(click=Some(fn(_) { router.navigate(base + "/users/1") })),
          [@dom.text("User 1")],
        ),
        @dom.button(
          style="margin-right: 10px;",
          on=@dom.on(click=Some(fn(_) { router.navigate(base + "/users/2") })),
          [@dom.text("User 2")],
        ),
        @dom.button(
          on=@dom.on(click=Some(fn(_) { router.navigate(base + "/users/3") })),
          [@dom.text("User 3")],
        ),
      ]),
      children,
    ],
  )
}

///|
/// ユーザー一覧
fn users_list_component(_router : @client.BrowserRouter) -> @dom.DomNode {
  @dom.div(class="users-list", [
    @dom.h3([@dom.text("User List")]),
    @dom.ul([
      @dom.li([@dom.text("User 1 - Alice")]),
      @dom.li([@dom.text("User 2 - Bob")]),
      @dom.li([@dom.text("User 3 - Charlie")]),
    ]),
  ])
}

///|
/// ユーザー詳細
fn user_detail_component(
  _router : @client.BrowserRouter,
  m : @router.RoutesMatch,
) -> @dom.DomNode {
  let user_id = m.get_param("id").unwrap_or("unknown")
  let user_name = match user_id {
    "1" => "Alice"
    "2" => "Bob"
    "3" => "Charlie"
    _ => "Unknown User"
  }
  @dom.div(class="user-detail", [
    @dom.h3([@dom.text("User Detail")]),
    @dom.p([@dom.text("User ID: " + user_id)]),
    @dom.p([@dom.text("Name: " + user_name)]),
    @dom.p(
      style="color: #666; font-style: italic;",
      [@dom.text("(In a real app, this data would be fetched from an API)")],
    ),
  ])
}

///|
/// 設定インデックス
fn settings_index_component(router : @client.BrowserRouter) -> @dom.DomNode {
  let base = router.get_base()
  let profile_path = base + "/settings/profile"
  @dom.div(class="settings-index", [
    @dom.h1([@dom.text("Settings")]),
    @dom.ul([
      @dom.li([
        @dom.a(
          href=profile_path,
          on=@dom.on(click=Some(fn(e) {
            e.preventDefault()
            router.navigate(profile_path)
          })),
          [@dom.text("Profile Settings")],
        ),
      ]),
    ]),
  ])
}

///|
/// プロファイル設定
fn settings_profile_component(router : @client.BrowserRouter) -> @dom.DomNode {
  let base = router.get_base()
  @dom.div(class="settings-profile", [
    @dom.h1([@dom.text("Profile Settings")]),
    @dom.p([@dom.text("Edit your profile here.")]),
    @dom.button(on=@dom.on(click=Some(fn(_) { router.navigate(base + "/settings") })), [
      @dom.text("Back to Settings"),
    ]),
  ])
}

///|
/// 404 ページ
fn not_found_component(router : @client.BrowserRouter) -> @dom.DomNode {
  let base = router.get_base()
  @dom.div(class="not-found", [
    @dom.h1([@dom.text("404 - Not Found")]),
    @dom.p([
      @dom.text("Page not found: "),
      @dom.text_dyn(fn() { router.get_path() }),
    ]),
    @dom.button(on=@dom.on(click=Some(fn(_) { router.navigate(base) })), [
      @dom.text("Go Home"),
    ]),
  ])
}

// =============================================================================
// Component Resolver
// =============================================================================

///|
/// コンポーネントIDからコンポーネントを解決
fn resolve_component(
  router : @client.BrowserRouter,
  m : @router.RoutesMatch,
) -> @dom.DomNode {
  let component_id = m.component()
  let layouts = m.layouts()
  console_log(
    "Resolving component: " + component_id + ", layouts: " + layouts.length().to_string(),
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
fn render_route(router : @client.BrowserRouter, container : @dom.DomElement) -> Unit {
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
      @dom.div(
        class="app",
        style="font-family: system-ui, sans-serif; max-width: 800px; margin: 0 auto;",
        [nav, @dom.div(style="padding: 20px;", [page])],
      )
    })

    @dom.mount(container, app)
  })
}

// =============================================================================
// Main
// =============================================================================

fn main {
  console_log("Browser App Starting...")

  let doc = @js_dom.document()
  let container = doc.getElementById("app")
  match container {
    Some(el) => {
      // ルーターを作成（ベースパスを指定）
      let base = "/playground/browser_app"
      let routes = create_routes()
      let router = @client.BrowserRouter::new(routes, base=base)

      // Debug: log compiled routes
      for route in router.routes {
        console_log(
          "Compiled route: pattern=" + route.pattern + ", component=" + route.component,
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
