///|
/// Signals Library Benchmarks

// =============================================================================
// Signal Creation & Access
// =============================================================================

test "signal_create" (b : @bench.T) {
  b.bench(name="Signal::new", fn() { b.keep(@signal.signal(42)) })
}

///|
test "signal_peek" (b : @bench.T) {
  let sig = @signal.signal(42)
  b.bench(name="Signal::peek", fn() { b.keep(sig.peek()) })
}

///|
test "signal_get" (b : @bench.T) {
  let sig = @signal.signal(42)
  b.bench(name="Signal::get", fn() { b.keep(sig.get()) })
}

///|
test "signal_set" (b : @bench.T) {
  let sig = @signal.signal(0)
  let mut i = 0
  b.bench(name="Signal::set", fn() {
    i = i + 1
    sig.set(i)
  })
}

///|
test "signal_update" (b : @bench.T) {
  let sig = @signal.signal(0)
  b.bench(name="Signal::update", fn() { sig.update(fn(n) { n + 1 }) })
}

// =============================================================================
// Effect
// =============================================================================

///|
test "effect_create_dispose" (b : @bench.T) {
  b.bench(name="effect_create_dispose", fn() {
    let dispose = @signal.effect(fn() { () })
    dispose()
  })
}

///|
test "effect_with_signal" (b : @bench.T) {
  let sig = @signal.signal(0)
  b.bench(name="effect_with_1_signal", fn() {
    let dispose = @signal.effect(fn() {
      let _ = sig.get()

    })
    dispose()
  })
}

///|
test "effect_rerun" (b : @bench.T) {
  let sig = @signal.signal(0)
  let count = { val: 0 }
  let _ = @signal.effect(fn() { count.val = sig.get() })
  let mut i = 0
  b.bench(name="effect_rerun", fn() {
    i = i + 1
    sig.set(i)
  })
}

// =============================================================================
// Memo
// =============================================================================

///|
test "memo_create" (b : @bench.T) {
  b.bench(name="memo_create", fn() { b.keep(@signal.memo(fn() { 42 })) })
}

///|
test "memo_cached_read" (b : @bench.T) {
  let m = @signal.memo(fn() { 42 * 2 })
  let _ = m() // Initialize
  b.bench(name="memo_cached_read", fn() { b.keep(m()) })
}

///|
test "memo_recompute" (b : @bench.T) {
  let sig = @signal.signal(0)
  let doubled = @signal.memo(fn() { sig.get() * 2 })
  let mut i = 0
  b.bench(name="memo_recompute", fn() {
    i = i + 1
    sig.set(i)
    b.keep(doubled())
  })
}

// =============================================================================
// Batch
// =============================================================================

///|
test "batch_3_updates" (b : @bench.T) {
  let a = @signal.signal(0)
  let b_ = @signal.signal(0)
  let c = @signal.signal(0)
  let mut i = 0
  b.bench(name="batch_3_updates", fn() {
    i = i + 1
    @signal.batch(fn() {
      a.set(i)
      b_.set(i)
      c.set(i)
    })
  })
}

// =============================================================================
// Complex Scenarios
// =============================================================================

///|
test "derived_chain_3" (b : @bench.T) {
  let source = @signal.signal(1)
  let doubled = @signal.memo(fn() { source.get() * 2 })
  let quadrupled = @signal.memo(fn() { doubled() * 2 })
  let mut i = 0
  b.bench(name="derived_chain_3_levels", fn() {
    i = i + 1
    source.set(i)
    b.keep(quadrupled())
  })
}

///|
test "diamond_dependency" (b : @bench.T) {
  let a = @signal.signal(1)
  let b_ = @signal.memo(fn() { a.get() * 2 })
  let c = @signal.memo(fn() { a.get() * 3 })
  let d = @signal.memo(fn() { b_() + c() })
  let mut i = 0
  b.bench(name="diamond_dependency", fn() {
    i = i + 1
    a.set(i)
    b.keep(d())
  })
}

///|
test "5_effects_1_signal" (b : @bench.T) {
  let sig = @signal.signal(0)
  let counts : Array[Int] = [0, 0, 0, 0, 0]
  let _ = @signal.effect(fn() { counts[0] = sig.get() })
  let _ = @signal.effect(fn() { counts[1] = sig.get() })
  let _ = @signal.effect(fn() { counts[2] = sig.get() })
  let _ = @signal.effect(fn() { counts[3] = sig.get() })
  let _ = @signal.effect(fn() { counts[4] = sig.get() })
  let mut i = 0
  b.bench(name="5_effects_on_1_signal", fn() {
    i = i + 1
    sig.set(i)
  })
}

///|
test "untracked_read" (b : @bench.T) {
  let sig = @signal.signal(42)
  b.bench(name="untracked_read", fn() { b.keep(@signal.untracked(fn() { sig.get() })) })
}

// =============================================================================
// Large Scale Benchmarks
// =============================================================================

///|
test "create_100_signals" (b : @bench.T) {
  b.bench(name="create_100_signals", fn() {
    let signals : Array[@signal.Signal[Int]] = []
    for i = 0; i < 100; i = i + 1 {
      signals.push(@signal.signal(i))
    }
    b.keep(signals)
  })
}

///|
test "create_1000_signals" (b : @bench.T) {
  b.bench(name="create_1000_signals", fn() {
    let signals : Array[@signal.Signal[Int]] = []
    for i = 0; i < 1000; i = i + 1 {
      signals.push(@signal.signal(i))
    }
    b.keep(signals)
  })
}

///|
test "100_effects_1_signal" (b : @bench.T) {
  let sig = @signal.signal(0)
  let counts : Array[Int] = []
  for i = 0; i < 100; i = i + 1 {
    counts.push(0)
  }
  for i = 0; i < 100; i = i + 1 {
    let idx = i
    let _ = @signal.effect(fn() { counts[idx] = sig.get() })

  }
  let mut i = 0
  b.bench(name="100_effects_on_1_signal", fn() {
    i = i + 1
    sig.set(i)
  })
}

///|
test "derived_chain_10" (b : @bench.T) {
  let source = @signal.signal(1)
  let m1 = @signal.memo(fn() { source.get() + 1 })
  let m2 = @signal.memo(fn() { m1() + 1 })
  let m3 = @signal.memo(fn() { m2() + 1 })
  let m4 = @signal.memo(fn() { m3() + 1 })
  let m5 = @signal.memo(fn() { m4() + 1 })
  let m6 = @signal.memo(fn() { m5() + 1 })
  let m7 = @signal.memo(fn() { m6() + 1 })
  let m8 = @signal.memo(fn() { m7() + 1 })
  let m9 = @signal.memo(fn() { m8() + 1 })
  let m10 = @signal.memo(fn() { m9() + 1 })
  let mut i = 0
  b.bench(name="derived_chain_10_levels", fn() {
    i = i + 1
    source.set(i)
    b.keep(m10())
  })
}

///|
test "wide_dependency_100_memos" (b : @bench.T) {
  let source = @signal.signal(1)
  let memos : Array[() -> Int] = []
  for i = 0; i < 100; i = i + 1 {
    let multiplier = i + 1
    memos.push(@signal.memo(fn() { source.get() * multiplier }))
  }
  // Sum all memos
  let sum_memo = @signal.memo(fn() {
    let mut sum = 0
    for i = 0; i < memos.length(); i = i + 1 {
      sum = sum + memos[i]()
    }
    sum
  })
  let mut i = 0
  b.bench(name="wide_100_memos_update", fn() {
    i = i + 1
    source.set(i)
    b.keep(sum_memo())
  })
}

///|
test "batch_100_updates" (b : @bench.T) {
  let signals : Array[@signal.Signal[Int]] = []
  for i = 0; i < 100; i = i + 1 {
    signals.push(@signal.signal(0))
  }
  // One effect that reads all
  let sum = { val: 0 }
  let _ = @signal.effect(fn() {
    let mut s = 0
    for i = 0; i < signals.length(); i = i + 1 {
      s = s + signals[i].get()
    }
    sum.val = s
  })
  let mut iter = 0
  b.bench(name="batch_100_signal_updates", fn() {
    iter = iter + 1
    @signal.batch(fn() {
      for i = 0; i < signals.length(); i = i + 1 {
        signals[i].set(iter)
      }
    })
  })
}

///|
test "unbatched_100_updates" (b : @bench.T) {
  let signals : Array[@signal.Signal[Int]] = []
  for i = 0; i < 100; i = i + 1 {
    signals.push(@signal.signal(0))
  }
  // One effect that reads all
  let sum = { val: 0 }
  let _ = @signal.effect(fn() {
    let mut s = 0
    for i = 0; i < signals.length(); i = i + 1 {
      s = s + signals[i].get()
    }
    sum.val = s
  })
  let mut iter = 0
  b.bench(name="unbatched_100_updates", fn() {
    iter = iter + 1
    for i = 0; i < signals.length(); i = i + 1 {
      signals[i].set(iter)
    }
  })
}
