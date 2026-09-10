// Tests for `memo_eq`. The counts here are exact: each one asserts how many
// times a node ran, so a regression in cutoff or in dependency tracking fails
// outright instead of hiding behind a timing tolerance.

///|
/// Counts effect runs behind a derived value that collapses many distinct
/// inputs onto an equal, freshly allocated result.
fn count_effect_runs_behind(wrap : (() -> String) -> () -> String) -> Int {
  let src = signal(0)
  let collapsed = wrap(() => "bucket \{src.get() / 100}")
  let runs = Ref(0)
  let _ = render_effect(() => {
    let _ = collapsed()
    runs.val += 1
  })
  let base = runs.val
  for i in 1..=5 {
    src.set(i)
  }
  runs.val - base
}

///|
test "memo_eq cuts off on Eq, memo does not" {
  assert_eq(count_effect_runs_behind((f : () -> String) => memo_eq(f)), 0)
  // The contrast is the whole point of the function: `memo` allocates a new
  // String on each recomputation, so identity cutoff never fires.
  assert_eq(count_effect_runs_behind((f : () -> String) => memo(f)), 5)
}

///|
test "memo_eq still propagates when the value really changes" {
  let src = signal(0)
  let bucket = memo_eq(() => src.get() / 100)
  let seen : Array[Int] = []
  let _ = render_effect(() => seen.push(bucket()))
  for i in [50, 99, 100, 150, 200] {
    src.set(i)
  }
  // 0 (initial) then one entry per bucket change: 1 at 100, 2 at 200.
  assert_eq(seen, [0, 1, 2])
}

///|
test "memo_eq reads are current without an explicit flush" {
  let src = signal(0)
  let doubled = memo_eq(() => src.get() * 2)
  assert_eq(doubled(), 0)
  src.set(21)
  assert_eq(doubled(), 42)
}

///|
test "memo_eq runs compute once per source change" {
  let src = signal(0)
  let evals = Ref(0)
  let m = memo_eq(() => {
    evals.val += 1
    src.get() / 100
  })
  // Eager: one evaluation at construction, before anything reads it.
  assert_eq(evals.val, 1)
  assert_eq(m(), 0)
  assert_eq(evals.val, 1)
  for i in 1..=5 {
    src.set(i)
  }
  // One per change, even though every result compared equal.
  assert_eq(evals.val, 6)
}

///|
test "memo_eq created inside an effect does not leak deps to it" {
  let hidden = signal(0)
  let outer_runs = Ref(0)
  let _ = render_effect(() => {
    outer_runs.val += 1
    // The enclosing effect never reads `hidden` itself; creating a memo_eq
    // over it must not subscribe the effect to it.
    let _ = memo_eq(() => hidden.get() * 2)

  })
  let base = outer_runs.val
  for i in 1..=3 {
    hidden.set(i)
  }
  assert_eq(outer_runs.val - base, 0)
}

///|
test "memo_eq stops recomputing when its owner is disposed" {
  let src = signal(0)
  let evals = Ref(0)
  let (value, dispose) = create_root_with_dispose(() => memo_eq(() => {
    evals.val += 1
    src.get()
  }))
  src.set(1)
  assert_eq(evals.val, 2)
  assert_eq(value(), 1)
  dispose()
  for i in 2..=5 {
    src.set(i)
  }
  // No further recomputation, and the getter keeps the last published value.
  assert_eq(evals.val, 2)
  assert_eq(value(), 1)
}
