///| Island helpers for server_dom

///|

///| Provides integration with client-side components through islands.

///|
/// Create an island for client-side hydration
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
  trigger? : @luna.IslandTrigger,
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
  @luna.visland(id, url, state_value, children, trigger=trigger_value)
}

///|
/// Create an island with load trigger (hydrates immediately)
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
pub fn island_media(
  id : String,
  url : String,
  state : String,
  media_query : String,
  children~ : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  island(id, url, state~, trigger=@luna.Media(media_query), children~)
}
