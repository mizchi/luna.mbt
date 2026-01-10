// Effect - Reactive side effect that auto-tracks signal dependencies
//

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
    cleanups[i]()
  }
  cleanups.clear()
}

///|
/// Create an effect runner with cleanup and subscription tracking
/// Internal helper used by both effect and render_effect
fn create_effect_runner(
  fn_ : () -> Unit,
  state : EffectState,
) -> (EffectRunner, () -> Unit) {
  let id = new_effect_id()
  let runner_ref : Ref[EffectRunner?] = Ref::new(None)
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
  let dispose = fn() {
    state.active = false
    run_cleanups(state.cleanups)
  }
  (runner, dispose)
}

///|
/// Create an effect that runs immediately and re-runs when dependencies change.
/// (Solid.js style createRenderEffect - synchronous execution)
/// Returns a dispose function to stop the effect.
/// Supports `on_cleanup()` calls inside the effect.
/// ```mbt check
/// test {
///   let count = @signal.signal(0)
///   let log : Array[String] = []
///   let dispose = @signal.render_effect(fn() {
///     log.push("count=" + count.get().to_string())
///   })
///   log.push("after-effect")
///   count.set(1)
///   dispose()
///   count.set(2) // Won't trigger effect
///   inspect(
///     log,
///     content=(
///       #|["count=0", "after-effect", "count=1"]
///     ),
///   )
/// }
/// ```
pub fn render_effect(fn_ : () -> Unit) -> () -> Unit {
  let state : EffectState = { active: true, cleanups: [] }
  let (runner, dispose) = create_effect_runner(fn_, state)

  // Run immediately (synchronous)
  (runner.run)()

  // Register with current owner if present
  register_disposer(dispose)
  dispose
}

///|
/// Create an effect that is deferred until after rendering completes.
/// (Solid.js style createEffect - deferred execution via microtask)
/// Returns a dispose function to stop the effect.
/// Unlike `render_effect`, this runs asynchronously via microtask queue.
/// ```mbt nocheck
/// // Note: effect() uses microtasks, so testing requires async handling
/// let count = @signal.signal(0)
/// let _ = @signal.effect(fn() {
/// println("count changed to: " + count.get().to_string())
/// })
/// count.set(1) // Effect will run after current task completes
/// ```
pub fn effect(fn_ : () -> Unit) -> () -> Unit {
  let state : EffectState = { active: true, cleanups: [] }
  let (runner, dispose) = create_effect_runner(fn_, state)

  // Defer initial run via microtask (like Solid.js createEffect)
  queue_microtask(fn() { if state.active { (runner.run)() } })

  // Register with current owner if present
  register_disposer(dispose)
  dispose
}

///|
/// Create an effect that only runs when condition is true.
/// Uses `render_effect` for synchronous execution.
/// ```mbt check
/// test {
///   let enabled = @signal.signal(false)
///   let count = @signal.signal(0)
///   let log : Array[Int] = []
///   let _ = @signal.effect_when(fn() { enabled.get() }, fn() {
///     log.push(count.get())
///   })
///   count.set(1) // Won't run, enabled is false
///   enabled.set(true)
///   count.set(2)
///   inspect(log, content="[1, 2]")
/// }
/// ```
pub fn effect_when(condition : () -> Bool, fn_ : () -> Unit) -> () -> Unit {
  render_effect(fn() { if condition() { fn_() } })
}

///|
/// Create a one-time effect that disposes itself after first run.
/// Useful for initialization logic that should only run once.
/// ```mbt check
/// test {
///   let count = @signal.signal(0)
///   let runs : Ref[Int] = Ref::new(0)
///   @signal.effect_once(fn() {
///     let _ = count.get()
///     runs.val = runs.val + 1
///   })
///   count.set(1)
///   count.set(2)
///   inspect(runs.val, content="2")
/// }
/// ```
pub fn effect_once(fn_ : () -> Unit) -> Unit {
  let dispose : Ref[(() -> Unit)?] = Ref::new(None)
  dispose.val = Some(
    render_effect(fn() {
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
/// Run a function once after mount (Solid.js style onMount).
/// The function runs without tracking dependencies.
/// Cleanup registered via `on_cleanup` inside will run when owner is disposed.
/// ```mbt check
/// test {
///   let count = @signal.signal(0)
///   let runs : Ref[Int] = Ref::new(0)
///   @signal.on_mount(fn() {
///     let _ = count.get() // This read won't create subscription
///     runs.val = runs.val + 1
///   })
///   count.set(1)
///   count.set(2)
///   // on_mount only ran once, signal changes don't trigger re-run
///   inspect(runs.val, content="1")
/// }
/// ```
pub fn on_mount(fn_ : () -> Unit) -> Unit {
  // Run untracked so we don't create any subscriptions
  untracked(fn_)
}
