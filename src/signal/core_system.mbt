// Core reactive system - link/unlink/propagate algorithms
// Port of alien-signals system.ts

// Global state using Ref for mutability

///|
let cycle : Ref[Int] = Ref::new(0)

///|
let batch_depth : Ref[Int] = Ref::new(0)

///|
let notify_index : Ref[Int] = Ref::new(0)

///|
let queued_length : Ref[Int] = Ref::new(0)

///|
let active_sub : Ref[ReactiveNode?] = Ref::new(None)

// Effect queue (fixed-size array for simplicity)

///|
let queued : Array[EffectNode?] = Array::make(1024, None)

// Callback-based effect queue for simpler effect tracking

///|
let callback_queue : Array[() -> Unit] = []

///|
let callback_queue_nodes : Array[ReactiveNode] = [] // Track which nodes are queued

///|
/// Get current active subscriber
pub fn get_active_sub() -> ReactiveNode? {
  active_sub.val
}

///|
/// Set active subscriber, returns previous
pub fn set_active_sub(sub : ReactiveNode?) -> ReactiveNode? {
  let prev = active_sub.val
  active_sub.val = sub
  prev
}

///|
/// Get current batch depth
pub fn get_batch_depth() -> Int {
  batch_depth.val
}

///|
/// Start a batch update
pub fn start_batch() -> Unit {
  batch_depth.val = batch_depth.val + 1
}

///|
/// End a batch update
pub fn end_batch() -> Unit {
  batch_depth.val = batch_depth.val - 1
  if batch_depth.val == 0 {
    flush()
  }
}

///|
/// Get current cycle
pub fn get_cycle() -> Int {
  cycle.val
}

///|
/// Increment cycle
pub fn inc_cycle() -> Unit {
  cycle.val = cycle.val + 1
}

// =============================================================================
// Link operations
// =============================================================================

///|
/// Create a link between dependency and subscriber
pub fn link(dep : ReactiveNode, sub : ReactiveNode, version : Int) -> Unit {
  let prev_dep = sub.deps_tail

  // Check if already linked to same dep (optimization)
  match prev_dep {
    Some(pd) => if physical_equal(pd.dep, dep) { return }
    None => ()
  }

  // Check next dep slot
  let next_dep = match prev_dep {
    Some(pd) => pd.next_dep
    None => sub.deps
  }
  match next_dep {
    Some(nd) =>
      if physical_equal(nd.dep, dep) {
        nd.version = version
        sub.deps_tail = Some(nd)
        return
      }
    None => ()
  }

  // Check if dep already has this sub with same version
  match dep.subs_tail {
    Some(ps) =>
      if ps.version == version && physical_equal(ps.sub, sub) {
        return
      }
    None => ()
  }

  // Create new link
  let new_link : Link = {
    version,
    dep,
    sub,
    prev_dep,
    next_dep,
    prev_sub: dep.subs_tail,
    next_sub: None,
  }

  // Update sub's dep list
  sub.deps_tail = Some(new_link)
  match next_dep {
    Some(nd) => nd.prev_dep = Some(new_link)
    None => ()
  }
  match prev_dep {
    Some(pd) => pd.next_dep = Some(new_link)
    None => sub.deps = Some(new_link)
  }

  // Update dep's sub list
  match new_link.prev_sub {
    Some(ps) => ps.next_sub = Some(new_link)
    None => dep.subs = Some(new_link)
  }
  dep.subs_tail = Some(new_link)
}

///|
/// Unlink a dependency link, returns next dep link
pub fn unlink(lnk : Link, sub : ReactiveNode) -> Link? {
  let dep = lnk.dep
  let prev_dep = lnk.prev_dep
  let next_dep = lnk.next_dep
  let next_sub = lnk.next_sub
  let prev_sub = lnk.prev_sub

  // Update sub's dep list
  match next_dep {
    Some(nd) => nd.prev_dep = prev_dep
    None => sub.deps_tail = prev_dep
  }
  match prev_dep {
    Some(pd) => pd.next_dep = next_dep
    None => sub.deps = next_dep
  }

  // Update dep's sub list
  match next_sub {
    Some(ns) => ns.prev_sub = prev_sub
    None => dep.subs_tail = prev_sub
  }
  match prev_sub {
    Some(ps) => ps.next_sub = next_sub
    None => {
      dep.subs = next_sub
      // If no more subscribers, call unwatched
      if next_sub is None {
        unwatched(dep)
      }
    }
  }
  next_dep
}

///|
/// Called when a node has no more subscribers
fn unwatched(node : ReactiveNode) -> Unit {
  let flags = node.flags.get_value()
  let is_mutable = (flags & ReactiveFlags::Mutable.to_int()) != 0
  if not(is_mutable) {
    // Effect scope - clean up
    cleanup_node(node)
  } else {
    // Computed - mark as lazy again
    match node.deps_tail {
      Some(_) => {
        node.deps_tail = None
        node.flags.set_value(
          ReactiveFlags::Mutable.to_int() | ReactiveFlags::Dirty.to_int(),
        )
        purge_deps(node)
      }
      None => ()
    }
  }
}

///|
/// Clean up a node (effect scope)
fn cleanup_node(node : ReactiveNode) -> Unit {
  node.deps_tail = None
  node.flags.set_value(ReactiveFlags::None.to_int())
  purge_deps(node)
  match node.subs {
    Some(sub) => {
      let _ = unlink(sub, sub.sub)

    }
    None => ()
  }
}

///|
/// Purge unused deps after deps_tail
pub fn purge_deps(sub : ReactiveNode) -> Unit {
  let deps_tail = sub.deps_tail
  let dep_ref : Ref[Link?] = Ref::new(
    match deps_tail {
      Some(dt) => dt.next_dep
      None => sub.deps
    },
  )
  while not(dep_ref.val is None) {
    match dep_ref.val {
      Some(d) => dep_ref.val = unlink(d, sub)
      None => ()
    }
  }
}

// =============================================================================
// Propagation
// =============================================================================

///|
/// Propagate changes through the dependency graph (simplified version)
pub fn propagate(start_link : Link) -> Unit {
  let link_ref : Ref[Link?] = Ref::new(Some(start_link))
  let next_ref : Ref[Link?] = Ref::new(start_link.next_sub)
  let stack : Array[(Link?, Link?)] = []
  let mut running = true
  while running {
    match link_ref.val {
      None =>
        // Try to pop from stack
        if stack.length() > 0 {
          match stack.pop() {
            Some((l, _)) => {
              link_ref.val = l
              // Restore next_ref from the popped link's next_sub
              next_ref.val = match l {
                Some(lnk) => lnk.next_sub
                None => None
              }
            }
            None => running = false
          }
        } else {
          running = false
        }
      Some(lnk) => {
        let sub = lnk.sub
        let flags = sub.flags.get_value()
        let mutable_flag = ReactiveFlags::Mutable.to_int()
        let watching_flag = ReactiveFlags::Watching.to_int()
        let recursed_check_flag = ReactiveFlags::RecursedCheck.to_int()
        let recursed_flag = ReactiveFlags::Recursed.to_int()
        let dirty_flag = ReactiveFlags::Dirty.to_int()
        let pending_flag = ReactiveFlags::Pending.to_int()
        let mut new_flags = flags
        let mut should_notify = false
        let mut should_propagate_subs = false
        if (
            flags &
            (recursed_check_flag | recursed_flag | dirty_flag | pending_flag)
          ) ==
          0 {
          new_flags = flags | pending_flag
          sub.flags.set_value(new_flags)
        } else if (flags & (recursed_check_flag | recursed_flag)) == 0 {
          new_flags = ReactiveFlags::None.to_int()
        } else if (flags & recursed_check_flag) == 0 {
          new_flags = (flags & (recursed_flag ^ -1)) | pending_flag
          sub.flags.set_value(new_flags)
        } else if (flags & (dirty_flag | pending_flag)) == 0 &&
          is_valid_link(lnk, sub) {
          new_flags = flags | recursed_flag | pending_flag
          sub.flags.set_value(new_flags)
          new_flags = new_flags & mutable_flag
        } else {
          new_flags = ReactiveFlags::None.to_int()
        }
        if (new_flags & watching_flag) != 0 {
          should_notify = true
        }
        if (new_flags & mutable_flag) != 0 {
          should_propagate_subs = true
        }
        if should_notify {
          notify_effect(sub)
        }
        if should_propagate_subs {
          match sub.subs {
            Some(sub_subs) => {
              match sub_subs.next_sub {
                Some(_) => {
                  stack.push((next_ref.val, None))
                  next_ref.val = sub_subs.next_sub
                }
                None => ()
              }
              link_ref.val = Some(sub_subs)
            }
            None => {
              link_ref.val = next_ref.val
              match link_ref.val {
                Some(l) => next_ref.val = l.next_sub
                None => next_ref.val = None
              }
            }
          }
        } else {
          link_ref.val = next_ref.val
          match link_ref.val {
            Some(l) => next_ref.val = l.next_sub
            None => next_ref.val = None
          }
        }
      }
    }
  }
}

///|
/// Check if link is valid for the subscriber
fn is_valid_link(check_link : Link, sub : ReactiveNode) -> Bool {
  let link_ref : Ref[Link?] = Ref::new(sub.deps_tail)
  while not(link_ref.val is None) {
    match link_ref.val {
      Some(l) => {
        if physical_equal(l, check_link) {
          return true
        }
        link_ref.val = l.prev_dep
      }
      None => ()
    }
  }
  false
}

///|
/// Shallow propagate - mark direct subscribers as dirty
pub fn shallow_propagate(start_link : Link) -> Unit {
  let link_ref : Ref[Link?] = Ref::new(Some(start_link))
  while not(link_ref.val is None) {
    match link_ref.val {
      Some(lnk) => {
        let sub = lnk.sub
        let flags = sub.flags.get_value()
        let pending_flag = ReactiveFlags::Pending.to_int()
        let dirty_flag = ReactiveFlags::Dirty.to_int()
        let watching_flag = ReactiveFlags::Watching.to_int()
        let recursed_check_flag = ReactiveFlags::RecursedCheck.to_int()
        if (flags & (pending_flag | dirty_flag)) == pending_flag {
          sub.flags.set_value(flags | dirty_flag)
          if (flags & (watching_flag | recursed_check_flag)) == watching_flag {
            notify_effect(sub)
          }
        }
        link_ref.val = lnk.next_sub
      }
      None => ()
    }
  }
}

// =============================================================================
// Check Dirty (simplified - doesn't recurse)
// =============================================================================

///|
/// Check if any dependency is dirty and needs update
pub fn check_dirty(
  start_link : Link,
  sub : ReactiveNode,
  update_fn : (ReactiveNode) -> Bool,
) -> Bool {
  let link_ref : Ref[Link?] = Ref::new(Some(start_link))
  let dirty_flag = ReactiveFlags::Dirty.to_int()
  let mutable_flag = ReactiveFlags::Mutable.to_int()
  while not(link_ref.val is None) {
    match link_ref.val {
      Some(lnk) => {
        let dep = lnk.dep
        let flags = dep.flags.get_value()

        // Check if sub is dirty
        if (sub.flags.get_value() & dirty_flag) != 0 {
          return true
        }

        // Dep is mutable and dirty - update it
        if (flags & (mutable_flag | dirty_flag)) == (mutable_flag | dirty_flag) {
          if update_fn(dep) {
            match dep.subs {
              Some(subs) =>
                if subs.next_sub is Some(_) {
                  shallow_propagate(subs)
                }
              None => ()
            }
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

// =============================================================================
// Effect Queue
// =============================================================================

///|
/// Notify an effect - queue it for execution
fn notify_effect(node : ReactiveNode) -> Unit {
  match node.effect_callback {
    Some(callback) => {
      // Check if already queued (avoid duplicates)
      let mut already_queued = false
      for n in callback_queue_nodes {
        if physical_equal(n, node) {
          already_queued = true
          break
        }
      }
      if not(already_queued) {
        callback_queue.push(callback)
        callback_queue_nodes.push(node)
        node.flags.unset(Watching)
      }
    }
    None => ()
  }
}

///|
/// Queue an effect for execution
pub fn queue_effect(eff : EffectNode) -> Unit {
  let insert_index = queued_length.val
  queued[insert_index] = Some(eff)
  eff.node.flags.unset(Watching)
  queued_length.val = queued_length.val + 1
}

///|
/// Flush the effect queue
pub fn flush() -> Unit {
  // Run EffectNode queue (legacy)
  while notify_index.val < queued_length.val {
    match queued[notify_index.val] {
      Some(eff) => {
        queued[notify_index.val] = None
        notify_index.val = notify_index.val + 1
        run_effect(eff)
      }
      None => notify_index.val = notify_index.val + 1
    }
  }

  // Reset legacy queue
  notify_index.val = 0
  queued_length.val = 0

  // Run callback queue
  while callback_queue.length() > 0 {
    let callback = callback_queue.remove(0)
    let _ = callback_queue_nodes.remove(0)
    callback()
  }
}

///|
/// Run an effect
fn run_effect(e : EffectNode) -> Unit {
  let flags = e.node.flags.get_value()
  let dirty_flag = ReactiveFlags::Dirty.to_int()
  let pending_flag = ReactiveFlags::Pending.to_int()
  let is_deps_dirty = match e.node.deps {
    Some(deps) => check_dirty(deps, e.node, fn(_) { false })
    None => false
  }
  let should_run = (flags & dirty_flag) != 0 ||
    ((flags & pending_flag) != 0 && is_deps_dirty)
  if should_run {
    inc_cycle()
    e.node.deps_tail = None
    e.node.flags.set_value(
      ReactiveFlags::Watching.to_int() | ReactiveFlags::RecursedCheck.to_int(),
    )
    let prev_sub = set_active_sub(Some(e.node))
    (e.run_fn)()
    let _ = set_active_sub(prev_sub)
    let current_flags = e.node.flags.get_value()
    e.node.flags.set_value(
      current_flags & (ReactiveFlags::RecursedCheck.to_int() ^ -1),
    )
    purge_deps(e.node)
  } else {
    e.node.flags.set_value(ReactiveFlags::Watching.to_int())
  }
}
