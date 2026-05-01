# Server Action

Server Actions are secure server-side functions that can be called from the client. They automatically include CSRF protection based on modern browser security features.

## Security Design

Based on [jxck's CSRF article](https://blog.jxck.io/entries/2024-04-26/csrf.html), the security model prioritizes:

1. **Origin Header Validation** (Primary Defense)
2. **Fetch Metadata Validation** (`Sec-Fetch-Site`, `Sec-Fetch-Mode`)
3. **Content-Type Validation** (for JSON APIs)
4. **SameSite Cookie** (Secondary Effect)

CSRF tokens are intentionally NOT included as they add complexity without significant benefit when proper Origin validation is in place.

## Server-Side Usage

### 1. Define Actions

```moonbit
let create_user_handler = ActionHandler(async fn(ctx) {
  // Parse request body
  let body = ctx.body
  // ... validate and process

  // Return success
  ActionResult::ok(@js.any({ "id": 123, "name": "John" }))
})

let delete_user_handler = ActionHandler(async fn(ctx) {
  // Check authorization
  let user_id = ctx.get_query("id")
  // ...

  // Return redirect on success
  ActionResult::redirect("/users")
})
```

### 2. Register Actions

```moonbit
let registry = ActionRegistry::new(
  allowed_origins=["https://example.com"]
)
  .register(ActionDef::new("create-user", create_user_handler))
  .register(
    ActionDef::new("delete-user", delete_user_handler)
      .with_require_json(false)
  )
```

### 3. Mount to Hono App

```moonbit
let app = @hono.Hono::new()
let app = register_actions(app, registry)
```

This registers endpoints at:
- `POST /_action/create-user`
- `POST /_action/delete-user`

## Client-Side Usage

### Basic Invocation

```moonbit
let response = invoke_action(
  "/_action/create-user",
  @js.any({ "name": "John", "email": "john@example.com" })
)

match response {
  Success(data) => {
    // Handle success
    let id = data["id"]
  }
  Redirect(url) => {
    // Handle redirect (usually automatic)
  }
  Error(status, message) => {
    // Handle error
  }
  NetworkError(message) => {
    // Handle network failure
  }
}
```

### Create Reusable Invoker

```moonbit
let create_user = create_action_invoker("/_action/create-user")

// Later...
let response = create_user(@js.any({ "name": "Jane" }))
```

### Form Integration

```moonbit
submit_form_as_action(
  form_element,
  ActionFormConfig::new("/_action/create-user")
)
```

## ActionResult Types

| Result | Description |
|--------|-------------|
| `Success(data)` | Operation succeeded, return JSON data |
| `Redirect(url)` | Operation succeeded, redirect client |
| `ClientError(status, msg)` | Client error (4xx) |
| `ServerError(msg)` | Server error (logged, not exposed) |

## Security Middleware

The CSRF middleware can also be used standalone:

```moonbit
// Full CSRF protection
@middleware.csrf_for_origin("https://example.com")

// Origin-only validation
@middleware.validate_origin_middleware(["https://example.com"])

// Fetch Metadata validation
@middleware.fetch_metadata()

// Require JSON Content-Type
@middleware.require_json_content_type()
```

## Configuration Options

### CsrfConfig

```moonbit
CsrfConfig::default()
  .with_origins(["https://example.com", "https://api.example.com"])
  .with_fetch_metadata(true)
  .require_json()
  .with_error_message("Access Denied")
```

### ActionDef

```moonbit
ActionDef::new("my-action", handler)
  .with_require_json(true)           // Require application/json
  .with_middleware(auth_middleware)  // Add custom middleware
```

### ActionRegistry

```moonbit
ActionRegistry::new(allowed_origins=["https://example.com"])
  .with_base_path("/api/action")  // Custom base path
  .register(action1)
  .register_all([action2, action3])
```
