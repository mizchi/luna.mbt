// CoreSignal - internal reactive value primitive
// alien-signals style API

/// Create a new core signal with initial value
pub fn[T] core_signal(initial : T) -> CoreSignal[T] {
  {
    node: ReactiveNode::new(ReactiveFlags::Mutable.to_int()),
    current_value: initial,
    pending_value: initial,
  }
}

/// Get the current value of a core signal
/// Automatically tracks dependency if called inside an effect/computed
pub fn[T] CoreSignal::get(self : CoreSignal[T]) -> T {
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
  while found_sub is Some(_) {
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

/// Set a new value for the core signal
/// Notifies all subscribers if value changed
pub fn[T] CoreSignal::set(self : CoreSignal[T], value : T) -> Unit {
  if not(physical_equal_value(self.pending_value, value)) {
    self.pending_value = value
    // Track when this signal was modified for diamond dependency resolution
    inc_cycle()
    self.node.last_modified_cycle = get_cycle()
    self.node.flags.set_value(
      ReactiveFlags::Mutable.to_int() | ReactiveFlags::Dirty.to_int(),
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

/// Update core signal value using a function
pub fn[T] CoreSignal::update(self : CoreSignal[T], f : (T) -> T) -> Unit {
  self.set(f(self.get()))
}

/// Get value without tracking (peek)
/// Returns the latest value (pending if dirty, otherwise current)
pub fn[T] CoreSignal::peek(self : CoreSignal[T]) -> T {
  let flags = self.node.flags.get_value()
  let dirty_flag = ReactiveFlags::Dirty.to_int()
  if (flags & dirty_flag) != 0 {
    self.pending_value
  } else {
    self.current_value
  }
}

/// Get number of subscribers (for debugging)
pub fn[T] CoreSignal::subscriber_count(self : CoreSignal[T]) -> Int {
  let mut count = 0
  let mut lnk = self.node.subs
  while lnk is Some(_) {
    match lnk {
      Some(l) => {
        count = count + 1
        lnk = l.next_sub
      }
      None => ()
    }
  }
  count
}

/// Clear all subscribers
pub fn[T] CoreSignal::clear_subscribers(self : CoreSignal[T]) -> Unit {
  // Unlink all subs
  let mut lnk = self.node.subs
  while lnk is Some(_) {
    match lnk {
      Some(l) => {
        let next = l.next_sub
        let _ = unlink(l, l.sub)
        lnk = next
      }
      None => ()
    }
  }
  self.node.subs = None
  self.node.subs_tail = None
}

// Helper for value comparison
fn[T] physical_equal_value(a : T, b : T) -> Bool {
  // Use physical equality for reference types
  physical_equal(a, b)
}
