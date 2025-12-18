///| Luna top-level re-exports

///|

///| This module re-exports commonly used types and functions from core modules

///| so that users can import from `mizchi/luna` instead of `mizchi/luna/core`, etc.

// =============================================================================
// Core VNode types and functions
// =============================================================================

///|
pub using @core {
  type EventHandler,
  type Attr,
  type TriggerType,
  type Node,
  type VElement,
  type VIsland,
  type VWcIsland,
  type VInternalRef,
  type VAsync,
  type VErrorBoundary,
  type MatchCase,
  type VSwitch,
  type ComponentRef,
  type Trigger,
  handler,
  h,
  text,
  text_dyn,
  text_of,
  fragment,
  show,
  for_each,
  component,
  island,
  wc_island,
  async_,
  error_boundary,
  match_case,
  switch_,
  internal_ref,
  has_dynamic_content,
  attr_static,
  attr_dynamic,
  attr_handler,
  attr_style,
  attr_dynamic_style,
  action,
  component_ref,
  wc_component_ref,
  event_handler,
  handler_from_callback,
}

// =============================================================================
// Signal types and functions
// =============================================================================

///|
pub using @signal {
  type Signal,
  type Owner,
  type EffectRunner,
  type AsyncState,
  type Resource,
  type Context,
  signal,
  effect,
  effect_when,
  effect_once,
  memo,
  computed,
  on,
  on_immediate,
  on_cleanup,
  on_mount,
  batch,
  batch_start,
  batch_end,
  untracked,
  create_root,
  create_root_with_dispose,
  get_owner,
  run_with_owner,
  has_owner,
  register_disposer,
  register_owner_cleanup,
  combine2,
  combine3,
  combine4,
  all,
  any,
  select,
  flatten,
  watch,
  watch_immediate,
  previous,
  previous_with_initial,
  resource,
  resource_resolved,
  resource_rejected,
  deferred,
  create_context,
  provide,
  use_context,
}
