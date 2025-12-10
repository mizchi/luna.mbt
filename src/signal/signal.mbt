///| Signal - Reactive value container with automatic dependency tracking

///|
/// Signal type - holds a value and notifies subscribers on change
pub struct Signal[T] {
  mut value : T
  subscribers : Array[EffectRunner]
}

///|
/// Create a new signal with initial value
pub fn[T] Signal::new(initial : T) -> Signal[T] {
  { value: initial, subscribers: [] }
}

///|
/// Get the current value and track dependency if inside an effect
pub fn[T] Signal::get(self : Signal[T]) -> T {
  // Auto-track: if we're inside an effect, subscribe to this signal
  match get_current_subscriber() {
    Some(subscriber) => {
      // Check if already subscribed (by ID)
      let already_subscribed = self.subscribers.iter().any(fn(s) {
        s.id == subscriber.id
      })
      if not(already_subscribed) {
        self.subscribers.push(subscriber)
      }
    }
    None => ()
  }
  self.value
}

///|
/// Set a new value and notify all subscribers
pub fn[T] Signal::set(self : Signal[T], new_value : T) -> Unit {
  self.value = new_value
  self.notify()
}

///|
/// Update the value using a function
pub fn[T] Signal::update(self : Signal[T], f : (T) -> T) -> Unit {
  self.value = f(self.value)
  self.notify()
}

///|
/// Get value without tracking (won't create dependency)
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
/// Convenience function to create a signal
pub fn[T] signal(initial : T) -> Signal[T] {
  Signal::new(initial)
}

///| Explicitly subscribe to a signal with a callback

///| Returns an unsubscribe function

///|
/// Unlike effect(), this doesn't auto-track and only listens to this one signal
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
/// Subscribe and run immediately with current value
pub fn[T] on_immediate(sig : Signal[T], callback : (T) -> Unit) -> () -> Unit {
  callback(sig.peek()) // Run immediately
  on(sig, callback)
}
