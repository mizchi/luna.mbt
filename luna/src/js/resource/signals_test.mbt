// Luna-specific signal tests (Resource and VNode)
// Core signal tests are in mizchi/signals

// =============================================================================
// VNode Helper Tests
// =============================================================================

///|
test "text_sig creates dynamic text from signal" {
  let sig = @signals.signal(42)
  let node : @luna.Node[Unit, String] = @luna.text_of(sig)
  guard node is DynamicText(getter) else { fail("expected DynamicText") }
  assert_eq(getter(), "42")
  sig.set(100)
  assert_eq(getter(), "100")
}

// =============================================================================
// Resource Tests
// =============================================================================

///|
test "Resource::peek returns state without tracking" {
  let res = resource_resolved(42)
  let state = res.peek()
  assert_true(state.is_success())
  assert_eq(state.value(), Some(42))
}

///|
test "resource_resolved creates pre-resolved resource" {
  let res = resource_resolved("hello")
  assert_true(res.is_success())
  assert_eq(res.value(), Some("hello"))
  assert_false(res.is_pending())
  assert_false(res.is_failure())
}

///|
test "resource_rejected creates pre-rejected resource" {
  let res : Resource[Int] = resource_rejected("error")
  assert_true(res.is_failure())
  assert_eq(res.error(), Some("error"))
  assert_false(res.is_pending())
  assert_false(res.is_success())
}

///|
test "deferred creates manual resource with resolve/reject" {
  let (res, resolve, _reject) : (Resource[Int], (Int) -> Unit, (String) -> Unit) = deferred()
  assert_true(res.is_pending())
  resolve(100)
  assert_true(res.is_success())
  assert_eq(res.value(), Some(100))
}

///|
test "deferred reject works" {
  let (res, _resolve, reject) : (Resource[Int], (Int) -> Unit, (String) -> Unit) = deferred()
  assert_true(res.is_pending())
  reject("failed")
  assert_true(res.is_failure())
  assert_eq(res.error(), Some("failed"))
}

///|
test "resource_resolved refetch is no-op" {
  let res = resource_resolved(42)
  // refetch should be no-op for pre-resolved
  res.refetch()
  // Should still be success
  assert_true(res.is_success())
  assert_eq(res.value(), Some(42))
}

///|
test "resource_rejected refetch is no-op" {
  let res : Resource[Int] = resource_rejected("error")
  // refetch should be no-op for pre-rejected
  res.refetch()
  // Should still be failure
  assert_true(res.is_failure())
}

///|
test "deferred refetch resets to pending" {
  let (res, resolve, _reject) : (Resource[Int], (Int) -> Unit, (String) -> Unit) = deferred()
  assert_true(res.is_pending())
  resolve(100)
  assert_true(res.is_success())

  // refetch should reset to pending
  res.refetch()
  assert_true(res.is_pending())
}
