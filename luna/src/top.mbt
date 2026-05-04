// Luna top-level re-exports
//
// This module re-exports commonly used types and functions from core modules
// so that users can import from `mizchi/luna` instead of `mizchi/luna/core`, etc.

// =============================================================================
// Core VNode types and functions (from core/vnode.mbt)
// =============================================================================

///|
// Types
pub using @core {
  type EventHandler,
  type Attr,
  type Node,
  type VElement,
  type VIsland,
  type VWcIsland,
  type VAsync,
  type VErrorBoundary,
  type VSwitch,
  type MatchCase,
  type VInternalRef,
  type TriggerType,
  type Trigger,
  type ComponentRef,

  // Factory functions
  handler,
  h,
  text,
  text_dyn,
  fragment,
  raw_html,
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

  // Attr factory functions
  attr_static,
  attr_dynamic,
  attr_handler,
  attr_style,
  attr_dynamic_style,
  action,

  // ComponentRef functions
  component_ref,
  wc_component_ref,

  // SSR functions
  event_handler,
  handler_from_callback,

  // Utilities
  has_dynamic_content,
}

// =============================================================================
// AsyncState (from signals/ui)
// =============================================================================

///|
pub using @ui {type AsyncState}

// =============================================================================
// Signal types and functions (from js/resource)
// =============================================================================

///|
pub using @resource {
  type Signal,
  type Owner,
  type Resource,
  type Context,
  signal,
  effect,
  render_effect,
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

// =============================================================================
// Signal-dependent VNode functions (defined here to avoid core -> resource dep)
// =============================================================================

///|
/// Create a text VNode from a signal.
/// Shorthand for `text_dyn(fn() { sig.get().to_string() })`.
pub fn[E, A, T : Show] text_of(sig : @resource.Signal[T]) -> @core.Node[E, A] {
  @core.DynamicText(fn() { sig.get().to_string() })
}
