// Computed - derived reactive values
// alien-signals style API

/// Create a computed value that derives from other signals
/// ```
/// let count = signal(2)
/// let doubled = computed(fn(_) { count.get() * 2 })
/// println(doubled.get())  // 4
/// count.set(5)
/// println(doubled.get())  // 10
/// ```
pub fn computed[T](getter : (T?) -> T) -> ComputedNode[T] {
  {
    node: ReactiveNode::new(ReactiveFlags::None.to_int()),
    value: None,
    getter,
  }
}

/// Get the computed value
/// Automatically tracks dependency if called inside an effect/computed
pub fn ComputedNode::get[T](self : ComputedNode[T]) -> T {
  let flags = self.node.flags.get_value()
  let dirty_flag = ReactiveFlags::Dirty.to_int()
  let pending_flag = ReactiveFlags::Pending.to_int()
  let mutable_flag = ReactiveFlags::Mutable.to_int()
  let recursed_check_flag = ReactiveFlags::RecursedCheck.to_int()

  // Check if dirty or pending (need to recompute)
  let is_dirty = (flags & dirty_flag) != 0
  let is_pending = (flags & pending_flag) != 0

  // Check if dependencies have changed
  let deps_changed = if is_pending {
    // Check if any dependency is dirty
    check_deps_dirty(self.node)
  } else {
    false
  }

  if is_dirty || deps_changed {
    // Recompute
    if update_computed(self) {
      match self.node.subs {
        Some(subs) => shallow_propagate(subs)
        None => ()
      }
    }
  } else if is_pending {
    // Clear pending flag if deps not dirty
    self.node.flags.set_value(flags & (pending_flag ^ (-1)))
  } else if flags == ReactiveFlags::None.to_int() {
    // First computation
    self.node.flags.set_value(mutable_flag | recursed_check_flag)
    let prev_sub = set_active_sub(Some(self.node))
    self.value = Some((self.getter)(None))
    let _ = set_active_sub(prev_sub)
    let current_flags = self.node.flags.get_value()
    self.node.flags.set_value(current_flags & (recursed_check_flag ^ (-1)))
  }

  // Track dependency
  match get_active_sub() {
    Some(sub) => link(self.node, sub, get_cycle())
    None => ()
  }

  match self.value {
    Some(v) => v
    None => abort("Computed value not initialized")
  }
}

/// Update computed value, returns true if changed
fn update_computed[T](c : ComputedNode[T]) -> Bool {
  inc_cycle()
  c.node.deps_tail = None
  c.node.flags.set_value(
    ReactiveFlags::Mutable.to_int() | ReactiveFlags::RecursedCheck.to_int()
  )
  let prev_sub = set_active_sub(Some(c.node))
  let old_value = c.value
  let new_value = (c.getter)(old_value)
  c.value = Some(new_value)
  let _ = set_active_sub(prev_sub)
  let current_flags = c.node.flags.get_value()
  c.node.flags.set_value(current_flags & (ReactiveFlags::RecursedCheck.to_int() ^ (-1)))
  purge_deps(c.node)

  match old_value {
    Some(old) => not(physical_equal(old, new_value))
    None => true
  }
}

/// Generic update function for check_dirty
fn update_computed_any(node : ReactiveNode) -> Bool {
  // This is a simplified version
  // In a full implementation, we'd need to store the computed node reference
  ignore(node)
  false
}

/// Check if any dependency has dirty or pending flag set
fn check_deps_dirty(node : ReactiveNode) -> Bool {
  let dirty_flag = ReactiveFlags::Dirty.to_int()
  let pending_flag = ReactiveFlags::Pending.to_int()
  let mutable_flag = ReactiveFlags::Mutable.to_int()
  let link_ref : Ref[Link?] = Ref::new(node.deps)

  while not(link_ref.val.is_empty()) {
    match link_ref.val {
      Some(lnk) => {
        let dep = lnk.dep
        let dep_flags = dep.flags.get_value()
        // Check if dependency is dirty (signal) or pending (computed that may need update)
        if (dep_flags & mutable_flag) != 0 {
          if (dep_flags & (dirty_flag | pending_flag)) != 0 {
            return true
          }
        }
        link_ref.val = lnk.next_dep
      }
      None => ()
    }
  }
  false
}

/// Peek at current value without tracking
pub fn ComputedNode::peek[T](self : ComputedNode[T]) -> T? {
  self.value
}
