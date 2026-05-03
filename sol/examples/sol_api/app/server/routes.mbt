// Pure REST API Example
// Demonstrates: JSON API, Middleware, Error Handling, CRUD operations

///|
pub fn routes() -> Array[@sol.SolRoutes] {
  [
    @sol.with_mw(
      [
        @middleware.cors(),
        @middleware.logger(),
        @middleware.security_headers_relaxed(),
      ],
      [
        @sol.api_get("/api/health", health_handler),
        @sol.api_get("/api/items", list_items_handler),
        @sol.api_get("/api/items/:id", get_item_handler),
        @sol.api_post("/api/items", create_item_handler),
        @sol.api_put("/api/items/:id", update_item_handler),
        @sol.api_delete("/api/items/:id", delete_item_handler),
        @sol.api_get("/api/stats", stats_handler),
        @sol.api_get("/api/error", error_handler),
      ],
    ),
  ]
}

///|
pub fn config() -> @sol.RouterConfig {
  @sol.RouterConfig::default()
}

// =============================================================================
// Response types (compile-time structure guarantee)
// =============================================================================

///|
priv struct HealthResponse {
  status : String
  timestamp : String
} derive(ToJson)

///|
priv struct ItemListResponse {
  items : Array[Item]
  total : Int
} derive(ToJson)

///|
priv struct StatsResponse {
  total_items : Int
  last_updated : String
} derive(ToJson)

// =============================================================================
// In-memory data store
// =============================================================================

///|
priv struct Item {
  id : Int
  name : String
  description : String
  created_at : String
} derive(ToJson)

///|
let items_store : Ref[Array[Item]] = { val: [] }

///|
fn ensure_items_initialized() -> Unit {
  if items_store.val.is_empty() {
    items_store.val = [
      {
        id: 1,
        name: "Item 1",
        description: "First item",
        created_at: "2024-01-01T00:00:00Z",
      },
      {
        id: 2,
        name: "Item 2",
        description: "Second item",
        created_at: "2024-01-02T00:00:00Z",
      },
      {
        id: 3,
        name: "Item 3",
        description: "Third item",
        created_at: "2024-01-03T00:00:00Z",
      },
    ]
  }
}

///|
fn get_next_id() -> Int {
  ensure_items_initialized()
  let max_id = items_store.val.fold(init=0, fn(acc, item) {
    if item.id > acc {
      item.id
    } else {
      acc
    }
  })
  max_id + 1
}

///|
fn find_item_index(id : Int) -> Int? {
  for i, item in items_store.val {
    if item.id == id {
      return Some(i)
    }
  }
  None
}

// =============================================================================
// Request types
// =============================================================================

///|
priv struct CreateItemRequest {
  name : String
  description : String
} derive(FromJson)

// =============================================================================
// API Handlers — guard let early-return pattern
// =============================================================================

///|
async fn health_handler(_props : @sol.PageProps) -> HealthResponse {
  { status: "ok", timestamp: get_timestamp() }
}

///|
async fn list_items_handler(_props : @sol.PageProps) -> ItemListResponse {
  ensure_items_initialized()
  { items: items_store.val, total: items_store.val.length() }
}

///|
async fn get_item_handler(props : @sol.PageProps) -> Json {
  ensure_items_initialized()
  let id = match @sol.require_int(props, "id") {
    Ok(id) => id
    Err(e) => return e.to_json()
  }
  let found = items_store.val.iter().find_first(fn(item) { item.id == id })
  match found {
    Some(item) => item.to_json()
    None => @sol.not_found_response(message="Item not found").to_json()
  }
}

///|
async fn create_item_handler(props : @sol.PageProps) -> Json {
  ensure_items_initialized()
  let body : CreateItemRequest = match props.body_as() {
    Ok(b) => b
    Err(e) => return e.to_json()
  }
  if body.name == "" {
    return @sol.bad_request("name is required").to_json()
  }
  let new_item : Item = {
    id: get_next_id(),
    name: body.name,
    description: body.description,
    created_at: get_timestamp(),
  }
  items_store.val.push(new_item)
  new_item.to_json()
}

///|
async fn update_item_handler(props : @sol.PageProps) -> Json {
  ensure_items_initialized()
  let id = match @sol.require_int(props, "id") {
    Ok(id) => id
    Err(e) => return e.to_json()
  }
  let i = match find_item_index(id) {
    Some(i) => i
    None => return @sol.not_found_response(message="Item not found").to_json()
  }
  let body : CreateItemRequest = match props.body_as() {
    Ok(b) => b
    Err(e) => return e.to_json()
  }
  let old_item = items_store.val[i]
  let updated_item : Item = {
    id: old_item.id,
    name: if body.name == "" { old_item.name } else { body.name },
    description: if body.description == "" {
      old_item.description
    } else {
      body.description
    },
    created_at: old_item.created_at,
  }
  items_store.val[i] = updated_item
  updated_item.to_json()
}

///|
async fn delete_item_handler(props : @sol.PageProps) -> Json {
  ensure_items_initialized()
  let id = match @sol.require_int(props, "id") {
    Ok(id) => id
    Err(e) => return e.to_json()
  }
  let i = match find_item_index(id) {
    Some(i) => i
    None => return @sol.not_found_response(message="Item not found").to_json()
  }
  let removed = items_store.val[i]
  items_store.val = items_store.val
    .iter()
    .filter(fn(item) { item.id != id })
    .collect()
  @sol.ok([("deleted", true.to_json()), ("item", removed.to_json())]).to_json()
}

///|
async fn stats_handler(_props : @sol.PageProps) -> StatsResponse {
  ensure_items_initialized()
  { total_items: items_store.val.length(), last_updated: get_timestamp() }
}

///|
async fn error_handler(props : @sol.PageProps) -> Json {
  let error_type = props.get_query("type").unwrap_or("generic")
  match error_type {
    "not_found" =>
      @sol.not_found_response(message="Resource not found").to_json()
    "unauthorized" =>
      @sol.unauthorized(message="Authentication required").to_json()
    "forbidden" => @sol.forbidden(message="Access denied").to_json()
    "bad_request" => @sol.bad_request("Invalid request").to_json()
    _ => @sol.error_response("Internal server error").to_json()
  }
}

// =============================================================================
// Utilities
// =============================================================================

///|
fn get_timestamp() -> String {
  ffi_get_timestamp()
}

///|
extern "js" fn ffi_get_timestamp() -> String =
  #| () => new Date().toISOString()
