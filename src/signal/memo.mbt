// Memo - Cached computed value that updates when dependencies change
// Now backed by experimental_signals for improved performance

///|
/// Create a memoized computation.
/// Returns a getter function that caches the result and recomputes only when dependencies change.
/// ```mbt check
/// test {
///   let a = @signal.signal(2)
///   let b = @signal.signal(3)
///   let compute_count : Ref[Int] = Ref::new(0)
///   let sum = @signal.memo(fn() {
///     compute_count.val = compute_count.val + 1
///     a.get() + b.get()
///   })
///   inspect(sum(), content="5")
///   inspect(sum(), content="5") // Cached, no recompute
///   inspect(compute_count.val, content="1")
///   a.set(10)
///   inspect(sum(), content="13") // Recomputes
///   inspect(compute_count.val, content="2")
/// }
/// ```
pub fn[T] memo(compute : () -> T) -> () -> T {
  let inner = @esig.memo(compute)
  fn() { inner.get() }
}

///|
/// Create a computed signal (alias for memo with Signal-like API).
/// Same as `memo`, but named to be more familiar for those coming from other reactive frameworks.
/// ```mbt check
/// test {
///   let count = @signal.signal(5)
///   let doubled = @signal.computed(fn() { count.get() * 2 })
///   inspect(doubled(), content="10")
///   count.set(7)
///   inspect(doubled(), content="14")
/// }
/// ```
pub fn[T] computed(compute : () -> T) -> () -> T {
  memo(compute)
}
