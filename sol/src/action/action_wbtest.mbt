// Server Action unit tests
// Note: ActionContext tests require Mars.Context, which is not easily mockable.
// These tests focus on ActionResult and ActionDef/ActionRegistry.

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
test "ActionResult::http_redirect creates http redirect result" {
  let result = ActionResult::http_redirect("/login")
  match result {
    HttpRedirect(url) => assert_eq(url, "/login")
    _ => fail("expected HttpRedirect")
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
test "ActionResult::validation_error creates 422 error" {
  let result = ActionResult::validation_error("Name is required")
  match result {
    ClientError(status, msg) => {
      assert_eq(status, 422)
      assert_eq(msg, "Name is required")
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
  let handler = ActionHandler(async fn(_ctx) {
    ActionResult::ok(@js.new_object())
  })
  let action = ActionDef::new("test-action", handler)
  assert_eq(action.id, "test-action")
  assert_true(action.require_json)
  assert_true(action.middlewares.is_empty())
}

///|
test "ActionDef::with_require_json toggles json requirement" {
  let handler = ActionHandler(async fn(_ctx) {
    ActionResult::ok(@js.new_object())
  })
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
  let handler = ActionHandler(async fn(_ctx) {
    ActionResult::ok(@js.new_object())
  })
  let action = ActionDef::new("create-user", handler)
  let registry = ActionRegistry::new().register(action)
  assert_eq(registry.action_ids().length(), 1)
  assert_true(registry.action_ids().contains("create-user"))
}

///|
test "ActionRegistry::get returns registered action" {
  let handler = ActionHandler(async fn(_ctx) {
    ActionResult::ok(@js.new_object())
  })
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
  let handler1 = ActionHandler(async fn(_ctx) {
    ActionResult::ok(@js.new_object())
  })
  let handler2 = ActionHandler(async fn(_ctx) {
    ActionResult::ok(@js.new_object())
  })
  let actions = [
    ActionDef::new("action1", handler1),
    ActionDef::new("action2", handler2),
  ]
  let registry = ActionRegistry::new().register_all(actions)
  assert_eq(registry.action_ids().length(), 2)
}

// ============================================================================
// ActionState Tests
// ============================================================================

///|
test "ActionState constructors cover idle pending success and error states" {
  let idle = ActionState::idle()
  assert_true(idle.phase is ActionPhase::Idle)
  assert_eq(idle.message, None)

  let pending = ActionState::pending(message="Saving")
  assert_true(pending.phase is ActionPhase::Pending)
  assert_eq(pending.message, Some("Saving"))

  let success = ActionState::success(message="Saved")
  assert_true(success.phase is ActionPhase::Succeeded)
  assert_eq(success.message, Some("Saved"))

  let failed = ActionState::error(status=422, message="Invalid")
  assert_true(failed.phase is ActionPhase::Failed)
  assert_eq(failed.status, Some(422))
  assert_eq(failed.message, Some("Invalid"))
}

///|
test "ActionState::from_response maps action responses to UI states" {
  let ok = ActionState::from_response(ActionResponse::Success(@js.new_object()))
  assert_true(ok.phase is ActionPhase::Succeeded)
  assert_eq(ok.message, Some("Success"))

  let redirect = ActionState::from_response(ActionResponse::Redirect("/done"))
  assert_true(redirect.phase is ActionPhase::Redirecting)
  assert_eq(redirect.redirect, Some("/done"))

  let failed = ActionState::from_response(ActionResponse::Error(400, "Bad input"))
  assert_true(failed.phase is ActionPhase::Failed)
  assert_eq(failed.status, Some(400))
  assert_eq(failed.message, Some("Bad input"))

  let network = ActionState::from_response(ActionResponse::NetworkError("offline"))
  assert_true(network.phase is ActionPhase::Failed)
  assert_eq(network.status, Some(0))
  assert_eq(network.message, Some("offline"))
}
