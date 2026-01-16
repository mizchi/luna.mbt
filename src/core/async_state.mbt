// AsyncState - Environment-agnostic async state representation

///|
/// Async state representation - environment independent
pub(all) enum AsyncState[T] {
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
