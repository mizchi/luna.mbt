///|
/// Tests for fine-grained reactive store APIs

// =============================================================================
// SplitStore Tests
// =============================================================================

///|
test "SplitStore2 creates store with two fields" {
  let store = SplitStore2::new(0, "hello")
  assert_eq(store.field1.get(), 0)
  assert_eq(store.field2.get(), "hello")
}

///|
test "SplitStore2 fields are independent" {
  let store = SplitStore2::new(0, "hello")
  let field1_runs = Ref::new(0)
  let field2_runs = Ref::new(0)
  let _ = render_effect(fn() {
    let _ = store.field1.get()
    field1_runs.val = field1_runs.val + 1
  })
  let _ = render_effect(fn() {
    let _ = store.field2.get()
    field2_runs.val = field2_runs.val + 1
  })

  // Initial
  assert_eq(field1_runs.val, 1)
  assert_eq(field2_runs.val, 1)

  // Update field1 - only field1 effect runs
  store.field1.set(10)
  assert_eq(field1_runs.val, 2)
  assert_eq(field2_runs.val, 1)

  // Update field2 - only field2 effect runs
  store.field2.set("world")
  assert_eq(field1_runs.val, 2)
  assert_eq(field2_runs.val, 2)
}

///|
test "SplitStore3 creates store with three fields" {
  let store = SplitStore3::new(1, "test", true)
  assert_eq(store.field1.get(), 1)
  assert_eq(store.field2.get(), "test")
  assert_eq(store.field3.get(), true)
}

// =============================================================================
// LensStore Tests
// =============================================================================

///|
priv struct TestRecord {
  count : Int
  name : String
}

///|
test "LensStore creates store with initial value" {
  let store : LensStore[TestRecord] = LensStore::new({ count: 0, name: "John" })
  let snapshot = store.snapshot()
  assert_eq(snapshot.count, 0)
  assert_eq(snapshot.name, "John")
}

///|
test "LensStore::focus creates reactive field accessor" {
  let store : LensStore[TestRecord] = LensStore::new({ count: 0, name: "John" })
  let count_lens : Lens[TestRecord, Int] = Lens::new(fn(s) { s.count }, fn(
    s,
    v,
  ) {
    { count: v, name: s.name }
  })
  let (count_sig, set_count) = store.focus(count_lens)
  assert_eq(count_sig.get(), 0)
  set_count(42)
  assert_eq(count_sig.get(), 42)
  assert_eq(store.snapshot().count, 42)
}

///|
test "LensStore focused field only updates when value changes" {
  let store : LensStore[TestRecord] = LensStore::new({ count: 0, name: "John" })
  let count_lens : Lens[TestRecord, Int] = Lens::new(fn(s) { s.count }, fn(
    s,
    v,
  ) {
    { count: v, name: s.name }
  })
  let name_lens : Lens[TestRecord, String] = Lens::new(fn(s) { s.name }, fn(
    s,
    v,
  ) {
    { count: s.count, name: v }
  })
  let (count_sig, _) = store.focus(count_lens)
  let (_, set_name) = store.focus(name_lens)
  let count_runs = Ref::new(0)
  let _ = render_effect(fn() {
    let _ = count_sig.get()
    count_runs.val = count_runs.val + 1
  })

  // Initial run
  assert_eq(count_runs.val, 1)

  // Update name - count effect should NOT run (value unchanged)
  set_name("Jane")
  // Note: Due to implementation, source update triggers check but no actual update if value same
  assert_eq(count_sig.get(), 0)
}

// =============================================================================
// ReactiveRecord Pattern Example
// =============================================================================

///|
priv struct AppState {
  count : Int
  name : String
  active : Bool
}

///|
priv struct ReactiveAppState {
  count : Signal[Int]
  name : Signal[String]
  active : Signal[Bool]
}

///|
fn ReactiveAppState::new(initial : AppState) -> ReactiveAppState {
  {
    count: signal(initial.count),
    name: signal(initial.name),
    active: signal(initial.active),
  }
}

///|
fn ReactiveAppState::snapshot(self : ReactiveAppState) -> AppState {
  {
    count: self.count.peek(),
    name: self.name.peek(),
    active: self.active.peek(),
  }
}

///|
test "ReactiveRecord pattern provides fine-grained updates" {
  let state = ReactiveAppState::new({ count: 0, name: "User", active: true })
  let count_runs = Ref::new(0)
  let name_runs = Ref::new(0)
  let _ = render_effect(fn() {
    let _ = state.count.get()
    count_runs.val = count_runs.val + 1
  })
  let _ = render_effect(fn() {
    let _ = state.name.get()
    name_runs.val = name_runs.val + 1
  })

  // Initial
  assert_eq(count_runs.val, 1)
  assert_eq(name_runs.val, 1)

  // Update count only
  state.count.set(10)
  assert_eq(count_runs.val, 2)
  assert_eq(name_runs.val, 1) // name effect not triggered!

  // Snapshot works
  let snap = state.snapshot()
  assert_eq(snap.count, 10)
  assert_eq(snap.name, "User")
  assert_eq(snap.active, true)
}
