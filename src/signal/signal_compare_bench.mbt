// Benchmarks for signal module comparison with experimental_signals
// Run both benchmarks and compare results

// =============================================================================
// Basic Signal Operations
// =============================================================================

///|
test "sig: signal.get (1000 reads)" (b : @bench.T) {
  let sig = signal(42)
  b.bench(fn() {
    for i = 0; i < 1000; i = i + 1 {
      let _ = sig.get()

    }
  })
}

///|
test "sig: signal.peek (1000 reads)" (b : @bench.T) {
  let sig = signal(42)
  b.bench(fn() {
    for i = 0; i < 1000; i = i + 1 {
      let _ = sig.peek()

    }
  })
}

///|
test "sig: signal.set (1000 writes, no subs)" (b : @bench.T) {
  let sig = signal(0)
  b.bench(fn() {
    for i = 0; i < 1000; i = i + 1 {
      sig.set(i)
    }
  })
}

// =============================================================================
// Computed (memo) Operations
// =============================================================================

///|
test "sig: memo.get (1000 reads, cached)" (b : @bench.T) {
  let a = signal(1)
  let b_sig = signal(2)
  let sum = memo(fn() { a.get() + b_sig.get() })
  // Initialize
  let _ = sum()
  b.bench(fn() {
    for i = 0; i < 1000; i = i + 1 {
      let _ = sum()

    }
  })
}

///|
test "sig: memo chain (depth 3, 1000 reads)" (b : @bench.T) {
  let a = signal(1)
  let b_memo = memo(fn() { a.get() + 1 })
  let c_memo = memo(fn() { b_memo() * 2 })
  let d_memo = memo(fn() { c_memo() + 10 })
  // Initialize
  let _ = d_memo()
  b.bench(fn() {
    for i = 0; i < 1000; i = i + 1 {
      let _ = d_memo()

    }
  })
}

///|
test "sig: memo after update (1000 cycles)" (b : @bench.T) {
  let a = signal(0)
  let doubled = memo(fn() { a.get() * 2 })
  b.bench(fn() {
    for i = 0; i < 1000; i = i + 1 {
      a.set(i)
      let _ = doubled()

    }
  })
}

// =============================================================================
// Effect Operations
// =============================================================================

///|
test "sig: render_effect creation and dispose (100 cycles)" (b : @bench.T) {
  b.bench(fn() {
    for i = 0; i < 100; i = i + 1 {
      let count = signal(0)
      let dispose = render_effect(fn() {
        let _ = count.get()

      })
      dispose()
    }
  })
}

///|
test "sig: render_effect with signal update (100 cycles)" (b : @bench.T) {
  let count = signal(0)
  let effect_runs = Ref::new(0)
  let _dispose = render_effect(fn() {
    let _ = count.get()
    effect_runs.val = effect_runs.val + 1
  })
  b.bench(fn() {
    for i = 0; i < 100; i = i + 1 {
      count.set(i)
    }
  })
}

// =============================================================================
// Batch Operations (using untracked for signal module)
// =============================================================================

///|
test "sig: untracked batch-like (100 updates)" (b : @bench.T) {
  let a = signal(0)
  let b_sig = signal(0)
  let c_sig = signal(0)
  b.bench(fn() {
    for i = 0; i < 100; i = i + 1 {
      // signal module doesn't have batch, but we can simulate
      a.set(i)
      b_sig.set(i * 2)
      c_sig.set(i * 3)
    }
  })
}

// =============================================================================
// Dependency Fan-out (1 signal -> N memos)
// =============================================================================

///|
test "sig: fan-out 10 memos (1000 reads each)" (b : @bench.T) {
  let source = signal(1)
  let memos : Array[() -> Int] = []
  for i = 0; i < 10; i = i + 1 {
    memos.push(memo(fn() { source.get() + 1 }))
  }
  // Initialize all
  for m in memos {
    let _ = m()

  }
  b.bench(fn() {
    for j = 0; j < 1000; j = j + 1 {
      for m in memos {
        let _ = m()

      }
    }
  })
}

///|
test "sig: fan-out 10 memos, source update (100 cycles)" (b : @bench.T) {
  let source = signal(0)
  let memos : Array[() -> Int] = []
  for i = 0; i < 10; i = i + 1 {
    memos.push(memo(fn() { source.get() + 1 }))
  }
  // Initialize all
  for m in memos {
    let _ = m()

  }
  b.bench(fn() {
    for i = 0; i < 100; i = i + 1 {
      source.set(i)
      for m in memos {
        let _ = m()

      }
    }
  })
}

// =============================================================================
// Dependency Fan-in (N signals -> 1 memo)
// =============================================================================

///|
test "sig: fan-in 10 signals (1000 reads)" (b : @bench.T) {
  let signals : Array[Signal[Int]] = []
  for i = 0; i < 10; i = i + 1 {
    signals.push(signal(i))
  }
  let sum = memo(fn() {
    let mut total = 0
    for s in signals {
      total = total + s.get()
    }
    total
  })
  // Initialize
  let _ = sum()
  b.bench(fn() {
    for j = 0; j < 1000; j = j + 1 {
      let _ = sum()

    }
  })
}

///|
test "sig: fan-in 10 signals, 1 update (100 cycles)" (b : @bench.T) {
  let signals : Array[Signal[Int]] = []
  for i = 0; i < 10; i = i + 1 {
    signals.push(signal(i))
  }
  let sum = memo(fn() {
    let mut total = 0
    for s in signals {
      total = total + s.get()
    }
    total
  })
  // Initialize
  let _ = sum()
  b.bench(fn() {
    for i = 0; i < 100; i = i + 1 {
      signals[0].set(i)
      let _ = sum()

    }
  })
}

// =============================================================================
// Memory / Subscribe/Unsubscribe test
// =============================================================================

///|
test "sig: repeated effect create/dispose (100 cycles)" (b : @bench.T) {
  let source = signal(1)
  b.bench(fn() {
    for i = 0; i < 100; i = i + 1 {
      let dispose = render_effect(fn() {
        let _ = source.get()

      })
      dispose()
    }
  })
}
