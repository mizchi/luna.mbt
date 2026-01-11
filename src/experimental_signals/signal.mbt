// Signal - reactive value primitive
// alien-signals style API

/// Create a new signal with initial value
/// ```
/// let count = signal(0)
/// println(count.get())  // 0
/// count.set(5)
/// println(count.get())  // 5
/// ```
pub fn signal[T](initial : T) -> Signal[T] {
  {
    node: ReactiveNode::new(ReactiveFlags::Mutable.to_int()),
    current_value: initial,
    pending_value: initial,
  }
}

/// Get the current value of a signal
/// Automatically tracks dependency if called inside an effect/computed
pub fn Signal::get[T](self : Signal[T]) -> T {
  let flags = self.node.flags.get_value()
  let dirty_flag = ReactiveFlags::Dirty.to_int()

  // If dirty, update current from pending
  if (flags & dirty_flag) != 0 {
    if not(physical_equal_value(self.current_value, self.pending_value)) {
      self.current_value = self.pending_value
      match self.node.subs {
        Some(subs) => shallow_propagate(subs)
        None => ()
      }
    }
    self.node.flags.set_value(ReactiveFlags::Mutable.to_int())
  }

  // Track dependency
  let sub = get_active_sub()
  let mut found_sub = sub
  while found_sub.is_some() {
    match found_sub {
      Some(s) => {
        let sub_flags = s.flags.get_value()
        let mutable_flag = ReactiveFlags::Mutable.to_int()
        let watching_flag = ReactiveFlags::Watching.to_int()
        if (sub_flags & (mutable_flag | watching_flag)) != 0 {
          link(self.node, s, get_cycle())
          break
        }
        found_sub = match s.subs {
          Some(subs) => Some(subs.sub)
          None => None
        }
      }
      None => ()
    }
  }

  self.current_value
}

/// Set a new value for the signal
/// Notifies all subscribers if value changed
pub fn Signal::set[T](self : Signal[T], value : T) -> Unit {
  if not(physical_equal_value(self.pending_value, value)) {
    self.pending_value = value
    // Track when this signal was modified for diamond dependency resolution
    inc_cycle()
    self.node.last_modified_cycle = get_cycle()
    self.node.flags.set_value(
      ReactiveFlags::Mutable.to_int() | ReactiveFlags::Dirty.to_int()
    )
    match self.node.subs {
      Some(subs) => {
        propagate(subs)
        if get_batch_depth() == 0 {
          flush()
        }
      }
      None => ()
    }
  }
}

/// Update signal value using a function
pub fn Signal::update[T](self : Signal[T], f : (T) -> T) -> Unit {
  self.set(f(self.get()))
}

/// Get value without tracking (peek)
/// Returns the latest value (pending if dirty, otherwise current)
pub fn Signal::peek[T](self : Signal[T]) -> T {
  let flags = self.node.flags.get_value()
  let dirty_flag = ReactiveFlags::Dirty.to_int()
  if (flags & dirty_flag) != 0 {
    self.pending_value
  } else {
    self.current_value
  }
}

// Helper for value comparison
fn physical_equal_value[T](a : T, b : T) -> Bool {
  // Use physical equality for reference types
  physical_equal(a, b)
}
