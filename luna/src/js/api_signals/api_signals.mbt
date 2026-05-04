// JS Signals API - minimal wrapper for tree-shake friendly entrypoint

///|
/// Opaque type for JS interop - represents any JS value
#external
pub type Any

// Signal operations with Any

///|
/// Create a signal with any value
pub fn create_signal(initial : Any) -> @resource.Signal[Any] {
  @resource.signal(initial)
}

///|
/// Get signal value
pub fn get(sig : @resource.Signal[Any]) -> Any {
  sig.get()
}

///|
/// Set signal value
pub fn set(sig : @resource.Signal[Any], value : Any) -> Unit {
  sig.set(value)
}

///|
/// Update signal with function
pub fn update(sig : @resource.Signal[Any], f : (Any) -> Any) -> Unit {
  sig.update(f)
}

///|
/// Peek signal value without tracking
pub fn peek(sig : @resource.Signal[Any]) -> Any {
  sig.peek()
}

///|
/// Subscribe to signal changes
pub fn subscribe(
  sig : @resource.Signal[Any],
  callback : (Any) -> Unit,
) -> () -> Unit {
  @resource.on(sig, callback)
}

///|
/// Map signal to derived value
pub fn map(sig : @resource.Signal[Any], f : (Any) -> Any) -> () -> Any {
  @resource.sig_map(sig, f)
}

///|
/// Create a memo (computed value)
pub fn create_memo(compute : () -> Any) -> () -> Any {
  @resource.memo(compute)
}

///|
/// Combine two signals
pub fn combine(
  a : @resource.Signal[Any],
  b : @resource.Signal[Any],
  f : (Any, Any) -> Any,
) -> () -> Any {
  @resource.combine2(a, b, f)
}

///|
/// Create an effect (deferred execution via microtask, like Solid.js createEffect)
pub fn effect(fn_ : () -> Unit) -> () -> Unit {
  @resource.effect(fn_)
}

///|
/// Create a render effect (immediate execution, like Solid.js createRenderEffect)
pub fn render_effect(fn_ : () -> Unit) -> () -> Unit {
  @resource.render_effect(fn_)
}

///|
/// Start batch updates
pub fn batch_start() -> Unit {
  @resource.batch_start()
}

///|
/// End batch updates
pub fn batch_end() -> Unit {
  @resource.batch_end()
}

///|
/// Run function without tracking dependencies
pub fn run_untracked(f : () -> Any) -> Any {
  @resource.untracked(f)
}

///|
/// Run a function in a batch - all signal updates are batched
pub fn batch(f : () -> Any) -> Any {
  @resource.batch(f)
}

///|
/// Register a cleanup function inside an effect
pub fn on_cleanup(cleanup : () -> Unit) -> Unit {
  @resource.on_cleanup(cleanup)
}

// ============================================================================
// Owner-based scope management (Solid.js style)
// ============================================================================

///|
/// Opaque Owner type for JS
pub struct JsOwner(@resource.Owner)

///|
/// Create a new reactive root scope
/// The function receives a dispose callback
pub fn create_root(f : (() -> Unit) -> Any) -> Any {
  @resource.create_root(f)
}

///|
/// Get the current owner (if any)
pub fn get_owner() -> JsOwner? {
  match @resource.get_owner() {
    Some(owner) => Some(JsOwner(owner))
    None => None
  }
}

///|
/// Run a function with a specific owner as current
pub fn run_with_owner(owner : JsOwner, f : () -> Any) -> Any {
  @resource.run_with_owner(owner.0, f)
}

///|
/// Check if currently inside an owner scope
pub fn has_owner() -> Bool {
  @resource.has_owner()
}

///|
/// Queue a microtask (runs after current synchronous execution)
extern "js" fn queue_microtask(f : () -> Unit) -> Unit =
  #| (f) => queueMicrotask(f)

///|
/// Run a function once (Solid.js style onMount)
/// The callback is deferred via microtask to run after DOM is created and refs are bound.
/// onCleanup registered inside will run when the owner is disposed (component unmounts).
pub fn on_mount(fn_ : () -> Unit) -> Unit {
  // Capture current owner for later use
  let captured_owner = @resource.get_owner()

  // Queue microtask to run after current synchronous execution.
  // This ensures refs are bound before onMount runs.
  queue_microtask(fn() {
    match captured_owner {
      Some(owner) =>
        // Run with owner context so cleanup registration works
        @resource.run_with_owner(owner, fn() {
          // Run untracked (no dependency tracking)
          @resource.untracked(fn() {
            // Set up cleanup tracking
            let mount_cleanups : Array[() -> Unit] = []
            @resource.run_with_cleanup_tracking(mount_cleanups, fn_)
            // Transfer cleanups to owner so they run on unmount
            for cleanup in mount_cleanups {
              @resource.register_owner_cleanup(cleanup)
            }
          })
        })
      None =>
        // No owner - just run untracked
        @resource.untracked(fn_)
    }
  })
}
