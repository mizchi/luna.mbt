// Signal - Reactive value container with automatic dependency tracking
//

///|
/// Signal type - holds a value and notifies subscribers on change.
/// A reactive primitive that stores a value and automatically tracks dependencies.
/// ```mbt check
/// test {
///   let count = @signal.signal(0)
///   inspect(count.get(), content="0")
///   count.set(5)
///   inspect(count.get(), content="5")
/// }
/// ```
pub struct Signal[T] {
  mut value : T
  subscribers : Array[EffectRunner]
}

///|
/// Create a new signal with initial value.
/// ```mbt check
/// test {
///   let name = @signal.Signal::new("Alice")
///   inspect(name.get(), content="Alice")
/// }
/// ```
pub fn[T] Signal::new(initial : T) -> Signal[T] {
  { value: initial, subscribers: [] }
}

///|
/// Get the current value and track dependency if inside an effect.
/// When called inside an `effect` or `memo`, automatically subscribes to changes.
/// ```mbt check
/// test {
///   let count = @signal.signal(0)
///   let log : Array[Int] = []
///   let _ = @signal.render_effect(fn() { log.push(count.get()) })
///   count.set(1)
///   count.set(2)
///   inspect(log, content="[0, 1, 2]")
/// }
/// ```
pub fn[T] Signal::get(self : Signal[T]) -> T {
  // Auto-track: if we're inside an effect, subscribe to this signal
  match get_current_subscriber() {
    Some(subscriber) => {
      // Check if already subscribed (by ID)
      let already_subscribed = self.subscribers
        .iter()
        .any(fn(s) { s.id == subscriber.id })
      if not(already_subscribed) {
        self.subscribers.push(subscriber)
      }
    }
    None => ()
  }
  self.value
}

///|
/// Set a new value and notify all subscribers.
/// ```mbt check
/// test {
///   let count = @signal.signal(0)
///   count.set(42)
///   inspect(count.get(), content="42")
/// }
/// ```
pub fn[T] Signal::set(self : Signal[T], new_value : T) -> Unit {
  self.value = new_value
  self.notify()
}

///|
/// Update the value using a function.
/// Useful for updating based on current value.
/// ```mbt check
/// test {
///   let count = @signal.signal(10)
///   count.update(fn(n) { n * 2 })
///   inspect(count.get(), content="20")
///   count.update(fn(n) { n + 5 })
///   inspect(count.get(), content="25")
/// }
/// ```
pub fn[T] Signal::update(self : Signal[T], f : (T) -> T) -> Unit {
  self.value = f(self.value)
  self.notify()
}

///|
/// Get value without tracking (won't create dependency).
/// Useful when you need to read a signal without subscribing to it.
/// ```mbt check
/// test {
///   let count = @signal.signal(0)
///   let runs : Ref[Int] = { val: 0 }
///   let _ = @signal.render_effect(fn() {
///     // peek() won't create dependency
///     let _ = count.peek()
///     runs.val = runs.val + 1
///   })
///   count.set(1)
///   count.set(2)
///   // Effect only ran once (initial), not on updates
///   inspect(runs.val, content="1")
/// }
/// ```
pub fn[T] Signal::peek(self : Signal[T]) -> T {
  self.value
}

///|
/// Notify all subscribers
fn[T] Signal::notify(self : Signal[T]) -> Unit {
  // Schedule all subscribers to run
  // Note: We don't clear subscribers here anymore
  // Effects will re-register via get() when they re-run
  for subscriber in self.subscribers {
    schedule_effect(subscriber)
  }
}

///|
/// Clear all subscribers (for cleanup)
pub fn[T] Signal::clear_subscribers(self : Signal[T]) -> Unit {
  self.subscribers.clear()
}

///|
/// Remove a specific subscriber by ID
pub fn[T] Signal::remove_subscriber(self : Signal[T], id : Int) -> Unit {
  self.subscribers.retain(fn(s) { s.id != id })
}

///|
/// Get number of subscribers (for debugging)
pub fn[T] Signal::subscriber_count(self : Signal[T]) -> Int {
  self.subscribers.length()
}

///|
/// Convenience function to create a signal.
/// Shorthand for `Signal::new`.
/// ```mbt check
/// test {
///   let count = @signal.signal(100)
///   inspect(count.get(), content="100")
/// }
/// ```
pub fn[T] signal(initial : T) -> Signal[T] {
  Signal::new(initial)
}

///|
/// Explicitly subscribe to a signal with a callback.
/// Returns an unsubscribe function.
/// Unlike `effect()`, this doesn't auto-track and only listens to this one signal.
/// ```mbt check
/// test {
///   let count = @signal.signal(0)
///   let values : Array[Int] = []
///   let unsub = @signal.on(count, fn(v) { values.push(v) })
///   count.set(1)
///   count.set(2)
///   unsub()
///   count.set(3) // This won't be captured
///   inspect(values, content="[1, 2]")
/// }
/// ```
pub fn[T] on(sig : Signal[T], callback : (T) -> Unit) -> () -> Unit {
  let id = new_effect_id()
  let active = { val: true }
  let runner : EffectRunner = {
    id,
    run: fn() {
      if active.val {
        callback(sig.peek()) // Use peek to avoid re-subscribing
      }
    },
  }

  // Initial subscription
  sig.subscribers.push(runner)

  // Return unsubscribe function
  fn() {
    active.val = false
    sig.remove_subscriber(id)
  }
}

///|
/// Subscribe and run immediately with current value.
/// Like `on`, but also invokes the callback with the current value right away.
/// ```mbt check
/// test {
///   let count = @signal.signal(10)
///   let values : Array[Int] = []
///   let unsub = @signal.on_immediate(count, fn(v) { values.push(v) })
///   count.set(20)
///   unsub()
///   // First value (10) was captured immediately, then 20 on update
///   inspect(values, content="[10, 20]")
/// }
/// ```
pub fn[T] on_immediate(sig : Signal[T], callback : (T) -> Unit) -> () -> Unit {
  callback(sig.peek()) // Run immediately
  on(sig, callback)
}
