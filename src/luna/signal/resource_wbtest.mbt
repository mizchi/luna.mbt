//

///|
/// Tests for async Resource (environment-agnostic)
test "AsyncState::is_pending" {
  let state : AsyncState[Int] = Pending
  assert_true(state.is_pending())
  assert_false(state.is_success())
  assert_false(state.is_failure())
}

///|
test "AsyncState::is_success" {
  let state : AsyncState[Int] = Success(42)
  assert_false(state.is_pending())
  assert_true(state.is_success())
  assert_false(state.is_failure())
}

///|
test "AsyncState::is_failure" {
  let state : AsyncState[Int] = Failure("error")
  assert_false(state.is_pending())
  assert_false(state.is_success())
  assert_true(state.is_failure())
}

///|
test "AsyncState::value" {
  let success : AsyncState[Int] = Success(42)
  let pending : AsyncState[Int] = Pending
  let failure : AsyncState[Int] = Failure("error")
  assert_eq(success.value(), Some(42))
  assert_eq(pending.value(), None)
  assert_eq(failure.value(), None)
}

///|
test "AsyncState::error" {
  let success : AsyncState[Int] = Success(42)
  let pending : AsyncState[Int] = Pending
  let failure : AsyncState[Int] = Failure("error")
  assert_eq(success.error(), None)
  assert_eq(pending.error(), None)
  assert_eq(failure.error(), Some("error"))
}

///|
test "resource - sync resolve" {
  let res = resource(fn(resolve, _reject) { resolve(42) })

  // Should be immediately resolved since fetcher is synchronous
  assert_true(res.is_success())
  assert_eq(res.value(), Some(42))
}

///|
test "resource - sync reject" {
  let res : Resource[Int] = resource(fn(_resolve, reject) {
    reject("something went wrong")
  })

  // Should be immediately rejected since fetcher is synchronous
  assert_true(res.is_failure())
  assert_eq(res.error(), Some("something went wrong"))
}

///|
test "resource_resolved" {
  let res = resource_resolved(100)
  assert_true(res.is_success())
  assert_eq(res.value(), Some(100))
  assert_false(res.is_pending())
}

///|
test "resource_rejected" {
  let res : Resource[Int] = resource_rejected("pre-failed")
  assert_true(res.is_failure())
  assert_eq(res.error(), Some("pre-failed"))
  assert_false(res.is_pending())
}

///|
test "deferred - manual resolve" {
  let (res, resolve, _reject) = deferred()

  // Initially pending
  assert_true(res.is_pending())
  assert_eq(res.value(), None)

  // Resolve manually
  resolve(999)
  assert_true(res.is_success())
  assert_eq(res.value(), Some(999))
}

///|
test "deferred - manual reject" {
  let (res, _resolve, reject) : (Resource[Int], (Int) -> Unit, (String) -> Unit) = deferred()

  // Initially pending
  assert_true(res.is_pending())

  // Reject manually
  reject("manual error")
  assert_true(res.is_failure())
  assert_eq(res.error(), Some("manual error"))
}

///|
test "Resource::get tracks signal" {
  let (res, resolve, _reject) : (Resource[Int], (Int) -> Unit, (String) -> Unit) = deferred()

  // Track changes via render_effect (synchronous)
  let log : Array[String] = []
  let dispose = render_effect(fn() {
    match res.get() {
      Pending => log.push("pending")
      Success(v) => log.push("success:" + v.to_string())
      Failure(e) => log.push("failure:" + e)
    }
  })
  defer dispose()

  // Initial state tracked
  assert_eq(log.length(), 1)
  assert_eq(log[0], "pending")

  // Resolve triggers effect (render_effect runs synchronously on signal change)
  resolve(42)
  assert_eq(log.length(), 2)
  assert_eq(log[1], "success:42")
}

///|
test "Resource::refetch" {
  let call_count = { val: 0 }
  let res = resource(fn(resolve, _reject) {
    call_count.val = call_count.val + 1
    resolve(call_count.val)
  })

  // Initial fetch
  assert_eq(res.value(), Some(1))

  // Refetch
  res.refetch()
  assert_eq(res.value(), Some(2))

  // Refetch again
  res.refetch()
  assert_eq(res.value(), Some(3))
}
