///| Async Resource - Environment-agnostic async state management
///|
///| This module provides a callback-based async primitive that can be
///| integrated with any async runtime (JS Promise, native async, etc.)

///|
/// Async state representation - environment independent
pub enum AsyncState[T] {
  Pending
  Success(T)
  Failure(String)
}

///|
/// Check if state is pending
pub fn[T] AsyncState::is_pending(self : AsyncState[T]) -> Bool {
  match self {
    Pending => true
    _ => false
  }
}

///|
/// Check if state is success
pub fn[T] AsyncState::is_success(self : AsyncState[T]) -> Bool {
  match self {
    Success(_) => true
    _ => false
  }
}

///|
/// Check if state is failure
pub fn[T] AsyncState::is_failure(self : AsyncState[T]) -> Bool {
  match self {
    Failure(_) => true
    _ => false
  }
}

///|
/// Get value if success, None otherwise
pub fn[T] AsyncState::value(self : AsyncState[T]) -> T? {
  match self {
    Success(v) => Some(v)
    _ => None
  }
}

///|
/// Get error if failure, None otherwise
pub fn[T] AsyncState::error(self : AsyncState[T]) -> String? {
  match self {
    Failure(e) => Some(e)
    _ => None
  }
}

///|
/// Resource - Async value container with Signal integration
/// Environment-agnostic: uses callbacks instead of Promise/async directly
pub struct Resource[T] {
  /// The reactive state
  state : Signal[AsyncState[T]]
  /// Trigger refetch
  priv refetch_ : () -> Unit
}

///|
/// Get current async state (reactive)
pub fn[T] Resource::get(self : Resource[T]) -> AsyncState[T] {
  self.state.get()
}

///|
/// Peek current state without tracking
pub fn[T] Resource::peek(self : Resource[T]) -> AsyncState[T] {
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
  fetcher : ((T) -> Unit, (String) -> Unit) -> Unit
) -> Resource[T] {
  let state : Signal[AsyncState[T]] = signal(Pending)

  let resolve_ = fn(value : T) {
    state.set(Success(value))
  }

  let reject_ = fn(error : String) {
    state.set(Failure(error))
  }

  fn do_fetch() {
    state.set(Pending)
    fetcher(resolve_, reject_)
  }

  // Initial fetch
  do_fetch()

  { state, refetch_: do_fetch }
}

///|
/// Create a Resource with initial value (already resolved)
pub fn[T] resource_resolved(value : T) -> Resource[T] {
  let state : Signal[AsyncState[T]] = signal(Success(value))
  { state, refetch_: fn() { () } } // No-op for pre-resolved
}

///|
/// Create a Resource with initial error (already rejected)
pub fn[T] resource_rejected(error : String) -> Resource[T] {
  let state : Signal[AsyncState[T]] = signal(Failure(error))
  { state, refetch_: fn() { () } } // No-op for pre-rejected
}

///|
/// Create a deferred Resource (starts pending, resolve/reject manually)
pub fn[T] deferred() -> (Resource[T], (T) -> Unit, (String) -> Unit) {
  let state : Signal[AsyncState[T]] = signal(Pending)

  let resolve = fn(value : T) { state.set(Success(value)) }
  let reject = fn(error : String) { state.set(Failure(error)) }

  let res : Resource[T] = { state, refetch_: fn() { state.set(Pending) } }

  (res, resolve, reject)
}
