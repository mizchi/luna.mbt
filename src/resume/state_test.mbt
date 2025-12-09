///| Tests for Resumable State

// =============================================================================
// State Serialization Tests
// =============================================================================

///|
test "ResumableState register and get int" {
  let state = ResumableState::new()
  let id = state.register_int(42)
  assert_eq(id, 0)
  assert_eq(state.get_int(id), Some(42))
}

///|
test "ResumableState register and get string" {
  let state = ResumableState::new()
  let id = state.register_string("hello")
  assert_eq(id, 0)
  assert_eq(state.get_string(id), Some("hello"))
}

///|
test "ResumableState register and get bool" {
  let state = ResumableState::new()
  let id1 = state.register_bool(true)
  let id2 = state.register_bool(false)
  assert_eq(state.get_bool(id1), Some(true))
  assert_eq(state.get_bool(id2), Some(false))
}

///|
test "ResumableState register and get float" {
  let state = ResumableState::new()
  let id = state.register_float(3.14)
  match state.get_float(id) {
    Some(v) => assert_true(v > 3.13 && v < 3.15)
    None => assert_true(false)
  }
}

///|
test "ResumableState multiple values" {
  let state = ResumableState::new()
  let id1 = state.register_int(1)
  let id2 = state.register_string("two")
  let id3 = state.register_bool(true)
  assert_eq(id1, 0)
  assert_eq(id2, 1)
  assert_eq(id3, 2)
  assert_eq(state.get_int(id1), Some(1))
  assert_eq(state.get_string(id2), Some("two"))
  assert_eq(state.get_bool(id3), Some(true))
}

// =============================================================================
// JSON Serialization Tests
// =============================================================================

///|
test "ResumableState to_json empty" {
  let state = ResumableState::new()
  assert_eq(state.to_json(), "[]")
}

///|
test "ResumableState to_json single int" {
  let state = ResumableState::new()
  let _ = state.register_int(42)
  assert_eq(state.to_json(), "[42]")
}

///|
test "ResumableState to_json multiple values" {
  let state = ResumableState::new()
  let _ = state.register_int(1)
  let _ = state.register_string("hello")
  let _ = state.register_bool(true)
  assert_eq(state.to_json(), "[1,\"hello\",true]")
}

///|
test "ResumableState to_json string with escapes" {
  let state = ResumableState::new()
  let _ = state.register_string("line1\nline2")
  assert_eq(state.to_json(), "[\"line1\\nline2\"]")
}

///|
test "ResumableState to_json null" {
  let state = ResumableState::new()
  let _ = state.register_null()
  assert_eq(state.to_json(), "[null]")
}

// =============================================================================
// JSON Parsing Tests
// =============================================================================

///|
test "ResumableState from_json empty array" {
  match ResumableState::from_json("[]") {
    Some(state) => assert_eq(state.values.length(), 0)
    None => assert_true(false)
  }
}

///|
test "ResumableState from_json single int" {
  match ResumableState::from_json("[42]") {
    Some(state) => {
      assert_eq(state.values.length(), 1)
      assert_eq(state.get_int(0), Some(42))
    }
    None => assert_true(false)
  }
}

///|
test "ResumableState from_json multiple values" {
  match ResumableState::from_json("[1,\"hello\",true,false,null]") {
    Some(state) => {
      assert_eq(state.values.length(), 5)
      assert_eq(state.get_int(0), Some(1))
      assert_eq(state.get_string(1), Some("hello"))
      assert_eq(state.get_bool(2), Some(true))
      assert_eq(state.get_bool(3), Some(false))
      match state.get(4) {
        Some(Null) => assert_true(true)
        _ => assert_true(false)
      }
    }
    None => assert_true(false)
  }
}

///|
test "ResumableState from_json negative int" {
  match ResumableState::from_json("[-42]") {
    Some(state) => assert_eq(state.get_int(0), Some(-42))
    None => assert_true(false)
  }
}

///|
test "ResumableState from_json float" {
  match ResumableState::from_json("[3.14]") {
    Some(state) =>
      match state.get_float(0) {
        Some(v) => assert_true(v > 3.13 && v < 3.15)
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "ResumableState from_json string with escapes" {
  match ResumableState::from_json("[\"line1\\nline2\"]") {
    Some(state) => assert_eq(state.get_string(0), Some("line1\nline2"))
    None => assert_true(false)
  }
}

///|
test "ResumableState roundtrip" {
  let state1 = ResumableState::new()
  let _ = state1.register_int(42)
  let _ = state1.register_string("test")
  let _ = state1.register_bool(true)
  let json = state1.to_json()
  match ResumableState::from_json(json) {
    Some(state2) => {
      assert_eq(state2.get_int(0), Some(42))
      assert_eq(state2.get_string(1), Some("test"))
      assert_eq(state2.get_bool(2), Some(true))
    }
    None => assert_true(false)
  }
}

// =============================================================================
// HTML Embedding Tests
// =============================================================================

///|
test "state_to_script_tag" {
  let state = ResumableState::new()
  let _ = state.register_int(42)
  let tag = state_to_script_tag(state)
  assert_true(tag.contains("data-resumable-state"))
  assert_true(tag.contains("[42]"))
}

///|
test "extract_state_from_html" {
  let html = "<div>content</div><script type=\"application/json\" data-resumable-state>[1,2,3]</script>"
  match extract_state_from_html(html) {
    Some(json) => assert_eq(json, "[1,2,3]")
    None => assert_true(false)
  }
}

///|
test "extract_state_from_html not found" {
  let html = "<div>content</div>"
  match extract_state_from_html(html) {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
}

///|
test "parse_state_from_html" {
  let html = "<div>content</div><script type=\"application/json\" data-resumable-state>[42,\"hello\"]</script>"
  match parse_state_from_html(html) {
    Some(state) => {
      assert_eq(state.get_int(0), Some(42))
      assert_eq(state.get_string(1), Some("hello"))
    }
    None => assert_true(false)
  }
}

///|
test "state embedding roundtrip" {
  // SSR side: create state and embed in HTML
  let ssr_state = ResumableState::new()
  let _ = ssr_state.register_int(42)
  let _ = ssr_state.register_string("hello")
  let _ = ssr_state.register_bool(true)
  let script_tag = state_to_script_tag(ssr_state)
  let html = "<div>App content</div>" + script_tag
  // Client side: extract and restore state
  match parse_state_from_html(html) {
    Some(client_state) => {
      assert_eq(client_state.get_int(0), Some(42))
      assert_eq(client_state.get_string(1), Some("hello"))
      assert_eq(client_state.get_bool(2), Some(true))
    }
    None => assert_true(false)
  }
}

// =============================================================================
// Multi-State HTML Embedding Tests
// =============================================================================

///|
test "state_to_script_tag_with_id" {
  let state = ResumableState::new()
  let _ = state.register_int(42)
  let tag = state_to_script_tag_with_id(state, "counter")
  assert_true(tag.contains("data-resumable-state=\"counter\""))
  assert_true(tag.contains("[42]"))
}

///|
test "state_to_script_tag_with_id multiple components" {
  // Counter component state
  let counter_state = ResumableState::new()
  let _ = counter_state.register_int(5)

  // Form component state
  let form_state = ResumableState::new()
  let _ = form_state.register_string("alice")
  let _ = form_state.register_string("alice@example.com")

  let counter_tag = state_to_script_tag_with_id(counter_state, "counter")
  let form_tag = state_to_script_tag_with_id(form_state, "form")

  // Both should have unique IDs
  assert_true(counter_tag.contains("data-resumable-state=\"counter\""))
  assert_true(form_tag.contains("data-resumable-state=\"form\""))
  assert_true(counter_tag.contains("[5]"))
  assert_true(form_tag.contains("[\"alice\",\"alice@example.com\"]"))
}

///|
test "state_endpoint_tag" {
  let tag = state_endpoint_tag("user-profile", "/api/user/123", "<div>Loading...</div>")
  assert_true(tag.contains("data-state-id=\"user-profile\""))
  assert_true(tag.contains("data-state-src=\"/api/user/123\""))
  assert_true(tag.contains("<div>Loading...</div>"))
}

///|
test "portable HTML with multiple states" {
  // Simulate SSR rendering multiple components
  let counter_state = ResumableState::new()
  let _ = counter_state.register_int(10)

  let todo_state = ResumableState::new()
  let _ = todo_state.register_string("Buy milk")
  let _ = todo_state.register_bool(false)

  // Build portable HTML
  let html = "<!DOCTYPE html><html><body>" +
    "<div data-state-id=\"counter\"><span>10</span><button on:click=\"./app.js#increment\">+1</button></div>" +
    state_to_script_tag_with_id(counter_state, "counter") +
    "<div data-state-id=\"todo\"><input value=\"Buy milk\"><input type=\"checkbox\"></div>" +
    state_to_script_tag_with_id(todo_state, "todo") +
    "</body></html>"

  // Verify structure
  assert_true(html.contains("data-state-id=\"counter\""))
  assert_true(html.contains("data-state-id=\"todo\""))
  assert_true(html.contains("data-resumable-state=\"counter\""))
  assert_true(html.contains("data-resumable-state=\"todo\""))
  assert_true(html.contains("[10]"))
  assert_true(html.contains("[\"Buy milk\",false]"))
}
