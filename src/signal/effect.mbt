///| Effect - Reactive side effect that auto-tracks signal dependencies

///|
/// Effect state
priv struct EffectState {
  mut active : Bool
  cleanups : Array[() -> Unit]
}

///|
/// Run all cleanup functions
fn run_cleanups(cleanups : Array[() -> Unit]) -> Unit {
  // Run in reverse order (LIFO)
  for i = cleanups.length() - 1; i >= 0; i = i - 1 {
    (cleanups[i])()
  }
  cleanups.clear()
}

///| Create an effect that runs immediately and re-runs when dependencies change

///| Returns a dispose function to stop the effect

///|
/// Supports onCleanup() calls inside the effect
/// If inside an owner scope, the effect is automatically registered for disposal
pub fn effect(fn_ : () -> Unit) -> () -> Unit {
  let state : EffectState = { active: true, cleanups: [] }
  let id = new_effect_id()

  // Create the EffectRunner
  let runner_ref : Ref[EffectRunner?] = { val: None }
  fn run_effect() -> Unit {
    if not(state.active) {
      return
    }
    // Run previous cleanups before re-running
    run_cleanups(state.cleanups)
    // Run the effect function with cleanup tracking and subscriber
    match runner_ref.val {
      Some(runner) =>
        run_with_subscriber(runner, fn() {
          run_with_cleanup_tracking(state.cleanups, fn_)
        })
      None => ()
    }
  }

  let runner : EffectRunner = { id, run: run_effect }
  runner_ref.val = Some(runner)

  // Run immediately
  run_effect()

  // Create dispose function
  let dispose = fn() {
    state.active = false
    run_cleanups(state.cleanups)
  }

  // Register with current owner if present
  register_disposer(dispose)

  dispose
}

///| Create an effect with cleanup function (legacy API)

///| The effect function returns a cleanup function that runs before re-execution

///|
/// Prefer using effect() with onCleanup() instead
pub fn effect_with_cleanup(fn_ : () -> (() -> Unit)?) -> () -> Unit {
  effect(fn() {
    match fn_() {
      Some(cleanup) => on_cleanup(cleanup)
      None => ()
    }
  })
}

///|
/// Create an effect that only runs when condition is true
pub fn effect_when(condition : () -> Bool, fn_ : () -> Unit) -> () -> Unit {
  effect(fn() { if condition() { fn_() } })
}

///|
/// Create a one-time effect that disposes itself after first run
pub fn effect_once(fn_ : () -> Unit) -> Unit {
  let dispose : Ref[(() -> Unit)?] = { val: None }
  dispose.val = Some(
    effect(fn() {
      fn_()
      // Dispose after first run
      match dispose.val {
        Some(d) => d()
        None => ()
      }
    }),
  )
}

///|
/// Run a function once after mount (Solid.js style onMount)
/// The function runs without tracking dependencies
/// Cleanup registered via onCleanup inside will run when owner is disposed
pub fn on_mount(fn_ : () -> Unit) -> Unit {
  // Run untracked so we don't create any subscriptions
  untracked(fn_)
}
