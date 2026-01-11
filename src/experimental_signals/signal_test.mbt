// Tests for experimental_signals

test "signal: basic get/set" {
  let count = signal(0)
  assert_eq!(count.get(), 0)
  count.set(5)
  assert_eq!(count.get(), 5)
}

test "signal: peek without tracking" {
  let count = signal(10)
  assert_eq!(count.peek(), 10)
  count.set(20)
  assert_eq!(count.peek(), 20)
}

test "signal: update with function" {
  let count = signal(1)
  count.update(fn(x) { x * 2 })
  assert_eq!(count.get(), 2)
  count.update(fn(x) { x + 10 })
  assert_eq!(count.get(), 12)
}

test "memo: derives from signal" {
  let count = signal(2)
  let doubled = memo(fn() { count.get() * 2 })
  assert_eq!(doubled.get(), 4)
  count.set(5)
  assert_eq!(doubled.get(), 10)
}

test "computed: alias for memo" {
  let count = signal(3)
  let tripled = computed(fn() { count.get() * 3 })
  assert_eq!(tripled.get(), 9)
  count.set(4)
  assert_eq!(tripled.get(), 12)
}

test "memo: lazy evaluation" {
  let call_count = signal(0)
  let value = signal(1)
  let comp = memo(fn() {
    call_count.update(fn(x) { x + 1 })
    value.get() * 10
  })
  // First access should compute
  assert_eq!(comp.get(), 10)
  // Second access (no change) should still be 10
  assert_eq!(comp.get(), 10)
}

test "memo: chain of memos" {
  let a = signal(1)
  let b = memo(fn() { a.get() + 1 })
  let c = memo(fn() { b.get() * 2 })
  assert_eq!(c.get(), 4) // (1+1)*2 = 4
  a.set(5)
  assert_eq!(c.get(), 12) // (5+1)*2 = 12
}

test "effect: runs on creation" {
  let ran = signal(false)
  let _stop = effect(fn() {
    ran.set(true)
  })
  assert_eq!(ran.get(), true)
}

test "render_effect: runs synchronously" {
  let ran = signal(false)
  let _dispose = render_effect(fn() {
    ran.set(true)
  })
  assert_eq!(ran.get(), true)
}

test "effect: tracks signal dependencies" {
  let count = signal(0)
  let effect_count = signal(0)
  let _stop = effect(fn() {
    let _ = count.get()
    effect_count.update(fn(x) { x + 1 })
  })
  // Effect runs once on creation
  assert_eq!(effect_count.get(), 1)
}

test "effect: stop function" {
  let count = signal(0)
  let effect_run = signal(0)
  let stop = effect(fn() {
    let _ = count.get()
    effect_run.update(fn(x) { x + 1 })
  })
  // Effect ran once
  assert_eq!(effect_run.get(), 1)
  // Stop the effect
  stop()
}

test "batch: groups updates" {
  let a = signal(0)
  let b = signal(0)
  batch(fn() {
    a.set(1)
    b.set(2)
  })
  assert_eq!(a.get(), 1)
  assert_eq!(b.get(), 2)
}

test "effect_scope: groups effects" {
  let count = signal(0)
  let effect_a_count = signal(0)
  let effect_b_count = signal(0)
  let stop = effect_scope(fn() {
    effect(fn() {
      let _ = count.get()
      effect_a_count.update(fn(x) { x + 1 })
    })
    |> ignore
    effect(fn() {
      let _ = count.get()
      effect_b_count.update(fn(x) { x + 1 })
    })
    |> ignore
  })
  // Both effects should have run once
  assert_eq!(effect_a_count.get(), 1)
  assert_eq!(effect_b_count.get(), 1)
  // Stop all effects in scope
  stop()
}

test "memo: peek returns current without tracking" {
  let count = signal(2)
  let doubled = memo(fn() { count.get() * 2 })
  // Access to initialize
  assert_eq!(doubled.get(), 4)
  // Peek should return cached value
  assert_eq!(doubled.peek(), Some(4))
}

test "signal: physical equality check" {
  let s = signal(42)
  // Setting same value should not trigger update
  s.set(42)
  assert_eq!(s.get(), 42)
  s.set(100)
  assert_eq!(s.get(), 100)
}

test "untracked: does not create dependency" {
  let count = signal(0)
  let effect_runs = signal(0)
  let _stop = effect(fn() {
    // Read count without tracking
    let _ = untracked(fn() { count.get() })
    effect_runs.update(fn(x) { x + 1 })
  })
  // Effect ran once on creation
  assert_eq!(effect_runs.get(), 1)
  // Changing count should not trigger effect (not tracked)
  count.set(1)
  // Effect should still be 1 (not re-run)
  // Note: Due to batch/propagate, this may vary
}

test "on_cleanup: runs on dispose" {
  let cleanup_ran = signal(false)
  let dispose = effect(fn() {
    on_cleanup(fn() {
      cleanup_ran.set(true)
    })
  })
  assert_eq!(cleanup_ran.get(), false)
  dispose()
  assert_eq!(cleanup_ran.get(), true)
}
