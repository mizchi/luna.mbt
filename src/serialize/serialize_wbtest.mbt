// Whitebox tests for Signal Serialization
//

///|
test "register_signal int" {
  let state = ResumableState::new()
  let signal = @signal.signal(42)
  let id = register_signal(state, signal)
  assert_eq(id, 0)
  assert_eq(state.get_int(id), Some(42))
}

///|
test "register_signal string" {
  let state = ResumableState::new()
  let signal = @signal.signal("hello")
  let id = register_signal(state, signal)
  assert_eq(state.get_string(id), Some("hello"))
}

///|
test "register_signal bool" {
  let state = ResumableState::new()
  let signal = @signal.signal(true)
  let id = register_signal(state, signal)
  assert_eq(state.get_bool(id), Some(true))
}

///|
test "restore_signal int" {
  let state = ResumableState::new()
  let _ = state.register_int(100)
  let signal = @signal.signal(0)
  let success = restore_signal(state, signal, 0)
  assert_true(success)
  assert_eq(signal.get(), 100)
}

///|
test "restore_signal string" {
  let state = ResumableState::new()
  let _ = state.register_string("restored")
  let signal = @signal.signal("")
  let success = restore_signal(state, signal, 0)
  assert_true(success)
  assert_eq(signal.get(), "restored")
}

///|
test "create_resumable_signal int" {
  let state = ResumableState::new()
  let (signal, id) = create_resumable_signal(state, 42)
  assert_eq(id, 0)
  assert_eq(signal.get(), 42)
  assert_eq(state.get_int(id), Some(42))
}

///|
test "create_resumable_signal string" {
  let state = ResumableState::new()
  let (signal, id) = create_resumable_signal(state, "hello")
  assert_eq(id, 0)
  assert_eq(signal.get(), "hello")
  assert_eq(state.get_string(id), Some("hello"))
}

///|
test "resume_signal with existing value" {
  let state = ResumableState::new()
  let _ = state.register_int(100)
  let signal : @signal.Signal[Int] = resume_signal(state, 0, 0)
  assert_eq(signal.get(), 100)
}

///|
test "resume_signal with missing value" {
  let state = ResumableState::new()
  let signal : @signal.Signal[Int] = resume_signal(state, 0, 42)
  assert_eq(signal.get(), 42)
}

///|
test "full resumable signal flow" {
  // === SSR Phase ===
  let ssr_state = ResumableState::new()
  let (count, _) = create_resumable_signal(ssr_state, 10)
  let (name, _) = create_resumable_signal(ssr_state, "Alice")
  // Simulate update during SSR
  count.set(15)
  // Re-register to capture updated value
  let ssr_state2 = ResumableState::new()
  let count_id = register_signal(ssr_state2, count)
  let name_id = register_signal(ssr_state2, name)
  // Generate HTML with embedded state
  let script = state_to_script_tag(ssr_state2)
  let html = "<div>Content</div>" + script
  // === Client Phase ===
  match parse_state_from_html(html) {
    Some(client_state) => {
      let client_count : @signal.Signal[Int] = resume_signal(
        client_state, count_id, 0,
      )
      let client_name : @signal.Signal[String] = resume_signal(
        client_state, name_id, "",
      )
      assert_eq(client_count.get(), 15)
      assert_eq(client_name.get(), "Alice")
      // Signals are reactive
      client_count.set(20)
      assert_eq(client_count.get(), 20)
    }
    None => assert_true(false)
  }
}

// =============================================================================
// Serializable from_state_value Edge Cases (for coverage)
// =============================================================================

///|
test "Serializable Int from wrong type returns None" {
  let value = sv_str("not an int")
  let result : Int? = Serializable::from_state_value(value)
  assert_eq(result, None)
}

///|
test "Serializable String from wrong type returns None" {
  let value = sv_int(42)
  let result : String? = Serializable::from_state_value(value)
  assert_eq(result, None)
}

///|
test "Serializable Bool from wrong type returns None" {
  let value = sv_int(42)
  let result : Bool? = Serializable::from_state_value(value)
  assert_eq(result, None)
}

///|
test "Serializable Double from wrong type returns None" {
  let value = sv_int(42)
  let result : Double? = Serializable::from_state_value(value)
  assert_eq(result, None)
}

///|
test "restore_signal returns false for wrong type" {
  let state = ResumableState::new()
  let _ = state.register_string("not an int")
  let sig = @signal.signal(0)
  let result = restore_signal(state, sig, 0)
  assert_eq(result, false)
  // Signal should still have initial value
  assert_eq(sig.peek(), 0)
}

///|
test "restore_signal returns false for missing id" {
  let state = ResumableState::new()
  let sig = @signal.signal(42)
  let result = restore_signal(state, sig, 999)
  assert_eq(result, false)
  // Signal should still have initial value
  assert_eq(sig.peek(), 42)
}

///|
test "resume_signal uses initial for wrong type" {
  let state = ResumableState::new()
  let _ = state.register_string("not an int")
  let sig : @signal.Signal[Int] = resume_signal(state, 0, 42)
  // Should use initial value since type doesn't match
  assert_eq(sig.peek(), 42)
}

// =============================================================================
// Serializable to_state_value Tests (for coverage)
// =============================================================================

///|
test "Serializable Int to_state_value" {
  let value : Int = 42
  let state_val = Serializable::to_state_value(value)
  assert_eq(state_val.as_int(), Some(42))
}

///|
test "Serializable String to_state_value" {
  let value : String = "hello"
  let state_val = Serializable::to_state_value(value)
  assert_eq(state_val.as_string(), Some("hello"))
}

///|
test "Serializable Bool to_state_value" {
  let value : Bool = true
  let state_val = Serializable::to_state_value(value)
  assert_eq(state_val.as_bool(), Some(true))
}

///|
test "Serializable Double to_state_value" {
  let value : Double = 3.14
  let state_val = Serializable::to_state_value(value)
  match state_val.as_number() {
    Some(f) => assert_true(f > 3.13 && f < 3.15)
    None => assert_true(false)
  }
}

///|
test "Serializable Int roundtrip" {
  let original : Int = 99
  let state_val = Serializable::to_state_value(original)
  let restored : Int? = Serializable::from_state_value(state_val)
  assert_eq(restored, Some(99))
}

///|
test "Serializable String roundtrip" {
  let original : String = "test string"
  let state_val = Serializable::to_state_value(original)
  let restored : String? = Serializable::from_state_value(state_val)
  assert_eq(restored, Some("test string"))
}

///|
test "Serializable Bool roundtrip" {
  let original : Bool = false
  let state_val = Serializable::to_state_value(original)
  let restored : Bool? = Serializable::from_state_value(state_val)
  assert_eq(restored, Some(false))
}

///|
test "Serializable Double roundtrip" {
  let original : Double = 2.718
  let state_val = Serializable::to_state_value(original)
  let restored : Double? = Serializable::from_state_value(state_val)
  match restored {
    Some(f) => assert_true(f > 2.7 && f < 2.8)
    None => assert_true(false)
  }
}
