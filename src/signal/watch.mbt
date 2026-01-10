// Watch - Advanced signal utilities
// Watch a computed expression and run callback when it changes
//

///|
/// Watch a computed expression and run callback when it changes.
/// Returns a dispose function.
/// The callback receives (newValue, oldValue).
/// ```mbt check
/// test {
///   let count = @signal.signal(0)
///   let changes : Array[(Int, Int)] = []
///   let dispose = @signal.watch(fn() { count.get() }, fn(new_val, old_val) {
///     changes.push((new_val, old_val))
///   })
///   count.set(1)
///   count.set(2)
///   count.set(2) // Same value, no callback
///   count.set(3)
///   dispose()
///   inspect(changes, content="[(1, 0), (2, 1), (3, 2)]")
/// }
/// ```
pub fn[T : Eq] watch(source : () -> T, callback : (T, T) -> Unit) -> () -> Unit {
  let prev_value : Ref[T?] = Ref::new(None)
  render_effect(fn() {
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
/// Watch with immediate execution (runs callback on first value too).
/// The callback receives (newValue, oldValue?) where oldValue is None on first run.
/// ```mbt check
/// test {
///   let count = @signal.signal(5)
///   let log : Array[String] = []
///   let dispose = @signal.watch_immediate(fn() { count.get() }, fn(
///     new_val,
///     old_val,
///   ) {
///     match old_val {
///       Some(old) => log.push(old.to_string() + "->" + new_val.to_string())
///       None => log.push("init:" + new_val.to_string())
///     }
///   })
///   count.set(10)
///   dispose()
///   inspect(
///     log,
///     content=(
///       #|["init:5", "5->10"]
///     ),
///   )
/// }
/// ```
pub fn[T : Eq] watch_immediate(
  source : () -> T,
  callback : (T, T?) -> Unit,
) -> () -> Unit {
  let prev_value : Ref[T?] = Ref::new(None)
  render_effect(fn() {
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

///|
/// Create a signal that holds the previous value of another signal.
/// Returns a getter function for the previous value (None on first read).
/// ```mbt check
/// test {
///   let count = @signal.signal(1)
///   let prev = @signal.previous(count)
///   inspect(prev(), content="None") // No previous value yet
///   count.set(2)
///   inspect(prev(), content="Some(1)")
///   count.set(3)
///   inspect(prev(), content="Some(2)")
/// }
/// ```
pub fn[T] previous(sig : Signal[T]) -> () -> T? {
  let prev : Ref[T?] = Ref::new(None)
  let current : Ref[T?] = Ref::new(None)
  let _ = render_effect(fn() {
    let new_val = sig.get()
    prev.val = current.val
    current.val = Some(new_val)
  })
  fn() { prev.val }
}

///|
/// Create a signal that holds the previous value with initial value.
/// Unlike `previous`, this returns a plain T instead of T?.
/// ```mbt check
/// test {
///   let count = @signal.signal(10)
///   let prev = @signal.previous_with_initial(count, 0)
///   inspect(prev(), content="0") // Initial value
///   count.set(20)
///   inspect(prev(), content="10")
///   count.set(30)
///   inspect(prev(), content="20")
/// }
/// ```
pub fn[T] previous_with_initial(sig : Signal[T], initial : T) -> () -> T {
  let prev : Ref[T] = Ref::new(initial)
  let current : Ref[T?] = Ref::new(None)
  let _ = render_effect(fn() {
    let new_val = sig.get()
    match current.val {
      Some(curr) => prev.val = curr
      None => ()
    }
    current.val = Some(new_val)
  })
  fn() { prev.val }
}
