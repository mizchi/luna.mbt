//

///|
/// Signals Library Benchmarks

// =============================================================================
// Signal Creation & Access
// =============================================================================

test "signal_create" (b : @bench.T) {
  b.bench(name="Signal::new", fn() { b.keep(@resource.signal(42)) })
}

///|
test "signal_peek" (b : @bench.T) {
  let sig = @resource.signal(42)
  b.bench(name="Signal::peek", fn() { b.keep(sig.peek()) })
}

///|
test "signal_get" (b : @bench.T) {
  let sig = @resource.signal(42)
  b.bench(name="Signal::get", fn() { b.keep(sig.get()) })
}

///|
test "signal_set" (b : @bench.T) {
  let sig = @resource.signal(0)
  let mut i = 0
  b.bench(name="Signal::set", fn() {
    i = i + 1
    sig.set(i)
  })
}

///|
test "signal_update" (b : @bench.T) {
  let sig = @resource.signal(0)
  b.bench(name="Signal::update", fn() { sig.update(n => n + 1) })
}

// =============================================================================
// Effect
// =============================================================================

///|
test "effect_create_dispose" (b : @bench.T) {
  b.bench(name="effect_create_dispose", fn() {
    let dispose = @resource.effect(fn() { () })
    dispose()
  })
}

///|
test "effect_with_signal" (b : @bench.T) {
  let sig = @resource.signal(0)
  b.bench(name="effect_with_1_signal", fn() {
    let dispose = @resource.effect(fn() {
      let _ = sig.get()

    })
    dispose()
  })
}

///|
test "effect_rerun" (b : @bench.T) {
  let sig = @resource.signal(0)
  let count = Ref::new(0)
  let _ = @resource.effect(fn() { count.val = sig.get() })
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
  b.bench(name="memo_create", fn() { b.keep(@resource.memo(fn() { 42 })) })
}

///|
test "memo_cached_read" (b : @bench.T) {
  let m = @resource.memo(fn() { 42 * 2 })
  let _ = m() // Initialize
  b.bench(name="memo_cached_read", fn() { b.keep(m()) })
}

///|
test "memo_recompute" (b : @bench.T) {
  let sig = @resource.signal(0)
  let doubled = @resource.memo(fn() { sig.get() * 2 })
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
  let a = @resource.signal(0)
  let b_ = @resource.signal(0)
  let c = @resource.signal(0)
  let mut i = 0
  b.bench(name="batch_3_updates", fn() {
    i = i + 1
    @resource.batch(fn() {
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
  let source = @resource.signal(1)
  let doubled = @resource.memo(fn() { source.get() * 2 })
  let quadrupled = @resource.memo(fn() { doubled() * 2 })
  let mut i = 0
  b.bench(name="derived_chain_3_levels", fn() {
    i = i + 1
    source.set(i)
    b.keep(quadrupled())
  })
}

///|
test "diamond_dependency" (b : @bench.T) {
  let a = @resource.signal(1)
  let b_ = @resource.memo(fn() { a.get() * 2 })
  let c = @resource.memo(fn() { a.get() * 3 })
  let d = @resource.memo(fn() { b_() + c() })
  let mut i = 0
  b.bench(name="diamond_dependency", fn() {
    i = i + 1
    a.set(i)
    b.keep(d())
  })
}

///|
test "5_effects_1_signal" (b : @bench.T) {
  let sig = @resource.signal(0)
  let counts : Array[Int] = [0, 0, 0, 0, 0]
  let _ = @resource.effect(fn() { counts[0] = sig.get() })
  let _ = @resource.effect(fn() { counts[1] = sig.get() })
  let _ = @resource.effect(fn() { counts[2] = sig.get() })
  let _ = @resource.effect(fn() { counts[3] = sig.get() })
  let _ = @resource.effect(fn() { counts[4] = sig.get() })
  let mut i = 0
  b.bench(name="5_effects_on_1_signal", fn() {
    i = i + 1
    sig.set(i)
  })
}

///|
test "untracked_read" (b : @bench.T) {
  let sig = @resource.signal(42)
  b.bench(name="untracked_read", fn() {
    b.keep(@resource.untracked(fn() { sig.get() }))
  })
}

// =============================================================================
// Large Scale Benchmarks
// =============================================================================

///|
test "create_100_signals" (b : @bench.T) {
  b.bench(name="create_100_signals", fn() {
    let signals : Array[@resource.Signal[Int]] = []
    for i in 0..<100 {
      signals.push(@resource.signal(i))
    }
    b.keep(signals)
  })
}

///|
test "create_1000_signals" (b : @bench.T) {
  b.bench(name="create_1000_signals", fn() {
    let signals : Array[@resource.Signal[Int]] = []
    for i in 0..<1000 {
      signals.push(@resource.signal(i))
    }
    b.keep(signals)
  })
}

///|
test "100_effects_1_signal" (b : @bench.T) {
  let sig = @resource.signal(0)
  let counts : Array[Int] = []
  for i in 0..<100 {
    counts.push(0)
  }
  for i in 0..<100 {
    let idx = i
    let _ = @resource.effect(fn() { counts[idx] = sig.get() })

  }
  let mut i = 0
  b.bench(name="100_effects_on_1_signal", fn() {
    i = i + 1
    sig.set(i)
  })
}

///|
test "derived_chain_10" (b : @bench.T) {
  let source = @resource.signal(1)
  let m1 = @resource.memo(fn() { source.get() + 1 })
  let m2 = @resource.memo(fn() { m1() + 1 })
  let m3 = @resource.memo(fn() { m2() + 1 })
  let m4 = @resource.memo(fn() { m3() + 1 })
  let m5 = @resource.memo(fn() { m4() + 1 })
  let m6 = @resource.memo(fn() { m5() + 1 })
  let m7 = @resource.memo(fn() { m6() + 1 })
  let m8 = @resource.memo(fn() { m7() + 1 })
  let m9 = @resource.memo(fn() { m8() + 1 })
  let m10 = @resource.memo(fn() { m9() + 1 })
  let mut i = 0
  b.bench(name="derived_chain_10_levels", fn() {
    i = i + 1
    source.set(i)
    b.keep(m10())
  })
}

///|
test "wide_dependency_100_memos" (b : @bench.T) {
  let source = @resource.signal(1)
  let memos : Array[() -> Int] = []
  for i in 0..<100 {
    let multiplier = i + 1
    memos.push(@resource.memo(fn() { source.get() * multiplier }))
  }
  // Sum all memos
  let sum_memo = @resource.memo(fn() {
    let mut sum = 0
    for i in 0..<memos.length() {
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
  let signals : Array[@resource.Signal[Int]] = []
  for i in 0..<100 {
    signals.push(@resource.signal(0))
  }
  // One effect that reads all
  let sum = Ref::new(0)
  let _ = @resource.effect(fn() {
    let mut s = 0
    for i in 0..<signals.length() {
      s = s + signals[i].get()
    }
    sum.val = s
  })
  let mut iter = 0
  b.bench(name="batch_100_signal_updates", fn() {
    iter = iter + 1
    @resource.batch(fn() {
      for i in 0..<signals.length() {
        signals[i].set(iter)
      }
    })
  })
}

///|
test "unbatched_100_updates" (b : @bench.T) {
  let signals : Array[@resource.Signal[Int]] = []
  for i in 0..<100 {
    signals.push(@resource.signal(0))
  }
  // One effect that reads all
  let sum = Ref::new(0)
  let _ = @resource.effect(fn() {
    let mut s = 0
    for i in 0..<signals.length() {
      s = s + signals[i].get()
    }
    sum.val = s
  })
  let mut iter = 0
  b.bench(name="unbatched_100_updates", fn() {
    iter = iter + 1
    for i in 0..<signals.length() {
      signals[i].set(iter)
    }
  })
}
