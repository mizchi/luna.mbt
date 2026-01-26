// Resource - Signal-based async value container
//
// Uses @ui.AsyncState for state representation

///|
/// Resource - Async value container with Signal integration
/// Environment-agnostic: uses callbacks instead of Promise/async directly
pub struct Resource[T] {
  /// The reactive state
  state : Signal[@ui.AsyncState[T]]
  /// Trigger refetch
  priv refetch_ : () -> Unit
}

///|
/// Get current async state (reactive)
pub fn[T] Resource::get(self : Resource[T]) -> @ui.AsyncState[T] {
  self.state.get()
}

///|
/// Peek current state without tracking
pub fn[T] Resource::peek(self : Resource[T]) -> @ui.AsyncState[T] {
  self.state.peek()
}

///|
/// Check if currently pending
pub fn[T] Resource::is_pending(self : Resource[T]) -> Bool {
  self.state.peek().is_pending()
}

///|
/// Check if successfully loaded
pub fn[T] Resource::is_success(self : Resource[T]) -> Bool {
  self.state.peek().is_success()
}

///|
/// Check if failed
pub fn[T] Resource::is_failure(self : Resource[T]) -> Bool {
  self.state.peek().is_failure()
}

///|
/// Get value if success
pub fn[T] Resource::value(self : Resource[T]) -> T? {
  self.state.peek().value()
}

///|
/// Get error if failure
pub fn[T] Resource::error(self : Resource[T]) -> String? {
  self.state.peek().error()
}

///|
/// Trigger refetch
pub fn[T] Resource::refetch(self : Resource[T]) -> Unit {
  (self.refetch_)()
}

///|
/// Create a Resource from a callback-based fetcher
/// The fetcher receives (resolve, reject) callbacks
/// This is environment-agnostic - the actual async execution
/// is handled by the caller
pub fn[T] resource(
  fetcher : ((T) -> Unit, (String) -> Unit) -> Unit,
) -> Resource[T] {
  let state : Signal[@ui.AsyncState[T]] = signal(@ui.Pending)
  let resolve_ = fn(value : T) { state.set(@ui.Success(value)) }
  let reject_ = fn(error : String) { state.set(@ui.Failure(error)) }
  fn do_fetch() {
    state.set(@ui.Pending)
    fetcher(resolve_, reject_)
  }

  // Initial fetch
  do_fetch()
  { state, refetch_: do_fetch }
}

///|
/// Create a Resource with initial value (already resolved)
pub fn[T] resource_resolved(value : T) -> Resource[T] {
  let state : Signal[@ui.AsyncState[T]] = signal(@ui.Success(value))
  { state, refetch_: fn() { () } } // No-op for pre-resolved
}

///|
/// Create a Resource with initial error (already rejected)
pub fn[T] resource_rejected(error : String) -> Resource[T] {
  let state : Signal[@ui.AsyncState[T]] = signal(@ui.Failure(error))
  { state, refetch_: fn() { () } } // No-op for pre-rejected
}

///|
/// Create a deferred Resource (starts pending, resolve/reject manually)
pub fn[T] deferred() -> (Resource[T], (T) -> Unit, (String) -> Unit) {
  let state : Signal[@ui.AsyncState[T]] = signal(@ui.Pending)
  let resolve = fn(value : T) { state.set(@ui.Success(value)) }
  let reject = fn(error : String) { state.set(@ui.Failure(error)) }
  let res : Resource[T] = { state, refetch_: fn() { state.set(@ui.Pending) } }
  (res, resolve, reject)
}
