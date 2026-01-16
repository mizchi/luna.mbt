// Tests for Resumable State

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
test "state_to_script_tag with id" {
  let state = ResumableState::new()
  let _ = state.register_int(42)
  let tag = state_to_script_tag(state, id="counter")
  assert_true(tag.contains("data-resumable-state=\"counter\""))
  assert_true(tag.contains("[42]"))
}

///|
test "state_to_script_tag with id multiple components" {
  // Counter component state
  let counter_state = ResumableState::new()
  let _ = counter_state.register_int(5)

  // Form component state
  let form_state = ResumableState::new()
  let _ = form_state.register_string("alice")
  let _ = form_state.register_string("alice@example.com")
  let counter_tag = state_to_script_tag(counter_state, id="counter")
  let form_tag = state_to_script_tag(form_state, id="form")

  // Both should have unique IDs
  assert_true(counter_tag.contains("data-resumable-state=\"counter\""))
  assert_true(form_tag.contains("data-resumable-state=\"form\""))
  assert_true(counter_tag.contains("[5]"))
  assert_true(form_tag.contains("[\"alice\",\"alice@example.com\"]"))
}

///|
test "state_endpoint_tag" {
  let tag = state_endpoint_tag(
    "user-profile", "/api/user/123", "<div>Loading...</div>",
  )
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
    state_to_script_tag(counter_state, id="counter") +
    "<div data-state-id=\"todo\"><input value=\"Buy milk\"><input type=\"checkbox\"></div>" +
    state_to_script_tag(todo_state, id="todo") +
    "</body></html>"

  // Verify structure
  assert_true(html.contains("data-state-id=\"counter\""))
  assert_true(html.contains("data-state-id=\"todo\""))
  assert_true(html.contains("data-resumable-state=\"counter\""))
  assert_true(html.contains("data-resumable-state=\"todo\""))
  assert_true(html.contains("[10]"))
  assert_true(html.contains("[\"Buy milk\",false]"))
}

// =============================================================================
// JSON Parsing Edge Case Tests (for coverage)
// =============================================================================

///|
test "ResumableState from_json nested array" {
  match ResumableState::from_json("[[1,2],[3,4]]") {
    Some(state) => {
      assert_eq(state.values.length(), 2)
      match state.get(0) {
        Some(Arr(arr)) => {
          assert_eq(arr.length(), 2)
          match arr[0] {
            Int(n) => assert_eq(n, 1)
            _ => assert_true(false)
          }
        }
        _ => assert_true(false)
      }
    }
    None => assert_true(false)
  }
}

///|
test "ResumableState from_json string with quotes" {
  match ResumableState::from_json("[\"hello \\\"world\\\"\"]") {
    Some(state) => assert_eq(state.get_string(0), Some("hello \"world\""))
    None => assert_true(false)
  }
}

///|
test "ResumableState from_json string with carriage return" {
  match ResumableState::from_json("[\"line1\\rline2\"]") {
    Some(state) => assert_eq(state.get_string(0), Some("line1\rline2"))
    None => assert_true(false)
  }
}

///|
test "ResumableState from_json string with tab" {
  match ResumableState::from_json("[\"col1\\tcol2\"]") {
    Some(state) => assert_eq(state.get_string(0), Some("col1\tcol2"))
    None => assert_true(false)
  }
}

///|
test "ResumableState to_json string with special chars" {
  let state = ResumableState::new()
  let _ = state.register_string("line1\rline2")
  assert_eq(state.to_json(), "[\"line1\\rline2\"]")
}

///|
test "ResumableState to_json string with quotes" {
  let state = ResumableState::new()
  let _ = state.register_string("say \"hello\"")
  assert_eq(state.to_json(), "[\"say \\\"hello\\\"\"]")
}

///|
test "ResumableState to_json string with tab" {
  let state = ResumableState::new()
  let _ = state.register_string("col1\tcol2")
  assert_eq(state.to_json(), "[\"col1\\tcol2\"]")
}

///|
test "ResumableState get_int returns None for wrong type" {
  match ResumableState::from_json("[\"not an int\"]") {
    Some(state) => assert_eq(state.get_int(0), None)
    None => assert_true(false)
  }
}

///|
test "ResumableState get_string returns None for wrong type" {
  match ResumableState::from_json("[42]") {
    Some(state) => assert_eq(state.get_string(0), None)
    None => assert_true(false)
  }
}

///|
test "ResumableState get_bool returns None for wrong type" {
  match ResumableState::from_json("[\"not a bool\"]") {
    Some(state) => assert_eq(state.get_bool(0), None)
    None => assert_true(false)
  }
}

///|
test "ResumableState get_float returns None for wrong type" {
  match ResumableState::from_json("[\"not a float\"]") {
    Some(state) => assert_eq(state.get_float(0), None)
    None => assert_true(false)
  }
}

// =============================================================================
// HTML Escape/Unescape Tests (for coverage)
// =============================================================================

///|
test "state_to_script_tag escapes special HTML chars" {
  let state = ResumableState::new()
  let _ = state.register_string("<script>alert('xss')</script>")
  let tag = state_to_script_tag(state)
  // Should escape < and > characters
  assert_true(tag.contains("\\u003c"))
  assert_true(tag.contains("\\u003e"))
}

///|
test "extract_state_from_html unescapes special chars" {
  // HTML with escaped JSON containing < > &
  let html = "<div>content</div><script type=\"application/json\" data-resumable-state>[\"\\u003cscript\\u003e\"]</script>"
  match extract_state_from_html(html) {
    Some(json) => assert_eq(json, "[\"<script>\"]")
    None => assert_true(false)
  }
}

///|
test "extract_state_from_html unescape ampersand" {
  let html = "<div>content</div><script type=\"application/json\" data-resumable-state>[\"foo\\u0026bar\"]</script>"
  match extract_state_from_html(html) {
    Some(json) => assert_eq(json, "[\"foo&bar\"]")
    None => assert_true(false)
  }
}

///|
test "state embedding roundtrip with special chars" {
  let state = ResumableState::new()
  let _ = state.register_string("<div>&</div>")
  let tag = state_to_script_tag(state)

  // Simulate extraction
  let html = "<body>" + tag + "</body>"
  match parse_state_from_html(html) {
    Some(restored) => assert_eq(restored.get_string(0), Some("<div>&</div>"))
    None => assert_true(false)
  }
}

// =============================================================================
// JSON Parser Edge Cases (for coverage)
// =============================================================================

///|
test "ResumableState from_json invalid returns None" {
  // Invalid JSON - not an array
  assert_true(ResumableState::from_json("{}") is None)

  // Invalid JSON - unclosed array
  assert_true(ResumableState::from_json("[1,2,") is None)

  // Invalid JSON - empty string
  assert_true(ResumableState::from_json("") is None)
}

///|
test "ResumableState from_json with whitespace" {
  match ResumableState::from_json("[ 1 , 2 , 3 ]") {
    Some(state) => {
      assert_eq(state.values.length(), 3)
      assert_eq(state.get_int(0), Some(1))
      assert_eq(state.get_int(1), Some(2))
      assert_eq(state.get_int(2), Some(3))
    }
    None => assert_true(false)
  }
}

///|
test "ResumableState from_json with tabs and newlines" {
  match ResumableState::from_json("[\n\t1,\n\t2\n]") {
    Some(state) => {
      assert_eq(state.values.length(), 2)
      assert_eq(state.get_int(0), Some(1))
      assert_eq(state.get_int(1), Some(2))
    }
    None => assert_true(false)
  }
}

///|
test "ResumableState from_json invalid character returns None" {
  // Invalid JSON - unexpected character
  assert_true(ResumableState::from_json("[!]") is None)
}

///|
test "ResumableState to_json string with backslash" {
  let state = ResumableState::new()
  let _ = state.register_string("path\\to\\file")
  assert_eq(state.to_json(), "[\"path\\\\to\\\\file\"]")
}

///|
test "ResumableState from_json string with backslash" {
  match ResumableState::from_json("[\"path\\\\to\\\\file\"]") {
    Some(state) => assert_eq(state.get_string(0), Some("path\\to\\file"))
    None => assert_true(false)
  }
}

// =============================================================================
// JSON Module Direct API Tests (for coverage of json.mbt)
// =============================================================================

///|
test "state_value_to_json covers all value types" {
  // Null
  assert_eq(state_value_to_json(sv_null()), "null")

  // Bool
  assert_eq(state_value_to_json(sv_bool(true)), "true")
  assert_eq(state_value_to_json(sv_bool(false)), "false")

  // Int
  assert_eq(state_value_to_json(sv_int(42)), "42")
  assert_eq(state_value_to_json(sv_int(-100)), "-100")

  // Number (float with decimal point)
  let float_json = state_value_to_json(sv_number(3.14))
  assert_true(float_json.contains("3.14"))

  // Number (integer-like double without decimal)
  let int_double_json = state_value_to_json(sv_number(5.0))
  assert_true(int_double_json.contains("5.0"))

  // String
  assert_eq(state_value_to_json(sv_str("hello")), "\"hello\"")

  // Array
  assert_eq(state_value_to_json(sv_arr([sv_int(1), sv_int(2)])), "[1,2]")
}

///|
test "state_values_to_json" {
  let values : Array[StateValue] = [sv_int(1), sv_str("two"), sv_bool(true)]
  assert_eq(state_values_to_json(values), "[1,\"two\",true]")

  // Empty array
  let empty : Array[StateValue] = []
  assert_eq(state_values_to_json(empty), "[]")
}

///|
test "escape_json_string direct call" {
  // Normal string
  assert_eq(escape_json_string("hello"), "hello")

  // String with special chars
  assert_eq(escape_json_string("a\"b"), "a\\\"b")
  assert_eq(escape_json_string("a\\b"), "a\\\\b")
  assert_eq(escape_json_string("a\nb"), "a\\nb")
  assert_eq(escape_json_string("a\rb"), "a\\rb")
  assert_eq(escape_json_string("a\tb"), "a\\tb")
}

///|
test "escape_json_string control characters" {
  // Control character (ASCII < 32, not newline/tab/cr)
  // Form feed (ASCII 12 = 0x0C)
  let form_feed = (12).unsafe_to_char().to_string()
  let escaped = escape_json_string(form_feed)
  assert_eq(escaped, "\\u000c")

  // Bell (ASCII 7 = 0x07)
  let bell = (7).unsafe_to_char().to_string()
  let escaped_bell = escape_json_string(bell)
  assert_eq(escaped_bell, "\\u0007")
}

///|
test "state_value_from_json direct call" {
  // Valid JSON
  match state_value_from_json("42") {
    Some(v) => assert_eq(v.as_int(), Some(42))
    _ => assert_true(false)
  }
  match state_value_from_json("\"hello\"") {
    Some(v) => assert_eq(v.as_string(), Some("hello"))
    _ => assert_true(false)
  }
  match state_value_from_json("true") {
    Some(v) => assert_eq(v.as_bool(), Some(true))
    _ => assert_true(false)
  }
  match state_value_from_json("null") {
    Some(v) => assert_true(v.is_null())
    _ => assert_true(false)
  }

  // Invalid JSON
  assert_true(state_value_from_json("invalid") is None)
}

///|
test "state_values_from_json direct call" {
  match state_values_from_json("[1,2,3]") {
    Some(arr) => {
      assert_eq(arr.length(), 3)
      assert_eq(arr[0].as_int(), Some(1))
      assert_eq(arr[1].as_int(), Some(2))
      assert_eq(arr[2].as_int(), Some(3))
    }
    _ => assert_true(false)
  }

  // Not an array
  assert_true(state_values_from_json("42") is None)

  // Invalid JSON
  assert_true(state_values_from_json("invalid") is None)
}

///|
test "state_value_to_json_value conversion" {
  // Null
  let null_json = state_value_to_json_value(sv_null())
  assert_true(null_json is Null)

  // Bool
  let true_json = state_value_to_json_value(sv_bool(true))
  assert_true(true_json is True)
  let false_json = state_value_to_json_value(sv_bool(false))
  assert_true(false_json is False)

  // Int
  let int_json = state_value_to_json_value(sv_int(42))
  assert_true(int_json is Number(_))

  // Number
  let num_json = state_value_to_json_value(sv_number(3.14))
  assert_true(num_json is Number(_))

  // String
  let str_json = state_value_to_json_value(sv_str("hello"))
  assert_true(str_json is String(_))

  // Array
  let arr_json = state_value_to_json_value(sv_arr([sv_int(1)]))
  assert_true(arr_json is Array(_))
}

///|
test "json_value_to_state_value with float" {
  // Float (non-integer)
  match state_value_from_json("3.14") {
    Some(v) =>
      match v.as_number() {
        Some(f) => assert_true(f > 3.0 && f < 4.0)
        None => assert_true(false)
      }
    _ => assert_true(false)
  }
}

///|
test "json_value_to_state_value rejects object" {
  // Object is not supported
  assert_true(state_value_from_json("{}") is None)
  assert_true(state_value_from_json("{\"a\":1}") is None)
}

// =============================================================================
// StateValue Module Tests (for coverage of state_value.mbt)
// =============================================================================

///|
test "StateValue::is_null" {
  assert_true(sv_null().is_null())
  assert_true(not(sv_bool(true).is_null()))
  assert_true(not(sv_int(0).is_null()))
  assert_true(not(sv_number(0.0).is_null()))
  assert_true(not(sv_str("").is_null()))
  assert_true(not(sv_arr([]).is_null()))
}

///|
test "StateValue::as_bool" {
  assert_eq(sv_bool(true).as_bool(), Some(true))
  assert_eq(sv_bool(false).as_bool(), Some(false))
  assert_eq(sv_int(1).as_bool(), None)
  assert_eq(sv_null().as_bool(), None)
}

///|
test "StateValue::as_int" {
  assert_eq(sv_int(42).as_int(), Some(42))
  assert_eq(sv_int(-100).as_int(), Some(-100))
  assert_eq(sv_bool(true).as_int(), None)
  assert_eq(sv_null().as_int(), None)
}

///|
test "StateValue::as_number" {
  match sv_number(3.14).as_number() {
    Some(f) => assert_true(f > 3.0 && f < 4.0)
    None => assert_true(false)
  }
  assert_eq(sv_int(1).as_number(), None)
  assert_eq(sv_null().as_number(), None)
}

///|
test "StateValue::as_string" {
  assert_eq(sv_str("hello").as_string(), Some("hello"))
  assert_eq(sv_str("").as_string(), Some(""))
  assert_eq(sv_int(1).as_string(), None)
  assert_eq(sv_null().as_string(), None)
}

///|
test "StateValue::as_array" {
  match sv_arr([sv_int(1), sv_int(2)]).as_array() {
    Some(arr) => assert_eq(arr.length(), 2)
    None => assert_true(false)
  }
  match sv_arr([]).as_array() {
    Some(arr) => assert_eq(arr.length(), 0)
    None => assert_true(false)
  }
  assert_eq(sv_int(1).as_array(), None)
  assert_eq(sv_null().as_array(), None)
}

///|
test "sv_xxx factory functions" {
  assert_true(sv_null().is_null())
  assert_eq(sv_bool(true).as_bool(), Some(true))
  assert_eq(sv_bool(false).as_bool(), Some(false))
  assert_eq(sv_int(42).as_int(), Some(42))
  assert_eq(sv_str("hello").as_string(), Some("hello"))
  match sv_number(3.14).as_number() {
    Some(f) => assert_true(f > 3.0 && f < 4.0)
    _ => assert_true(false)
  }
  match sv_arr([sv_int(1), sv_int(2)]).as_array() {
    Some(arr) => assert_eq(arr.length(), 2)
    _ => assert_true(false)
  }
}
