// alien-signals style reactive system for MoonBit
// Based on https://github.com/stackblitz/alien-signals

/// Reactive flags for tracking node state
pub(all) enum ReactiveFlags {
  None           // 0
  Mutable        // 1 - Can be updated (signal/computed)
  Watching       // 2 - Effect is watching
  RecursedCheck  // 4 - Checking for recursion
  Recursed       // 8 - Recursion detected
  Dirty          // 16 - Value is stale
  Pending        // 32 - Dependencies may have changed
}

/// Convert flags to int for bitwise operations
pub fn ReactiveFlags::to_int(self : ReactiveFlags) -> Int {
  match self {
    None => 0
    Mutable => 1
    Watching => 2
    RecursedCheck => 4
    Recursed => 8
    Dirty => 16
    Pending => 32
  }
}

/// Bitwise flag set
pub(all) struct Flags {
  mut value : Int
}

pub fn Flags::new(initial : Int) -> Flags {
  { value: initial }
}

pub fn Flags::has(self : Flags, flag : ReactiveFlags) -> Bool {
  (self.value & flag.to_int()) != 0
}

pub fn Flags::set(self : Flags, flag : ReactiveFlags) -> Unit {
  self.value = self.value | flag.to_int()
}

pub fn Flags::unset(self : Flags, flag : ReactiveFlags) -> Unit {
  self.value = self.value & (flag.to_int() ^ (-1))
}

pub fn Flags::has_any(self : Flags, flags : Array[ReactiveFlags]) -> Bool {
  let mask = flags.fold(init=0, fn(acc, f) { acc | f.to_int() })
  (self.value & mask) != 0
}

pub fn Flags::set_value(self : Flags, v : Int) -> Unit {
  self.value = v
}

pub fn Flags::get_value(self : Flags) -> Int {
  self.value
}

/// Double-linked list node connecting dependencies and subscribers
pub(all) struct Link {
  mut version : Int
  dep : ReactiveNode
  sub : ReactiveNode
  mut prev_sub : Link?
  mut next_sub : Link?
  mut prev_dep : Link?
  mut next_dep : Link?
}

/// Base reactive node - can be signal, computed, or effect
pub(all) struct ReactiveNode {
  mut deps : Link?       // First dependency link
  mut deps_tail : Link?  // Last dependency link
  mut subs : Link?       // First subscriber link
  mut subs_tail : Link?  // Last subscriber link
  flags : Flags
  mut last_modified_cycle : Int  // Track when value was last modified
  mut effect_callback : (() -> Unit)?  // Callback for effect re-run
}

pub fn ReactiveNode::new(flags : Int) -> ReactiveNode {
  {
    deps: None,
    deps_tail: None,
    subs: None,
    subs_tail: None,
    flags: Flags::new(flags),
    last_modified_cycle: 0,
    effect_callback: None,
  }
}

/// CoreSignal - internal reactive value container (use Signal for public API)
pub(all) struct CoreSignal[T] {
  node : ReactiveNode
  mut current_value : T
  mut pending_value : T
}

/// Computed node - derives value from dependencies (internal)
pub(all) struct Computed[T] {
  node : ReactiveNode
  mut value : T?
  getter : () -> T
}

/// Effect node - runs side effects
pub(all) struct EffectNode {
  node : ReactiveNode
  run_fn : () -> Unit
}

/// Stack for non-recursive algorithms
struct Stack[T] {
  value : T
  prev : Stack[T]?
}

fn Stack::push[T](prev : Stack[T]?, value : T) -> Stack[T] {
  { value, prev }
}

fn Stack::pop[T](self : Stack[T]) -> (T, Stack[T]?) {
  (self.value, self.prev)
}
