///| JS API - Generic wrappers using Any type for JavaScript consumption

///|
/// Opaque type for JS interop - represents any JS value
#external
pub type Any

// Signal operations with Any

///|
/// Create a signal with any value
pub fn create_signal(initial : Any) -> Signal[Any] {
  signal(initial)
}

///|
/// Get signal value
pub fn get(sig : Signal[Any]) -> Any {
  sig.get()
}

///|
/// Set signal value
pub fn set(sig : Signal[Any], value : Any) -> Unit {
  sig.set(value)
}

///|
/// Update signal with function
pub fn update(sig : Signal[Any], f : (Any) -> Any) -> Unit {
  sig.update(f)
}

///|
/// Peek signal value without tracking
pub fn peek(sig : Signal[Any]) -> Any {
  sig.peek()
}

///|
/// Subscribe to signal changes
pub fn subscribe(sig : Signal[Any], callback : (Any) -> Unit) -> () -> Unit {
  on(sig, callback)
}

///|
/// Map signal to derived value
pub fn map(sig : Signal[Any], f : (Any) -> Any) -> () -> Any {
  sig.map(f)
}

///|
/// Create a memo (computed value)
pub fn create_memo(compute : () -> Any) -> () -> Any {
  memo(compute)
}

///|
/// Combine two signals
pub fn combine(
  a : Signal[Any],
  b : Signal[Any],
  f : (Any, Any) -> Any,
) -> () -> Any {
  combine2(a, b, f)
}

///|
/// Run function without tracking dependencies
pub fn run_untracked(f : () -> Any) -> Any {
  untracked(f)
}
