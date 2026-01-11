// Reactive Context - Tracks current running effect for auto-subscription
//

///|
/// Effect wrapper with unique ID for deduplication
pub struct EffectRunner {
  id : Int
  run : () -> Unit
}

///|
/// Global effect ID counter
let effect_id_counter : Ref[Int] = Ref::new(0)

///|
/// Generate a new unique effect ID
pub fn new_effect_id() -> Int {
  let id = effect_id_counter.val
  effect_id_counter.val = id + 1
  id
}

///|
/// Owner - manages lifecycle of reactive computations (Solid.js style)
pub struct Owner {
  id : Int
  parent : Owner?
  children : Array[Owner]
  cleanups : Array[() -> Unit]
  disposers : Array[() -> Unit]
  mut disposed : Bool
}

///|
/// Create a new Owner
pub fn Owner::new(parent : Owner?) -> Owner {
  let owner : Owner = {
    id: new_effect_id(),
    parent,
    children: [],
    cleanups: [],
    disposers: [],
    disposed: false,
  }
  // Register with parent
  match parent {
    Some(p) => p.children.push(owner)
    None => ()
  }
  owner
}

///|
/// Dispose this owner and all its children
pub fn Owner::dispose(self : Owner) -> Unit {
  if self.disposed {
    return
  }
  self.disposed = true
  // Dispose children first (depth-first)
  for i = self.children.length() - 1; i >= 0; i = i - 1 {
    self.children[i].dispose()
  }
  // Run disposers (for effects)
  for i = self.disposers.length() - 1; i >= 0; i = i - 1 {
    self.disposers[i]()
  }
  // Run cleanups
  for i = self.cleanups.length() - 1; i >= 0; i = i - 1 {
    self.cleanups[i]()
  }
  // Clear arrays
  self.children.clear()
  self.disposers.clear()
  self.cleanups.clear()
  // Remove from parent's children
  match self.parent {
    Some(p) => p.children.retain(fn(child) { child.id != self.id })
    None => ()
  }
}

///|
/// Reactive context - tracks currently running computation
priv struct ReactiveContext {
  mut current_subscriber : EffectRunner?
  mut current_owner : Owner?
  mut current_cleanups : Array[() -> Unit]?
  mut batch_depth : Int
  pending_effects : Array[EffectRunner]
  pending_ids : Array[Int]
}

///|
/// Global reactive context instance
let reactive_context : ReactiveContext = {
  current_subscriber: None,
  current_owner: None,
  current_cleanups: None,
  batch_depth: 0,
  pending_effects: [],
  pending_ids: [],
}

///|
/// Get current subscriber (if any) during signal read
pub fn get_current_subscriber() -> EffectRunner? {
  reactive_context.current_subscriber
}

///|
/// Run a function with the given subscriber as current
/// This enables auto-tracking of signal dependencies
pub fn[T] run_with_subscriber(subscriber : EffectRunner, f : () -> T) -> T {
  let prev = reactive_context.current_subscriber
  reactive_context.current_subscriber = Some(subscriber)
  let result = f()
  reactive_context.current_subscriber = prev
  result
}

///|
/// Run a function without tracking (useful for avoiding circular deps).
/// Signal reads inside this function won't create subscriptions.
/// ```mbt check
/// test {
///   let count = @signal.signal(0)
///   let runs : Ref[Int] = Ref::new(0)
///   let _ = @signal.render_effect(fn() {
///     @signal.untracked(fn() {
///       let _ = count.get() // Won't create dependency
///       runs.val = runs.val + 1
///     })
///   })
///   count.set(1)
///   count.set(2)
///   // Effect only ran once (initial), not on updates
///   inspect(runs.val, content="1")
/// }
/// ```
pub fn[T] untracked(f : () -> T) -> T {
  // Disable both legacy and core tracking
  let prev_legacy = reactive_context.current_subscriber
  reactive_context.current_subscriber = None
  // Also disable core tracking
  let prev_core = set_active_sub(None)
  let result = f()
  let _ = set_active_sub(prev_core)
  reactive_context.current_subscriber = prev_legacy
  result
}

///|
/// Start a batch update - effects won't run until batch ends
pub fn batch_start() -> Unit {
  reactive_context.batch_depth = reactive_context.batch_depth + 1
  start_batch()
}

///|
/// End a batch update - run all pending effects
pub fn batch_end() -> Unit {
  reactive_context.batch_depth = reactive_context.batch_depth - 1
  end_batch()
  if reactive_context.batch_depth == 0 {
    flush_effects()
  }
}

///|
/// Run a function in a batch - all signal updates are batched.
/// Effects only run once after all updates complete.
/// ```mbt check
/// test {
///   let a = @signal.signal(0)
///   let b = @signal.signal(0)
///   let runs : Ref[Int] = Ref::new(0)
///   let _ = @signal.render_effect(fn() {
///     let _ = a.get() + b.get()
///     runs.val = runs.val + 1
///   })
///   inspect(runs.val, content="1") // Initial run
///   @signal.batch(fn() {
///     a.set(1)
///     b.set(2)
///   })
///   // Only one additional run, not two
///   inspect(runs.val, content="2")
/// }
/// ```
pub fn[T] batch(f : () -> T) -> T {
  batch_start()
  let result = f()
  batch_end()
  result
}

///|
/// Check if an effect ID is already pending
fn is_pending(id : Int) -> Bool {
  for pending_id in reactive_context.pending_ids {
    if pending_id == id {
      return true
    }
  }
  false
}

///|
/// Schedule an effect to run (respects batching, deduplicates)
pub fn schedule_effect(effect : EffectRunner) -> Unit {
  if reactive_context.batch_depth > 0 {
    // In batch mode, queue the effect if not already pending
    if not(is_pending(effect.id)) {
      reactive_context.pending_ids.push(effect.id)
      reactive_context.pending_effects.push(effect)
    }
  } else {
    // Run immediately
    (effect.run)()
  }
}

///|
/// Flush all pending effects
fn flush_effects() -> Unit {
  while reactive_context.pending_effects.length() > 0 {
    let effect = reactive_context.pending_effects.remove(0)
    let _ = reactive_context.pending_ids.remove(0)
    (effect.run)()
  }
}

///|
/// Check if we're currently inside a batch
pub fn is_batching() -> Bool {
  reactive_context.batch_depth > 0
}

///|
/// Register a cleanup function to run when the current scope disposes.
/// Works in:
/// - Effects: cleanup runs before effect re-runs or when effect disposes
/// - Components: cleanup runs when component unmounts
/// (Solid.js style - can be called directly in component body)
/// ```mbt check
/// test {
///   let count = @signal.signal(0)
///   let log : Array[String] = []
///   let dispose = @signal.render_effect(fn() {
///     let v = count.get()
///     log.push("run:" + v.to_string())
///     @signal.on_cleanup(fn() { log.push("cleanup:" + v.to_string()) })
///   })
///   count.set(1)
///   dispose()
///   inspect(
///     log,
///     content=(
///       #|["run:0", "cleanup:0", "run:1", "cleanup:1"]
///     ),
///   )
/// }
/// ```
pub fn on_cleanup(cleanup : () -> Unit) -> Unit {
  // First priority: effect-level cleanup tracking
  match reactive_context.current_cleanups {
    Some(cleanups) => cleanups.push(cleanup)
    None =>
      // Second priority: owner-level cleanup (for component body)
      match reactive_context.current_owner {
        Some(owner) => owner.cleanups.push(cleanup)
        None => () // No tracking scope, ignore
      }
  }
}

///|
/// Set the current cleanup array (used internally by effect)
pub fn set_current_cleanups(
  cleanups : Array[() -> Unit]?,
) -> Array[() -> Unit]? {
  let prev = reactive_context.current_cleanups
  reactive_context.current_cleanups = cleanups
  prev
}

///|
/// Run a function with cleanup tracking enabled
pub fn[T] run_with_cleanup_tracking(
  cleanups : Array[() -> Unit],
  f : () -> T,
) -> T {
  let prev = set_current_cleanups(Some(cleanups))
  let result = f()
  reactive_context.current_cleanups = prev
  result
}

// ============================================================================
// Owner-based scope management (Solid.js style)
// ============================================================================

///|
/// Get the current owner (if any)
pub fn get_owner() -> Owner? {
  reactive_context.current_owner
}

///|
/// Run a function with a specific owner as current
pub fn[T] run_with_owner(owner : Owner, f : () -> T) -> T {
  let prev = reactive_context.current_owner
  reactive_context.current_owner = Some(owner)
  let result = f()
  reactive_context.current_owner = prev
  result
}

///|
/// Create a new reactive root scope.
/// The function receives a dispose callback that cleans up all effects.
/// Returns the result of the function.
/// ```mbt check
/// test {
///   let count = @signal.signal(0)
///   let log : Array[Int] = []
///   let result = @signal.create_root(fn(dispose) {
///     let _ = @signal.render_effect(fn() { log.push(count.get()) })
///     dispose // Return dispose function
///   })
///   count.set(1)
///   result() // Dispose the root
///   count.set(2) // Won't trigger effect
///   inspect(log, content="[0, 1]")
/// }
/// ```
pub fn[T] create_root(f : (() -> Unit) -> T) -> T {
  let owner = Owner::new(reactive_context.current_owner)
  let dispose = fn() { owner.dispose() }
  run_with_owner(owner, fn() { f(dispose) })
}

///|
/// Create a reactive root and return both result and dispose function
pub fn[T] create_root_with_dispose(f : () -> T) -> (T, () -> Unit) {
  let owner = Owner::new(reactive_context.current_owner)
  let dispose = fn() { owner.dispose() }
  let result = run_with_owner(owner, f)
  (result, dispose)
}

///|
/// Register a disposer with the current owner
/// Called internally by effect() to register its dispose function
pub fn register_disposer(disposer : () -> Unit) -> Unit {
  match reactive_context.current_owner {
    Some(owner) => owner.disposers.push(disposer)
    None => () // No owner, disposer won't be tracked
  }
}

///|
/// Register a cleanup with the current owner (alternative to onCleanup in effect)
pub fn register_owner_cleanup(cleanup : () -> Unit) -> Unit {
  match reactive_context.current_owner {
    Some(owner) => owner.cleanups.push(cleanup)
    None => () // No owner, cleanup won't be tracked
  }
}

///|
/// Check if currently inside an owner scope
pub fn has_owner() -> Bool {
  reactive_context.current_owner is Some(_)
}

///|
/// Run a function with a captured parent owner context (if any)
/// This is useful for rendering child components that need to inherit the parent's owner.
/// If captured_owner is Some, runs with that owner as context.
/// If captured_owner is None, runs directly without owner context.
pub fn[T] with_parent_owner(captured_owner : Owner?, f : () -> T) -> T {
  match captured_owner {
    Some(parent) => run_with_owner(parent, f)
    None => f()
  }
}
