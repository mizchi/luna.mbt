///| Watch - Advanced signal utilities

///| Watch a computed expression and run callback when it changes

///|
/// Returns a dispose function
pub fn[T : Eq] watch(source : () -> T, callback : (T, T) -> Unit) -> () -> Unit {
  let prev_value : Ref[T?] = { val: None }
  effect(fn() {
    let new_value = source()
    match prev_value.val {
      Some(old) =>
        if old != new_value {
          callback(new_value, old)
          prev_value.val = Some(new_value)
        }
      None => prev_value.val = Some(new_value)
    }
  })
}

///|
/// Watch with immediate execution (runs callback on first value too)
pub fn[T : Eq] watch_immediate(
  source : () -> T,
  callback : (T, T?) -> Unit,
) -> () -> Unit {
  let prev_value : Ref[T?] = { val: None }
  effect(fn() {
    let new_value = source()
    match prev_value.val {
      Some(old) =>
        if old != new_value {
          callback(new_value, Some(old))
          prev_value.val = Some(new_value)
        }
      None => {
        callback(new_value, None)
        prev_value.val = Some(new_value)
      }
    }
  })
}

///| Create a signal that holds the previous value of another signal

///|
/// Returns a getter function for the previous value
pub fn[T] previous(sig : Signal[T]) -> () -> T? {
  let prev : Ref[T?] = { val: None }
  let current : Ref[T?] = { val: None }
  let _ = effect(fn() {
    let new_val = sig.get()
    prev.val = current.val
    current.val = Some(new_val)
  })
  fn() { prev.val }
}

///|
/// Create a signal that holds the previous value with initial value
pub fn[T] previous_with_initial(sig : Signal[T], initial : T) -> () -> T {
  let prev : Ref[T] = { val: initial }
  let current : Ref[T?] = { val: None }
  let _ = effect(fn() {
    let new_val = sig.get()
    match current.val {
      Some(curr) => prev.val = curr
      None => ()
    }
    current.val = Some(new_val)
  })
  fn() { prev.val }
}
