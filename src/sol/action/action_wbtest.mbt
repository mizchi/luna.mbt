// Server Action unit tests

// ============================================================================
// ActionContext Tests
// ============================================================================

///|
test "ActionContext::get_header returns header value" {
  let ctx : ActionContext = {
    body: "{}",
    headers: [("Content-Type", "application/json"), ("X-Custom", "value")],
    query: [],
    state: {},
  }
  match ctx.get_header("Content-Type") {
    Some(v) => assert_eq(v, "application/json")
    None => fail("expected header")
  }
  match ctx.get_header("x-custom") {
    Some(v) => assert_eq(v, "value")
    None => fail("expected header (case-insensitive)")
  }
  match ctx.get_header("Not-Found") {
    Some(_) => fail("expected None")
    None => ()
  }
}

///|
test "ActionContext::get_query returns query value" {
  let ctx : ActionContext = {
    body: "{}",
    headers: [],
    query: [("page", "1"), ("limit", "10")],
    state: {},
  }
  match ctx.get_query("page") {
    Some(v) => assert_eq(v, "1")
    None => fail("expected query")
  }
  match ctx.get_query("missing") {
    Some(_) => fail("expected None")
    None => ()
  }
}

// ============================================================================
// ActionResult Tests
// ============================================================================

///|
test "ActionResult::ok creates success result" {
  let result = ActionResult::ok(@js.any({ "id": 1 }))
  match result {
    Success(_) => ()
    _ => fail("expected Success")
  }
}

///|
test "ActionResult::redirect creates redirect result" {
  let result = ActionResult::redirect("/dashboard")
  match result {
    Redirect(url) => assert_eq(url, "/dashboard")
    _ => fail("expected Redirect")
  }
}

///|
test "ActionResult::bad_request creates 400 error" {
  let result = ActionResult::bad_request("Invalid input")
  match result {
    ClientError(status, msg) => {
      assert_eq(status, 400)
      assert_eq(msg, "Invalid input")
    }
    _ => fail("expected ClientError")
  }
}

///|
test "ActionResult::unauthorized creates 401 error" {
  let result = ActionResult::unauthorized()
  match result {
    ClientError(status, msg) => {
      assert_eq(status, 401)
      assert_eq(msg, "Unauthorized")
    }
    _ => fail("expected ClientError")
  }
}

///|
test "ActionResult::forbidden creates 403 error" {
  let result = ActionResult::forbidden(message="Access denied")
  match result {
    ClientError(status, msg) => {
      assert_eq(status, 403)
      assert_eq(msg, "Access denied")
    }
    _ => fail("expected ClientError")
  }
}

///|
test "ActionResult::not_found creates 404 error" {
  let result = ActionResult::not_found()
  match result {
    ClientError(status, msg) => {
      assert_eq(status, 404)
      assert_eq(msg, "Not Found")
    }
    _ => fail("expected ClientError")
  }
}

///|
test "ActionResult::server_error creates 500 error" {
  let result = ActionResult::server_error(message="DB connection failed")
  match result {
    ServerError(msg) => assert_eq(msg, "DB connection failed")
    _ => fail("expected ServerError")
  }
}

// ============================================================================
// ActionDef Tests
// ============================================================================

///|
test "ActionDef::new creates default action" {
  let handler = ActionHandler(async fn(_ctx) { ActionResult::ok(@js.any({})) })
  let action = ActionDef::new("test-action", handler)
  assert_eq(action.id, "test-action")
  assert_true(action.require_json)
  assert_true(action.middlewares.is_empty())
}

///|
test "ActionDef::with_require_json toggles json requirement" {
  let handler = ActionHandler(async fn(_ctx) { ActionResult::ok(@js.any({})) })
  let action = ActionDef::new("test-action", handler).with_require_json(false)
  assert_false(action.require_json)
}

// ============================================================================
// ActionRegistry Tests
// ============================================================================

///|
test "ActionRegistry::new creates empty registry" {
  let registry = ActionRegistry::new()
  assert_true(registry.action_ids().is_empty())
  assert_eq(registry.base_path, "/_action")
}

///|
test "ActionRegistry::with_base_path sets base path" {
  let registry = ActionRegistry::new().with_base_path("/api/action")
  assert_eq(registry.base_path, "/api/action")
}

///|
test "ActionRegistry::register adds action" {
  let handler = ActionHandler(async fn(_ctx) { ActionResult::ok(@js.any({})) })
  let action = ActionDef::new("create-user", handler)
  let registry = ActionRegistry::new().register(action)
  assert_eq(registry.action_ids().length(), 1)
  assert_true(registry.action_ids().contains("create-user"))
}

///|
test "ActionRegistry::get returns registered action" {
  let handler = ActionHandler(async fn(_ctx) { ActionResult::ok(@js.any({})) })
  let action = ActionDef::new("get-user", handler)
  let registry = ActionRegistry::new().register(action)
  match registry.get("get-user") {
    Some(a) => assert_eq(a.id, "get-user")
    None => fail("expected action")
  }
  match registry.get("not-found") {
    Some(_) => fail("expected None")
    None => ()
  }
}

///|
test "ActionRegistry::action_url generates correct URL" {
  let registry = ActionRegistry::new()
  assert_eq(registry.action_url("create-user"), "/_action/create-user")
  let registry2 = registry.with_base_path("/api/v1/action")
  assert_eq(registry2.action_url("create-user"), "/api/v1/action/create-user")
}

///|
test "ActionRegistry::register_all adds multiple actions" {
  let handler1 = ActionHandler(async fn(_ctx) { ActionResult::ok(@js.any({})) })
  let handler2 = ActionHandler(async fn(_ctx) { ActionResult::ok(@js.any({})) })
  let actions = [
    ActionDef::new("action1", handler1),
    ActionDef::new("action2", handler2),
  ]
  let registry = ActionRegistry::new().register_all(actions)
  assert_eq(registry.action_ids().length(), 2)
}
