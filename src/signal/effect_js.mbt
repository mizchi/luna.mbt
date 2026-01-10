// JS Target - Uses native queueMicrotask

///|
/// Queue a microtask (runs after current synchronous execution)
extern "js" fn queue_microtask(f : () -> Unit) -> Unit =
  #| (f) => queueMicrotask(f)
