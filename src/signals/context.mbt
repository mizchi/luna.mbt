///| Reactive Context - Tracks current running effect for auto-subscription

///|
/// Effect wrapper with unique ID for deduplication
pub struct EffectRunner {
  id : Int
  run : () -> Unit
}

///|
/// Global effect ID counter
let effect_id_counter : Ref[Int] = { val: 0 }

///|
/// Generate a new unique effect ID
pub fn new_effect_id() -> Int {
  let id = effect_id_counter.val
  effect_id_counter.val = id + 1
  id
}

///|
/// Reactive context - tracks currently running computation
priv struct ReactiveContext {
  mut current_subscriber : EffectRunner?
  mut current_cleanups : Array[() -> Unit]?
  mut batch_depth : Int
  pending_effects : Array[EffectRunner]
  pending_ids : Array[Int]
}

///|
/// Global reactive context instance
let reactive_context : ReactiveContext = {
  current_subscriber: None,
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

///| Run a function with the given subscriber as current

///|
/// This enables auto-tracking of signal dependencies
pub fn[T] run_with_subscriber(subscriber : EffectRunner, f : () -> T) -> T {
  let prev = reactive_context.current_subscriber
  reactive_context.current_subscriber = Some(subscriber)
  let result = f()
  reactive_context.current_subscriber = prev
  result
}

///|
/// Run a function without tracking (useful for avoiding circular deps)
pub fn[T] untracked(f : () -> T) -> T {
  let prev = reactive_context.current_subscriber
  reactive_context.current_subscriber = None
  let result = f()
  reactive_context.current_subscriber = prev
  result
}

///|
/// Start a batch update - effects won't run until batch ends
pub fn batch_start() -> Unit {
  reactive_context.batch_depth = reactive_context.batch_depth + 1
}

///|
/// End a batch update - run all pending effects
pub fn batch_end() -> Unit {
  reactive_context.batch_depth = reactive_context.batch_depth - 1
  if reactive_context.batch_depth == 0 {
    flush_effects()
  }
}

///|
/// Run a function in a batch - all signal updates are batched
pub fn[T] batch(f : () -> T) -> T {
  batch_start()
  let result = f()
  batch_end()
  result
}

///|
/// Check if an effect ID is already pending
fn is_pending(id : Int) -> Bool {
  for i = 0; i < reactive_context.pending_ids.length(); i = i + 1 {
    if reactive_context.pending_ids[i] == id {
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

///| Register a cleanup function to run when the current effect re-runs or disposes

///|
/// Must be called inside an effect
pub fn onCleanup(cleanup : () -> Unit) -> Unit {
  match reactive_context.current_cleanups {
    Some(cleanups) => cleanups.push(cleanup)
    None => () // Not inside an effect with cleanup tracking, ignore
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
