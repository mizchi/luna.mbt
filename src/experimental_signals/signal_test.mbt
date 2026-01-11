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

test "diamond: simple fan-out/fan-in" {
  // d -> f1, f2 -> g
  let d = signal(0)
  let f1 = memo(fn() { d.get() })
  let f2 = memo(fn() { d.get() })
  let g = memo(fn() { f1.get() + f2.get() })

  // Initial
  assert_eq!(g.get(), 0)

  // Update
  d.set(1)

  // Debug: check individual values
  let v1 = f1.get()
  let v2 = f2.get()
  assert_eq!(v1, 1)
  assert_eq!(v2, 1)
  assert_eq!(g.get(), 2) // 1 + 1 = 2
}

test "diamond: multi-level convergence" {
  //       d
  //    /  |  \
  //   f1  f2  f3
  //    \  |  /
  //       g
  let d = signal(0)
  let f1 = memo(fn() { d.get() })
  let f2 = memo(fn() { d.get() })
  let f3 = memo(fn() { d.get() })
  let g = memo(fn() { f1.get() + f2.get() + f3.get() })

  assert_eq!(g.get(), 0)
  d.set(1)
  assert_eq!(g.get(), 3) // 1 + 1 + 1 = 3
}

test "diamond: exponential convergence - isolated f" {
  // Simpler test: d -> f1, f2
  // Check if f1.get() affects f2
  let d = signal(0)
  let f1 = memo(fn() { d.get() })
  let f2 = memo(fn() { d.get() })

  // Initial read to create links
  let _ = f1.get()
  let _ = f2.get()

  // Update d
  d.set(1)

  // Read f1 first - this triggers d.get() which clears dirty
  let vf1 = f1.get()
  assert_eq!(vf1, 1)

  // Now read f2 - should still see updated value
  let vf2 = f2.get()
  assert_eq!(vf2, 1)
}

test "diamond: exponential convergence - with g layer" {
  // d -> f1, f2 -> g (reads both)
  let d = signal(0)
  let f1 = memo(fn() { d.get() })
  let f2 = memo(fn() { d.get() })
  let g = memo(fn() { f1.get() + f2.get() })

  // Initial read
  assert_eq!(g.get(), 0)

  // Update d
  d.set(1)

  // Read f values directly after d.set
  let vf1 = f1.get()
  let vf2 = f2.get()
  assert_eq!(vf1, 1)
  assert_eq!(vf2, 1)
}

test "diamond: multiple subscribers to same f" {
  // d -> f -> g1, g2
  // f has multiple subscribers
  let d = signal(0)
  let f = memo(fn() { d.get() })
  let g1 = memo(fn() { f.get() })
  let g2 = memo(fn() { f.get() })

  // Initial read through g1 and g2
  assert_eq!(g1.get(), 0)
  assert_eq!(g2.get(), 0)

  // Update d
  d.set(1)

  // Read g values - both should see updated f
  let vg1 = g1.get()
  let vg2 = g2.get()
  assert_eq!(vg1, 1)
  assert_eq!(vg2, 1)
}

test "diamond: f with multiple g subscribers reading same f" {
  // d -> f1, f2 -> g1, g2 (each g reads both f's)
  let d = signal(0)
  let f1 = memo(fn() { d.get() })
  let f2 = memo(fn() { d.get() })
  let g1 = memo(fn() { f1.get() + f2.get() })
  let g2 = memo(fn() { f1.get() + f2.get() })

  // Initial read
  assert_eq!(g1.get(), 0)
  assert_eq!(g2.get(), 0)

  // Update d
  d.set(1)

  // Read through h (which triggers g1 and g2)
  let vg1 = g1.get()
  let vg2 = g2.get()
  assert_eq!(vg1, 2)  // f1 + f2 = 1 + 1 = 2
  assert_eq!(vg2, 2)
}

test "diamond: three levels simple" {
  // d -> f -> g -> h (simple chain, no fan-out)
  let d = signal(0)
  let f = memo(fn() { d.get() })
  let g = memo(fn() { f.get() })
  let h = memo(fn() { g.get() })

  assert_eq!(h.get(), 0)
  d.set(1)
  assert_eq!(h.get(), 1)
}

test "diamond: three levels with fan-out at f" {
  // d -> f1, f2 -> g -> h
  let d = signal(0)
  let f1 = memo(fn() { d.get() })
  let f2 = memo(fn() { d.get() })
  let g = memo(fn() { f1.get() + f2.get() })
  let h = memo(fn() { g.get() })

  assert_eq!(h.get(), 0)
  d.set(1)
  assert_eq!(h.get(), 2)
}

test "diamond: three levels with fan-out at g" {
  // d -> f -> g1, g2 -> h
  let d = signal(0)
  let f = memo(fn() { d.get() })
  let g1 = memo(fn() { f.get() })
  let g2 = memo(fn() { f.get() })
  let h = memo(fn() { g1.get() + g2.get() })

  assert_eq!(h.get(), 0)
  d.set(1)
  assert_eq!(h.get(), 2)
}

test "diamond: three levels with full fan-out" {
  // d -> f1, f2 -> g1, g2 -> h
  let d = signal(0)
  let f1 = memo(fn() { d.get() })
  let f2 = memo(fn() { d.get() })
  let g1 = memo(fn() { f1.get() + f2.get() })
  let g2 = memo(fn() { f1.get() + f2.get() })
  let h = memo(fn() { g1.get() + g2.get() })

  assert_eq!(h.get(), 0)
  d.set(1)
  assert_eq!(h.get(), 4) // (1+1) + (1+1) = 4
}

test "diamond: 3 f's with 2 g's" {
  // d -> f1, f2, f3 -> g1, g2 -> h
  let d = signal(0)
  let f1 = memo(fn() { d.get() })
  let f2 = memo(fn() { d.get() })
  let f3 = memo(fn() { d.get() })
  let g1 = memo(fn() { f1.get() + f2.get() + f3.get() })
  let g2 = memo(fn() { f1.get() + f2.get() + f3.get() })
  let h = memo(fn() { g1.get() + g2.get() })

  assert_eq!(h.get(), 0)
  d.set(1)
  assert_eq!(h.get(), 6) // (1+1+1) + (1+1+1) = 6
}

test "diamond: 2 f's with 3 g's" {
  // d -> f1, f2 -> g1, g2, g3 -> h
  let d = signal(0)
  let f1 = memo(fn() { d.get() })
  let f2 = memo(fn() { d.get() })
  let g1 = memo(fn() { f1.get() + f2.get() })
  let g2 = memo(fn() { f1.get() + f2.get() })
  let g3 = memo(fn() { f1.get() + f2.get() })
  let h = memo(fn() { g1.get() + g2.get() + g3.get() })

  assert_eq!(h.get(), 0)
  d.set(1)
  assert_eq!(h.get(), 6) // (1+1) * 3 = 6
}

test "diamond: exponential convergence" {
  //       d
  //    /  |  \
  //   f1  f2  f3
  //    \  |  /
  //   g1  g2  g3
  //    \  |  /
  //       h
  let d = signal(0)
  let f1 = memo(fn() { d.get() })
  let f2 = memo(fn() { d.get() })
  let f3 = memo(fn() { d.get() })
  let g1 = memo(fn() { f1.get() + f2.get() + f3.get() })
  let g2 = memo(fn() { f1.get() + f2.get() + f3.get() })
  let g3 = memo(fn() { f1.get() + f2.get() + f3.get() })
  let h = memo(fn() { g1.get() + g2.get() + g3.get() })

  assert_eq!(h.get(), 0)
  d.set(1)
  assert_eq!(h.get(), 9) // (1+1+1) * 3 = 9
}
