// Signal module - Re-exports from @signals
// All core signal functionality is provided by mizchi/signals

// Signal and reactive primitives

///|
pub using @signals {type Signal, signal, on, on_immediate}

// Effects

///|
pub using @signals {render_effect, effect, effect_when, effect_once, on_mount}

// Memo and computed

///|
pub using @signals {memo, computed}

// Context and lifecycle

///|
pub using @signals {
  type Owner,
  new_effect_id,
  untracked,
  batch_start,
  batch_end,
  batch,
  is_batching,
  on_cleanup,
  set_current_cleanups,
  run_with_cleanup_tracking,
  get_owner,
  run_with_owner,
  create_root,
  create_root_with_dispose,
  register_disposer,
  register_owner_cleanup,
  has_owner,
  with_parent_owner,
}

// Combinators

///|
pub using @signals {
  sig_map,
  sig_filter,
  sig_filter_map,
  combine2,
  combine3,
  combine4,
  all,
  any,
  select,
  to_getter,
  flatten,
  switch_,
}

// Watch

///|
pub using @signals {watch, watch_immediate, previous, previous_with_initial}

// Context Provider

///|
pub using @signals {type Context, create_context, provide, use_context}

// Store

///|
pub using @signals {
  type SplitStore2,
  type SplitStore3,
  type Lens,
  type LensStore,
  trait Snapshot,
}
