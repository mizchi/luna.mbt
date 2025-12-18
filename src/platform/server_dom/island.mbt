// Island helpers for server_dom
//
// Provides integration with client-side components through islands.

// =============================================================================
// Type-safe client component API (Recommended)
// =============================================================================

///|
/// Embed a client component with type-safe props
///
/// This is the recommended way to create interactive components in server-rendered HTML.
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
/// client(
///   @types.counter({ initial_count: 42 }),
///   children=[text("Loading...")],
/// )
/// ```
pub fn[T : ToJson] client(
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

///|
/// @deprecated Use `client()` instead
#deprecated("Use client() instead")
pub fn[T : ToJson] island_from_ref(
  cref : @luna.ComponentRef[T],
  styles? : String = "",
  children? : Array[@luna.Node[Unit]] = [],
) -> @luna.Node[Unit] {
  client(cref, styles~, children~)
}

// =============================================================================
// Legacy island API (deprecated)
// =============================================================================

///|
/// Create an island for client-side hydration (legacy API)
///
/// @deprecated Use `client()` with ComponentRef instead
///
/// Example:
/// ```moonbit
/// // Old way (deprecated):
/// island(
///   id="counter",
///   url="/components/counter.js",
///   state="{\"count\":0}",
///   children=[text("Loading...")],
/// )
///
/// // New way (recommended):
/// client(@types.counter({ initial_count: 0 }), children=[text("Loading...")])
/// ```
#deprecated("Use client() with ComponentRef instead")
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
/// @deprecated Use `client()` with ComponentRef instead
#deprecated("Use client() with ComponentRef instead")
pub fn island_load(
  id : String,
  url : String,
  state : String,
  children~ : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  island(id, url, state~, trigger=@luna.Load, children~)
}

///|
/// @deprecated Use `client()` with ComponentRef instead
#deprecated("Use client() with ComponentRef instead")
pub fn island_idle(
  id : String,
  url : String,
  state : String,
  children~ : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  island(id, url, state~, trigger=@luna.Idle, children~)
}

///|
/// @deprecated Use `client()` with ComponentRef instead
#deprecated("Use client() with ComponentRef instead")
pub fn island_visible(
  id : String,
  url : String,
  state : String,
  children~ : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  island(id, url, state~, trigger=@luna.Visible, children~)
}

///|
/// @deprecated Use `client()` with ComponentRef instead
#deprecated("Use client() with ComponentRef instead")
pub fn island_media(
  id : String,
  url : String,
  state : String,
  media_query : String,
  children~ : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  island(id, url, state~, trigger=@luna.Media(media_query), children~)
}
