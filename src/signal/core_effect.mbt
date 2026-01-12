// Core effect - reactive side effects (internal)

// Cleanup tracking for core effects

///|
let core_current_cleanups : Ref[Array[() -> Unit]?] = Ref::new(None)

///|
/// Create a synchronous effect (runs immediately) - internal implementation
/// Returns a dispose function
fn core_render_effect(fn_ : () -> Unit) -> () -> Unit {
  let cleanups : Array[() -> Unit] = []
  let node : ReactiveNode = ReactiveNode::new(
    ReactiveFlags::Watching.to_int() | ReactiveFlags::RecursedCheck.to_int(),
  )

  // Set up re-run callback for when dependencies change
  node.effect_callback = Some(fn() {
    let flags = node.flags.get_value()
    let dirty_flag = ReactiveFlags::Dirty.to_int()
    let pending_flag = ReactiveFlags::Pending.to_int()

    // Check if we should run based on dirty/pending flags
    let should_run = (flags & dirty_flag) != 0 || (flags & pending_flag) != 0
    if should_run {
      inc_cycle()
      node.deps_tail = None
      node.flags.set_value(
        ReactiveFlags::Watching.to_int() | ReactiveFlags::RecursedCheck.to_int(),
      )

      // Run cleanups before re-running
      core_run_cleanups(cleanups)

      // Run effect with tracking
      let prev_sub = set_active_sub(Some(node))
      let prev_cleanups = core_current_cleanups.val
      core_current_cleanups.val = Some(cleanups)
      fn_()
      core_current_cleanups.val = prev_cleanups
      let _ = set_active_sub(prev_sub)

      // Clear recursed check flag
      let current_flags = node.flags.get_value()
      node.flags.set_value(
        current_flags & (ReactiveFlags::RecursedCheck.to_int() ^ -1),
      )
      purge_deps(node)
    } else {
      node.flags.set_value(ReactiveFlags::Watching.to_int())
    }
  })
  let prev_sub = set_active_sub(Some(node))

  // Link to parent effect if nested
  match prev_sub {
    Some(ps) => link(node, ps, 0)
    None => ()
  }

  // Track cleanups during initial run
  let prev_cleanups = core_current_cleanups.val
  core_current_cleanups.val = Some(cleanups)
  fn_()
  core_current_cleanups.val = prev_cleanups

  // Restore previous subscriber
  let _ = set_active_sub(prev_sub)
  let flags = node.flags.get_value()
  node.flags.set_value(flags & (ReactiveFlags::RecursedCheck.to_int() ^ -1))

  // Return cleanup function
  fn() {
    core_run_cleanups(cleanups)
    cleanup_effect_node(node)
  }
}

///|
/// Run cleanup functions
fn core_run_cleanups(cleanups : Array[() -> Unit]) -> Unit {
  // Run in reverse order (LIFO)
  for i = cleanups.length() - 1; i >= 0; i = i - 1 {
    cleanups[i]()
  }
  cleanups.clear()
}

///|
/// Clean up an effect node
fn cleanup_effect_node(node : ReactiveNode) -> Unit {
  node.deps_tail = None
  node.flags.set_value(ReactiveFlags::None.to_int())
  node.effect_callback = None // Clear callback to prevent re-runs
  purge_deps(node)

  // Unlink from parent if any
  match node.subs {
    Some(sub) => {
      let _ = unlink(sub, sub.sub)

    }
    None => ()
  }
}
