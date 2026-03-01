// Pure REST API Example
// Demonstrates: JSON API, Middleware, Error Handling, CRUD operations

///|
/// Define API routes
pub fn routes() -> Array[@router.SolRoutes] {
  [
    // Apply middleware to all API routes
    @router.SolRoutes::WithMiddleware(
      middleware=[
        // CORS middleware for API access
        @middleware.cors(),
        // Request logging
        @middleware.logger(),
        // Security headers
        @middleware.security_headers_relaxed(),
      ],
      children=[
        // Health check endpoint
        @router.SolRoutes::Get(
          path="/api/health",
          handler=@router.ApiHandler(health_handler),
        ),
        // Items CRUD endpoints
        @router.SolRoutes::Get(
          path="/api/items",
          handler=@router.ApiHandler(list_items_handler),
        ),
        @router.SolRoutes::Get(
          path="/api/items/:id",
          handler=@router.ApiHandler(get_item_handler),
        ),
        @router.SolRoutes::Post(
          path="/api/items",
          handler=@router.ApiHandler(create_item_handler),
        ),
        @router.SolRoutes::Put(
          path="/api/items/:id",
          handler=@router.ApiHandler(update_item_handler),
        ),
        @router.SolRoutes::Delete(
          path="/api/items/:id",
          handler=@router.ApiHandler(delete_item_handler),
        ),
        // Stats endpoint
        @router.SolRoutes::Get(
          path="/api/stats",
          handler=@router.ApiHandler(stats_handler),
        ),
        // Error test endpoint
        @router.SolRoutes::Get(
          path="/api/error",
          handler=@router.ApiHandler(error_handler),
        ),
      ],
    ),
  ]
}

///|
/// Server configuration
pub fn config() -> @router.RouterConfig {
  @router.RouterConfig::default()
}

///|
/// Empty action registry (no server actions for API)
pub fn action_registry() -> @action.ActionRegistry {
  @action.ActionRegistry::new(allowed_origins=[])
}

// =============================================================================
// In-memory data store (for demo purposes)
// =============================================================================

///|
/// Item structure
priv struct Item {
  id : Int
  name : String
  description : String
  created_at : String
} derive(ToJson)

///|
/// Global items store (simulated database)
let items_store : Ref[Array[Item]] = { val: [] }

///|
/// Initialize default items
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
/// Get next ID
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
/// Find index of item by ID
fn find_item_index(id : Int) -> Int? {
  for i, item in items_store.val {
    if item.id == id {
      return Some(i)
    }
  }
  None
}

// =============================================================================
// API Handlers
// =============================================================================

///|
/// Health check endpoint
async fn health_handler(_props : @router.PageProps) -> @core.Any {
  @sol.json_obj([
    ("status", @core.any("ok")),
    ("timestamp", @core.any(get_timestamp())),
  ])
}

///|
/// List all items
async fn list_items_handler(_props : @router.PageProps) -> @core.Any {
  ensure_items_initialized()
  let items_json = items_store.val.map(fn(item) { item.to_json() })
  @sol.json_obj([
    ("items", @sol.json_array_to_any(items_json)),
    ("total", @core.any(items_store.val.length())),
  ])
}

///|
/// Get single item by ID
async fn get_item_handler(props : @router.PageProps) -> @core.Any {
  ensure_items_initialized()
  let id_str = props.get_param("id").unwrap_or("")
  let id = parse_int(id_str)
  if id <= 0 {
    return error_response("invalid_id", "Invalid item ID")
  }
  let found = items_store.val.iter().find_first(fn(item) { item.id == id })
  match found {
    Some(item) => @sol.json_to_any(item.to_json())
    None => error_response("not_found", "Item not found")
  }
}

///|
/// Extract string field from JSON
fn get_json_string(json : Json?, field : String) -> String {
  match json {
    Some(Object(obj)) =>
      match obj.get(field) {
        Some(String(s)) => s
        _ => ""
      }
    _ => ""
  }
}

///|
/// Create new item (POST /api/items)
async fn create_item_handler(props : @router.PageProps) -> @core.Any {
  ensure_items_initialized()
  let json = props.ctx.body_json()
  let name = get_json_string(json, "name")
  if name == "" {
    return error_response("validation_error", "name is required")
  }
  let description = get_json_string(json, "description")
  let new_item : Item = {
    id: get_next_id(),
    name,
    description,
    created_at: get_timestamp(),
  }
  items_store.val.push(new_item)
  @sol.json_to_any(new_item.to_json())
}

///|
/// Update existing item (PUT /api/items/:id)
async fn update_item_handler(props : @router.PageProps) -> @core.Any {
  ensure_items_initialized()
  let id_str = props.get_param("id").unwrap_or("")
  let id = parse_int(id_str)
  if id <= 0 {
    return error_response("invalid_id", "Invalid item ID")
  }
  match find_item_index(id) {
    Some(i) => {
      let json = props.ctx.body_json()
      let old_item = items_store.val[i]
      let name_field = get_json_string(json, "name")
      let name = if name_field == "" { old_item.name } else { name_field }
      let desc_field = get_json_string(json, "description")
      let description = if desc_field == "" {
        old_item.description
      } else {
        desc_field
      }
      let updated_item : Item = {
        id: old_item.id,
        name,
        description,
        created_at: old_item.created_at,
      }
      items_store.val[i] = updated_item
      @sol.json_to_any(updated_item.to_json())
    }
    None => error_response("not_found", "Item not found")
  }
}

///|
/// Delete item (DELETE /api/items/:id)
async fn delete_item_handler(props : @router.PageProps) -> @core.Any {
  ensure_items_initialized()
  let id_str = props.get_param("id").unwrap_or("")
  let id = parse_int(id_str)
  if id <= 0 {
    return error_response("invalid_id", "Invalid item ID")
  }
  match find_item_index(id) {
    Some(i) => {
      let removed = items_store.val[i]
      items_store.val = items_store.val
        .iter()
        .filter(fn(item) { item.id != id })
        .collect()
      @sol.json_obj([
        ("deleted", @core.any(true)),
        ("item", @sol.json_to_any(removed.to_json())),
      ])
    }
    None => error_response("not_found", "Item not found")
  }
}

///|
/// Stats endpoint
async fn stats_handler(_props : @router.PageProps) -> @core.Any {
  ensure_items_initialized()
  @sol.json_obj([
    ("total_items", @core.any(items_store.val.length())),
    ("last_updated", @core.any(get_timestamp())),
  ])
}

///|
/// Error test endpoint
async fn error_handler(props : @router.PageProps) -> @core.Any {
  let error_type = props.get_query("type").unwrap_or("generic")
  match error_type {
    "not_found" => error_response("not_found", "Resource not found")
    "unauthorized" => error_response("unauthorized", "Authentication required")
    "forbidden" => error_response("forbidden", "Access denied")
    "bad_request" => error_response("bad_request", "Invalid request")
    _ => error_response("internal_error", "Internal server error")
  }
}

// =============================================================================
// Utilities
// =============================================================================

///|
/// Create error response object
fn error_response(error : String, message : String) -> @core.Any {
  @sol.json_obj([("error", @core.any(error)), ("message", @core.any(message))])
}

///|
/// Get current timestamp
fn get_timestamp() -> String {
  ffi_get_timestamp()
}

///|
extern "js" fn ffi_get_timestamp() -> String =
  #| () => new Date().toISOString()

///|
extern "js" fn parse_int(s : String) -> Int =
  #| (s) => parseInt(s, 10) || 0

