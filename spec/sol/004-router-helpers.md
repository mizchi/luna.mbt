# Sol Router Helpers

Sol Router Helpers は、ルート定義とAPIハンドラーを簡潔に書くためのヘルパー関数群。

## ルート定義ヘルパー

### page() - ページルート

```moonbit
@router.page("/", home, title="Home")
@router.page("/blog/:slug", blog_post, title="Blog", revalidate=Some(60))
```

**パラメータ:**
- `path: String` - URLパターン
- `handler: async (PageProps) -> ServerNode` - ページハンドラー
- `title?: String = ""` - ページタイトル
- `meta?: Array[(String, String)] = []` - メタタグ
- `revalidate?: Int? = None` - ISR TTL（秒）
- `cache?: CacheStrategy? = None` - CSRキャッシュ戦略

### api_get() / api_post() - APIルート

```moonbit
@router.api_get("/api/users/:id", get_user)
@router.api_post("/api/users", create_user)
```

### wrap() - レイアウト

```moonbit
@router.wrap("/admin", admin_layout, [
  @router.page("/", admin_dashboard),
  @router.page("/settings", admin_settings),
])
```

### with_mw() - ミドルウェア

```moonbit
@router.with_mw([@mw.logger(), @mw.cors()], [
  @router.api_get("/api/data", get_data),
])
```

## レスポンスビルダー

### ApiResponse enum

```moonbit
pub enum ApiResponse {
  Json(@js.Any)
  Redirect(String, Int)
  NotFound(String)
  Error(String, Int)
}
```

### ヘルパー関数

```moonbit
// 成功レスポンス
@router.ok([("status", @js.any("success"))]).to_json()

// リダイレクト
@router.redirect_to("/dashboard").to_json()
@router.redirect_permanent_to("/new-url").to_json()

// エラーレスポンス
@router.not_found_response().to_json()
@router.error_response("Server error", status=500).to_json()
@router.bad_request("Invalid input").to_json()
@router.unauthorized().to_json()
@router.forbidden().to_json()
```

## パラメータ抽出

### require() - 必須パラメータ

```moonbit
async fn get_user(props : @router.PageProps) -> @js.Any {
  match @router.require(props, "id") {
    Ok(id) => @router.ok([("id", @js.any(id))]).to_json()
    Err(err) => err.to_json()
  }
}
```

### require_int() - 整数パラメータ

```moonbit
match @router.require_int(props, "id") {
  Ok(id) => @router.ok([("computed", @js.any(id * 2))]).to_json()
  Err(err) => err.to_json()
}
```

### optional() - オプショナルパラメータ

```moonbit
let slug = @router.optional(props, "slug", "index")
```

### クエリパラメータ

```moonbit
match @router.require_query(props, "sort") {
  Ok(sort) => ...
  Err(err) => err.to_json()
}

let limit = @router.optional_query(props, "limit", "10")
```

## ServerNode ヘルパー

### nodes() - フラグメント作成

```moonbit
@router.nodes([
  @element.h1([@element.text("Hello")]),
  @element.p([@element.text("World")]),
])
```

## 完全な例

```moonbit
pub fn routes() -> Array[@router.SolRoutes] {
  [
    @router.with_mw([@mw.logger()], [
      @router.wrap("", root_layout, [
        @router.page("/", home, title="Home"),
        @router.page("/user/:id", user_profile, title="User"),
        @router.page("/blog", blog_index, title="Blog", revalidate=Some(60)),
      ]),
      @router.api_get("/api/health", api_health),
      @router.api_get("/api/users/:id", api_get_user),
      @router.api_post("/api/users", api_create_user),
    ]),
  ]
}

async fn home(_props : @router.PageProps) -> @server_dom.ServerNode {
  @router.nodes([
    @element.h1([@element.text("Home")]),
    @element.p([@element.text("Welcome!")]),
  ])
}

async fn api_health(_props : @router.PageProps) -> @js.Any {
  @router.ok([("status", @js.any("ok"))]).to_json()
}

async fn api_get_user(props : @router.PageProps) -> @js.Any {
  match @router.require(props, "id") {
    Ok(id) => {
      @router.ok([
        ("id", @js.any(id)),
        ("name", @js.any("User " + id)),
      ]).to_json()
    }
    Err(err) => err.to_json()
  }
}
```

## 従来APIとの比較

### Before (従来)

```moonbit
@router.SolRoutes::Page(
  path="/",
  handler=@router.PageHandler(home),
  title="Home",
  meta=[],
  revalidate=None,
  cache=None,
)
```

### After (新API)

```moonbit
@router.page("/", home, title="Home")
```
