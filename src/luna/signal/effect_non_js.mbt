// Non-JS Target - Fallback for wasm/native (run immediately)

///|
/// Queue a microtask - fallback: run immediately for non-JS targets
fn queue_microtask(f : () -> Unit) -> Unit {
  f()
}
