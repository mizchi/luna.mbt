// Propagation-count measurements.
//
// These are deliberately NOT timing benchmarks. Every number here is a count
// of how many times a reactive node re-ran, so it is exact and reproducible:
// a regression fails the assertion outright instead of hiding under a timing
// tolerance. `moonbench-check.mjs` cannot see any of these properties — an
// effect firing twice as often is invisible to a wall-clock benchmark that
// only measures one render.

///|
/// Number of source updates each scenario applies.
const UPDATES : Int = 5

///|
/// Asserts an exact propagation count and echoes it, so a run doubles as a
/// readable report.
fn count_is(label : String, actual : Int, expect : Int) -> Unit raise {
  println("  \{label}: \{actual}")
  assert_eq(actual, expect)
}

///|
/// Drives `n` updates through `set`, flushing between each.
fn drive(set : (Int) -> Unit) -> Unit {
  for i in 1..=UPDATES {
    set(i)
    @signals.flush()
  }
}

///|
test "propagation: an effect ignores signals it does not read" {
  let watched = @resource.signal(0)
  let unrelated = @resource.signal(0)
  let runs = Ref(0)
  let _ = @resource.render_effect(() => {
    let _ = watched.get()
    runs.val += 1
  })
  let base = runs.val
  drive(i => unrelated.set(i))
  count_is("effect re-runs on unrelated updates", runs.val - base, 0)
}

///|
test "propagation: an effect re-runs once per update it depends on" {
  let src = @resource.signal(0)
  let runs = Ref(0)
  let _ = @resource.render_effect(() => {
    let _ = src.get()
    runs.val += 1
  })
  let base = runs.val
  drive(i => src.set(i))
  count_is("effect re-runs", runs.val - base, UPDATES)
}

///|
test "propagation: a diamond wakes its effect once per update, not twice" {
  let src = @resource.signal(0)
  let left = @resource.memo(() => src.get() * 2)
  let right = @resource.memo(() => src.get() + 1)
  let runs = Ref(0)
  let _ = @resource.render_effect(() => {
    let _ = left()
    let _ = right()
    runs.val += 1
  })
  let base = runs.val
  drive(i => src.set(i))
  // 2 * UPDATES here would mean the effect observes an inconsistent
  // intermediate state (a glitch) once per branch.
  count_is("effect re-runs through 2 branches", runs.val - base, UPDATES)
}

///|
test "propagation: every level of a depth-8 memo chain recomputes" {
  let src = @resource.signal(0)
  let bodies = Ref(0)
  let mut node : () -> Int = () => src.get()
  for _ in 0..<8 {
    let prev = node
    node = @resource.memo(() => {
      bodies.val += 1
      prev() + 1
    })
  }
  let leaf = node
  let _ = @resource.render_effect(() => { let _ = leaf(); })
  let base = bodies.val
  drive(i => src.set(i))
  count_is("memo bodies evaluated", bodies.val - base, UPDATES * 8)
}

///|
test "propagation: batch coalesces many sets into one effect run" {
  let src = @resource.signal(0)
  let runs = Ref(0)
  let _ = @resource.render_effect(() => {
    let _ = src.get()
    runs.val += 1
  })
  let base = runs.val
  @resource.batch(() => for i in 1..=UPDATES {
    src.set(i)
  })
  @signals.flush()
  count_is("effect re-runs for a batch of \{UPDATES}", runs.val - base, 1)
}

///|
test "propagation: watch cuts off on structural equality" {
  let src = @resource.signal(0)
  let runs = Ref(0)
  // The observed value never changes, so an Eq-aware observer should stay quiet.
  let _ = @signals.watch(() => { let _ = src.get(); 42 }, (_new, _old) => runs.val +=
    1)
  drive(i => src.set(i))
  count_is("watch callbacks for an unchanging value", runs.val, 0)
}

///|
test "propagation: memo does NOT cut off on structural equality" {
  let src = @resource.signal(0)
  // Collapses every input below 100 onto the same String.
  let bucket = @resource.memo(() => if src.get() < 100 { "low" } else { "high" })
  let runs = Ref(0)
  let _ = @resource.render_effect(() => {
    let _ = bucket()
    runs.val += 1
  })
  let base = runs.val
  drive(i => src.set(i))
  // Known gap, asserted at the current value so a change is visible.
  //
  // `memo` cuts off with `physical_equal`, so a freshly produced value that is
  // structurally equal to the previous one still propagates. Downstream effects
  // re-render once per source update even though nothing they can observe
  // changed. `watch` above shows the Eq-based machinery already exists; it is
  // just not wired into the derived-value graph.
  //
  // If this ever drops to 0, the cutoff landed: update the expectation.
  count_is("effect re-runs behind a collapsing memo", runs.val - base, UPDATES)
}

///|
/// A memo that cuts off on structural equality, built from the public API.
/// `watch` only fires when its observed value actually changes, so the signal
/// it feeds stays put while the derived value does.
fn[T : Eq] memo_eq(f : () -> T) -> () -> T {
  let out = @resource.signal(f())
  let _ = @signals.watch(f, (next, _prev) => out.set(next))
  () => out.get()
}

///|
test "propagation: an Eq-aware memo closes the gap in user space" {
  let src = @resource.signal(0)
  let bucket = memo_eq(() => if src.get() < 100 { "low" } else { "high" })
  let runs = Ref(0)
  let _ = @resource.render_effect(() => {
    let _ = bucket()
    runs.val += 1
  })
  let base = runs.val
  drive(i => src.set(i))
  count_is("effect re-runs behind an Eq-aware memo", runs.val - base, 0)
}
