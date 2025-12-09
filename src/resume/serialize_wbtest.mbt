///| Whitebox tests for Signal Serialization

///|
test "register_signal int" {
  let state = ResumableState::new()
  let signal = @ui.signal(42)
  let id = register_signal(state, signal)
  assert_eq(id, 0)
  assert_eq(state.get_int(id), Some(42))
}

///|
test "register_signal string" {
  let state = ResumableState::new()
  let signal = @ui.signal("hello")
  let id = register_signal(state, signal)
  assert_eq(state.get_string(id), Some("hello"))
}

///|
test "register_signal bool" {
  let state = ResumableState::new()
  let signal = @ui.signal(true)
  let id = register_signal(state, signal)
  assert_eq(state.get_bool(id), Some(true))
}

///|
test "restore_signal int" {
  let state = ResumableState::new()
  let _ = state.register_int(100)
  let signal = @ui.signal(0)
  let success = restore_signal(state, signal, 0)
  assert_true(success)
  assert_eq(signal.get(), 100)
}

///|
test "restore_signal string" {
  let state = ResumableState::new()
  let _ = state.register_string("restored")
  let signal = @ui.signal("")
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
  let signal : @ui.Signal[Int] = resume_signal(state, 0, 0)
  assert_eq(signal.get(), 100)
}

///|
test "resume_signal with missing value" {
  let state = ResumableState::new()
  let signal : @ui.Signal[Int] = resume_signal(state, 0, 42)
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
      let client_count : @ui.Signal[Int] = resume_signal(
        client_state,
        count_id,
        0,
      )
      let client_name : @ui.Signal[String] = resume_signal(
        client_state,
        name_id,
        "",
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
