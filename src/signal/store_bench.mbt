///|
/// Benchmarks for fine-grained reactive store approaches

// =============================================================================
// Test data structures
// =============================================================================

///|
priv struct BenchRecord {
  count : Int
  name : String
}

// =============================================================================
// Approach 1: Split Signals (Fine-grained) - Recommended
// =============================================================================

///|
test "split: 2 fields - read (1000 ops)" (b : @bench.T) {
  let store = SplitStore2::new(0, "test")
  b.bench(fn() {
    for i = 0; i < 1000; i = i + 1 {
      let _ = store.field1.get()
      let _ = store.field2.get()

    }
  })
}

///|
test "split: 2 fields - update field1 only (100 ops)" (b : @bench.T) {
  let store = SplitStore2::new(0, "test")
  b.bench(fn() {
    for i = 0; i < 100; i = i + 1 {
      store.field1.set(i)
    }
  })
}

///|
test "split: 2 fields - effect on field1, update field2 (100 ops)" (
  b : @bench.T,
) {
  let store = SplitStore2::new(0, "test")
  let effect_runs = Ref::new(0)
  let _ = effect(fn() {
    let _ = store.field1.get()
    effect_runs.val = effect_runs.val + 1
  })
  b.bench(fn() {
    for i = 0; i < 100; i = i + 1 {
      // Update field2 - should NOT trigger effect on field1
      store.field2.set("updated")
    }
  })
}

///|
test "split: 10 fields - update 1 field (100 ops)" (b : @bench.T) {
  // Simulate 10-field store with individual signals
  let f1 = signal(1)
  let f2 = signal(2)
  let f3 = signal(3)
  let f4 = signal(4)
  let f5 = signal(5)
  let f6 = signal(6)
  let f7 = signal(7)
  let f8 = signal(8)
  let f9 = signal(9)
  let f10 = signal(10)

  // Effects on all fields
  let _ = effect(fn() {
    let _ = f1.get()

  })
  let _ = effect(fn() {
    let _ = f2.get()

  })
  let _ = effect(fn() {
    let _ = f3.get()

  })
  let _ = effect(fn() {
    let _ = f4.get()

  })
  let _ = effect(fn() {
    let _ = f5.get()

  })
  let _ = effect(fn() {
    let _ = f6.get()

  })
  let _ = effect(fn() {
    let _ = f7.get()

  })
  let _ = effect(fn() {
    let _ = f8.get()

  })
  let _ = effect(fn() {
    let _ = f9.get()

  })
  let _ = effect(fn() {
    let _ = f10.get()

  })
  b.bench(fn() {
    for i = 0; i < 100; i = i + 1 {
      // Only update field1 - only 1 effect should run
      f1.set(i)
    }
  })
}

// =============================================================================
// Approach 2: Lens-based Store
// =============================================================================

///|
test "lens: 2 fields - setup and read (1000 ops)" (b : @bench.T) {
  let store : LensStore[BenchRecord] = LensStore::new({ count: 0, name: "test" })
  let count_lens : Lens[BenchRecord, Int] = Lens::new(fn(s) { s.count }, fn(
    s,
    v,
  ) {
    { count: v, name: s.name }
  })
  let name_lens : Lens[BenchRecord, String] = Lens::new(fn(s) { s.name }, fn(
    s,
    v,
  ) {
    { count: s.count, name: v }
  })
  let (count_sig, _) = store.focus(count_lens)
  let (name_sig, _) = store.focus(name_lens)
  b.bench(fn() {
    for i = 0; i < 1000; i = i + 1 {
      let _ = count_sig.get()
      let _ = name_sig.get()

    }
  })
}

///|
test "lens: 2 fields - update via setter (100 ops)" (b : @bench.T) {
  let store : LensStore[BenchRecord] = LensStore::new({ count: 0, name: "test" })
  let count_lens : Lens[BenchRecord, Int] = Lens::new(fn(s) { s.count }, fn(
    s,
    v,
  ) {
    { count: v, name: s.name }
  })
  let (_, set_count) = store.focus(count_lens)
  b.bench(fn() {
    for i = 0; i < 100; i = i + 1 {
      set_count(i)
    }
  })
}

// =============================================================================
// Signal-based approach
// =============================================================================

///|
test "signal: create and read (1000 ops)" (b : @bench.T) {
  let counter = signal(0)
  b.bench(fn() {
    for i = 0; i < 1000; i = i + 1 {
      let _ = counter.get()

    }
  })
}

///|
test "signal: update (100 ops)" (b : @bench.T) {
  let counter = signal(0)
  b.bench(fn() {
    for i = 0; i < 100; i = i + 1 {
      counter.set(i)
    }
  })
}

///|
test "signal: memo (1000 reads)" (b : @bench.T) {
  let counter = signal(0)
  let doubled = memo(fn() { counter.get() * 2 })
  b.bench(fn() {
    for i = 0; i < 1000; i = i + 1 {
      let _ = doubled()

    }
  })
}

///|
test "signal: 10 signals, update 1 with 10 effects (100 ops)" (b : @bench.T) {
  let signals : Array[Signal[Int]] = []
  for i = 0; i < 10; i = i + 1 {
    signals.push(signal(i))
  }

  // Each signal has its own effect
  for s in signals {
    let _ = effect(fn() {
      let _ = s.get()

    })

  }
  b.bench(fn() {
    for i = 0; i < 100; i = i + 1 {
      // Only update first signal - only 1 effect runs
      signals[0].set(i)
    }
  })
}

// =============================================================================
// Setup cost comparison
// =============================================================================

///|
test "setup: create 100 signals" (b : @bench.T) {
  b.bench(fn() {
    let signals : Array[Signal[Int]] = []
    for i = 0; i < 100; i = i + 1 {
      signals.push(signal(i))
    }
  })
}

///|
test "setup: create SplitStore2 (2 fields)" (b : @bench.T) {
  b.bench(fn() {
    let _ = SplitStore2::new(0, "test")

  })
}

///|
test "setup: create SplitStore3 (3 fields)" (b : @bench.T) {
  b.bench(fn() {
    let _ = SplitStore3::new(0, "test", true)

  })
}
