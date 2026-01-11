// Computed / Memo - derived reactive values
// Compatible with signal module API

///|
/// Create a memoized computed value (internal)
fn[T] create_computed(getter : () -> T) -> Computed[T] {
  { node: ReactiveNode::new(ReactiveFlags::None.to_int()), value: None, getter }
}

///|
/// Get the computed value
/// Automatically tracks dependency if called inside an effect/computed
pub fn[T] Computed::get(self : Computed[T]) -> T {
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
    self.node.flags.set_value(flags & (pending_flag ^ -1))
  } else if flags == ReactiveFlags::None.to_int() {
    // First computation
    self.node.flags.set_value(mutable_flag | recursed_check_flag)
    let prev_sub = set_active_sub(Some(self.node))
    self.value = Some((self.getter)())
    let _ = set_active_sub(prev_sub)
    let current_flags = self.node.flags.get_value()
    self.node.flags.set_value(current_flags & (recursed_check_flag ^ -1))
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

///|
/// Update computed value, returns true if changed
fn[T] update_computed(c : Computed[T]) -> Bool {
  inc_cycle()
  c.node.deps_tail = None
  c.node.flags.set_value(
    ReactiveFlags::Mutable.to_int() | ReactiveFlags::RecursedCheck.to_int(),
  )
  let prev_sub = set_active_sub(Some(c.node))
  let old_value = c.value
  let new_value = (c.getter)()
  c.value = Some(new_value)
  let _ = set_active_sub(prev_sub)
  let current_flags = c.node.flags.get_value()
  c.node.flags.set_value(
    current_flags & (ReactiveFlags::RecursedCheck.to_int() ^ -1),
  )
  purge_deps(c.node)
  match old_value {
    Some(old) => not(physical_equal(old, new_value))
    None => true
  }
}

///|
/// Check if any dependency has changed since last computation
/// Uses last_modified_cycle to handle diamond dependencies correctly
fn check_deps_dirty(node : ReactiveNode) -> Bool {
  let dirty_flag = ReactiveFlags::Dirty.to_int()
  let pending_flag = ReactiveFlags::Pending.to_int()
  let mutable_flag = ReactiveFlags::Mutable.to_int()
  let link_ref : Ref[Link?] = Ref::new(node.deps)
  while not(link_ref.val is None) {
    match link_ref.val {
      Some(lnk) => {
        let dep = lnk.dep
        let dep_flags = dep.flags.get_value()
        if (dep_flags & mutable_flag) != 0 {
          // Check if dep was modified after this link was created
          // This handles diamond dependencies where dirty flag may be cleared
          if dep.last_modified_cycle > lnk.version {
            return true
          }
          // Also check traditional dirty/pending flags
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

///|
/// Peek at current value without tracking
pub fn[T] Computed::peek(self : Computed[T]) -> T? {
  self.value
}
