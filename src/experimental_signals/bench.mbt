// Benchmarks for experimental_signals (alien-signals style)
// Compare with src/signal benchmarks for performance analysis

// =============================================================================
// Basic Signal Operations
// =============================================================================

test "exp: signal.get (1000 reads)" (b : @bench.T) {
  let sig = signal(42)
  b.bench(fn() {
    for i = 0; i < 1000; i = i + 1 {
      let _ = sig.get()
    }
  })
}

test "exp: signal.peek (1000 reads)" (b : @bench.T) {
  let sig = signal(42)
  b.bench(fn() {
    for i = 0; i < 1000; i = i + 1 {
      let _ = sig.peek()
    }
  })
}

test "exp: signal.set (1000 writes, no subs)" (b : @bench.T) {
  let sig = signal(0)
  b.bench(fn() {
    for i = 0; i < 1000; i = i + 1 {
      sig.set(i)
    }
  })
}

// =============================================================================
// Computed Operations
// =============================================================================

test "exp: computed.get (1000 reads, cached)" (b : @bench.T) {
  let a = signal(1)
  let b_sig = signal(2)
  let sum = computed(fn(_) { a.get() + b_sig.get() })
  // Initialize
  let _ = sum.get()
  b.bench(fn() {
    for i = 0; i < 1000; i = i + 1 {
      let _ = sum.get()
    }
  })
}

test "exp: computed chain (depth 3, 1000 reads)" (b : @bench.T) {
  let a = signal(1)
  let b_comp = computed(fn(_) { a.get() + 1 })
  let c_comp = computed(fn(_) { b_comp.get() * 2 })
  let d_comp = computed(fn(_) { c_comp.get() + 10 })
  // Initialize
  let _ = d_comp.get()
  b.bench(fn() {
    for i = 0; i < 1000; i = i + 1 {
      let _ = d_comp.get()
    }
  })
}

test "exp: computed after update (1000 cycles)" (b : @bench.T) {
  let a = signal(0)
  let doubled = computed(fn(_) { a.get() * 2 })
  b.bench(fn() {
    for i = 0; i < 1000; i = i + 1 {
      a.set(i)
      let _ = doubled.get()
    }
  })
}

// =============================================================================
// Effect Operations
// =============================================================================

test "exp: effect creation and stop (100 cycles)" (b : @bench.T) {
  b.bench(fn() {
    for i = 0; i < 100; i = i + 1 {
      let count = signal(0)
      let stop = effect(fn() {
        let _ = count.get()
      })
      stop()
    }
  })
}

test "exp: effect with signal update (100 cycles)" (b : @bench.T) {
  let count = signal(0)
  let effect_runs = Ref::new(0)
  let _stop = effect(fn() {
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
// Batch Operations
// =============================================================================

test "exp: batch (100 updates)" (b : @bench.T) {
  let a = signal(0)
  let b_sig = signal(0)
  let c_sig = signal(0)
  b.bench(fn() {
    for i = 0; i < 100; i = i + 1 {
      batch(fn() {
        a.set(i)
        b_sig.set(i * 2)
        c_sig.set(i * 3)
      })
    }
  })
}

// =============================================================================
// Dependency Fan-out (1 signal -> N computeds)
// =============================================================================

test "exp: fan-out 10 computeds (1000 reads each)" (b : @bench.T) {
  let source = signal(1)
  let computeds : Array[ComputedNode[Int]] = []
  for i = 0; i < 10; i = i + 1 {
    computeds.push(computed(fn(_) { source.get() + 1 }))
  }
  // Initialize all
  for c in computeds {
    let _ = c.get()
  }
  b.bench(fn() {
    for j = 0; j < 1000; j = j + 1 {
      for c in computeds {
        let _ = c.get()
      }
    }
  })
}

test "exp: fan-out 10 computeds, source update (100 cycles)" (b : @bench.T) {
  let source = signal(0)
  let computeds : Array[ComputedNode[Int]] = []
  for i = 0; i < 10; i = i + 1 {
    computeds.push(computed(fn(_) { source.get() + 1 }))
  }
  // Initialize all
  for c in computeds {
    let _ = c.get()
  }
  b.bench(fn() {
    for i = 0; i < 100; i = i + 1 {
      source.set(i)
      for c in computeds {
        let _ = c.get()
      }
    }
  })
}

// =============================================================================
// Dependency Fan-in (N signals -> 1 computed)
// =============================================================================

test "exp: fan-in 10 signals (1000 reads)" (b : @bench.T) {
  let signals : Array[SignalNode[Int]] = []
  for i = 0; i < 10; i = i + 1 {
    signals.push(signal(i))
  }
  let sum = computed(fn(_) {
    let mut total = 0
    for s in signals {
      total = total + s.get()
    }
    total
  })
  // Initialize
  let _ = sum.get()
  b.bench(fn() {
    for j = 0; j < 1000; j = j + 1 {
      let _ = sum.get()
    }
  })
}

test "exp: fan-in 10 signals, 1 update (100 cycles)" (b : @bench.T) {
  let signals : Array[SignalNode[Int]] = []
  for i = 0; i < 10; i = i + 1 {
    signals.push(signal(i))
  }
  let sum = computed(fn(_) {
    let mut total = 0
    for s in signals {
      total = total + s.get()
    }
    total
  })
  // Initialize
  let _ = sum.get()
  b.bench(fn() {
    for i = 0; i < 100; i = i + 1 {
      signals[0].set(i)
      let _ = sum.get()
    }
  })
}

// =============================================================================
// Memory / Link reuse test
// =============================================================================

test "exp: repeated subscribe/unsubscribe (100 cycles)" (b : @bench.T) {
  let source = signal(1)
  b.bench(fn() {
    for i = 0; i < 100; i = i + 1 {
      let stop = effect(fn() {
        let _ = source.get()
      })
      stop()
    }
  })
}
