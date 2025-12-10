///| Signal Combinators - Transform and combine signals

///| Map a signal's value through a function

///|
/// Returns a getter function (like memo)
pub fn[T, U] Signal::map(self : Signal[T], f : (T) -> U) -> () -> U {
  memo(fn() { f(self.get()) })
}

///| Filter signal updates - only updates when predicate is true

///|
/// Returns a signal that only updates when predicate passes
pub fn[T] Signal::filter(
  self : Signal[T],
  predicate : (T) -> Bool,
) -> Signal[T?] {
  let result : Signal[T?] = Signal::new(None)
  let _ = effect(fn() {
    let value = self.get()
    if predicate(value) {
      result.set(Some(value))
    }
  })
  result
}

///|
/// Filter and map signal updates
pub fn[T, U] Signal::filter_map(self : Signal[T], f : (T) -> U?) -> Signal[U?] {
  let result : Signal[U?] = Signal::new(None)
  let _ = effect(fn() {
    let value = self.get()
    match f(value) {
      Some(mapped) => result.set(Some(mapped))
      None => ()
    }
  })
  result
}

///|
/// Combine two signals into one
pub fn[A, B, R] combine2(
  a : Signal[A],
  b : Signal[B],
  f : (A, B) -> R,
) -> () -> R {
  memo(fn() { f(a.get(), b.get()) })
}

///|
/// Combine three signals into one
pub fn[A, B, C, R] combine3(
  a : Signal[A],
  b : Signal[B],
  c : Signal[C],
  f : (A, B, C) -> R,
) -> () -> R {
  memo(fn() { f(a.get(), b.get(), c.get()) })
}

///|
/// Combine four signals into one
pub fn[A, B, C, D, R] combine4(
  a : Signal[A],
  b : Signal[B],
  c : Signal[C],
  d : Signal[D],
  f : (A, B, C, D) -> R,
) -> () -> R {
  memo(fn() { f(a.get(), b.get(), c.get(), d.get()) })
}

///|
/// Create a signal that is true when all input signals are true
pub fn all(signals : Array[Signal[Bool]]) -> () -> Bool {
  memo(fn() {
    for sig in signals {
      if not(sig.get()) {
        break false
      }
    } else {
      true
    }
  })
}

///|
/// Create a signal that is true when any input signal is true
pub fn any(signals : Array[Signal[Bool]]) -> () -> Bool {
  memo(fn() {
    for sig in signals {
      if sig.get() {
        break true
      }
    } else {
      false
    }
  })
}

///|
/// Select from an array signal by index signal
pub fn[T] select(items : Signal[Array[T]], index : Signal[Int]) -> () -> T? {
  memo(fn() {
    let arr = items.get()
    let idx = index.get()
    if idx >= 0 && idx < arr.length() {
      Some(arr[idx])
    } else {
      None
    }
  })
}

///|
/// Create a read-only getter for a signal
pub fn[T] Signal::to_getter(self : Signal[T]) -> () -> T {
  fn() { self.get() }
}

///|
/// Flatten a signal of signals
pub fn[T] flatten(outer : Signal[Signal[T]]) -> () -> T {
  memo(fn() { outer.get().get() })
}

///|
/// Switch between signals based on a boolean signal
pub fn[T] switch_(
  condition : Signal[Bool],
  on_true : Signal[T],
  on_false : Signal[T],
) -> () -> T {
  memo(fn() { if condition.get() { on_true.get() } else { on_false.get() } })
}
