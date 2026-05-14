///|
using @test {assert_eq}

// Server Action unit tests
// Note: ActionContext tests require Mars.Context, which is not easily mockable.
// These tests focus on ActionResult and ActionDef/ActionRegistry.

// ============================================================================
// ActionResult Tests
// ============================================================================

///|
test "ActionResult success variant carries raw data internally" {
  let result = ActionResult::{ kind: JsonSuccess(@js.any({ "id": 1 })) }
  match result.kind {
    JsonSuccess(_) => ()
    _ => fail("expected Success")
  }
}

///|
test "ActionResult::json creates success result from ToJson payload" {
  let result = ActionResult::json(CreateUserResponse::{ id: "user-1" })
  match result.kind {
    JsonSuccess(_) => ()
    _ => fail("expected Success")
  }
}

///|
test "ActionResult::redirect creates redirect result" {
  let result = ActionResult::redirect("/dashboard")
  match result.kind {
    ClientRedirect(url) => assert_eq(url, "/dashboard")
    _ => fail("expected Redirect")
  }
}

///|
test "ActionResult::http_redirect creates http redirect result" {
  let result = ActionResult::http_redirect("/login")
  match result.kind {
    HttpRedirectResult(url) => assert_eq(url, "/login")
    _ => fail("expected HttpRedirect")
  }
}

///|
test "ActionResult::bad_request creates 400 error" {
  let result = ActionResult::bad_request("Invalid input")
  match result.kind {
    ClientFailure(status, msg) => {
      assert_eq(status, 400)
      assert_eq(msg, "Invalid input")
    }
    _ => fail("expected ClientError")
  }
}

///|
test "ActionResult::validation_error creates 422 error" {
  let result = ActionResult::validation_error("Name is required")
  match result.kind {
    ClientFailure(status, msg) => {
      assert_eq(status, 422)
      assert_eq(msg, "Name is required")
    }
    _ => fail("expected ClientError")
  }
}

///|
test "ActionResult::unauthorized creates 401 error" {
  let result = ActionResult::unauthorized()
  match result.kind {
    ClientFailure(status, msg) => {
      assert_eq(status, 401)
      assert_eq(msg, "Unauthorized")
    }
    _ => fail("expected ClientError")
  }
}

///|
test "ActionResult::forbidden creates 403 error" {
  let result = ActionResult::forbidden(message="Access denied")
  match result.kind {
    ClientFailure(status, msg) => {
      assert_eq(status, 403)
      assert_eq(msg, "Access denied")
    }
    _ => fail("expected ClientError")
  }
}

///|
test "ActionResult::not_found creates 404 error" {
  let result = ActionResult::not_found()
  match result.kind {
    ClientFailure(status, msg) => {
      assert_eq(status, 404)
      assert_eq(msg, "Not Found")
    }
    _ => fail("expected ClientError")
  }
}

///|
test "ActionResult::server_error creates 500 error" {
  let result = ActionResult::server_error(message="DB connection failed")
  match result.kind {
    ServerFailure(msg) => assert_eq(msg, "DB connection failed")
    _ => fail("expected ServerError")
  }
}

// ============================================================================
// ActionDef Tests
// ============================================================================

///|
priv struct CreateUserActionKey {}

///|
impl ActionKey for CreateUserActionKey with id(_self) {
  "create-user"
}

///|
impl ActionKey for CreateUserActionKey with base_path(_self) {
  "/_action"
}

///|
priv struct GetUserActionKey {}

///|
impl ActionKey for GetUserActionKey with id(_self) {
  "get-user"
}

///|
impl ActionKey for GetUserActionKey with base_path(_self) {
  "/_action"
}

///|
priv struct ActionOneKey {}

///|
impl ActionKey for ActionOneKey with id(_self) {
  "action1"
}

///|
impl ActionKey for ActionOneKey with base_path(_self) {
  "/_action"
}

///|
priv struct ActionTwoKey {}

///|
impl ActionKey for ActionTwoKey with id(_self) {
  "action2"
}

///|
impl ActionKey for ActionTwoKey with base_path(_self) {
  "/_action"
}

///|
test "action_url builds endpoint URL from action key" {
  let key = CreateUserActionKey::{  }
  assert_eq(action_id(key), "create-user")
  assert_eq(action_url(key), "/_action/create-user")
}

///|
priv struct CreateUserRequest {
  name : String
} derive(ToJson, FromJson)

///|
priv struct CreateUserResponse {
  id : String
} derive(ToJson, FromJson)

///|
test "TypedActionKey carries request and response phantom types" {
  let req = CreateUserRequest::{ name: "Alice" }
  let res = CreateUserResponse::{ id: "user-1" }
  let key : TypedActionKey[CreateUserRequest, CreateUserResponse] = TypedActionKey::from_key(CreateUserActionKey::{

    },
  )
  assert_eq(req.name, "Alice")
  assert_eq(res.id, "user-1")
  assert_eq(key.id(), "create-user")
  assert_eq(key.base_path(), "/_action")
  assert_eq(typed_action_url(key), "/_action/create-user")
}

///|
test "TypedActionKey can be used as an ActionKey" {
  let key : TypedActionKey[CreateUserRequest, CreateUserResponse] = TypedActionKey::from_key(CreateUserActionKey::{

    },
  )
  assert_eq(action_id(key), "create-user")
  assert_eq(action_url(key), "/_action/create-user")
}

///|
test "decode_action_body decodes typed JSON request bodies" {
  let body = CreateUserRequest::{ name: "Alice" }.to_json().stringify()
  let decoded : CreateUserRequest? = decode_action_body(body)
  match decoded {
    Some(req) => assert_eq(req.name, "Alice")
    None => fail("expected decoded request")
  }
}

///|
test "decode_action_body rejects invalid request bodies" {
  let decoded : CreateUserRequest? = decode_action_body("{\"unexpected\":true}")
  assert_true(decoded is None)
}

///|
test "typed action invoker carries request payload type" {
  let key : TypedActionKey[CreateUserRequest, CreateUserResponse] = TypedActionKey::from_key(CreateUserActionKey::{

    },
  )
  let _invoker : (
    CreateUserRequest,
    (TypedActionResponse[CreateUserResponse]) -> Unit,
  ) -> Unit = create_typed_action_invoker_key(key)
}

///|
test "typed action response decodes success payload" {
  let raw = ActionResponse::Success(
    @js_any.json_to_any(CreateUserResponse::{ id: "user-1" }.to_json()),
  )
  let typed : TypedActionResponse[CreateUserResponse] = TypedActionResponse::from_action_response(
    raw,
  )
  match typed {
    Success(data) => assert_eq(data.id, "user-1")
    _ => fail("expected typed success")
  }
}

///|
test "typed action response reports decode errors" {
  let obj : Map[String, Json] = {}
  let raw = ActionResponse::Success(@js_any.json_to_any(obj.to_json()))
  let typed : TypedActionResponse[CreateUserResponse] = TypedActionResponse::from_action_response(
    raw,
  )
  match typed {
    DecodeError(_) => ()
    _ => fail("expected decode error")
  }
}

///|
test "ActionDef::from_key creates definition from action key" {
  let handler = ActionHandler(async fn(_ctx) {
    ActionResult::json(())
  })
  let action = ActionDef::from_key(CreateUserActionKey::{  }, handler)
  assert_eq(action.id, "create-user")
  assert_true(action.require_json)
  assert_true(action.middlewares.is_empty())
}

///|
test "ActionDef::with_require_json toggles json requirement" {
  let handler = ActionHandler(async fn(_ctx) {
    ActionResult::json(())
  })
  let action = ActionDef::from_key(CreateUserActionKey::{  }, handler).with_require_json(
    false,
  )
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
    ActionResult::json(())
  })
  let action = ActionDef::from_key(CreateUserActionKey::{  }, handler)
  let registry = ActionRegistry::new().register(action)
  assert_eq(registry.action_ids().length(), 1)
  assert_true(registry.action_ids().contains("create-user"))
}

///|
test "ActionRegistry::register_key adds generated-key action" {
  let handler = ActionHandler(async fn(_ctx) {
    ActionResult::json(())
  })
  let registry = ActionRegistry::new().register_key(
    CreateUserActionKey::{  },
    handler,
  )
  assert_eq(registry.action_ids().length(), 1)
  assert_true(registry.action_ids().contains("create-user"))
}

///|
test "ActionRegistry::get returns registered action" {
  let handler = ActionHandler(async fn(_ctx) {
    ActionResult::json(())
  })
  let action = ActionDef::from_key(GetUserActionKey::{  }, handler)
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
    ActionResult::json(())
  })
  let handler2 = ActionHandler(async fn(_ctx) {
    ActionResult::json(())
  })
  let actions = [
    ActionDef::from_key(ActionOneKey::{  }, handler1),
    ActionDef::from_key(ActionTwoKey::{  }, handler2),
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

// ============================================================================
// ActionFormConfig Tests
// ============================================================================

///|
test "ActionFormConfig::from_key creates typed form config" {
  let config = ActionFormConfig::from_key(CreateUserActionKey::{  })
  assert_eq(config.action, "/_action/create-user")
  assert_eq(config.form_method, "POST")
}

///|
test "ActionFormConfig builder methods preserve typed action url" {
  let config = ActionFormConfig::from_key(CreateUserActionKey::{  })
    .with_method("PUT")
    .with_success(fn(_data) { () })
    .with_error(fn(_status, _message) { () })
    .with_redirect(fn(_url) { false })
  assert_eq(config.action, "/_action/create-user")
  assert_eq(config.form_method, "PUT")
  assert_true(config.on_success is Some(_))
  assert_true(config.on_error is Some(_))
  assert_true(config.on_redirect is Some(_))
}
