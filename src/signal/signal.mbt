// Signal - Reactive value container with automatic dependency tracking

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
  inner : CoreSignal[T]
  // Explicit subscribers for `on`/`on_immediate` API (non-tracking subscriptions)
  // Note: Effect auto-tracking uses the core reactive system, not this
  legacy_subscribers : Array[EffectRunner]
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
  { inner: core_signal(initial), legacy_subscribers: [] }
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
  // Track with legacy system if inside a signal-module effect
  match get_current_subscriber() {
    Some(subscriber) => {
      let already_subscribed = self.legacy_subscribers
        .iter()
        .any(fn(s) { s.id == subscriber.id })
      if not(already_subscribed) {
        self.legacy_subscribers.push(subscriber)
      }
    }
    None => ()
  }
  // Also track with core reactive system
  self.inner.get()
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
  self.inner.set(new_value)
  // Notify legacy subscribers
  self.notify_legacy()
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
  self.inner.update(f)
  self.notify_legacy()
}

///|
/// Get value without tracking (won't create dependency).
/// Useful when you need to read a signal without subscribing to it.
/// ```mbt check
/// test {
///   let count = @signal.signal(0)
///   let runs : Ref[Int] = Ref::new(0)
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
  self.inner.peek()
}

///|
/// Notify legacy subscribers (for `on` API compatibility)
fn[T] Signal::notify_legacy(self : Signal[T]) -> Unit {
  for subscriber in self.legacy_subscribers {
    schedule_effect(subscriber)
  }
}

///|
/// Clear all subscribers (for cleanup)
pub fn[T] Signal::clear_subscribers(self : Signal[T]) -> Unit {
  self.inner.clear_subscribers()
  self.legacy_subscribers.clear()
}

///|
/// Remove a specific subscriber by ID
pub fn[T] Signal::remove_subscriber(self : Signal[T], id : Int) -> Unit {
  self.legacy_subscribers.retain(fn(s) { s.id != id })
}

///|
/// Get number of subscribers (for debugging)
pub fn[T] Signal::subscriber_count(self : Signal[T]) -> Int {
  // Count core subscribers
  let core_count = self.inner.subscriber_count()
  // Add legacy subscribers
  core_count + self.legacy_subscribers.length()
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
  let active = Ref::new(true)
  let runner : EffectRunner = {
    id,
    run: fn() {
      if active.val {
        callback(sig.peek()) // Use peek to avoid re-subscribing
      }
    },
  }

  // Initial subscription
  sig.legacy_subscribers.push(runner)

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
