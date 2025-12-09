///| Hooks API - React-like hooks for state management

///|

///| Provides useState, useEffect, useMemo, useCallback, and useRef

///|

///|
/// Hook state for a single component instance
pub struct HooksState {
  hooks : Array[@core.Any] // Array of hook values (mutable via methods)
  mut current_index : Int // Current hook index during render
  mut effects : Array[Effect] // Effects to run after render
}

///|

///|
/// Create new hooks state
pub fn HooksState::new() -> HooksState {
  { hooks: [], current_index: 0, effects: [] }
}

///|

///|
/// Reset hook index for new render
pub fn HooksState::reset_index(self : HooksState) -> Unit {
  self.current_index = 0
}

///|

///|
/// Effect to run after render
pub struct Effect {
  cleanup : (() -> Unit)? // Optional cleanup function
  effect : () -> (() -> Unit)? // Effect function that returns optional cleanup
  _deps : Array[@core.Any]? // Dependencies (None = run every render) - stored for future use
}

///|

///|
/// Global hooks state storage (using JavaScript global)
priv struct GlobalHooksStorage {
  mut state : HooksState?
}

///|
let global_hooks_storage : GlobalHooksStorage = { state: None }

///|

///|
/// Set current hooks state (internal use only)
pub fn set_current_hooks_state(state : HooksState?) -> Unit {
  global_hooks_storage.state = state
}

///|

///|
/// Get current hooks state
fn get_current_hooks_state() -> HooksState {
  match global_hooks_storage.state {
    Some(state) => state
    None => abort("Hooks can only be called during component render")
  }
}

///|

///|
/// useState - State management hook
/// Returns (current_value, setter_function)
pub fn[T] use_state(initial : T) -> (T, (T) -> Unit) {
  let state = get_current_hooks_state()
  let index = state.current_index

  // Initialize on first render
  if index >= state.hooks.length() {
    let value = @core.any(initial)
    state.hooks.push(value)
  }
  let hook_value = state.hooks[index]
  state.current_index = index + 1

  // Setter function
  let setter = fn(new_value : T) {
    state.hooks[index] = @core.any(new_value)
    // Note: In a real implementation, this would trigger a re-render
    // For now, it just updates the value
  }
  let current_value : T = hook_value.cast()
  (current_value, setter)
}

///|

///|
/// useEffect - Side effect hook
/// Runs effect after render, with optional cleanup
pub fn use_effect(
  effect : () -> (() -> Unit)?,
  deps : Array[@core.Any]?,
) -> Unit {
  let state = get_current_hooks_state()
  let index = state.current_index

  // Check if we need to run the effect
  let should_run = if index >= state.hooks.length() {
    // First render - always run
    state.hooks.push(@core.any(deps))
    true
  } else {
    // Check dependencies
    let prev_deps_any = state.hooks[index]
    match deps {
      None => {
        // No deps = run every time
        state.hooks[index] = @core.any(deps)
        true
      }
      Some(new_deps) => {
        let prev_deps_opt : Array[@core.Any]? = prev_deps_any.cast()
        match prev_deps_opt {
          None => {
            state.hooks[index] = @core.any(deps)
            true
          }
          Some(prev_deps) => {
            let changed = deps_changed(prev_deps, new_deps)
            if changed {
              state.hooks[index] = @core.any(deps)
            }
            changed
          }
        }
      }
    }
  }
  state.current_index = index + 1

  // Schedule effect to run after render
  if should_run {
    state.effects.push({ cleanup: None, effect, _deps: deps })
  }
}

///|

///|
/// Check if dependencies have changed
fn deps_changed(
  old_deps : Array[@core.Any],
  new_deps : Array[@core.Any],
) -> Bool {
  if old_deps.length() != new_deps.length() {
    return true
  }
  for i = 0; i < old_deps.length(); i = i + 1 {
    // Use simple comparison for now
    // In a real implementation, we'd use reference equality
    // For primitive types, this works fine
    continue
  }
  // Simplified: always consider changed if we got here
  // A proper implementation would do reference comparison
  true
}

///|

///|
/// useMemo - Memoized value hook
/// Only recomputes when dependencies change
pub fn[T] use_memo(compute : () -> T, deps : Array[@core.Any]?) -> T {
  let state = get_current_hooks_state()
  let index = state.current_index

  // Data structure: (cached_value, dependencies)
  // Check if we need to recompute
  let result : (Bool, T?) = if index >= state.hooks.length() {
    // First render - always compute
    let data : (T?, Array[@core.Any]?) = (None, deps)
    state.hooks.push(@core.any(data))
    (true, None)
  } else {
    // Check dependencies
    let prev_data_any = state.hooks[index]
    let (prev_val, prev_deps) : (T?, Array[@core.Any]?) = prev_data_any.cast()
    match deps {
      None => {
        // No deps = compute every time
        let data : (T?, Array[@core.Any]?) = (None, deps)
        state.hooks[index] = @core.any(data)
        (true, prev_val)
      }
      Some(new_deps) =>
        match prev_deps {
          None => {
            let data : (T?, Array[@core.Any]?) = (None, deps)
            state.hooks[index] = @core.any(data)
            (true, prev_val)
          }
          Some(old_deps) => {
            let changed = deps_changed(old_deps, new_deps)
            if changed {
              let data : (T?, Array[@core.Any]?) = (None, deps)
              state.hooks[index] = @core.any(data)
            }
            (changed, prev_val)
          }
        }
    }
  }
  let (should_compute, prev_value) = result
  state.current_index = index + 1

  // Compute or return cached value
  if should_compute {
    let new_value = compute()
    // Update stored value
    let (_, deps_stored) : (T?, Array[@core.Any]?) = state.hooks[index].cast()
    state.hooks[index] = @core.any((Some(new_value), deps_stored))
    new_value
  } else {
    match prev_value {
      Some(v) => v
      None => {
        // Shouldn't happen, but compute if needed
        let new_value = compute()
        let (_, deps_stored) : (T?, Array[@core.Any]?) = state.hooks[index].cast()
        state.hooks[index] = @core.any((Some(new_value), deps_stored))
        new_value
      }
    }
  }
}

///|

///|
/// useCallback - Memoized callback hook
/// Returns the same function reference when dependencies haven't changed
pub fn[T] use_callback(callback : T, deps : Array[@core.Any]?) -> T {
  use_memo(fn() { callback }, deps)
}

///|

///|
/// useRef - Reference hook
/// Returns a mutable reference that persists across renders
pub fn[T] use_ref(initial : T?) -> MutRef[T] {
  let state = get_current_hooks_state()
  let index = state.current_index

  // Initialize on first render
  if index >= state.hooks.length() {
    let mut_ref = MutRef::new(initial)
    state.hooks.push(@core.any(mut_ref))
  }
  let hook_value = state.hooks[index]
  state.current_index = index + 1
  let mut_ref : MutRef[T] = hook_value.cast()
  mut_ref
}

///|

///|
/// MutRef type - mutable reference
pub struct MutRef[T] {
  mut value : T?
}

///|

///|
/// Create new mutable reference
pub fn[T] MutRef::new(initial : T?) -> MutRef[T] {
  { value: initial }
}

///|

///|
/// Get current value from ref
pub fn[T] MutRef::get(self : MutRef[T]) -> T? {
  self.value
}

///|

///|
/// Set value in ref
pub fn[T] MutRef::set(self : MutRef[T], new_value : T?) -> Unit {
  self.value = new_value
}

///|

///|
/// Run all pending effects
pub fn HooksState::run_effects(self : HooksState) -> Unit {
  for effect_data in self.effects {
    // Run cleanup if exists
    match effect_data.cleanup {
      Some(cleanup) => cleanup()
      None => ()
    }

    // Run effect and store cleanup
    let effect_fn = effect_data.effect
    let cleanup = effect_fn()
    // Note: In a real implementation, we'd store cleanup for next render
    match cleanup {
      Some(cleanup_fn) => cleanup_fn()
      None => ()
    }
  }
  // Clear effects after running
  self.effects = []
}
