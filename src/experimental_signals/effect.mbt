// Effect - reactive side effects
// Compatible with signal module API

// Cleanup tracking
let current_cleanups : Ref[Array[() -> Unit]?] = Ref::new(None)

/// Register a cleanup function to run before the effect re-runs or is disposed
pub fn on_cleanup(cleanup : () -> Unit) -> Unit {
  match current_cleanups.val {
    Some(arr) => arr.push(cleanup)
    None => () // Not inside an effect, ignore
  }
}

/// Run a function without tracking dependencies
pub fn[T] untracked(f : () -> T) -> T {
  let prev = set_active_sub(None)
  let result = f()
  let _ = set_active_sub(prev)
  result
}

/// Create a synchronous effect (runs immediately)
/// Returns a dispose function
/// ```
/// let count = signal(0)
/// let dispose = render_effect(fn() { println(count.get()) })  // prints 0
/// count.set(1)  // prints 1
/// dispose()  // stop watching
/// count.set(2)  // no output
/// ```
pub fn render_effect(fn_ : () -> Unit) -> () -> Unit {
  let cleanups : Array[() -> Unit] = []
  let node : ReactiveNode = ReactiveNode::new(
    ReactiveFlags::Watching.to_int() | ReactiveFlags::RecursedCheck.to_int()
  )

  // Set up re-run callback for when dependencies change
  node.effect_callback = Some(
    fn() {
      let flags = node.flags.get_value()
      let dirty_flag = ReactiveFlags::Dirty.to_int()
      let pending_flag = ReactiveFlags::Pending.to_int()

      // Check if we should run based on dirty/pending flags
      let should_run = (flags & dirty_flag) != 0 ||
        (flags & pending_flag) != 0

      if should_run {
        inc_cycle()
        node.deps_tail = None
        node.flags.set_value(
          ReactiveFlags::Watching.to_int() | ReactiveFlags::RecursedCheck.to_int()
        )

        // Run cleanups before re-running
        run_cleanups(cleanups)

        // Run effect with tracking
        let prev_sub = set_active_sub(Some(node))
        let prev_cleanups = current_cleanups.val
        current_cleanups.val = Some(cleanups)
        fn_()
        current_cleanups.val = prev_cleanups
        let _ = set_active_sub(prev_sub)

        // Clear recursed check flag
        let current_flags = node.flags.get_value()
        node.flags.set_value(
          current_flags & (ReactiveFlags::RecursedCheck.to_int() ^ (-1))
        )
        purge_deps(node)
      } else {
        node.flags.set_value(ReactiveFlags::Watching.to_int())
      }
    },
  )

  let prev_sub = set_active_sub(Some(node))

  // Link to parent effect if nested
  match prev_sub {
    Some(ps) => link(node, ps, 0)
    None => ()
  }

  // Track cleanups during initial run
  let prev_cleanups = current_cleanups.val
  current_cleanups.val = Some(cleanups)
  fn_()
  current_cleanups.val = prev_cleanups

  // Restore previous subscriber
  let _ = set_active_sub(prev_sub)
  let flags = node.flags.get_value()
  node.flags.set_value(flags & (ReactiveFlags::RecursedCheck.to_int() ^ (-1)))

  // Return cleanup function
  fn() {
    run_cleanups(cleanups)
    cleanup_effect_node(node)
  }
}

/// Alias for render_effect (synchronous effect)
pub fn effect(fn_ : () -> Unit) -> () -> Unit {
  render_effect(fn_)
}

/// Run cleanup functions
fn run_cleanups(cleanups : Array[() -> Unit]) -> Unit {
  // Run in reverse order (LIFO)
  for i = cleanups.length() - 1; i >= 0; i = i - 1 {
    cleanups[i]()
  }
  cleanups.clear()
}

/// Stop an effect from running (deprecated - use cleanup_effect_node directly)
fn stop_effect(e : EffectNode) -> Unit {
  cleanup_effect_node(e.node)
}

/// Stop an effect node from running
fn stop_effect_node(node : ReactiveNode) -> Unit {
  cleanup_effect_node(node)
}

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

/// Create an effect scope that can be stopped together
/// ```
/// let count = signal(0)
/// let stop = effect_scope(fn() {
///   effect(fn() { println("a: " + count.get().to_string()) })
///   effect(fn() { println("b: " + count.get().to_string()) })
/// })
/// count.set(1)  // both effects run
/// stop()  // stop all effects in scope
/// count.set(2)  // no output
/// ```
pub fn effect_scope(fn_ : () -> Unit) -> () -> Unit {
  let e : ReactiveNode = ReactiveNode::new(ReactiveFlags::None.to_int())

  let prev_sub = set_active_sub(Some(e))

  // Link to parent scope if nested
  match prev_sub {
    Some(ps) => link(e, ps, 0)
    None => ()
  }

  // Run the scope
  fn_()

  // Restore previous subscriber
  let _ = set_active_sub(prev_sub)

  // Return cleanup function
  fn() { cleanup_effect_node(e) }
}

/// Batch multiple updates together
/// Effects won't run until the batch is complete
/// ```
/// let a = signal(0)
/// let b = signal(0)
/// effect(fn() { println(a.get() + b.get()) })  // prints 0
/// batch(fn() {
///   a.set(1)
///   b.set(2)
/// })  // prints 3 (only once, not twice)
/// ```
pub fn batch(fn_ : () -> Unit) -> Unit {
  start_batch()
  fn_()
  end_batch()
}

/// Manually trigger updates for a signal after direct mutation
/// ```
/// let arr = signal([])
/// let len = memo(fn() { arr.get().length() })
/// arr.peek().push(1)  // Direct mutation
/// trigger_signal(arr)  // Manually trigger
/// println(len.get())  // 1
/// ```
pub fn trigger_signal[T](sig : Signal[T]) -> Unit {
  let sub : ReactiveNode = ReactiveNode::new(ReactiveFlags::Watching.to_int())

  let prev_sub = set_active_sub(Some(sub))

  // Touch the signal to create a link
  let _ = sig.get()

  // Restore previous subscriber
  let _ = set_active_sub(prev_sub)

  // Propagate to all links
  let mut dep_link = sub.deps
  while dep_link.is_some() {
    match dep_link {
      Some(lnk) => {
        let dep = lnk.dep
        dep_link = unlink(lnk, sub)
        match dep.subs {
          Some(subs) => {
            sub.flags.set_value(ReactiveFlags::None.to_int())
            propagate(subs)
            shallow_propagate(subs)
          }
          None => ()
        }
      }
      None => ()
    }
  }

  if get_batch_depth() == 0 {
    flush()
  }
}
