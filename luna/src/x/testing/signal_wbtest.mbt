// Luna Testing - Signal Tests

///|
test "track_signal records initial value" {
  let sig = @resource.signal(0)
  let tracker = track_signal(sig)
  assert_eq(tracker_values(tracker), [0])
}

///|
test "track_signal records value changes" {
  let sig = @resource.signal(0)
  let tracker = track_signal(sig)
  sig.set(1)
  sig.set(2)
  sig.set(3)
  assert_eq(tracker_values(tracker), [0, 1, 2, 3])
}

///|
test "tracker_last returns last value" {
  let sig = @resource.signal(0)
  let tracker = track_signal(sig)
  sig.set(42)
  assert_eq(tracker_last(tracker), Some(42))
}

///|
test "tracker_count returns change count" {
  let sig = @resource.signal(0)
  let tracker = track_signal(sig)
  sig.set(1)
  sig.set(2)
  assert_eq(tracker_count(tracker), 3) // initial + 2 changes
}

///|
test "assert_signal_value succeeds for correct value" {
  let sig = @resource.signal(42)
  assert_signal_value(sig, 42)
}

///|
test "assert_tracked_values succeeds for correct values" {
  let sig = @resource.signal(0)
  let tracker = track_signal(sig)
  sig.set(1)
  sig.set(2)
  assert_tracked_values(tracker, [0, 1, 2])
}

///|
test "test_batch executes in order" {
  let result : Ref[String] = Ref::new("")
  let verified : Ref[Bool] = Ref::new(false)
  test_batch(
    fn() { result.val = "setup" },
    fn() { result.val = result.val + "-update" },
    fn() { verified.val = result.val == "setup-update" },
  )
  assert_true(verified.val)
}
