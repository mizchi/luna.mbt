// Effect - reactive side effects
// alien-signals style API

/// Create an effect that runs when its dependencies change
/// Returns a cleanup function
/// ```
/// let count = signal(0)
/// let stop = effect(fn() { println(count.get()) })  // prints 0
/// count.set(1)  // prints 1
/// stop()  // stop watching
/// count.set(2)  // no output
/// ```
pub fn effect(fn_ : () -> Unit) -> () -> Unit {
  let e : EffectNode = {
    node: ReactiveNode::new(
      ReactiveFlags::Watching.to_int() | ReactiveFlags::RecursedCheck.to_int()
    ),
    run_fn: fn_,
  }

  let prev_sub = set_active_sub(Some(e.node))

  // Link to parent effect if nested
  match prev_sub {
    Some(ps) => link(e.node, ps, 0)
    None => ()
  }

  // Run the effect
  (e.run_fn)()

  // Restore previous subscriber
  let _ = set_active_sub(prev_sub)
  let flags = e.node.flags.get_value()
  e.node.flags.set_value(flags & (ReactiveFlags::RecursedCheck.to_int() ^ (-1)))

  // Return cleanup function
  fn() { stop_effect(e) }
}

/// Stop an effect from running
fn stop_effect(e : EffectNode) -> Unit {
  cleanup_effect_node(e.node)
}

/// Clean up an effect node
fn cleanup_effect_node(node : ReactiveNode) -> Unit {
  node.deps_tail = None
  node.flags.set_value(ReactiveFlags::None.to_int())
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
/// let len = computed(fn(_) { arr.get().length() })
/// arr.peek().push(1)  // Direct mutation
/// trigger_signal(arr)  // Manually trigger
/// println(len.get())  // 1
/// ```
pub fn trigger_signal[T](sig : SignalNode[T]) -> Unit {
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
