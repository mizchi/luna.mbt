// Effect - Reactive side effect that auto-tracks signal dependencies

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
  let cleanups : Array[() -> Unit] = []

  // Wrap function to enable signal's on_cleanup tracking
  let wrapped_fn = fn() {
    // Run cleanups from previous run
    for i = cleanups.length() - 1; i >= 0; i = i - 1 {
      cleanups[i]()
    }
    cleanups.clear()
    // Run with cleanup tracking enabled
    run_with_cleanup_tracking(cleanups, fn_)
  }

  let dispose = core_render_effect(wrapped_fn)

  // Create dispose function that also runs cleanups
  let full_dispose = fn() {
    // Run final cleanups
    for i = cleanups.length() - 1; i >= 0; i = i - 1 {
      cleanups[i]()
    }
    cleanups.clear()
    dispose()
  }

  // Register with current owner if present
  register_disposer(full_dispose)
  full_dispose
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
  let active = Ref::new(true)
  let dispose_ref : Ref[(() -> Unit)?] = Ref::new(None)
  let cleanups : Array[() -> Unit] = []

  // Wrap function to enable signal's on_cleanup tracking
  let wrapped_fn = fn() {
    // Run cleanups from previous run
    for i = cleanups.length() - 1; i >= 0; i = i - 1 {
      cleanups[i]()
    }
    cleanups.clear()
    // Run with cleanup tracking enabled
    run_with_cleanup_tracking(cleanups, fn_)
  }

  // Defer initial run via microtask (like Solid.js createEffect)
  queue_microtask(fn() {
    if active.val {
      dispose_ref.val = Some(core_render_effect(wrapped_fn))
    }
  })

  // Create dispose function
  let dispose = fn() {
    active.val = false
    // Run final cleanups
    for i = cleanups.length() - 1; i >= 0; i = i - 1 {
      cleanups[i]()
    }
    cleanups.clear()
    match dispose_ref.val {
      Some(d) => d()
      None => ()
    }
  }

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
