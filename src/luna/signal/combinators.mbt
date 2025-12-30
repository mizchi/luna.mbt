// Signal Combinators - Transform and combine signals
// Map a signal's value through a function
//

///|
/// Map a signal's value through a function.
/// Returns a getter function (like memo) that recomputes when the signal changes.
/// ```mbt test
/// let count = @signal.signal(5)
/// let doubled = count.map(fn(n) { n * 2 })
/// inspect(doubled(), content="10")
/// count.set(7)
/// inspect(doubled(), content="14")
/// ```
pub fn[T, U] Signal::map(self : Signal[T], f : (T) -> U) -> () -> U {
  memo(fn() { f(self.get()) })
}

///|
/// Filter signal updates - only updates when predicate is true.
/// Returns a signal that only updates when predicate passes.
/// ```mbt test
/// let num = @signal.signal(0)
/// let even_only = num.filter(fn(n) { n % 2 == 0 })
/// inspect(even_only.get(), content="Some(0)") // 0 hasn't passed through filter yet
/// num.set(1) // Odd, filtered out
/// num.set(2) // Even, passes
/// inspect(even_only.get(), content="Some(2)")
/// num.set(3) // Odd, filtered out
/// inspect(even_only.get(), content="Some(2)") // Still 2
/// ```
pub fn[T] Signal::filter(
  self : Signal[T],
  predicate : (T) -> Bool,
) -> Signal[T?] {
  let result : Signal[T?] = Signal::new(None)
  let _ = render_effect(fn() {
    let value = self.get()
    if predicate(value) {
      result.set(Some(value))
    }
  })
  result
}

///|
/// Filter and map signal updates
/// Uses render_effect for synchronous execution
pub fn[T, U] Signal::filter_map(self : Signal[T], f : (T) -> U?) -> Signal[U?] {
  let result : Signal[U?] = Signal::new(None)
  let _ = render_effect(fn() {
    let value = self.get()
    match f(value) {
      Some(mapped) => result.set(Some(mapped))
      None => ()
    }
  })
  result
}

///|
/// Combine two signals into one.
/// The getter recomputes when either signal changes.
/// ```mbt test
/// let first = @signal.signal("Hello")
/// let last = @signal.signal("World")
/// let full = @signal.combine2(first, last, fn(f, l) { f + " " + l })
/// inspect(full(), content="Hello World")
/// first.set("Hi")
/// inspect(full(), content="Hi World")
/// ```
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
/// Create a signal that is true when all input signals are true.
/// ```mbt test
/// let a = @signal.signal(true)
/// let b = @signal.signal(true)
/// let c = @signal.signal(false)
/// let all_true = @signal.all([a, b, c])
/// inspect(all_true(), content="false")
/// c.set(true)
/// inspect(all_true(), content="true")
/// a.set(false)
/// inspect(all_true(), content="false")
/// ```
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
/// Create a signal that is true when any input signal is true.
/// ```mbt test
/// let a = @signal.signal(false)
/// let b = @signal.signal(false)
/// let any_true = @signal.any([a, b])
/// inspect(any_true(), content="false")
/// a.set(true)
/// inspect(any_true(), content="true")
/// ```
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
/// Select from an array signal by index signal.
/// Returns None if index is out of bounds.
/// ```mbt test
/// let items = @signal.signal(["a", "b", "c"])
/// let idx = @signal.signal(1)
/// let selected = @signal.select(items, idx)
/// inspect(selected(), content=(
///   #|Some("b")
/// ))
/// idx.set(0)
/// inspect(selected(), content=(
///   #|Some("a")
/// ))
/// idx.set(10) // Out of bounds
/// inspect(selected(), content="None")
/// ```
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
/// Flatten a signal of signals.
/// Unwraps nested Signal[Signal[T]] to a getter for T.
/// ```mbt test
/// let inner1 = @signal.signal(10)
/// let inner2 = @signal.signal(20)
/// let outer = @signal.signal(inner1)
/// let flat = @signal.flatten(outer)
/// inspect(flat(), content="10")
/// outer.set(inner2)
/// inspect(flat(), content="20")
/// inner2.set(30)
/// inspect(flat(), content="30")
/// ```
pub fn[T] flatten(outer : Signal[Signal[T]]) -> () -> T {
  memo(fn() { outer.get().get() })
}

///|
/// Switch between signals based on a boolean signal.
/// Returns value from on_true when condition is true, otherwise on_false.
/// ```mbt test
/// let flag = @signal.signal(true)
/// let yes = @signal.signal("YES")
/// let no = @signal.signal("NO")
/// let result = @signal.switch_(flag, yes, no)
/// inspect(result(), content="YES")
/// flag.set(false)
/// inspect(result(), content="NO")
/// no.set("NOPE")
/// inspect(result(), content="NOPE")
/// ```
pub fn[T] switch_(
  condition : Signal[Bool],
  on_true : Signal[T],
  on_false : Signal[T],
) -> () -> T {
  memo(fn() { if condition.get() { on_true.get() } else { on_false.get() } })
}
