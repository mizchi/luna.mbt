// Memo - Cached computed value that updates when dependencies change
//

///|
/// Memo state
priv struct MemoState[T] {
  mut value : T?
  mut dirty : Bool
  subscribers : Array[EffectRunner]
}

///|
/// Create a memoized computation.
/// Returns a getter function that caches the result and recomputes only when dependencies change.
/// ```mbt check
/// test {
///   let a = @signal.signal(2)
///   let b = @signal.signal(3)
///   let compute_count : Ref[Int] = { val: 0 }
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
  let id = new_effect_id()
  let state : MemoState[T] = { value: None, dirty: true, subscribers: [] }

  // Create EffectRunner reference for self-registration
  let runner_ref : Ref[EffectRunner?] = { val: None }

  // The subscriber function for this memo
  fn mark_dirty() -> Unit {
    if not(state.dirty) {
      state.dirty = true
      // Notify our own subscribers that we changed
      for subscriber in state.subscribers {
        schedule_effect(subscriber)
      }
    }
  }

  let runner : EffectRunner = { id, run: mark_dirty }
  runner_ref.val = Some(runner)

  // Return getter function
  fn() {
    // Track this memo as a dependency if inside an effect
    match get_current_subscriber() {
      Some(subscriber) => {
        // Check if already subscribed (by ID)
        let already_subscribed = state.subscribers
          .iter()
          .any(fn(s) { s.id == subscriber.id })
        if not(already_subscribed) {
          state.subscribers.push(subscriber)
        }
      }
      None => ()
    }

    // Recompute if dirty
    if state.dirty {
      // Run computation with mark_dirty as subscriber to track dependencies
      match runner_ref.val {
        Some(r) => {
          let new_value = run_with_subscriber(r, compute)
          state.value = Some(new_value)
          state.dirty = false
        }
        None => ()
      }
    }

    // Return cached value
    match state.value {
      Some(v) => v
      None => {
        // This should never happen after first computation
        let v = compute()
        state.value = Some(v)
        v
      }
    }
  }
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
