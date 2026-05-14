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
struct CreateUserRequest {
  name : String
  email : String
} derive(ToJson, FromJson)

struct CreateUserResponse {
  id : String
  name : String
} derive(ToJson, FromJson)

let create_user_handler = ActionHandler(async fn(ctx) {
  let req : CreateUserRequest = match ctx.decode_json() {
    Some(req) => req
    None => return ActionResult::bad_request("Invalid JSON payload")
  }

  if req.email == "" {
    return ActionResult::validation_error("Email is required")
  }

  ActionResult::json(CreateUserResponse::{ id: "123", name: req.name })
})

let update_profile_handler = ActionHandler(async fn(ctx) {
  let body = ctx.body
  // ... parse and validate

  if body == "" {
    return ActionResult::validation_error("Profile payload is required")
  }

  ActionResult::json({ "message": "Profile updated" })
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
// `sol generate` creates these factories from handler binding names:
// - create_user_handler -> @types.action_create_user()
// - submit_contact_handler -> @types.action_submit_contact()
// - add_todo_action -> @types.action_add_todo()
// - delete_user_handler -> @types.action_delete_user()

let registry = ActionRegistry::new(
  allowed_origins=["https://example.com"]
)
  .register(
    ActionDef::from_key(@types.action_create_user(), create_user_handler)
  )
  .register(
    ActionDef::from_key(@types.action_delete_user(), delete_user_handler)
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
let create_user_action : TypedActionKey[CreateUserRequest, CreateUserResponse] =
  @types.action_create_user_typed()

let handle_create_user : (TypedActionResponse[CreateUserResponse]) -> Unit = fn(response) {
  match response {
    Success(data) => {
      save_user_id(data.id)
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
    DecodeError(message) => {
      // Handle a response contract mismatch
    }
  }
}

invoke_typed_action_key(
  create_user_action,
  CreateUserRequest::{ name: "John", email: "john@example.com" },
  handle_create_user,
)
```

### Create Reusable Invoker

```moonbit
let create_user_action : TypedActionKey[CreateUserRequest, CreateUserResponse] =
  @types.action_create_user_typed()
let create_user = create_typed_action_invoker_key(create_user_action)

// Later...
create_user(
  CreateUserRequest::{ name: "Jane", email: "jane@example.com" },
  fn(response) {
    match response {
      Success(data) => save_user_id(data.id)
      _ => ()
    }
  },
)
```

### Form Integration

```moonbit
submit_form_as_action(
  form_element,
  ActionFormConfig::from_key(@types.action_create_user())
)
```

### Pending / Success / Error State

Use `ActionState` when the UI needs standard action affordances without
hand-rolling every state transition:

```moonbit
let state = @signal.signal(ActionState::idle())

state.set(ActionState::pending(message="Saving"))
invoke_typed_action_key(@types.action_create_user_typed(), payload, fn(response) {
  match response {
    Success(_) => state.set(ActionState::success(message="Saved"))
    Redirect(url) => state.set(ActionState::redirect(url))
    Error(status, message) => state.set(ActionState::error(status~, message~))
    NetworkError(message) => state.set(ActionState::error(status=0, message~))
    DecodeError(message) => state.set(ActionState::error(status=0, message~))
  }
})
```

## ActionResult Types

| Result | Description |
|--------|-------------|
| `Success(data)` | Operation succeeded, return JSON data |
| `Redirect(url)` | Operation succeeded, redirect client |
| `ClientError(status, msg)` | Client error (4xx) |
| `ServerError(msg)` | Server error (logged, not exposed) |

`ActionResult::validation_error(message)` is a convenience helper for `422`
validation failures.

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

### ActionKey / ActionDef

```moonbit
ActionDef::from_key(@types.action_my_action(), handler)
  .with_require_json(true)           // Require application/json
  .with_middleware(auth_middleware)  // Add custom middleware
```

Action IDs are derived from generated action key factories. Hand-written action
ID strings are not part of the public action definition API.

### ActionRegistry

```moonbit
ActionRegistry::new(allowed_origins=["https://example.com"])
  .with_base_path("/api/action")  // Custom base path
  .register_key(@types.action_my_action(), handler)
```
