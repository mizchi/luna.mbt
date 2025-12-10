///| JS API - Generic wrappers using Any type for JavaScript consumption

///|
/// Opaque type for JS interop - represents any JS value
#external
pub type Any

// Signal operations with Any

///|
/// Create a signal with any value
pub fn create_signal(initial : Any) -> @signal.Signal[Any] {
  @signal.signal(initial)
}

///|
/// Get signal value
pub fn get(sig : @signal.Signal[Any]) -> Any {
  sig.get()
}

///|
/// Set signal value
pub fn set(sig : @signal.Signal[Any], value : Any) -> Unit {
  sig.set(value)
}

///|
/// Update signal with function
pub fn update(sig : @signal.Signal[Any], f : (Any) -> Any) -> Unit {
  sig.update(f)
}

///|
/// Peek signal value without tracking
pub fn peek(sig : @signal.Signal[Any]) -> Any {
  sig.peek()
}

///|
/// Subscribe to signal changes
pub fn subscribe(sig : @signal.Signal[Any], callback : (Any) -> Unit) -> () -> Unit {
  @signal.on(sig, callback)
}

///|
/// Map signal to derived value
pub fn map(sig : @signal.Signal[Any], f : (Any) -> Any) -> () -> Any {
  sig.map(f)
}

///|
/// Create a memo (computed value)
pub fn create_memo(compute : () -> Any) -> () -> Any {
  @signal.memo(compute)
}

///|
/// Combine two signals
pub fn combine(
  a : @signal.Signal[Any],
  b : @signal.Signal[Any],
  f : (Any, Any) -> Any,
) -> () -> Any {
  @signal.combine2(a, b, f)
}

///|
/// Create an effect
pub fn effect(fn_ : () -> Unit) -> () -> Unit {
  @signal.effect(fn_)
}

///|
/// Start batch updates
pub fn batch_start() -> Unit {
  @signal.batch_start()
}

///|
/// End batch updates
pub fn batch_end() -> Unit {
  @signal.batch_end()
}

///|
/// Run function without tracking dependencies
pub fn run_untracked(f : () -> Any) -> Any {
  @signal.untracked(f)
}

///|
/// Run a function in a batch - all signal updates are batched
pub fn batch(f : () -> Any) -> Any {
  @signal.batch(f)
}

///|
/// Register a cleanup function inside an effect
pub fn on_cleanup(cleanup : () -> Unit) -> Unit {
  @signal.on_cleanup(cleanup)
}

// ============================================================================
// Owner-based scope management (Solid.js style)
// ============================================================================

///|
/// Opaque Owner type for JS
pub struct JsOwner(@signal.Owner)

///|
/// Create a new reactive root scope
/// The function receives a dispose callback
pub fn create_root(f : (() -> Unit) -> Any) -> Any {
  @signal.create_root(f)
}

///|
/// Get the current owner (if any)
pub fn get_owner() -> JsOwner? {
  match @signal.get_owner() {
    Some(owner) => Some(JsOwner(owner))
    None => None
  }
}

///|
/// Run a function with a specific owner as current
pub fn run_with_owner(owner : JsOwner, f : () -> Any) -> Any {
  @signal.run_with_owner(owner.0, f)
}

///|
/// Check if currently inside an owner scope
pub fn has_owner() -> Bool {
  @signal.has_owner()
}

///|
/// Run a function once (Solid.js style onMount)
pub fn on_mount(fn_ : () -> Unit) -> Unit {
  @signal.on_mount(fn_)
}
