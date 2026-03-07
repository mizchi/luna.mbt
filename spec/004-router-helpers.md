# Sol Router Helpers

Sol Router Helpers are a set of helper functions for writing route definitions and API handlers concisely.

## Route Definition Helpers

### page() - Page Route

```moonbit
@router.page("/", home, title="Home")
@router.page("/blog/:slug", blog_post, title="Blog", revalidate=Some(60))
```

**Parameters:**
- `path: String` - URL pattern
- `handler: async (PageProps) -> ServerNode` - Page handler
- `title?: String = ""` - Page title
- `meta?: Array[(String, String)] = []` - Meta tags
- `revalidate?: Int? = None` - ISR TTL (seconds)
- `cache?: CacheStrategy? = None` - CSR cache strategy

### api_get() / api_post() - API Routes

```moonbit
@router.api_get("/api/users/:id", get_user)
@router.api_post("/api/users", create_user)
```

### wrap() - Layout

```moonbit
@router.wrap("/admin", admin_layout, [
  @router.page("/", admin_dashboard),
  @router.page("/settings", admin_settings),
])
```

### with_mw() - Middleware

```moonbit
@router.with_mw([@mw.logger(), @mw.cors()], [
  @router.api_get("/api/data", get_data),
])
```

## Response Builder

### ApiResponse enum

```moonbit
pub enum ApiResponse {
  Json(@js.Any)
  Redirect(String, Int)
  NotFound(String)
  Error(String, Int)
}
```

### Helper Functions

```moonbit
// Success response
@router.ok([("status", @js.any("success"))]).to_json()

// Redirect
@router.redirect_to("/dashboard").to_json()
@router.redirect_permanent_to("/new-url").to_json()

// Error responses
@router.not_found_response().to_json()
@router.error_response("Server error", status=500).to_json()
@router.bad_request("Invalid input").to_json()
@router.unauthorized().to_json()
@router.forbidden().to_json()
```

## Parameter Extraction

### require() - Required Parameter

```moonbit
async fn get_user(props : @router.PageProps) -> @js.Any {
  match @router.require(props, "id") {
    Ok(id) => @router.ok([("id", @js.any(id))]).to_json()
    Err(err) => err.to_json()
  }
}
```

### require_int() - Integer Parameter

```moonbit
match @router.require_int(props, "id") {
  Ok(id) => @router.ok([("computed", @js.any(id * 2))]).to_json()
  Err(err) => err.to_json()
}
```

### optional() - Optional Parameter

```moonbit
let slug = @router.optional(props, "slug", "index")
```

### Query Parameters

```moonbit
match @router.require_query(props, "sort") {
  Ok(sort) => ...
  Err(err) => err.to_json()
}

let limit = @router.optional_query(props, "limit", "10")
```

## ServerNode Helpers

### nodes() - Create Fragment

```moonbit
@router.nodes([
  @element.h1([@element.text("Hello")]),
  @element.p([@element.text("World")]),
])
```

## Complete Example

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

## Comparison with Legacy API

### Before (Legacy)

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

### After (New API)

```moonbit
@router.page("/", home, title="Home")
```
