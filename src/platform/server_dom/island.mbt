///| Island helpers for server_dom

///|

///| Provides integration with client-side components through islands.

// =============================================================================
// New ComponentRef-based island API
// =============================================================================

///|
/// Create an island from ComponentRef (type-safe API)
///
/// This is the recommended way to create islands in server components.
/// The ComponentRef contains all necessary information (url, props, trigger, wc flag).
///
/// Example:
/// ```moonbit
/// // In app/__gen__/types/types.mbt (generated)
/// pub fn counter(props: CounterProps) -> @luna.ComponentRef[CounterProps] {
///   @luna.component_ref("/static/counter.js", props)
/// }
///
/// // In server component
/// island_from_ref(
///   @types.counter({ initial_count: 42 }),
///   children=[text("Loading...")],
/// )
/// ```
pub fn[T : ToJson] island_from_ref(
  cref : @luna.ComponentRef[T],
  styles? : String = "",
  children? : Array[@luna.Node[Unit]] = [],
) -> @luna.Node[Unit] {
  @luna.internal_ref(
    cref.url,
    cref.props.to_json().stringify(),
    trigger=cref.trigger,
    wc=cref.wc,
    styles~,
    children~,
  )
}

// =============================================================================
// Legacy island API (for backward compatibility)
// =============================================================================

///|
/// Create an island for client-side hydration (legacy API)
///
/// Example:
/// ```moonbit
/// island(
///   id="counter",
///   url="/components/counter.js",
///   state="{\"count\":0}",
///   children=[text("Loading...")],
/// )
/// ```
pub fn island(
  id : String,
  url : String,
  state? : String,
  trigger? : @luna.TriggerType,
  children~ : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let state_value = match state {
    Some(s) => s
    None => "{}"
  }
  let trigger_value = match trigger {
    Some(t) => t
    None => @luna.Load
  }
  @luna.island(id, url, state_value, children, trigger=trigger_value)
}

///|
/// Create an island with load trigger (hydrates immediately)
/// @deprecated Use `island(id, url, state~, trigger=@luna.Load, children~)` instead
#deprecated("Use island() with trigger parameter instead")
pub fn island_load(
  id : String,
  url : String,
  state : String,
  children~ : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  island(id, url, state~, trigger=@luna.Load, children~)
}

///|
/// Create an island with idle trigger (hydrates when browser is idle)
/// @deprecated Use `island(id, url, state~, trigger=@luna.Idle, children~)` instead
#deprecated("Use island() with trigger parameter instead")
pub fn island_idle(
  id : String,
  url : String,
  state : String,
  children~ : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  island(id, url, state~, trigger=@luna.Idle, children~)
}

///|
/// Create an island with visible trigger (hydrates when visible)
/// @deprecated Use `island(id, url, state~, trigger=@luna.Visible, children~)` instead
#deprecated("Use island() with trigger parameter instead")
pub fn island_visible(
  id : String,
  url : String,
  state : String,
  children~ : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  island(id, url, state~, trigger=@luna.Visible, children~)
}

///|
/// Create an island with media trigger
/// @deprecated Use `island(id, url, state~, trigger=@luna.Media(query), children~)` instead
#deprecated("Use island() with trigger parameter instead")
pub fn island_media(
  id : String,
  url : String,
  state : String,
  media_query : String,
  children~ : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  island(id, url, state~, trigger=@luna.Media(media_query), children~)
}
