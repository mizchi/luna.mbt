// Eq-based memo.
//
// `memo` cuts off on identity: it stops propagating when a recomputation
// returns the *same object* as last time (`physical_equal`). That is the
// right default for scalars and for values meant to be shared by reference,
// but it means a memo that maps many different inputs onto an equal-but-
// freshly-allocated value wakes every dependent on every source change.
// `memo_eq` compares with `Eq` instead.

///|
/// A memo whose cutoff compares values with `Eq` rather than object identity.
///
/// Reach for this when `compute` returns a freshly allocated value that is
/// often equal to the previous one — a formatted `String`, a small struct, a
/// bucketed number. `memo` republishes each of those because every result is
/// a new object; `memo_eq` republishes only when the value actually moved.
///
/// ```mbt check
/// test "memo_eq stops an effect that memo would wake" {
///   let n = @resource.signal(0)
///   // A fresh String every time, but the same text until `n` reaches 100.
///   let label = @resource.memo_eq(() => "page \{n.get() / 100}")
///   let runs = Ref(0)
///   let _ = @resource.render_effect(() => {
///     let _ = label()
///     runs.val += 1
///   })
///   for i in 1..=5 {
///     n.set(i)
///   }
///   // Five source changes, one effect run: the label never moved.
///   inspect(runs.val, content="1")
///   inspect(label(), content="page 0")
/// }
/// ```
///
/// Two differences from `memo` worth knowing:
///
/// - **It is eager.** `memo` is lazy — `compute` first runs on the first
///   read. `memo_eq` runs it once at construction and again on every source
///   change, whether or not anything reads the result. Per source change the
///   two cost the same single `compute` call.
/// - **It is owned.** It installs an effect, registered with the current
///   owner, so it stops recomputing once that owner is disposed; a disposed
///   `memo_eq` keeps returning the last value it published. Created outside
///   any owner it lives as long as the program, like a bare `render_effect`.
///
/// Reads are always current: a read straight after `set`, with no flush in
/// between, sees the new value.
pub fn[T : Eq] memo_eq(compute : () -> T) -> () -> T {
  // The inner memo owns the caching and the recomputation; `out` republishes
  // its value only when `Eq` says it moved, and that is the cutoff dependents
  // observe. Seeding `out` through `untracked` does two jobs: it keeps an
  // enclosing effect from picking up `compute`'s dependencies as its own, and
  // it leaves `inner` warm so the watch below reuses the cached value instead
  // of running `compute` a second time.
  let inner = @signals.memo(compute)
  let out = @signals.signal(@signals.untracked(inner))
  let _ = @signals.watch(inner, (next, _prev) => out.set(next))
  () => out.get()
}
